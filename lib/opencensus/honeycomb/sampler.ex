defmodule Opencensus.Honeycomb.Sampler do
  @moduledoc """
  Appropriate sampling decisions for Honeycomb reporters.

  Honeycomb is distinct from some other targets for OpenCensus trace data in that:

  * Honeycomb might be interested in individual spans, even if the trace is not sampled in, and:

  * Honeycomb needs to know the sample rate of the surviving spans.

  By contrast, `:oc_sampler` doesn't retain any information about why a sampling decision turned
  out the way it did, and `:oc_sampler_probability` keeps all children of any sampled span.
  """

  alias Opencensus.Honeycomb.Config
  alias Opencensus.Honeycomb.Event
  require Logger

  @doc """
  Given an event and some `options`, return either:

  * The original event, or
  * A modified event.

  As shortcuts, return:

  * `nil` to express that the original event should be kept unmodified, or
  * A positive integer to use as the new `samplerate`.

  For predictable operation, samplers shipped as packages [SHOULD NOT] modify events with
  `samplerate` already set unless their documented purpose is to do exactly that.

  Samplers [MAY] be non-idempotent, e.g. return different values for the same event because they
  are adjusting their sample rate based on event rate.

  [SHOULD NOT]: https://tools.ietf.org/html/rfc2119#section-4
  [MAY]: https://tools.ietf.org/html/rfc2119#section-5

  """
  @callback sample(event :: Event.t(), options :: keyword()) :: nil | pos_integer() | Event.t()

  @doc false
  @spec sample(events :: list(Event.t()), samplers :: list(Config.sampler())) :: Event.t()
  def sample(events, samplers) when is_list(events) and is_list(samplers) do
    samplers |> Enum.reduce(events, &apply_sampler/2)
  end

  defp apply_sampler(sampler, events) do
    {module, options} = unpack(sampler)
    # At this point, we could ask another method on the sampler whether it wanted to be called
    # for all or just unsampled events, but for now we'll leave that up to their code:
    for event <- events do
      case Kernel.apply(module, :sample, [event, options]) do
        s when is_integer(s) and s > 0 ->
          event |> Event.with_samplerate(s)

        nil ->
          event

        %Event{} = modified_event ->
          modified_event

        _ ->
          Logger.warn("Unexpected return value from #{module}")
          event
      end
    end
  end

  defp unpack(module) when is_atom(module), do: {module, []}
  defp unpack({module}) when is_atom(module), do: {module, []}
  defp unpack({module, options}) when is_atom(module) and is_list(options), do: {module, options}
end
