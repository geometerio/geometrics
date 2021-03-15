defmodule Geometrics.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :geometrics,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [credo: :test, dialyzer: :test, docs: :docs],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      version: @version,
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :telemetry]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:docs], runtime: false},
      {:opentelemetry, "~> 0.6", override: true},
      {:opentelemetry_api, "~> 0.6", override: true},
      {:opentelemetry_exporter, ">= 0.6.0", override: true},
      {:opentelemetry_ecto, github: "opentelemetry-beam/opentelemetry_ecto"},
      {:opentelemetry_phoenix, github: "opentelemetry-beam/opentelemetry_phoenix"},
      {:phoenix_html, "~> 2.11"},
      {:plug, ">= 0.0.0"}
    ]
  end

  defp description,
    do: """
        Wraps OpenTelemetry from Erlang and JS, providing opinions and documentation for rapidly adding tracing
        to an application.
        """

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      extras: [
        "guides/overview.md",
        "guides/phoenix.md",
        "guides/javascript.md",
        "guides/deployment.md",
        "guides/references.md",
      ],
      assets: "guides/assets",
      source_ref: "v#{@version}",
      main: "overview"
    ]
  end

  def aliases() do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
