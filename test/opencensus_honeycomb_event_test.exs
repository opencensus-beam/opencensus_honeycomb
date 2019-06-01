defmodule Opencensus.Honeycomb.EventTest do
  use ExUnit.Case
  alias Opencensus.Honeycomb.Event

  test "Jason.encode!/1" do
    time = "2019-06-01T00:19:06.234131Z"

    event = %Event{
      time: time,
      data: %{
        map: %{a: 1, b: %{c: 2}}
      }
    }

    expected =
      Jason.encode!(%{
        time: time,
        # samplerate added:
        samplerate: 1,
        # data flattened:
        data: %{"map.a" => 1, "map.b.c" => 2}
      })

    assert Jason.encode!(event) == expected
  end

  test "Event.now/0" do
    assert String.match?(Event.now(), ~r/\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}(\.\d{1,6})?Z/)
  end
end
