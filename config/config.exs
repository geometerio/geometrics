import Config

config :geometrics, :ecto_prefix, []
config :geometrics, :warn_on_no_trace_context, true

if config_env() == :test do
  config :phoenix, :json_library, Jason
end
