# Geometrics

An opinionated library for adding application tracing and metrics to a Phoenix application. Geometrics includes
dependencies which hook into Phoenix and Ecto [telemetry](https://hexdocs.pm/phoenix/telemetry.html), adding support for
LiveView as well as crash tracking.

This repo also contains informative [guides](https://geometerio.github.io/geometrics) to help you wrap your head around
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
   easily consumed set of [guides](https://geometerio.github.io/geometrics).
2. To provide Phoenix LiveView observability, which has not yet been included into OpenTelemetry the way
   that [Phoenix](https://github.com/opentelemetry-beam/opentelemetry_phoenix)
   and [Ecto](https://github.com/opentelemetry-beam/opentelemetry_ecto) have.
3. To generally make it easier to get started with observing your Phoenix application

## Installation

[Installation guide](https://geometerio.github.io/geometrics/installation.html).

## Running the OpenTelemetry collector

In order to actually report data to Honeycomb (or other services), you will need to run
an [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector). This component is responsible
for receiving, processing and exporting OpenTelemetry data to external services.

To do this you will need to run an installation script (note that you will need to set `HONEYCOMB_DATASET`
and `HONEYCOMB_WRITE_KEY` in your environment before running this command):

`mix geometrics.install`

This will copy a `docker-compose.yml` file used to run the collector into your projects top level directory. It will
also copy over a configuration file, `otel-collector-config.yml`, used to configure the collector Docker process.

To run the collector, simply run `docker compose up`. You should now see metrics data appear in Honeycomb under the
dataset configured by `HONEYCOMB_DATASET`.

**Reporting to other third-party tracing services**:

By default the `otel-collector-config.yml` and `docker-compose.yml` also spin up a local instance of [Jaeger](https://www.jaegertracing.io/)
(running on http://localhost:16686/) and [Zipkin](https://zipkin.io/) (running on http://127.0.0.1:9411/)
that will both also receive the same trace data. If you'd prefer not to send your trace data over the network to
Honeycomb (or any other API), you can use these locally running tracing services instead.

## References

For further reading, see [the guides](https://geometerio.github.io/geometrics).

External references:

* https://opentelemetry.io/docs/concepts/what-is-opentelemetry/
* https://opentelemetry.io/docs/erlang/getting-started/
* https://github.com/open-telemetry/opentelemetry-specification
