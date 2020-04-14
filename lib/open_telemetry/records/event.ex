defmodule OpenTelemetry.Records.Event do
  @moduledoc false
  require Record

  @fields Record.extract(:event, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  Record.defrecordp(:event, @fields)
  defstruct @fields

  @type t :: %__MODULE__{}

  @spec from(record(:event)) :: t()
  def from(rec) when Record.is_record(rec, :event) do
    fields = event(rec)
    struct!(__MODULE__, fields)
  end
end
