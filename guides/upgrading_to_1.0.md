# Upgrading to 1.0

## Backend configuration

The `1.0.0` release of Geometrics updates to `1.0.x` releases of
[opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang) and
[opentelemetry-js](https://github.com/open-telemetry/opentelemetry-js). These updates
do not seem to change the API for tracing, but they do change the configuration of
exporters. When updating Geometrics to use these new releases, the following
configuration change must be made:

Old configuration:

```elixir
config :opentelemetry, processors: [
  otel_batch_processor: %{
    exporter: {
      :opentelemetry_exporter,
      %{endpoints: [{:http, '0.0.0.0', 5555, []}]}
    }
  }
]
```

New configuration:

```elixir
config :opentelemetry, processors: [
  otel_batch_processor: %{
    exporter: {
      :opentelemetry_exporter,
      %{endpoints: ["http://localhost:5555"]}
    }
  }
]
```


## Otel collector version / configuration

An additional change is that receivers of the OTEL data protocol changed the path by
which they receive data from `/v1/trace` to `/v1/traces`. While this is transparent
to the backend configuration of the `:opentelemetry_exporter`, which does not include
the path , the path provided to JavaScript will need to be updated:

```elixir
config :geometrics, :collector_endpoint, "http://localhost:55681/v1/traces"
```


