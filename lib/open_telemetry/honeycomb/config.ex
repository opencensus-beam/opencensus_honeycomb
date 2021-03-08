defmodule OpenTelemetry.Honeycomb.Config.AttributeMap do
  @moduledoc """
  Attribute map configuration.

  Controls the dataset attributes used for various span properties _eg._ `"trace.trace_id"` for
  the trace identifier, which you didn't set via `OpenTelemetry.Tracer.set_attributes/1`. Use the
  map to match any existing [definitions][HCdefs] you've configured at the Honeycomb end.

  [HCdefs]: https://docs.honeycomb.io/working-with-your-data/managing-your-data/definitions/#tracing
  """

  @typedoc """
  Attribute map configuration for the OpenTelemetry Honeycomb exporter.
  """

  @type t :: %__MODULE__{
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
  @external_resource "README.md"

  @moduledoc """
  Configuration.

    #{
    "README.md"
    |> File.read!()
    |> String.split("<!-- CDOC !-->")
    |> Enum.fetch!(1)
  }
  """

  alias OpenTelemetry.Honeycomb.Config.AttributeMap
  alias OpenTelemetry.Honeycomb.Http
  alias OpenTelemetry.Honeycomb.Json

  @typedoc """
  Configuration option for the OpenTelemetry Honeycomb exporter, giving:

  * `api_endpoint`: the API endpoint
  * `attribute_map`: a map to control dataset attributes used for span properties (see below)
  * `dataset`: the Honeycomb dataset name
  * `http_module`: the HTTP back end module (see `Http`)
  * `http_options`: options to pass to the HTTP back end (see `Http`)
  * `json_module`: the HTTP back end module (see `Json`)
  * `write_key`: the write key

  If the `write_key` is absent or `nil`, the exporter replaces your `http_module` with
  `OpenTelemetry.Honeycomb.Http.WriteKeyMissingBackend` to prevent spamming Honeycomb with
  unauthenticated requests.
  """
  @type config_opt ::
          {:api_endpoint, String.t()}
          | {:attribute_map, AttributeMap.t()}
          | {:dataset, String.t()}
          | {:write_key, String.t() | nil}
          | Http.config_opt()
          | Json.config_opt()

  @typedoc """
  A keyword list of configuration options for the OpenTelemetry Honeycomb exporter.
  """
  @type t :: [config_opt()]

  @doc """
  Get the default configuration for the OpenTelemetry Honeycomb exporter.
  """
  def default_config,
    do:
      [
        api_endpoint: "https://api.honeycomb.io",
        attribute_map: %AttributeMap{},
        dataset: "opentelemetry",
        write_key: nil
      ]
      |> Keyword.merge(Http.default_config())
      |> Keyword.merge(Json.default_config())
end
