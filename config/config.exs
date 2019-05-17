use Mix.Config

config :opencensus_honeycomb,
  write_key: nil

config :opencensus,
  reporters: [{Opencensus.Honeycomb.Reporter, []}],
  send_interval_ms: 1000
