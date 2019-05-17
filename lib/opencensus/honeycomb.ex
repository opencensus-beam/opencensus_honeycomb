defmodule Opencensus.Honeycomb do
  @moduledoc """
  In-process [OpenCensus] trace exporter for [Honeycomb].

  ## Installation

  Add `:opencensus_honeycomb` to your `deps` in `mix.exs`, alongside `:opencensus`:

  ```elixir
  {:opencensus, "~> 0.9.2"},
  {:opencensus_honeycomb, "~> 0.1"}
  ```

  Read the documentation for `Opencensus.Honeycomb.Event` for important information on span
  attribute name and value limitations.

  [OpenCensus]: https://opencensus.io
  [Honeycomb]: https://www.honeycomb.io

  ## Configuration

  Out of the box, we supply a default value for everything except `write_key`. To override the
  defaults, set the application environment for `:opencensus_honeycomb` in `config/config.exs`
  using keys from `t:Opencensus.Honeycomb.Config.t/0`, as below:

  ```elixir
  config :opencensus,
    reporters: [{Opencensus.Honeycomb.Reporter, []}],
    send_interval_ms: 1000

  config :opencensus_honeycomb,
    dataset: "opencensus",
    service_name: "your_app",
    write_key: System.get_env("HONEYCOMB_WRITEKEY")
  ```

  ## Telemetry

  `Opencensus.Honeycomb.Sender.send_batch/1` calls `:telemetry.execute/3` before and after sending
  events. See `Opencensus.Honeycomb.Sender` for details.

  To watch from your `console` or `remote_console` while troubleshooting:

  ```elixir
  alias Opencensus.Honeycomb.Sender
  handle_event = fn n, measure, meta, _ -> IO.inspect({n, measure, meta}) end
  :telemetry.attach_many("test", Sender.telemetry_events(), handle_event, nil)
  ```

  ## Manual Event Sending

  Construct your own `t:Opencensus.Honeycomb.Event.t/0`, and send it with
  `Opencensus.Honeycomb.Sender.send_batch/1`:

  ```elixir
  alias Opencensus.Honeycomb.{Event, Sender}
  [%Event{time: Event.now(), data: %{name: "hello"}}] |> Sender.send_batch()
  """
end
