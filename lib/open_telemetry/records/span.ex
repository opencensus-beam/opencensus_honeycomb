defmodule OpenTelemetry.Records.Span do
  @moduledoc false
  require Record

  alias OpenTelemetry.Records.Event

  @fields Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl")
  Record.defrecordp(:span, @fields)
  defstruct @fields

  @type t :: %__MODULE__{}

  @spec from(record(:span)) :: t()
  def from(rec) when Record.is_record(rec, :span) do
    events = rec |> span(:events) |> Enum.map(&Event.from/1)
    fields = span(rec) |> Keyword.put(:events, events)
    struct!(__MODULE__, fields)
  end
end
