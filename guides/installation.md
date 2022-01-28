# Installation

## mix.exs

Add `geometrics` to your `mix.exs`.

Note that it is not currently published to Hex due to version conflicts between `opentelemetry`
and `opentelemetry-phoenix`. Open Telemetry is in its early development stages, but folks in the
Elixir [#opentelemetry slack channel](https://elixir-lang.slack.com/archives/CA4CNK38B) are very responsive!

```elixir
def deps do
  [
    {:geometrics, github: "geometerio/geometrics", branch: "main"},
  ]
end
```

## config.exs / runtime.exs

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
```

This is the endpoint of an `otel-collector` that frontend opentelemetry trace data will be sent to. In development, this may be localhost. In production,
this should be a public https endpoint.

```elixir
config :geometrics, :collector_endpoint, "http://localhost:55681/v1/traces"
```

Configure `opentelemetry` with an exporter. If running `otel-collector` as a sidecar
in k8s, with an `otel` receiver on port 55821, the following will work.

```elixir
config :opentelemetry,
       processors: [
         otel_batch_processor: %{
           exporter: {
             :opentelemetry_exporter,
             %{endpoints: ["http://localhost:55681"]}]}
           }
         }
       ]
```

In this example we export all trace data to an opentelemetry-collector agent that will be running on `localhost:55681`.
See [the section on running the opentelemetry collector](#running-the-opentelemetry-collector) below
or [the guides](https://hexdocs.pm/geometrics) for more on this.

## application.ex

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

## Phoenix endpoint.ex -- LiveView

In order for LiveView to receive information about the browser user agent, `:user_agent` should be
add to the `:connect_info` when configuring the live view socket in `endpoint.ex`. Others listed
below are not required, but are provided for informational purposes.

```elixir
socket "/live", Phoenix.LiveView.Socket,
  websocket: [
    connect_info: [
      :peer_data,
      :trace_context_headers,
      :user_agent,
      :x_headers,
      session: @session_options
    ]
  ]
```

## Phoenix router.ex

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

## Root layout

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

To get javascript traces to show up within LiveView traces, check out the [javascript guide](javascript.html).
