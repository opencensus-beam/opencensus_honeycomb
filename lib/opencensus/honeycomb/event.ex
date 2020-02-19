defmodule Opencensus.Honeycomb.Event do
  @moduledoc """
  Event structure.

  Honeycomb events bind a timestamp to data as described in `t:t/0` below. The `data` corresponds
  to Opencensus span attributes, with limitations dictated by the intersection of OpenCensus' and
  Honeycomb's data models.

  ## Supported Value Types

  ### Honeycomb

  Honeycomb supports events (spans, when strung together in a trace) with dozens or hundreds of
  attributes. Keys [MUST] be strings, like in OpenCensus. Values [MUST] be JSON encodable, but
  [MAY] include objects (Elixir maps) and arrays -- neither of which are supported by OpenCensus.

  Honeycomb makes no distinction between measurements and metadata, unlike `:telemetry`.

  Honeycomb's keys for trace handling can be configured on a per-dataset basis, but default to:

  * `duration_ms`
  * `name`
  * `service_name`
  * `trace.parent_id`
  * `trace.span_id`
  * `trace.trace_id`

  ### OpenCensus

  To be compatible with the OpenCensus protobuf protocol, [attribute values][AttributeValue]
  [MUST] be one of:

  * `TruncatableString`
  * `int64`
  * `bool_value`
  * `double_value`

  ### Opencensus.Honeycomb

  The data models being quite similar, the `Jason.Encoder` implementation for
  `t:Opencensus.Honeycomb.Event.t/0`:

  * Flattens map values as described below
  * Converts atom keys and values to strings
  * **Drops any other values not compatible with the OpenCensus protobuf definition**
  * **Over-writes any keys that clash with the [default trace handling keys](#module-honeycomb)**

  [MUST]: https://tools.ietf.org/html/rfc2119#section-1
  [MAY]: https://tools.ietf.org/html/rfc2119#section-5
  [AttributeValue]: https://github.com/census-instrumentation/opencensus-proto/blob/e2601ef/src/opencensus/proto/trace/v1/trace.proto#L331
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

  alias Jason.Encode
  alias Jason.Encoder
  alias Opencensus.Honeycomb.Cleaner

  require Record

  defimpl Encoder, for: __MODULE__ do
    @spec encode(%{data: map(), time: any()}, Encode.opts()) ::
            binary()
            | maybe_improper_list(
                binary() | maybe_improper_list(any(), binary() | []) | byte(),
                binary() | []
              )
    def encode(%{time: time, data: data}, opts) do
      data = data |> Cleaner.clean()
      %{time: time, data: data} |> Encode.map(opts)
    end
  end

  @enforce_keys [:time, :data]
  defstruct [:time, :data]

  @typedoc """
  Span attributes after flattening.

  See [attribute limitations](#module-opencensus-honeycomb) for important detail on span attribute
  names and values.

  [attrlimits]: #module-opencensus-honeycomb
  """
  @type event_data :: map()

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

  # Record for :opencensus.span
  Record.defrecordp(
    :span,
    Record.extract(:span, from_lib: "opencensus/include/opencensus.hrl")
  )

  @doc """
  Convert one OpenCensus span to an event suitable for POSTing to the
  [Honeycomb Events API][HCevents].

  See [attribute limitations](#module-opencensus-honeycomb) for important detail on span attribute
  names and values.

  [HCevents]: https://docs.honeycomb.io/api/events/
  [HCstruct]: https://github.com/honeycombio/opencensus-exporter/blob/master/honeycomb/honeycomb.go#L42
  """
  @spec from_oc_span(:opencensus.span(), String.t()) :: t()
  def from_oc_span(record, service_name) do
    start_time = record |> span(:start_time) |> wts_us_since_epoch()
    end_time = record |> span(:end_time) |> wts_us_since_epoch()
    duration_ms = (end_time - start_time) / 1_000

    # All of the attributes that pass is_value_safe?/1 below:
    data =
      record
      |> span(:attributes)
      # Overridden with:
      |> Map.merge(%{
        # Honeycomb expectations:
        "trace.trace_id": record |> span(:trace_id) |> hexify_trace_id(),
        "trace.span_id": record |> span(:span_id) |> hexify_span_id(),
        "trace.parent_id": record |> span(:parent_span_id) |> hexify_span_id(),
        duration_ms: duration_ms |> Float.round(3),
        # timestamp: end_time |> Float.round(3),
        service_name: service_name,
        name: record |> span(:name),
        # Our extensions with matching style:
        "trace.span_kind": record |> span(:kind)
      })
      |> Map.to_list()
      |> Enum.filter(&is_value_safe?/1)
      |> Enum.into(%{})

    time =
      record
      |> span(:start_time)
      |> wts_us_since_epoch()
      |> DateTime.from_unix!(:microsecond)
      |> DateTime.to_iso8601()

    %__MODULE__{time: time, data: data}
  end

  defp wts_us_since_epoch({monotonic_time, time_offset}) do
    div(monotonic_time + time_offset, 1_000)
  end

  defp is_value_safe?({_key, :undefined}), do: false
  defp is_value_safe?({_key, :SPAN_KIND_UNSPECIFIED}), do: false
  defp is_value_safe?({_key, nil}), do: false
  defp is_value_safe?({_key, _}), do: true

  defp hexify_trace_id(:undefined), do: nil
  defp hexify_trace_id(n), do: :io_lib.format("~32.16.0b", [n]) |> to_string()

  defp hexify_span_id(:undefined), do: nil
  defp hexify_span_id(n), do: :io_lib.format("~16.16.0b", [n]) |> to_string()
end
