defmodule Geometrics.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.2.0"

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
      {:opentelemetry, "~> 1.0.0-rc"},
      {:opentelemetry_api, "~> 1.0.0-rc"},
      {:opentelemetry_exporter, "~> 1.0.0-rc"},
      {:opentelemetry_ecto, "~> 1.0.0-rc"},
      {:opentelemetry_phoenix, "~> 1.0.0-rc"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_view, "~> 0.15", optional: true},
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
        "guides/installation.md",
        "guides/phoenix.md",
        "guides/javascript.md",
        "guides/deployment.md",
        "guides/testing.md",
        "guides/references.md",
      ],
      output: "docs",
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
