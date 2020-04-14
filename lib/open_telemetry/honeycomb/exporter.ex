defmodule OpenTelemetry.Honeycomb.Exporter do
  @moduledoc """
  Exporter implementation.

  `:ot_batch_processor` calls `export/3`, which:

  * fetches the attributes of the named resource
  * loads the spans from the named ETS table
  * converts the spans to Honeycomb events
  * chunks them according to Honeycomb's [batch API limits][HClimits]

  [HClimits]: https://docs.honeycomb.io/api/events/#limits
  """

  alias OpenTelemetry.Honeycomb
  alias OpenTelemetry.Honeycomb.Config
  alias OpenTelemetry.Honeycomb.Event
  alias OpenTelemetry.Honeycomb.HttpBackend
  alias OpenTelemetry.Honeycomb.JsonBackend
  alias OpenTelemetry.Honeycomb.Sender
  alias OpenTelemetry.Records.Span

  require OpenTelemetry.Span

  # @hc_event_limit 102_400
  # @hc_batch_imit 5_242_880
  @hc_event_limit 102_400
  @hc_batch_imit 5_242

  @behaviour :ot_exporter
  @impl :ot_exporter
  @spec init(opts :: keyword()) :: {:ok, Config.t()} | :ignore
  def init(opts), do: {:ok, Kernel.struct!(Config, opts)}

  @impl :ot_exporter
  def shutdown(_), do: :ok

  @impl :ot_exporter
  @spec export(
          tab :: :ets.tab(),
          resource :: :ot_resource.t(),
          Config.t()
        ) :: :ok | :success | :failed_not_retryable | :failed_retryable
  def export(tab, resource, config) do
    # resource_attributes = :ot_resource.attributes(resource)
    # attribute_map = config.attribute_map

    # cook = fn ot_span -> Event.from_ot_span(ot_span, resource_attributes, attribute_map) end

    tab
    |> load_spans()
    |> List.flatten()
    |> export_loaded(resource, config)

    :ok
  end

  @spec export_loaded(
          spans :: [:opentelemetry.span()],
          resource :: :ot_resource.t(),
          Config.t()
        ) :: :ok | :success | :failed_not_retryable | :failed_retryable

  defp export_loaded([], _, _), do: :ok

  defp export_loaded(spans, resource, config) do
    resource_attributes = :ot_resource.attributes(resource)
    attribute_map = config.attribute_map
    cook = fn ot_span -> Event.from_ot_span(ot_span, resource_attributes, attribute_map) end

    spans
    |> Enum.map(cook)
    |> Enum.map(&JsonBackend.encode_to_iodata!(config, &1))
    |> chunk_events()
    |> Enum.each(&send_batch(&1, config))

    :ok
  end

  def send_batch(batch, config) when is_map(config) do
    url = "#{config.api_endpoint}/1/batch/#{config.dataset}"

    headers = [
      {"Content-Type", "application/json"},
      {"User-Agent", "opentelemetry_honeycomb/#{Honeycomb.version()}"},
      {"X-Honeycomb-Team", config.write_key}
    ]

    # Map.take(config, [:http_backend, :http_options])
    {:ok, 200, _, replies_payload} = HttpBackend.request(config, :post, url, headers, batch, [])

    for reply <- JsonBackend.decode!(config, replies_payload) do
      %{"status" => 202} = reply
    end
  end

  defp chunk_events(enum) do
    case Enum.reduce(enum, {[], [], 1}, &chunk_events/2) do
      {[], [], 1} -> []
      {finished, [], _} -> Enum.reverse(finished)
      {finished, unfinished, _} -> Enum.reverse([array_finish(unfinished) | finished])
    end
  end

  defp chunk_events(iodata, {finished, unfinished, unfinished_length}) do
    case IO.iodata_length(iodata) do
      length when length > @hc_event_limit ->
        IO.warn("Event exceeds #{@hc_event_limit} bytes; dropped.")
        {finished, unfinished, unfinished_length}

      length when length + unfinished_length + 1 > @hc_batch_imit ->
        {[array_finish(unfinished) | finished], array_append([], iodata), length + 1}

      length ->
        {finished, array_append(unfinished, iodata), unfinished_length + length + 1}
    end
  end

  defp array_append([], iodata), do: [?[, iodata]
  defp array_append(acc, iodata), do: [acc, ?,, iodata]

  defp array_finish([]), do: [?[, ?]]
  defp array_finish(iodata), do: [iodata, ?]]

  defp load_spans(tab), do: load_spans(tab, :ets.first(tab))

  defp load_spans(_, :"$end_of_table"), do: []

  defp load_spans(tab, key) do
    [:ets.lookup(tab, key) | load_spans(tab, :ets.next(tab, key))]
  end
end
