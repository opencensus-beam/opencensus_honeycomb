defmodule OpenTelemetry.Honeycomb.MixProject do
  use Mix.Project

  @app :opentelemetry_honeycomb
  @description "Integration between OpenTelemetry and Honeycomb"
  @main "OpenTelemetry.Honeycomb"
  @repo "https://github.com/garthk/opentelemetry_honeycomb"
  @version "0.6.0-rc.1"

  def project do
    [
      app: @app,
      deps: deps(),
      description: @description,
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @repo,
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        docs: :dev
      ],
      source_url: @repo,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application, do: [extra_applications: [:logger, :hackney, :poison]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps() do
    [
      {:credo, "~> 1.5.5", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.21.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.0", only: :test, runtime: false},
      {:licensir, "~> 0.6.1", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0.2", only: :dev, runtime: false},
      {:mox, "~> 1.0.0", only: :test, runtime: false},
      # versions for runtime dependencies deliberately set low and loose:
      {:hackney, ">= 1.11.0", optional: true},
      {:jason, ">= 1.0.0", optional: true},
      {:opentelemetry_api, "~> 0.6"},
      {:opentelemetry, "~> 0.6"},
      {:poison, ">= 1.5.0", optional: true},
      {:telemetry, "~> 0.4.0"}
    ]
  end

  defp dialyzer() do
    [
      # 'mix dialyzer --format dialyzer' to get lines you can paste into:
      # ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true,
      plt_add_deps: [:app_tree]
    ]
  end

  defp docs() do
    [
      api_reference: true,
      authors: ["Garth Kidd"],
      canonical: "http://hexdocs.pm/opentelemetry_honeycomb",
      main: @main,
      nest_modules_by_prefix: [OpenTelemetry.Honeycomb],
      source_ref: "v#{@version}"
    ]
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub repo" => @repo,
        "OpenTelemetry BEAM" => "https://github.com/opentelemetry-beam",
        "OpenTelemetry" => "https://opentelemetry.io"
      }
    ]
  end
end
