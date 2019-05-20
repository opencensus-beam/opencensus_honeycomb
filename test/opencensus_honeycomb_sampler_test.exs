defmodule Opencensus.Honeycomb.SamplerTest do
  use ExUnit.Case
  alias Opencensus.Honeycomb.Event
  alias Opencensus.Honeycomb.Sampler

  @time "2019-05-17T09:55:12.622658Z"

  describe "Sampler.sample/2" do
    defmodule ReturnOriginalEvent do
      @behaviour Sampler
      def sample(event, _), do: event
    end

    test "return original event" do
      events = [%Event{time: @time, data: %{}}]
      samplers = [ReturnOriginalEvent]
      assert Sampler.sample(events, samplers) == events
    end

    defmodule ReturnNil do
      @behaviour Sampler
      def sample(_, _), do: nil
    end

    test "return nil" do
      events = [%Event{time: @time, data: %{}}]
      samplers = [ReturnNil]
      assert Sampler.sample(events, samplers) == events
    end

    defmodule ReturnModifiedEvent do
      @behaviour Sampler
      def sample(event, _), do: event |> Event.with_samplerate(2)
    end

    test "return modified event" do
      events = [%Event{time: @time, data: %{}}]
      samplers = [ReturnModifiedEvent]

      expected = [
        events |> hd |> Map.put(:samplerate, 2)
      ]

      assert Sampler.sample(events, samplers) == expected
    end

    defmodule ReturnPositiveInteger do
      @behaviour Sampler
      def sample(_, _), do: 2
    end

    test "return positive integer" do
      events = [%Event{time: @time, data: %{}}]
      samplers = [ReturnPositiveInteger]

      expected = [
        events |> hd |> Map.put(:samplerate, 2)
      ]

      assert Sampler.sample(events, samplers) == expected
    end
  end

  describe "Fixed" do
    test "set the rate if not set" do
      event = %Event{time: @time, data: %{}}
      expected = event |> Map.put(:samplerate, 2)
      assert Sampler.sample([event], [{Sampler.Fixed, rate: 2}]) == [expected]
    end

    test "do not set the rate if already set" do
      event = %Event{time: @time, data: %{}, samplerate: 3}
      assert Sampler.sample([event], [{Sampler.Fixed, rate: 2}]) == [event]
    end

    test "DO set the rate EVEN if already set IF all: true" do
      event = %Event{time: @time, data: %{}, samplerate: 3}
      expected = event |> Map.put(:samplerate, 2)
      assert Sampler.sample([event], [{Sampler.Fixed, rate: 2, all: true}]) == [expected]
    end
  end
end
