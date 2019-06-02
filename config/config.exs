use Mix.Config

config :opencensus_honeycomb,
  write_key: nil

config :opencensus,
  reporters: [{Opencensus.Honeycomb.Reporter, []}],
  send_interval_ms: 1000

if Mix.env() == :test do
  # We need an OTP app to host Phoenix, and ours has strong opinions about its configuration, so:
  config :opencensus, Opencensus.Honeycomb.PhoenixIntegrationTest.HelloWeb.Endpoint,
    debug_errors: true,
    secret_key_base: 30 |> :crypto.strong_rand_bytes() |> Base.encode32(),
    json_library: Jason,
    url: [host: "localhost"]

  config :opencensus,
    reporters: [{Opencensus.Honeycomb.Reporter, []}],
    send_interval_ms: 5
end
