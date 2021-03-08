# Geometrics

An opinionated library for adding application tracing and metrics to a Phoenix application. Geometrics includes
dependencies which hook into Phoenix and Ecto telemetry, adding support for LiveView as well as crash tracking.

## Installation

Add `Geometrics` and an exporter (i.e. `opentelemetry_exporter`) to `mix.exs`:

```elixir
def deps do
[
  {:geometrics, github: "geometerio/geometrics"
  {:opentelemetry_exporter, ">= 0.0.0"},
]
end
```

Configure `Geometrics` in `config.exs`:

```elixir
config :geometrics, :ecto_prefix, [:my_app, :repo]

config :logger,
       backends: [
         :console,
         Geometrics.OpenTelemetry.Logger
       ]

config :opentelemetry, :resource,
       service: [name: "<app name> backend"]

config :geometrics, :collector_endpoint, "http://localhost:55681/v1/trace"
```

Run `mix geometrics.install`. This will set up the OpenTelemetry collector that is used to export trace data to external
services like Honeycomb.

Configure `opentelemetry` with an exporter. This example assumes that an `otel/opentelemetry-collector-dev:latest`
collector is running on localhost. The `docker-compose.yml` file that runs this image will be set up from
running `mix geometrics.install` in the previous step.

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

## Running the OpenTelemetry collector

In order to actually report data to Honeycomb (or other services), you will need to run
an [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector). This component is responsible
for receiving, processing and exporting OpenTelemetry data to external services.

To do this you will need to run an installation script (note that you will need to set `HONEYCOMB_DATASET`
and `HONEYCOMB_WRITE_KEY` in your environment before running this command):

`$ mix geometrics.intall`

This will copy a `docker-compose.yml` file used to run the collector into your projects top level directory. It will
also copy over a configuration file, `otel-collector-config.yml`, used to configure the collector Docker process.

To run the collector, simply run `docker compose up`. You should now see metrics data appear in Honeycomb under the
dataset configured by `HONEYCOMB_DATASET`.

## References

For further reading, see [guides/overview.md](guides/overview.md).

External references:

* https://opentelemetry.io/docs/concepts/what-is-opentelemetry/
* https://opentelemetry.io/docs/erlang/getting-started/
* https://github.com/open-telemetry/opentelemetry-specification
