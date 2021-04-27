import Config

config :geometrics, :ecto_prefix, []
config :geometrics, :collector_endpoint, "http://localhost:55681/v1/trace"
config :geometrics, :warn_on_no_trace_context, true
