defmodule OpenTelemetry.Honeycomb.Event do
  @moduledoc """
  Event structure.

  Honeycomb events bind a timestamp to data as described in `t:t/0` below. The `data` corresponds
  to OpenTelemetry span attributes, with limitations dictated by the intersection of their data
  data models. For information on how we clean and flatten span attributes before sending them,
  see `OpenTelemetry.Honeycomb.Attributes`.

  Honeycomb event attributes for trace handling can collide with other attributes. For information
  on the defaults and how to change them, see `OpenTelemetry.Honeycomb.Config.AttributeMap`.
  """

  alias OpenTelemetry.Honeycomb.Attributes
  alias OpenTelemetry.Honeycomb.Config.AttributeMap
  alias OpenTelemetry.Records.Span
  require Record

  @enforce_keys [:time, :data]
  defstruct [:time, :data, samplerate: 1]

  @typedoc """
  Span attributes after flattening.
  """
  @type event_data :: %{optional(String.t()) => OpenTelemetry.attribute_value()}

  @typedoc """
  Honeycomb event suitable for POSTing to their batch API.

  * `time`: ms since epoch; [MUST] be in ISO 8601 format, e.g. `"2019-05-17T09:55:12.622658Z"`
  * `data`: `t:event_data/0` after flattening.
  * `samplerate`: the sample rate, as a positive integer; `1_000` describes a `1:1000` ratio.

  [MUST]: https://tools.ietf.org/html/rfc2119#section-1
  """
  @type t :: %__MODULE__{
          time: String.t(),
          samplerate: pos_integer(),
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

  [HCevents]: https://docs.honeycomb.io/api/events/
  """
  @spec from_ot_span(
          :opentelemetry.span(),
          resource_attributes :: OpenTelemetry.attributes(),
          attribute_map :: AttributeMap.t(),
          samplerate_key :: nil | String.t()
        ) :: [t()]
  def from_ot_span(ot_span, resource_attributes, attribute_map, samplerate_key \\ nil) do
    span = Span.from(ot_span)

    data =
      span
      |> Map.get(:attributes)
      |> Attributes.clean()
      |> Attributes.merge(resource_attributes)
      |> Attributes.merge(extracted_attributes(span, attribute_map))
      |> Enum.into(%{}, &Attributes.trim_long_strings/1)

    time =
      span.start_time
      |> :opentelemetry.convert_timestamp(:microsecond)
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.to_iso8601()

    {samplerate, data} = pop_sample_rate(data, samplerate_key)
    [%__MODULE__{time: time, data: data, samplerate: samplerate}]
  end

  @spec pop_sample_rate(event_data(), nil | String.t()) :: {pos_integer(), event_data()}
  defp pop_sample_rate(data, samplerate_key)
  defp pop_sample_rate(data, nil), do: {1, data}
  defp pop_sample_rate(data, samplerate_key), do: Map.pop(data, samplerate_key, 1)

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
    |> Attributes.sort()
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
