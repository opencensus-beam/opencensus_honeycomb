import Config

config :opentelemetry, :resource,
  service: [
    name: "service-name",
    namespace: "service-namespace"
  ]

config :opentelemetry,
  tracer: :ot_tracer_default,
  processors: [
    ot_batch_processor: %{
      max_queue_size: 50,
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         http_module: OpenTelemetry.Honeycomb.Backend,
         http_options: [],
         write_key: System.get_env("HONEYCOMB_WRITEKEY")}
    }
  ]

if Mix.env() in [:test], do: import_config("#{Mix.env()}.exs")
