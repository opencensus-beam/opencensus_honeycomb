defmodule OpenTelemetry.Honeycomb.Http.WriteKeyMissingBackend do
  @moduledoc """
  A no-op HTTP back end.

  Installed instead of your configured back end if write_key is nil.
  """
  @behaviour OpenTelemetry.Honeycomb.Http
  @impl true
  def request(_, _, _, _, _) do
    {:ok, 204, [], ""}
  end
end
