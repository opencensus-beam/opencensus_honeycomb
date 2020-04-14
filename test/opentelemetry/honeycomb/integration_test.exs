defmodule OpenTelemetry.Honeycomb.IntegrationTest do
  use ExUnit.Case, async: false

  require OpenTelemetry.Tracer
  require OpenTelemetry.Span

  import Mox, only: [set_mox_from_context: 1, verify_on_exit!: 1]

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "span with attribute and event" do
    test_pid = self()

    Mox.expect(MockedHttpBackend, :request, fn method, url, headers, body, opts ->
      try do
        assert :post = method
        assert "https://api.honeycomb.io/1/batch/opentelemetry" = url
        assert [] = opts

        assert [
                 {"Content-Type", "application/json"},
                 {"User-Agent", "opentelemetry_honeycomb/" <> _version},
                 {"X-Honeycomb-Team", "HONEYCOMB_WRITEKEY"}
               ] = headers

        assert [
                 %{
                   "data" => %{
                     "attr1" => "value1",
                     "attr2.attr3" => 4,
                     "duration_ms" => duration_ms,
                     "name" => "some-span",
                     "service.name" => "service-name",
                     "service.namespace" => "service-namespace",
                     "trace.parent_id" => nil,
                     "trace.span_id" => span_id,
                     "trace.trace_id" => trace_id
                   },
                   "samplerate" => 1,
                   "time" => timestamp_8601_utc
                 }
               ] = body |> IO.iodata_to_binary() |> Poison.decode!()

        assert is_float(duration_ms)
        assert span_id =~ ~r"^[0-9a-f]{16,16}"
        assert trace_id =~ ~r"^[0-9a-f]{32,32}"
        assert {:ok, _dt, 0} = DateTime.from_iso8601(timestamp_8601_utc)

        send(test_pid, {:mock_result, :ok})
        {:ok, 200, [], "[{\"status\":202}]"}
      rescue
        e ->
          send(test_pid, {:mock_result, :error, e})
          {:ok, 400, [], "[]"}
      end
    end)

    OpenTelemetry.Tracer.with_span "some-span" do
      OpenTelemetry.Span.set_attribute("attr1", "value1")
      OpenTelemetry.Span.set_attribute(:attr2, %{attr3: 4})

      OpenTelemetry.Span.add_events([
        OpenTelemetry.event("event.name", [{"event.attr1", "event.value1"}])
      ])
    end

    receive do
      {:mock_result, :ok} -> :ok
      {:mock_result, :error, e} -> raise e
    end
  end
end
