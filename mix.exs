defmodule Geometrics.MixProject do
  @moduledoc false
  use Mix.Project

  @scm_url "https://github.com/geometerio/geometrics"
  @version "1.0.3-rc.3"

  def project do
    [
      app: :geometrics,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @scm_url,
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test, docs: :dev],
      source_url: @scm_url,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      version: @version
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :telemetry, :phoenix_live_view]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:opentelemetry, "~> 1.1.1"},
      {:opentelemetry_api, "~> 1.1.0"},
      {:opentelemetry_exporter, "~> 1.2.0"},
      {:opentelemetry_ecto, "~> 1.0.0"},
      {:opentelemetry_phoenix, "~> 1.0.0"},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:phoenix_html, "~> 2.11 or ~> 3.0"},
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
        "guides/upgrading_to_1.0.md"
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

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Geometer"],
      links: %{"GitHub" => @scm_url},
      files: ~w(
        lib
        mix.exs
        LICENSE.md
        README.md
        priv/opentelemetry
        priv/static
        package.json
      )
    ]
  end
end
