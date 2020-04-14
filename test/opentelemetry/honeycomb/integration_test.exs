defmodule OpenTelemetry.Honeycomb.IntegrationTest do
  use ExUnit.Case

  require OpenTelemetry.Tracer
  require OpenTelemetry.Span

  import Mox, only: [set_mox_from_context: 1, verify_on_exit!: 1]

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "span with attribute and event" do
    request_fun = fn :post,
                     "https://api.honeycomb.io/1/batch/opentelemetry",
                     [
                       {"Content-Type", "application/json"},
                       {"User-Agent", "opentelemetry_honeycomb/" <> _version},
                       {"X-Honeycomb-Team", "HONEYCOMB_WRITEKEY"}
                     ],
                     "",
                     [] ->
      {:ok, 200, [], "[]"}
    end

    Mox.expect(MockedHttpBackend, :request, request_fun)
    # Mox.expect(MockedHttpBackend, :request, fn a, b, c, d, e ->
    #   IO.inspect({a, b, c, d, e})
    #   {:ok, 200, [], "[]"}
    # end)

    OpenTelemetry.Tracer.with_span "some-span" do
      OpenTelemetry.Span.set_attribute("span.attr1", "span.value1")

      OpenTelemetry.Span.add_events([
        OpenTelemetry.event("event.name", [{"event.attr1", "event.value1"}])
      ])
    end

    :timer.sleep(100)
  end
end
