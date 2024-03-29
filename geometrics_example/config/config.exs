# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Necessary to tell OpenTelemetry what repository to report traces for
config :geometrics, :ecto_prefix, [:geometrics_example, :repo]

# Configuring a custom logger Geometrics.OpenTelemetry.Logger to help export process crashes to OpenTelemetry, which aren't reported by default
config :logger,
  backends: [
    :console,
    Geometrics.OpenTelemetry.Logger
  ]

# The service name will show up in each span in your metrics service (i.e. Honeycomb)
config :opentelemetry, :resource,
  service: [
    name: "Geometrics Example Backend"
  ]

config :geometrics, :collector_endpoint, "http://localhost:55681/v1/traces"

config :opentelemetry,
  processors: [
    otel_batch_processor: %{
      exporter: {
        :opentelemetry_exporter,
        %{endpoints: [{:http, '0.0.0.0', 55_681, []}]}
      }
    }
  ]

config :geometrics_example,
  ecto_repos: [GeometricsExample.Repo]

# Configures the endpoint
config :geometrics_example, GeometricsExampleWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: GeometricsExampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GeometricsExample.PubSub,
  live_view: [signing_salt: "pmLdj1iN"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :geometrics_example, GeometricsExample.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
