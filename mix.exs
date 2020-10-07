defmodule Opencensus.Honeycomb.MixProject do
  use Mix.Project

  @description "Integration between OpenCensus and Honeycomb"

  def project do
    [
      app: :opencensus_honeycomb,
      deps: deps(),
      description: @description,
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.5",
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        docs: :docs,
        inch: :docs,
        "inch.report": :docs,
        "inchci.add": :docs
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: "0.3.0"
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/opencensus-beam/opencensus_honeycomb",
        "OpenCensus" => "https://opencensus.io",
        "OpenCensus Erlang" => "https://github.com/census-instrumentation/opencensus-erlang",
        "OpenCensus BEAM" => "https://github.com/opencensus-beam"
      }
    ]
  end

  defp deps() do
    [
      {:credo, "~> 1.2.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false},
      {:ex_doc, ">= 0.21.3", only: [:dev, :docs], runtime: false},
      {:inch_ex, "~> 2.0.0", only: :docs, runtime: false},
      {:excoveralls, "~> 0.12.2", only: [:dev, :test], runtime: false},
      {:hackney, "~> 1.15"},
      {:jason, "~> 1.1"},
      {:licensir, "~> 0.6.0", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0.2", only: :dev, runtime: false},
      {:opencensus, "~> 0.9.2"},
      {:telemetry, "~> 0.4.0"}
    ]
  end

  defp dialyzer() do
    [
      # 'mix dialyzer --format dialyzer' to get lines you can paste into:
      ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true
    ]
  end

  defp docs() do
    [
      main: "Opencensus.Honeycomb",
      extras: [],
      deps: [
        opencensus: "https://hexdocs.pm/opencensus/"
      ]
    ]
  end
end
