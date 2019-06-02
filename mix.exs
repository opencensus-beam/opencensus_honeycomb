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
      version: "0.1.2"
    ]
  end

  def application() do
    [
      applications: [
        # We name the applications we need to be started here, so we don't have to specify
        # runtime: false on our dev and test dependencies, so we don't have to start them
        # manually during our tests, because I never quite figured out how to do that.
        # PR welcome!
        :hackney,
        :jason,
        :opencensus
      ],
      extra_applications: [
        # As above, but they're not in :deps because they're part of OTP or Elixir.
        :logger
      ]
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
      {:credo, "~> 0.10.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev},
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
      {:excoveralls, "~> 0.10.6", only: [:dev, :test]},
      {:hackney, "~> 1.15"},
      {:inch_ex, "~> 2.0.0", only: :docs},
      {:jason, "~> 1.1"},
      {:licensir, "~> 0.4.0", only: :dev},
      {:mix_test_watch, "~> 0.8", only: :dev},
      {:opencensus, "~> 0.9.2"},
      {:opencensus_plug, "~> 0.3.0", only: [:test, :docs]},
      {:phoenix, "~> 1.4", only: [:test, :docs]},
      {:plug, "~> 1.8", only: [:test, :docs]},
      {:poison, "~> 4.0", only: :test},
      {:telemetry, "~> 0.4"}
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
