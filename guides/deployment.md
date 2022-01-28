# Deployments

To collect trace data in production environments, it is necessary to run
the [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector)
somewhere in your network that will be accessible from both your frontend and backend. In a Kubernetes deploys, it could
be run as a sidecar container. In DigitalOcean deploys, you may need to deploy
the `otel/opentelemetry-collector-dev:0.25.0` docker image as a separate droplet.

## Compatibility

- [opentelemetry-js](https://github.com/open-telemetry/opentelemetry-js) - `1.0.1`
- [otel-collector](https://github.com/open-telemetry/opentelemetry-collector) - `> 0.36.0`
- [opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang) - `~> 1.0.0`

Geometrics depends on version of `opentelemetry-erlang` and `opentelemetry-js` that
may have different compatibility issues when running against different version of the
`opentelemetry-collector`. At the time of writing, this has been tested to work with
versions of the collector greater than or equal to `0.36.0`.

Because of changes in compatibility between different versions of the libraries and
versions of the collector, it's recommended to deploy a docker tag pinning a specific
version, rather than pinning to `latest`.

