# Geometrics

An opinionated library for adding application tracing and metrics to a Phoenix application.
Geometrics includes dependencies which hook into Phoenix and Ecto telemetry, adding support for
LiveView as well as crash tracking.

## Installation

Add `Geometrics` and an exporter (i.e. `opentelemetry_exporter`) to `mix.exs`:

```elixir
def deps do
  [
    {:geometrics, github: "geometerio/geometrics"}
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
```

Configure `opentelemetry` with an exporter. This example assumes that an `otel/opentelemetry-collector-dev:latest` collector is running on localhost.

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

Optionally add the traceparent to the root layout:

```slim
doctype html
html lang="en"
  head
    = csrf_meta_tag()
    = Geometrics.Phoenix.View.traceparent(@conn)
    / ....
  body
    = @inner_content
```

## References

* https://opentelemetry.io/docs/concepts/what-is-opentelemetry/
* https://opentelemetry.io/docs/erlang/getting-started/
* https://github.com/open-telemetry/opentelemetry-specification
