# Deployments

To collect trace data in production environments, it is necessary to run
the [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector)
somewhere in your network that will be accessible from both your frontend and backend. In a Kubernetes deploys, it could
be run as a sidecar container. In DigitalOcean deploys, you may need to deploy
the `otel/opentelemetry-collector-dev:latest` docker image as a separate droplet.

## Compatibility

- [opentelemetry-js](https://github.com/open-telemetry/opentelemetry-js) - `0.22.0`
- [otel-collector](https://github.com/open-telemetry/opentelemetry-collector) - `0.25.0`
- [opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang) - `~> 1.0.0-rc`

Geometrics uses [opentelemetry-js](https://github.com/open-telemetry/opentelemetry-js)
version `0.22.0`. The `@opentelemetry/exporter-collector` at the time of writing is
only compatible with `otel-collector` versions `0.25.0` or earlier. Some breaking
change in the `otel-collector` more recent than that version causes the
`CollectorTraceExporter` to receive `404` status codes when posting traces.
