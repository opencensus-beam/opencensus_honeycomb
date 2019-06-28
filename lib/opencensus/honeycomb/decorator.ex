defmodule Opencensus.Honeycomb.Decorator do
  @moduledoc """
  Behaviour to add data to events before delivery. API not final.
  """

  alias Opencensus.Honeycomb.Event

  @doc """
  Transform event data. API not final.

  Takes an `t:Event.event_data/0` (i.e. the span attributes after they've been flattened), and
  your options. Returns replacment `t:Event.event_data/0`.
  """
  @callback decorate(attributes :: Event.event_data(), opts :: keyword()) :: Event.event_data()
end
