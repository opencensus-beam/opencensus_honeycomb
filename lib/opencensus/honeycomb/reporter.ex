defmodule Opencensus.Honeycomb.Reporter do
  @moduledoc """
  Reporter implementation.

  `:opencensus` calls `report/2` with a list of spans collected over the last `send_interval_ms`.
  `report/2` cuts them into `batch_size` batches for `Opencensus.Honeycomb.Sender.send_batch/1`.
  """

  alias Opencensus.Honeycomb.Config
  alias Opencensus.Honeycomb.Event
  alias Opencensus.Honeycomb.Sampler
  alias Opencensus.Honeycomb.Sender

  @behaviour :oc_reporter

  @impl true
  def init(_args) do
    :ok
  end

  @doc "Implements the `report/2` callback for the `:oc_reporter` behaviour."
  @impl true
  def report(spans, :ok) do
    config = Config.effective()
    service_name = config.service_name
    translate = fn span -> Event.from_oc_span(span, service_name) end

    spans
    |> Enum.map(translate)
    |> Sampler.sample(config.samplers)
    |> Enum.chunk_every(config.batch_size)
    |> Enum.each(&Sender.send_batch/1)

    :ok
  end
end
