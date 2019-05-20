defmodule Opencensus.Honeycomb.Sampler.Fixed do
  @moduledoc """
  Fixed-rate sampling.

  Options:

  * `rate`: the sample rate; a positive integer
  * `all`: whether to apply to all events or not

  ```elixir
  config :opencensus_honeycomb, samplers: [Opencensus.Honeycomb.Sampler.Fixed, rate: 8}],
  ```
  """

  @enforce_keys [:rate]
  defstruct [:rate, :all]

  @behaviour Opencensus.Honeycomb.Sampler
  @impl true
  def sample(event, options \\ []) do
    options = struct!(__MODULE__, [all: false] |> Keyword.merge(options))

    if event.samplerate == nil or options.all do
      # return a positive integer to set the sample rate
      options.rate
    else
      # return the event to leave it unmodified
      event
    end
  end
end
