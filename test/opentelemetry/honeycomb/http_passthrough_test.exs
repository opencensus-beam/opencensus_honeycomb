defmodule OpenTelemetry.Honeycomb.Http.PassthroughTest do
  use ExUnit.Case

  alias OpenTelemetry.Honeycomb.Config
  alias OpenTelemetry.Honeycomb.Http

  import Mox, only: [set_mox_from_context: 1, verify_on_exit!: 1]

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "request/6 passes control to request/5 in http_module" do
    config = Config.default_config() |> Keyword.put(:http_module, MockedHttpBackend)

    method = :post
    url = "https://api.honeycomb.io/1/batch/opentelemetry"
    body = "[]"
    headers = []
    opts = [recv_timeout: 30_000, max_connections: 4, pool: :opentelemetry_honeycomb]

    Mox.expect(MockedHttpBackend, :request, fn ^method, ^url, ^headers, ^body, ^opts ->
      {:ok, 200, [], "[]"}
    end)

    Http.request(config, method, url, headers, body, opts)
  end
end
