use Mix.Config

config :opentelemetry,
  processors: [
    otel_batch_processor: %{
      scheduled_delay_ms: 1,
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         http_module: MockedHttpBackend, http_options: [], write_key: "HONEYCOMB_WRITEKEY"}
    }
  ]
