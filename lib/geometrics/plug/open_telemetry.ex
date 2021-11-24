defmodule Geometrics.Plug.OpenTelemetry do
  @moduledoc """
  Ensure that the current OpenTelemetry context is available to the conn.
  """

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    :otel_ctx.get_current()
    |> case do
      ctx when map_size(ctx) == 0 ->
        Logger.warn(
          "[#{__MODULE__}] expected current process have an OpenTelemetry span, but does not"
        )

        conn

      otel_ctx ->
        conn
        |> Plug.Conn.put_private(:__current_ot_ctx__, otel_ctx)
        |> Plug.Conn.put_resp_header("traceparent", traceparent(otel_ctx))
    end
  end

  def current_context(conn) do
    conn.private.__current_ot_ctx__
  end

  def traceparent(otel_ctx) do
    :otel_propagator_trace_context.inject(
      otel_ctx,
      [],
      &:otel_propagator_text_map.default_carrier_set/3,
      []
    )
    |> Enum.find(fn {key, _val} -> key == "traceparent" end)
    |> case do
      {"traceparent", traceparent} -> traceparent
      _ -> ""
    end
  end
end
