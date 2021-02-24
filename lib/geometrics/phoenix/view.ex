defmodule Geometrics.Phoenix.View do
  @moduledoc """
  Provides a mechanism for an OpenTelemetry trace created
  """

  alias Geometrics.Plug.OpenTelemetry
  alias Phoenix.HTML.Tag

  def traceparent(conn) do
    content =
      conn
      |> OpenTelemetry.current_context()
      |> :otel_propagator_http_w3c.encode()

    Tag.tag(:meta,
      name: "traceparent",
      content: content
    )
  end
end
