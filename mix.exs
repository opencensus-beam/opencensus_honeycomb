defmodule OpenTelemetry.Honeycomb.MixProject do
  use Mix.Project

  @description "Integration between OpenTelemetry and Honeycomb"

  def project do
    [
      app: :opentelemetry_honeycomb,
      deps: deps(),
      description: @description,
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "https://github.com/garthk/opentelemetry_honeycomb",
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        docs: :dev
      ],
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/garthk/opentelemetry_honeycomb",
      test_coverage: [tool: ExCoveralls],
      version: "0.3.0-rc.0"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :hackney, :poison]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/garthk/opentelemetry_honeycomb",
        "OpenTelemetry" => "https://opentelemetry.io",
        "OpenTelemetry Erlang API" =>
          "https://github.com/open-telemetry/opentelemetry-erlang-api",
        "OpenTelemetry Erlang SDK" => "https://github.com/open-telemetry/opentelemetry-erlang"
      }
    ]
  end

  defp deps() do
    [
      {:credo, "~> 1.4.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.21.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12.3", only: :test, runtime: false},
      {:licensir, "~> 0.6.1", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0.2", only: :dev, runtime: false},
      {:mox, "~> 0.5.1", only: :test, runtime: false},
      # versions for runtime dependencies deliberately set as low as possible:
      {:hackney, ">= 1.11.0", optional: true},
      {:jason, ">= 1.0.0", optional: true},
      {:opentelemetry, "~> 0.4.0"},
      {:opentelemetry_api, "~> 0.3.1"},
      {:poison, ">= 1.5.0", optional: true},
      {:telemetry, "~> 0.4.0"}
    ]
  end

  defp dialyzer() do
    [
      # 'mix dialyzer --format dialyzer' to get lines you can paste into:
      ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true,
      plt_add_apps: [:mix],
      plt_add_deps: [:app_tree]
    ]
  end

  defp docs() do
    [
      api_reference: true,
      authors: ["Garth Kidd"],
      canonical: "http://hexdocs.pm/opentelemetry_honeycomb",
      extras: [],
      main: "OpenTelemetry.Honeycomb",
      source_ref: "v#{@version}"
    ]
  end
end
