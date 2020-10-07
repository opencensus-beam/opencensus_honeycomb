defmodule Opencensus.Honeycomb.DecoratorTest do
  use ExUnit.Case

  alias Opencensus.Honeycomb.Event
  alias Opencensus.Honeycomb.Reporter

  defmodule MyDecorator do
    @behaviour Opencensus.Honeycomb.Decorator
    @impl Opencensus.Honeycomb.Decorator
    def decorate(data, opts) do
      data |> Map.merge(opts[:extra_data])
    end
  end

  test "no decoration" do
    original = %Event{
      time: "2019-06-28T00:40:05.782Z",
      data: %{"whatever" => 1},
      samplerate: 1
    }

    assert Reporter.decorate(original, nil) == original
  end

  test "decoration" do
    original = %Event{
      time: "2019-06-28T00:40:05.782Z",
      data: %{},
      samplerate: 1
    }

    extra_data = %{
      "whatever" => 1
    }

    expected = %Event{
      time: original.time,
      data: extra_data,
      samplerate: 1
    }

    assert Reporter.decorate(original, {MyDecorator, extra_data: extra_data}) == expected
  end
end
