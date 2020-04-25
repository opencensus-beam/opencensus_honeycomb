# Start the app and its runtime dependencies:
{:ok, _} = Application.ensure_all_started(:opentelemetry_honeycomb)

# Start the non-runtime dependencies we need for test:
:ok = Application.ensure_started(:mox)

ExUnit.start(capture_log: true, timeout: 10_000)
Mox.defmock(MockedHttpBackend, for: OpenTelemetry.Honeycomb.Http)
