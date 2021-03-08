defmodule Mix.Tasks.Geometrics.Install do
  use Mix.Task

  @shortdoc "Installs necessary components for Geometrics to work"
  def run(_) do
    cp_opentelemetry_files()
  end

  defp cp_opentelemetry_files() do
    if (System.get_env("HONEYCOMB_WRITE_KEY") && System.get_env("HONEYCOMB_DATASET")) do
      Mix.Shell.IO.info("Copying opentelemetry-collector files to working directory")

      cp_from_priv("opentelemetry", "docker-compose.yml")
      cp_from_priv("opentelemetry", "otel-collector-config.yml")

      Mix.Shell.IO.info("To start up the collector in your local development environment, simply run `docker-compose up`")
    else
      Mix.Shell.IO.info("Please set HONEYCOMB_WRITE_KEY and HONEYCOMB_DATASET in your environment")
    end
  end

  defp cp_from_priv(dir, file) do
    src = [:code.priv_dir(:geometrics), dir, file] |> Path.join()
    dest = [File.cwd!(), file] |> Path.join()
    Mix.Shell.IO.info("✅ #{dest}")

    File.cp(src, dest)
  end
end