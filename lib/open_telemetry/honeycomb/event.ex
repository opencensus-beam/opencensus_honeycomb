defmodule OpenTelemetry.Honeycomb.Event do
  @moduledoc """
  Event structure.

  Honeycomb events bind a timestamp to data as described in `t:t/0` below. The `data` corresponds
  to OpenTelemetry span attributes, with limitations dictated by the intersection of
  OpenTelemetry' and Honeycomb's data models.

  ## Supported Value Types

  ### Honeycomb

  Honeycomb supports events (spans, when strung together in a trace) with dozens or hundreds of
  attributes. Keys [MUST] be strings, like in OpenTelemetry. Values [MUST] be JSON encodable, but
  [MAY] include objects (Elixir maps) and arrays -- neither of which are supported by
  OpenTelemetry.

  Honeycomb makes no distinction between measurements and metadata, unlike `:telemetry`.

  Honeycomb's keys for trace handling can be configured on a per-dataset basis, but default to:

  * `duration_ms`
  * `name`
  * `service_name`
  * `trace.parent_id`
  * `trace.span_id`
  * `trace.trace_id`

  ### OpenTelemetry

  To be compatible with the OpenTelemetry protobuf protocol, [attribute values][AttributeValue]
  [MUST] be one of:

  * `TruncatableString`
  * `int64`
  * `bool_value`
  * `double_value`

  ### OpenTelemetry.Honeycomb

  The data models being quite similar, the `Jason.Encoder` implementation for
  `t:OpenTelemetry.Honeycomb.Event.t/0`:

  * Flattens map values as described below
  * Converts atom keys and values to strings
  * **Drops any other values not compatible with the OpenTelemetry protobuf definition**
  * **Over-writes any keys that clash with the [default trace handling keys](#module-honeycomb)**

  [MUST]: https://tools.ietf.org/html/rfc2119#section-1
  [MAY]: https://tools.ietf.org/html/rfc2119#section-5
  [AttributeValue]: https://github.com/census-instrumentation/opentelemetry-proto/blob/e2601ef/src/opentelemetry/proto/trace/v1/trace.proto#L331
  [honeycombtrace]: #module-honeycomb

  ### Flattening

  Map flattening uses periods (`.`) to delimit keys from nested maps, much like can be configured
  on a dataset basis at the Honeycomb end. These span attributes before flattening:

  ```elixir
  %{
    http: %{
      host:  "localhost",
      method: "POST",
      path: "/api"
    }
  }
  ```

  ... becomes this event after flattening:

  ```elixir
  %{
    "http.host" => "localhost",
    "http.method" => "POST",
    "http.path" => "/api",
  }
  ```
  """

  alias OpenTelemetry.Honeycomb.Cleaner
  alias OpenTelemetry.Honeycomb.Config
  alias OpenTelemetry.Honeycomb.Config.AttributeMap
  alias OpenTelemetry.Honeycomb.Event.Extract
  alias OpenTelemetry.Records.Span
  require Record

  @enforce_keys [:time, :data]
  defstruct [:time, :data]

  @typedoc """
  Span attributes after flattening.

  See [attribute limitations](#module-opentelemetry-honeycomb) for important detail on span
  attribute names and values.

  [attrlimits]: #module-opentelemetry-honeycomb
  """
  @type event_data :: %{optional(String.t()) => OpenTelemetry.attribute_value()}

  @typedoc """
  Honeycomb event suitable for POSTing to their batch API.

  * `time`: ms since epoch; [MUST] be in ISO 8601 format, e.g. `"2019-05-17T09:55:12.622658Z"`
  * `data`: `t:event_data/0` after flattening.

  [MUST]: https://tools.ietf.org/html/rfc2119#section-1
  """
  @type t :: %__MODULE__{
          time: String.t(),
          data: event_data()
        }

  @doc """
  The current UTC time in ISO 8601 format, e.g. `"2019-05-17T09:55:12.622658Z"`

  Useful when creating events manually.
  """
  @spec now() :: String.t()
  def now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  @doc """
  Convert one OpenTelemetry span to an event suitable for POSTing to the
  [Honeycomb Events API][HCevents].

  See [attribute limitations](#module-opentelemetry-honeycomb) for important detail on span a
  attribute names and values.

  [HCevents]: https://docs.honeycomb.io/api/events/
  [HCstruct]: https://github.com/honeycombio/opentelemetry-exporter-go/blob/66047b9/honeycomb/honeycomb.go#L325
  [HCdefs]: https://docs.honeycomb.io/working-with-your-data/managing-your-data/definitions/#tracing
  """
  @spec from_ot_span(
          :opentelemetry.span(),
          resource_attributes :: OpenTelemetry.attributes(),
          attribute_map :: AttributeMap.t()
        ) :: [t()]
  def from_ot_span(ot_span, resource_attributes, attribute_map) do
    span = Span.from(ot_span)

    data =
      span
      |> Map.get(:attributes)
      |> merge(resource_attributes)
      |> merge(extracted_attributes(span, attribute_map))
      |> Enum.into(%{})
      |> Cleaner.clean()

    time =
      span.start_time
      |> :opentelemetry.convert_timestamp(:microsecond)
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.to_iso8601()

    [%__MODULE__{time: time, data: data}]
  end

  @spec merge(OpenTelemetry.attributes(), OpenTelemetry.attributes()) ::
          OpenTelemetry.attributes()
  defp merge(att1, att2), do: :lists.ukeymerge(1, att1, att2)

  # span attribute extractors
  @spec extracted_attributes(Span.t(), AttributeMap.t()) :: OpenTelemetry.attributes()
  defp extracted_attributes(%Span{} = span, attribute_map) do
    attribute_mapper = get_attribute_mapper(attribute_map)

    [
      duration_ms: ms(span.end_time) - ms(span.start_time),
      name: span.name,
      parent_span_id: hexify_span_id(span.parent_span_id),
      span_id: hexify_span_id(span.span_id),
      trace_id: hexify_trace_id(span.trace_id)
    ]
    |> Enum.map(attribute_mapper)
    |> Enum.filter(&has_binary_key?/1)
  end

  @spec get_attribute_mapper(attribute_map :: AttributeMap.t()) ::
          ({atom(), OpenTelemetry.attribute_value()} ->
             {OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()})
  defp get_attribute_mapper(map) do
    fn {k, v} -> {Map.get(map, k), v} end
  end

  defp has_binary_key?({k, _}) when is_binary(k), do: true
  defp has_binary_key?(_), do: false

  defp hexify_trace_id(:undefined), do: nil
  defp hexify_trace_id(n), do: :io_lib.format("~32.16.0b", [n]) |> to_string()
  defp hexify_span_id(:undefined), do: nil
  defp hexify_span_id(n), do: :io_lib.format("~16.16.0b", [n]) |> to_string()
  defp ms(t), do: :opentelemetry.convert_timestamp(t, :microsecond) / 1000
end
