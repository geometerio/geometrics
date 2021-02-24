defmodule Geometrics.Plug.OpenTelemetry do
  @moduledoc """
  Ensure that the current OpenTelemetry context is available to the conn.
  """

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    OpenTelemetry.Tracer.current_span_ctx()
    |> case do
      :undefined ->
        Logger.warn("[#{__MODULE__}] expected current process have an OpenTelemetry span, but does not")
        conn

      span_ctx ->
        conn
        |> Plug.Conn.put_private(:__current_ot_ctx__, span_ctx)
    end
  end

  def current_context(conn) do
    conn.private.__current_ot_ctx__
  end
end
