defmodule Geometrics.Phoenix.View do
  @moduledoc """
  Provides a mechanism for an OpenTelemetry trace created
  """

  alias Geometrics.Plug.OpenTelemetry
  alias Phoenix.HTML.Tag

  def meta_tags(conn) do
    [
      traceparent(conn),
      collector_host()
    ]
  end

  def collector_host() do
    Tag.tag(:meta,
      name: "collector_endpoint",
      content: Application.get_env(:geometrics, :collector_endpoint)
    )
  end

  def traceparent(conn) do
    traceparent =
      conn
      |> OpenTelemetry.current_context()
      |> OpenTelemetry.traceparent()

    Tag.tag(:meta,
      name: "traceparent",
      content: traceparent
    )
  end
end
