# Deployments

To collect trace data in production environments, it is necessary to run
the [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector)
somewhere in your network that will be accessible from both your frontend and backend. In a Kubernetes deploys, it could
be run as a sidecar container. In DigitalOcean deploys, you may need to deploy
the `otel/opentelemetry-collector-dev:latest` as a separate droplet.