if Code.ensure_loaded?(Poison) do
  defmodule OpenTelemetry.Honeycomb.Json.PoisonBackend do
    @moduledoc false
    @behaviour OpenTelemetry.Honeycomb.Json
    @impl true
    def decode!(data), do: Poison.decode!(data)

    @impl true
    def encode_to_iodata!(data), do: Poison.Encoder.encode(data, %{})
  end
end
