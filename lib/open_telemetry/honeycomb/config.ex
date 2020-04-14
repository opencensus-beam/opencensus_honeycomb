defmodule OpenTelemetry.Honeycomb.Config.AttributeMap do
  @moduledoc """
  Attribute map configuration.

  Controls the dataset attributes used for various span properties _eg._ `"trace.trace_id"` for
  the trace identifier, which you didn't set via `OpenTelemetry.Span.set_attribute/2`. Use the map
  to match any existing [definitions][HCdefs] you've configured at the Honeycomb end.

  [HCdefs]: https://docs.honeycomb.io/working-with-your-data/managing-your-data/definitions/#tracing
  """

  @typedoc """
  Attribute map configuration for the OpenTelemetry Honeycomb exporter.
  """

  @type t :: %{
          duration_ms: String.t(),
          name: String.t(),
          parent_span_id: String.t(),
          span_id: String.t(),
          span_type: String.t(),
          trace_id: String.t()
        }

  defstruct duration_ms: "duration_ms",
            name: "name",
            parent_span_id: "trace.parent_id",
            span_id: "trace.span_id",
            span_type: "meta.span_type",
            trace_id: "trace.trace_id"
end

defmodule OpenTelemetry.Honeycomb.Config do
  @moduledoc """
  Provides configuration.

  A compact `config/config.exs` for OpenTelemetry is:

  ```elixir
  use Config

  config :opentelemetry, :resource,
    service: [
      name: "service-name",
      namespace: "service-namespace"
    ]

  config :opentelemetry,
    processors: [
      ot_batch_processor: %{
        max_queue_size: 50,
        exporter:
          {OpenTelemetry.Honeycomb.Exporter, write_key: System.get_env("HONEYCOMB_WRITEKEY")}
      }
    ]
  ```

  `processors` specifies `ot_batch_processor`, which specifies `exporter`, a 2-tuple of the
  exporter's module name and options to be supplied to its `init/1`. We convert those to this
  module's struct.

  We configure the other options because:

  * OpenTelemetry [specify](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/resource/semantic_conventions/README.md)
    both `service.name` and `service.namespace` as required; and

  * Honeycomb [documents](https://docs.honeycomb.io/api/events/#limits) a maximum batch body of
    5MB and a maximum event body sie of 100KB, giving a safe limit of 50 events per batch.

  If your events are smaller, you may safely raise `max_queue_size`.
  """

  alias OpenTelemetry.Honeycomb.Config.AttributeMap
  alias OpenTelemetry.Honeycomb.HttpBackend
  alias OpenTelemetry.Honeycomb.JsonBackend

  @typedoc """
  Configuration for the OpenTelemetry Honeycomb exporter, giving:

  * `api_endpoint`: the API endpoint
  * `attribute_map`: a map to control dataset attributes used for span properties (see below)
  * `dataset`: the Honeycomb dataset name
  * `http_module`: the HTTP back end module (see `HttpBackend`)
  * `http_options`: options to pass to the HTTP back end
  * `json_module`: the JSON back end module (see `JsonBackend`)
  * `json_options`: options to pass to the JSON back end
  * `write_key`: the write key

  `attribute_map` controls the dataset attributes used for various span properties _eg._
  `"trace.trace_id"` for the trace identifier, which you didn't set via
  `OpenTelemetry.Span.set_attribute/2`. Use the map to match any existing [definitions][HCdefs]
  you've configured at the Honeycomb end.

  [HCdefs]: https://docs.honeycomb.io/working-with-your-data/managing-your-data/definitions/#tracing

  If the `write_key` is absent or `nil`, the exporter won't attempt any outbound requests.
  """
  @type t :: %__MODULE__{
          api_endpoint: String.t(),
          attribute_map: AttributeMap.t(),
          dataset: String.t(),
          http_module: module(),
          http_options: Keyword.t(),
          json_module: module(),
          write_key: String.t() | nil
        }

  defstruct api_endpoint: "https://api.honeycomb.io",
            attribute_map: %AttributeMap{},
            dataset: "opentelemetry",
            http_module: HttpBackend.default_module(),
            http_options: HttpBackend.default_options(),
            json_module: JsonBackend.default_module(),
            write_key: nil
end
