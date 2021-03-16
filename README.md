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

Add `geometrics` to your `mix.exs`.

Note that it is not currently published to Hex due to version conflicts between `opentelemetry`
and `opentelemetry-phoenix`. Open Telemetry is in its early development stages, but folks in the
Elixir [#opentelemetry slack channel](https://elixir-lang.slack.com/archives/CA4CNK38B) are very responsive!

```elixir
def deps do
  [
    {:geometrics, github: "geometerio/geometrics"}
  ]
end
```

Configure `Geometrics` in `config.exs`:

```elixir
# Necessary to tell OpenTelemetry what repository to report traces for
config :geometrics, :ecto_prefix, [:my_app, :repo]

# Configuring a custom logger Geometrics.OpenTelemetry.Logger to help export process crashes to OpenTelemetry, which aren't reported by default 
config :logger,
       backends: [
         :console,
         Geometrics.OpenTelemetry.Logger
       ]

# The service name will show up in each span in your metrics service (i.e. Honeycomb)
config :opentelemetry, :resource,
       service: [
         name: "<app name> backend"
       ]

# This is the endpoint that both frontend and backend opentelemetry trace data will be sent to
config :geometrics, :collector_endpoint, "http://localhost:55681/v1/trace"
```

Configure `opentelemetry` with an exporter:

```elixir
config :opentelemetry,
       processors: [
         otel_batch_processor: %{
           exporter: {
             :opentelemetry_exporter,
             %{endpoints: [{:http, '0.0.0.0', 55_681, []}]}
           }
         }
       ]
```

In this example we export all trace data to an opentelemetry-collector agent that will be running on `localhost:55681`.
See [the section on running the opentelemetry collector](#running-the-opentelemetry-collector) below
or [the guides](https://geometerio.github.io/geometrics) for more on this.

Add the handler to the `Application`'s supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      Geometrics.OpenTelemetry.Handler, ## <------------
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Add our plug to the router:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    # .....
    plug Geometrics.Plug.OpenTelemetry
  end

  # ...
end
```

Add meta tags to the root layout that will enable front-end/back-end tracing

```slim
doctype html
html lang="en"
  head
    = csrf_meta_tag()
    = Geometrics.Phoenix.View.meta_tags(@conn)
    / ....
  body
    = @inner_content
```

## Getting frontend event traces

To get javascript traces to show up within LiveView traces, check out the [javascript guide](https://geometerio.github.io/geometrics/javascript.html).

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
