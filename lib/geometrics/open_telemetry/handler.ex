defmodule Geometrics.OpenTelemetry.Handler do
  @moduledoc """
  Configures OpenTelemetry to collect traces from Phoenix, Ecto, and LiveView.
  """
  @dialyzer {:nowarn_function, connection_status: 1}
  @dialyzer {:nowarn_function, create_child_span: 3}
  @dialyzer {:nowarn_function, create_parent_ctx: 1}
  @dialyzer {:nowarn_function, get_peer_data: 1}
  @dialyzer {:nowarn_function, get_user_agent: 1}
  @dialyzer {:nowarn_function, handle_cast: 2}
  @dialyzer {:nowarn_function, handle_exception: 4}
  @dialyzer {:nowarn_function, handle_initial_lv_mount: 1}
  @dialyzer {:nowarn_function, handle_lv_connect_mount: 1}
  @dialyzer {:nowarn_function, open_child_span: 4}

  use GenServer

  alias Geometrics.OpenTelemetry.Handler
  alias Geometrics.OpenTelemetry.Logger, as: OTLogger
  alias OpenTelemetry.Ctx
  alias OpenTelemetry.Span
  alias OpenTelemetry.Tracer
  alias OpentelemetryPhoenix.Reason
  require Logger
  require OpenTelemetry.Tracer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    setup()

    {:ok, nil}
  end

  @doc """
  Sets up telemetry attachments. Some bindings are registered via `OpentelemetryPhoenix`
  and `OpentelemetryEcto`, but since neither of those handle LiveView we attach our own
  bindings for those events.

  Some bindings are attached before the library code, so that we can add some normalized
  attributes across most events.
  """
  def setup() do
    #### exception attachments need to be registered *before* we setup
    #### OpentelemetryPhoenix or OpentelemetryEcto, so we can alter
    #### the OT spans before those libraries end any spans
    :telemetry.attach_many(
      "opentelemetry-error-handler",
      [
        [:phoenix, :endpoint, :exception],
        [:phoenix, :router_dispatch, :exception]
      ],
      &Handler.handle_errors/4,
      []
    )

    ecto_prefix = Application.get_env(:geometrics, :ecto_prefix)

    OpentelemetryPhoenix.setup()

    if ecto_prefix,
      do: OpentelemetryEcto.setup(ecto_prefix, time_unit: :millisecond)

    #### start attachments need to be registered *after* we setup
    #### OpentelemetryPhoenix or OpentelemetryEcto, so OT spans are already
    #### created for the current process.
    :telemetry.attach_many(
      "opentelemetry-phoenix-handler",
      [
        [:phoenix, :endpoint, :start],
        [:phoenix, :router_dispatch, :start],
        [:phoenix, :error_rendered]
      ],
      &Handler.add_ot_span_to_logger/4,
      []
    )

    #### Our custom telemetry handlers operate outside the scope of the
    #### external libraries, so can be attached in any order.
    :telemetry.attach_many(
      "opentelemetry-exception-handler",
      [
        [:geometrics, :open_telemetry, :exit],
        [:phoenix, :live_view, :handle_event, :exception],
        [:phoenix, :live_view, :mount, :exception]
      ],
      &Handler.handle_exception/4,
      []
    )

    :telemetry.attach_many(
      "opentelemetry-start-handler",
      [
        [:phoenix, :live_view, :handle_event, :start],
        [:phoenix, :live_view, :mount, :start]
      ],
      &Handler.open_child_span/4,
      []
    )

    :telemetry.attach_many(
      "opentelemetry-stop-handler",
      [
        [:phoenix, :live_view, :handle_event, :stop],
        [:phoenix, :live_view, :mount, :stop]
      ],
      &Handler.handle_success/4,
      []
    )
  end

  @doc """
  Given a telemetry event signaling that an action has begun, open a new child span.
  Makes sure that a parent span is either created, or attached to, so that events appear
  as siblings in a single trace spanning the LiveView session.

  Note that child spans pull attributes off of the socket that are only present if the
  `:connect_info` is configured to include them in the Endpoint:

      socket "/live", Phoenix.LiveView.Socket,
        websocket: [
          connect_info: [
            :peer_data,
            :trace_context_headers,
            :user_agent,
            :x_headers,
            session: @session_options
          ]
        ]
  """
  def open_child_span([:phoenix, :live_view, :handle_event, :start], _payload, meta, _config) do
    get_parent_ctx()
    |> create_child_span("HANDLE_EVENT #{meta.event}", meta.socket)
  end

  def open_child_span([:phoenix, :live_view, :mount, :start], _payload, meta, _config) do
    case meta.socket do
      %{root_pid: nil} ->
        handle_initial_lv_mount(meta.socket)

      %{root_pid: _root_pid} ->
        handle_lv_connect_mount(meta.socket)
    end
  end

  defp handle_initial_lv_mount(socket) do
    create_parent_ctx("LIVE #{to_module(socket.view)}")
    |> create_child_span("INITIAL MOUNT #{to_module(socket.view)}", socket)
  end

  defp handle_lv_connect_mount(socket) do
    case socket.private.connect_params do
      %{"traceContext" => trace_context} ->
        headers = [
          {"traceparent", "00-#{trace_context["traceId"]}-#{trace_context["spanId"]}-00"}
        ]

        :otel_propagator_text_map.extract(headers)

      _ ->
        if Application.get_env(:geometrics, :warn_on_no_trace_context, true),
          do: IO.warn("No traceContext on connect_params")
    end

    create_parent_ctx("SECOND MOUNT #{to_module(socket.view)}")
  end

  defp create_child_span(parent_ctx, span_name, socket) do
    new_ctx =
      Tracer.start_span(parent_ctx, span_name, %{kind: :SERVER})
      |> OTLogger.track_span_ctx()

    _ = Tracer.set_current_span(new_ctx)

    peer_data = get_peer_data(socket)
    user_agent = get_user_agent(socket)
    # peer_ip = Map.get(peer_data, :address)

    attributes = [
      #   "http.client_ip": client_ip(conn),
      #   "http.flavor": http_flavor(adapter),
      "http.host": socket.host_uri.host,
      #   "http.method": conn.method,
      "http.scheme": socket.host_uri.scheme,
      #   "http.target": conn.request_path,
      "http.user_agent": user_agent,
      "live_view.connection_status": connection_status(socket),
      #   "net.host.ip": to_string(:inet_parse.ntoa(conn.remote_ip)),
      "net.host.port": socket.host_uri.port,
      # "net.peer.ip": to_string(:inet_parse.ntoa(peer_ip)),
      "net.peer.port": peer_data.port,
      "net.transport": :"IP.TCP"
    ]

    Span.set_attributes(new_ctx, attributes)
  end

  defp create_parent_ctx(name) do
    parent_span = Tracer.start_span(name, %{kind: :SERVER})
    parent_ctx = Tracer.set_current_span(parent_span)

    _prev_ctx = Ctx.attach(parent_ctx)
    Span.end_span(parent_span)
    Process.put(:ot_parent_ctx, parent_ctx)

    parent_ctx
  end

  defp get_parent_ctx() do
    parent_ctx = Process.get(:ot_parent_ctx)
    _prev_ctx = Ctx.attach(parent_ctx)
    parent_ctx
  end

  @doc """
  Caught exits are cast to ourselves, so that we do not interrupt the logger.
  """
  def handle_cast(
        {:caught_exit, _payload, %{spans: spans, reason: reason, stacktrace: stacktrace}},
        state
      ) do
    crash_attrs =
      Keyword.merge(
        [
          type: :exit,
          stacktrace: Exception.format_stacktrace(stacktrace)
        ],
        Reason.normalize(reason)
      )

    for span_ctx <- spans do
      Span.set_attribute(span_ctx, :status, :crash)
      Span.add_event(span_ctx, "crash", crash_attrs)
      Span.set_status(span_ctx, OpenTelemetry.status(:Error, "Error"))

      OpenTelemetry.Span.end_span(span_ctx)
    end

    {:noreply, state}
  end

  @doc """
  Intended for exceptions that happen during spans that have been opened by OpentelemetryPhoenix or OpentelemetryEcto.
  Those libraries do not put a high-level `:status` key in the data, which we do for our spans to normalize across different
  event types.
  """
  def handle_errors(_event, _payload, _metadata, _config) do
    span_ctx = Tracer.current_span_ctx()
    Span.set_attribute(span_ctx, :status, :error)
    Span.end_span(span_ctx)
  end

  @doc """
  Catch message around exits and exceptions, to make sure that spans are marked with crash/exception status and
  closed.
  """
  def handle_exception([:geometrics, :open_telemetry, :exit], payload, metadata, _config) do
    GenServer.cast(__MODULE__, {:caught_exit, payload, metadata})
  end

  def handle_exception(
        [:phoenix, :live_view, _, :exception],
        _payload,
        %{kind: kind, reason: reason, stacktrace: stacktrace},
        _config
      ) do
    exception_attrs =
      Keyword.merge(
        [
          type: kind,
          stacktrace: Exception.format_stacktrace(stacktrace)
        ],
        Reason.normalize(reason)
      )

    status = OpenTelemetry.status(:Error, "Error")
    span_ctx = Tracer.current_span_ctx()
    Span.set_attribute(span_ctx, :status, :error)

    Span.add_event(span_ctx, "exception", exception_attrs)
    Span.set_status(span_ctx, status)
    Span.end_span(span_ctx)

    pop_span_ctx()
  end

  @doc """
  Set status to `:ok` when a `:stop` event fires, which suggests that whatever happened
  was successful, ie did not crash or raise.
  """
  def handle_success([:phoenix, :live_view, _, :stop], _payload, _meta, _config) do
    span_ctx = Tracer.current_span_ctx()
    Span.set_attribute(span_ctx, :status, :ok)
    Span.end_span(span_ctx)
    pop_span_ctx()
  end

  @doc """
  When crashes or exits occur, rather than exceptions, no telemetry fires to close open
  spans. To get around this, we keep a list of open spans in the `Logger.metadata`, and
  cheOTLogger in a `Geometrics.OpenTelemetry.Logger`.

  If a crash occurs where any `:ot_spans` live in the metadata, a `[:geometrics, :open_telemetry, :exit]`
  telemetry event is fired, which gets picked up by our `handle_exception` binding.
  """
  def add_ot_span_to_logger(event, _payload, _meta, _config) do
    Tracer.current_span_ctx()
    |> case do
      :undefined ->
        Logger.warn(
          "[#{__MODULE__}] (#{inspect(event)}) expected current process have an OpenTelemetry span, but does not"
        )

      span_ctx ->
        span_ctx
        |> OTLogger.track_span_ctx()
    end
  end

  #### See if any of this info is present on a socket in the context
  #### of GCP / DO.
  # defp client_ip(%{remote_ip: remote_ip} = conn) do
  #   case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
  #     [] ->
  #       to_string(:inet_parse.ntoa(remote_ip))

  #     [client | _] ->
  #       client
  #   end
  # end

  defp pop_span_ctx() do
    OTLogger.pop_span_ctx()
    |> case do
      [parent | _] -> parent
      _ -> :undefined
    end
    |> Tracer.set_current_span()
  end

  defp get_peer_data(%{private: %{connect_info: %{peer_data: peer_data}}}), do: peer_data
  defp get_peer_data(_), do: %{port: nil, address: nil, ssl_cert: nil}

  defp get_user_agent(%{private: %{connect_info: %{user_agent: user_agent}}}), do: user_agent
  defp get_user_agent(_), do: ""

  defp connection_status(socket) do
    if Phoenix.LiveView.connected?(socket),
      do: "connected",
      else: "disconnected"
  end

  defp to_module(module) do
    module
    |> to_string()
    |> case do
      "Elixir." <> name -> name
      erlang_module -> ":#{erlang_module}"
    end
  end
end
