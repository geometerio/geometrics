# Geometrics

An opinionated library for adding application tracing and metrics to a Phoenix application. Geometrics includes
dependencies which hook into Phoenix and Ecto [telemetry](https://hexdocs.pm/phoenix/telemetry.html), adding support for
LiveView as well as crash tracking.

This repo also contains informative [guides](https://hexdocs.pm/geometrics) to help you wrap your head around
Application tracing concepts which can be notoriously confusing, especially in Elixir and Erlang. It is worth reading
these before diving in.

## Basic Usage

Given this simple LiveView module in a Phoenix application:

```elixir
defmodule GeometerTracingDemosWeb.PageLive do
  use GeometerTracingDemosWeb, :live_view

  alias GeometerTracingDemos.Repo
  alias GeometerTracingDemos.SomeModel

  require OpenTelemetry.Tracer

  @impl true
  def mount(_params, _session, socket) do
    ...
  end

  @impl true
  def handle_event("create", %{"some_model" => form_attrs}, socket) do
    # This is an example of adding a custom span to your application. All of the other application traces in the image
    # below come by default after installing Geometrics without any other changes to source code.
    OpenTelemetry.Tracer.with_span "My custom span" do
      %SomeModel{}
      |> SomeModel.changeset(form_attrs)
      |> Repo.insert()
    end

    {:noreply, socket}
  end
end
```

You can see an application trace that extends throughout an entire live view session.

![Honeycomb Trace Exmample](guides/assets/honeycomb_trace_example.png)

(Note that the trace shown here is from the [Honeycomb.io](https://www.honeycomb.io/) UI, but should carry over to any
Application tracing service)

## Why does this library exists?

1. To distill knowledge gleaned from dissecting the somewhat overwhelming OpenTelemetry/observability ecosystem into an
   easily consumed set of [guides](https://hexdocs.pm/geometrics).
2. To provide Phoenix LiveView observability, which has not yet been included into OpenTelemetry the way
   that [Phoenix](https://github.com/opentelemetry-beam/opentelemetry_phoenix)
   and [Ecto](https://github.com/opentelemetry-beam/opentelemetry_ecto) have.
3. To generally make it easier to get started with observing your Phoenix application

## Installation

[Installation guide](https://hexdocs.pm/geometrics/installation.html).

## References

For further reading, see [the guides](https://hexdocs.pm/geometrics).

External references:

- https://opentelemetry.io/docs/concepts/what-is-opentelemetry/
- https://opentelemetry.io/docs/erlang/getting-started/
- https://github.com/open-telemetry/opentelemetry-specification
