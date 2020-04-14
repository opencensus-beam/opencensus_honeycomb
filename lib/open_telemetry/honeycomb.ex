defmodule OpenTelemetry.Honeycomb do
  @moduledoc """
  In-process [OpenTelemetry] trace exporter for [Honeycomb].

  ## Installation

  Add `:opentelemetry_honeycomb` to your `deps` in `mix.exs`, alongside `:opentelemetry`:

  ```elixir
  {:opentelemetry, "~> 0.4.0"},
  {:opentelemetry_api, "~> 0.3.1"},
  {:opentelemetry_honeycomb, "~> 0.3"},
  ```

  Read the documentation for `OpenTelemetry.Honeycomb.Event` for important information on span
  attribute name and value limitations.

  [OpenTelemetry]: https://opentelemetry.io
  [Honeycomb]: https://www.honeycomb.io

  ## Configuration

  Out of the box, we supply a default value for everything except `write_key`. To override the
  defaults, set the application environment for `:opentelemetry_honeycomb` in `config/config.exs`
  using keys from `t:OpenTelemetry.Honeycomb.Config.t/0`, as below:

  ```elixir
  config :opentelemetry,
    reporters: [{OpenTelemetry.Honeycomb.Reporter, []}],
    send_interval_ms: 1000

  config :opentelemetry_honeycomb,
    dataset: "opentelemetry",
    service_name: "your_app",
    write_key: System.get_env("HONEYCOMB_WRITEKEY")
  ```

  ## Telemetry

  `OpenTelemetry.Honeycomb.Sender.send_batch/1` calls `:telemetry.execute/3` before and after sending
  events. See `OpenTelemetry.Honeycomb.Sender` for details.

  To watch from your `console` or `remote_console` while troubleshooting:

  ```elixir
  alias OpenTelemetry.Honeycomb.Sender
  handle_event = fn n, measure, meta, _ -> IO.inspect({n, measure, meta}) end
  :telemetry.attach_many("test", Sender.telemetry_events(), handle_event, nil)
  ```

  ## Manual Event Sending

  Construct your own `t:OpenTelemetry.Honeycomb.Event.t/0`, and send it with
  `OpenTelemetry.Honeycomb.Sender.send_batch/1`:

  ```elixir
  alias OpenTelemetry.Honeycomb.{Event, Sender}
  [%Event{time: Event.now(), data: %{name: "hello"}}] |> Sender.send_batch()
  """

  @doc "Get the Honeycomb exporter's version."
  def version do
    case :application.get_key(:opentelemetry_honeycomb, :vsn) do
      {:ok, version} -> String.Chars.to_string(version)
      :undefined -> "0.0.0"
    end
  end
end
