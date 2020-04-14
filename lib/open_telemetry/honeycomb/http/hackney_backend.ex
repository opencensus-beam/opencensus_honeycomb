if Code.ensure_loaded?(:hackney) do
  defmodule OpenTelemetry.Honeycomb.Http.HackneyBackend do
    @moduledoc """
    The default HTTP back end, using Hackney.

    Absent if Hackney is absent.
    """
    @behaviour OpenTelemetry.Honeycomb.Http
    @impl true
    def request(method, url, headers, body, opts) do
      opts = Keyword.merge([with_body: true], opts)
      :hackney.request(method, url, headers, body, opts)
    end
  end
end
