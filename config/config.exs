use Mix.Config

# You can also supply opentelemetry resources using environment variables, eg.:
# OTEL_RESOURCE_LABELS=service.name=name,service.namespace=namespace

config :opentelemetry, :resource,
  service: [
    name: "service-name",
    namespace: "service-namespace"
  ]

config :opentelemetry,
  tracer: :ot_tracer_default,
  processors: [
    ot_batch_processor: %{
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         http_module: OpenTelemetry.Honeycomb.Http.HackneyBackend,
         http_options: [],
         write_key: System.get_env("HONEYCOMB_WRITEKEY")}
    }
  ]

if Mix.env() in [:test], do: import_config("#{Mix.env()}.exs")
