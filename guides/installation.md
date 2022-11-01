# Installation

NOTE: Check out the [geometrics_example](./geometrics_example) directory to see an example Phoenix application that has everything configured from this guide.

## Running the OpenTelemetry collector

There are two ways to report data to tracing services:

1. Use an [opentelemetry-collector](https://opentelemetry.io/docs/collector/) service that runs as a sidecar to your application

Pros:

* allows for exporting trace data to multiple APIs and keeps your app vendor-agnostic
* metric processing features like throttling / buffering data. 
* allows for connecting distributed traces between your front end and back end

Cons:
* requires you to figure out how to deploy it in production
* requires use of docker compose locally
* may be too many features for a simple use case

2. Directly export metric / trace data from your running Elixir app

Pros:
* Simple to set up
* No need to run docker locally to host the collector

Cons:
* Does not allow you to connect traces between frontend and backend code
* App remains coupled to whatever 3rd party metrics service you use
 
This guide walks you through setting up the opentelemetry-collector with Honeycomb, but later 
mentions how to set up geometrics without the collector (ie going straight to Honeycomb) as well.

## 1. Install Geometrics

Add `geometrics` to your `mix.exs`.

```elixir
def deps do
  [
    {:geometrics, "~> 1.0.2-rc.3"}
  ]
end
```

`$ mix deps.get`

## 2. Install the sidecar collector (skip if you do not want to run a collector)

We've made it easy to get set up a collector locally. The following command will copy a `docker-compose.yml` file 
used to run the collector into your projects top level directory. It will also copy over a configuration file, 
`otel-collector-config.yml`, used to configure the collector Docker process:

`$ mix geometrics.install`

(You will need to set `HONEYCOMB_DATASET` and `HONEYCOMB_WRITE_KEY` in your environment before running this command)

To run the collector, simply run:

`$ docker compose up` 

After wiring up your Phoenix app to send data to it locally, you should see metrics data appear in 
Honeycomb under the dataset configured by `HONEYCOMB_DATASET`. You can also feel free to 
configure additional exporters in the otel-collector-config.yml file via [the spec](https://opentelemetry.io/docs/collector/configuration/#basics)

Now, on to configuring your Phoenix app...

## 3. config.exs

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

## 3. runtime.exs

Configure `opentelemetry` with an exporter / collector. If running `otel-collector` as a sidecar
in k8s, with an `otel` receiver on port 55821, the following will work.

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

Despite being somewhat redundant, for now you must also specify the `collector_endpoint` so that the Geometrics javascript will know where to send its trace data.

```elixir
config :geometrics, :collector_endpoint, "http://localhost:55681/v1/traces"
```

In this example we export all trace data to an opentelemetry-collector agent that will be running on `localhost:55681` according to the docker compose file you copied over previously.

If you'd prefer to run without using the opentelemetry-collector sidecar, and to send directly to a metrics service like Honeycomb instead, 
you should instead configure opentelemetry like so:

```elixir
dataset = System.fetch_env!("HONEYCOMB_DATASET")
key = System.fetch_env!("HONEYCOMB_WRITE_KEY")

config :opentelemetry, :processors,
  otel_batch_processor: %{
    exporter: {
      :opentelemetry_exporter,
      %{
        endpoints: ["https://api.honeycomb.io:443"],
        headers: [
          {"x-honeycomb-dataset", dataset},
          {"x-honeycomb-team", key}
        ]
      }
    }
  }
```

*NOTE*: with this configuration you *will not* get any frontend trace reporting unless you separately configure opentelemetry-js to export to Honeycomb as well.
(this is something Geometrics does for you, so long as you are using the opentelemetry-collector sidecar as outlined above).

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
