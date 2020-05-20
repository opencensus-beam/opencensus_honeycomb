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
  alias OpenTelemetry.Honeycomb.Attributes
  alias OpenTelemetry.Honeycomb.Config
  alias OpenTelemetry.Honeycomb.Event
  alias OpenTelemetry.Honeycomb.Http
  alias OpenTelemetry.Honeycomb.Http.WriteKeyMissingBackend
  alias OpenTelemetry.Honeycomb.Json

  require OpenTelemetry.Span

  @hc_event_limit 102_400
  @hc_batch_limit 5_242_880

  @behaviour :ot_exporter
  @impl :ot_exporter
  @spec init(config :: Config.t()) :: {:ok, Config.t()} | :ignore
  def init(config) do
    config = Keyword.merge(Config.default_config(), config)

    http_module = Keyword.fetch!(config, :http_module)
    json_module = Keyword.fetch!(config, :json_module)

    cond do
      not Code.ensure_loaded?(json_module) ->
        warn("json_module #{json_module} not loaded; disabling exporter...")
        :ignore

      # Ugly work-around to ensure the integration tests get a working exporter:
      http_module == MockedHttpBackend ->
        {:ok, config}

      not Code.ensure_loaded?(http_module) ->
        warn("http_module #{http_module} not loaded; disabling exporter...")
        :ignore

      Keyword.get(config, :write_key) == nil ->
        warn("write_key absent; setting http_module=WriteKeyMissingBackend")
        {:ok, Keyword.merge(config, http_module: WriteKeyMissingBackend)}

      true ->
        {:ok, config}
    end
  end

  @impl :ot_exporter
  def shutdown(_), do: :ok

  @impl :ot_exporter
  @spec export(
          tab :: :ets.tab(),
          resource :: :ot_resource.t(),
          Config.t()
        ) :: :ok | :success | :failed_not_retryable | :failed_retryable
  def export(tab, resource, config) do
    tab
    |> :ets.tab2list()
    |> export_loaded(resource, config)
  end

  @spec export_loaded(
          spans :: [:opentelemetry.span()],
          resource :: :ot_resource.t(),
          Config.t()
        ) :: :ok | :success | :failed_not_retryable | :failed_retryable

  defp export_loaded([], _, _), do: :ok

  defp export_loaded(spans, resource, config) do
    resource_attributes = :ot_resource.attributes(resource) |> Attributes.sort()
    attribute_map = config[:attribute_map]

    cook = fn ot_span ->
      Event.from_ot_span(
        ot_span,
        resource_attributes,
        attribute_map,
        Keyword.get(config, :samplerate_key)
      )
    end

    spans
    |> Enum.flat_map(cook)
    |> Enum.map(&Json.encode_to_iodata!(config, &1))
    |> chunk_events()
    |> Enum.map(&send_batch(&1, config))
    |> Enum.find_value(:ok, &find_hc_batch_errors/1)
  end

  defp find_hc_batch_errors(:ok), do: false
  defp find_hc_batch_errors(error), do: error

  defp send_batch(batch, config) do
    url = "#{config[:api_endpoint]}/1/batch/#{config[:dataset]}"

    headers = [
      {"Content-Type", "application/json"},
      {"User-Agent", "opentelemetry_honeycomb/#{Honeycomb.version()}"},
      {"X-Honeycomb-Team", config[:write_key]}
    ]

    config
    |> Http.request(:post, url, headers, batch, [])
    |> handle_hc_reply(config)
  end

  defp handle_hc_reply({:ok, 204, _, _}, _), do: :ok

  defp handle_hc_reply({:ok, 200, _, replies_payload}, config) do
    config
    |> Json.decode!(replies_payload)
    |> Enum.find_value(:ok, &find_hc_batch_item_errors/1)
  end

  defp handle_hc_reply({:ok, 401, _, _}, _),
    do: failed_not_retryable("write_key incorrect for api_endpoint; got 401")

  defp handle_hc_reply({:ok, status, _, _}, _) when status >= 500,
    do: failed_retryable("upstream reports #{status}; failing batch")

  defp handle_hc_reply({:ok, status, _, _}, _),
    do: failed_not_retryable("upstream reports #{status}; dropping batch")

  defp handle_hc_reply(_, _), do: :failed_retryable

  defp find_hc_batch_item_errors(%{"status" => 202}), do: false
  defp find_hc_batch_item_errors(%{"status" => 400}), do: :failed_not_retryable
  defp find_hc_batch_item_errors(_), do: :failed_retryable

  defp failed_not_retryable(message) do
    warn(message)
    :failed_not_retryable
  end

  defp failed_retryable(message) do
    warn(message)
    :failed_retryable
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
        warn("event exceeds #{@hc_event_limit} bytes; dropped.")
        {finished, unfinished, unfinished_length}

      length when length + unfinished_length + 1 > @hc_batch_limit ->
        {[array_finish(unfinished) | finished], array_append([], iodata), length + 1}

      length ->
        {finished, array_append(unfinished, iodata), unfinished_length + length + 1}
    end
  end

  defp array_append([], iodata), do: [?[, iodata]
  defp array_append(acc, iodata), do: [acc, ?,, iodata]

  defp array_finish([]), do: [?[, ?]]
  defp array_finish(iodata), do: [iodata, ?]]

  defp warn(message), do: IO.warn("opentelemetry_honeycomb: #{message}", [])
end
