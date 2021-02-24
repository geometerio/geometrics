defmodule Geometrics.OpenTelemetry.Logger do
  @moduledoc """
  Capture crashes and exits with open spans. This helps to capture problems where a
  system is overloaded or under-optimized, and timeouts occur. Timeout errors (in Ecto,
  or when `call`ing into GenServers) typically trigger `exit` instead of raising exceptions.

  Frameworks such as `Phoenix` and `Phoenix.LiveView` use `:telemetry`, with wrappers that
  rescue and reraise exceptions, but which do not catch exits. For this reason, exits and
  other timeout errors can interrupt application tracing, since spans opened in processes
  may otherwise never be closed, and therefore never be exported.

  This module requires that when a span is opened, it be

  References:

  * https://github.com/elixir-lang/elixir/blob/v1.11.3/lib/logger/lib/logger/backends/console.ex

  """

  @behaviour :gen_event

  defstruct level: nil

  @doc """
  Given an otel span context, ensure that it is saved in the Logger metadata for the current process.
  If the process crashes or exits, the custom logger defined by this file will receive an error event,
  and can send telemetry to indicate that the span should be closed.
  """
  def track_span_ctx(span_ctx) do
    spans =
      Logger.metadata()
      |> Keyword.get(:ot_spans, [])
      |> List.insert_at(0, span_ctx)

    Logger.metadata(ot_spans: spans)

    span_ctx
  end

  @doc """
  When ending a span, it no longer needs to be tracked by the Logger.
  """
  def pop_span_ctx do
    spans =
      Logger.metadata()
      |> Keyword.get(:ot_spans, [])
      |> case do
        [_span | rest] -> rest
        [] -> []
      end

    Logger.metadata(ot_spans: spans)
    spans
  end

  def init(__MODULE__), do: init({__MODULE__, :geometrics_logger})

  def init({__MODULE__, config_name}) do
    config = Application.get_env(:logger, config_name)
    {:ok, new(config, %__MODULE__{})}
  end

  def handle_call({:configure, _options}, state) do
    {:ok, :ok, state}
  end

  def handle_event({:info, _, _}, state), do: {:ok, state}

  def handle_event({:error, _pid, {Logger, _, _timestamp, metadata}}, state) do
    case Keyword.get(metadata, :crash_reason) do
      nil ->
        {:ok, state}

      {crash_reason, stacktrace} ->
        case Keyword.get(metadata, :ot_spans) do
          nil ->
            {:ok, state}

          spans when is_list(spans) ->
            :telemetry.execute([:geometrics, :open_telemetry, :exit], %{}, %{
              spans: spans,
              reason: crash_reason,
              stacktrace: stacktrace
            })

            {:ok, state}
        end
    end

    {:ok, state}
  end

  def handle_event({level, _gl, _thing} = _event, state) do
    %{level: log_level} = state

    if meet_level?(level, log_level) do
      {:ok, state}
    else
      {:ok, state}
    end
  end

  def handle_event(:flush, state) do
    {:ok, flush(state)}
  end

  def handle_event(_msg, state) do
    {:ok, state}
  end

  def handle_info({:io_reply, _ref, _msg}, state), do: {:ok, state}
  def handle_info({:EXIT, _pid, _reason}, state), do: {:ok, state}

  defp flush(state), do: state

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp new(config, state) do
    level = Keyword.get(config, :level, :error)

    %{
      state
      | level: level
    }
  end
end
