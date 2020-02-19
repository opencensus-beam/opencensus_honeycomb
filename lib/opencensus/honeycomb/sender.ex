defmodule Opencensus.Honeycomb.Sender do
  @event_start [:opencensus, :honeycomb, :start]
  @event_stop_failure [:opencensus, :honeycomb, :stop, :failure]
  @event_stop_success [:opencensus, :honeycomb, :stop, :success]

  @moduledoc """
  Sends events to Honeycomb.

  ## Telemetry

  `send_batch/1` calls `:telemetry.execute/3` with with an `event_name` of:

  * `#{inspect(@event_start)}` before sending
  * `#{inspect(@event_stop_success)}` after sending successfully
  * `#{inspect(@event_stop_failure)}` after sending unsuccessfully

  The measurements map contains `count` and, in the trailing events, `ms`.

  The metadata map contains:

  * `events` on all three events
  * `exception` on `#{inspect(@event_stop_failure)}`
  * `payload` on `#{inspect(@event_stop_success)}`

  To watch from your `console` or `remote_console` while troubleshooting:

  ```elixir
  alias Opencensus.Honeycomb.Sender
  handle_event = fn n, measure, meta, _ -> IO.inspect({n, measure, meta}) end
  :telemetry.attach_many("test", Sender.telemetry_events(), handle_event, nil)
  ```
  """

  require Logger
  alias Opencensus.Honeycomb.Config
  alias Opencensus.Honeycomb.Event

  @doc false
  def telemetry_events, do: [@event_stop_failure, @event_start, @event_stop_success]

  @doc """
  Send a batch of Honeycomb events to the Honeycomb batch API.
  """
  @spec send_batch(list(Event.t())) :: {:ok, integer()} | {:error, Exception.t()}
  def send_batch(events) when is_list(events) do
    count = length(events)
    begin = System.monotonic_time(:microsecond)
    :telemetry.execute(@event_start, %{count: count}, %{events: events})

    try do
      config = Config.effective()
      payload = Jason.encode!(events)
      url = "#{config.api_endpoint}/1/batch/#{config.dataset}"

      headers = [
        {"X-Honeycomb-Team", config.write_key},
        {"Content-Type", "application/json"},
        {"User-Agent", "opencensus_honeycomb/0.0.0"}
      ]

      if has_set_write_key?(config), do: send_it(url, headers, payload)

      :telemetry.execute(
        @event_stop_success,
        %{count: count, ms: ms_since(begin)},
        %{events: events, payload: payload}
      )

      {:ok, count}
    rescue
      e ->
        :telemetry.execute(
          @event_stop_failure,
          %{count: count, ms: ms_since(begin)},
          %{events: events, exception: e}
        )

        {:error, e}
    end
  end

  defp send_it(url, headers, payload) do
    with {:ok, status, _headers, client_ref} <-
           :hackney.request(:post, url, headers, payload, []),
         {:ok} <- check_status(status, client_ref),
         {:ok, body} <- :hackney.body(client_ref),
         {:ok, replies} <- Jason.decode(body),
         {:ok} <- check_replies(replies) do
      nil
    end
  end

  defp ms_since(begin), do: (System.monotonic_time(:microsecond) - begin) / 1000.0

  defp has_set_write_key?(config) do
    case config.write_key do
      nil -> false
      "" -> false
      _ -> true
    end
  end

  defp check_status(status, client_ref) when is_integer(status) do
    if status == 200 do
      {:ok}
    else
      :hackney.close(client_ref)
      {:error, :bad_status, status}
    end
  end

  defp check_replies(replies) when is_list(replies) do
    case replies |> Enum.filter(&lacks_status_202?/1) |> length() do
      0 -> {:ok}
      _ -> {:error, :unexpected_replies}
    end
  end

  defp lacks_status_202?(reply) when is_map(reply), do: reply["status"] != 202
  defp lacks_status_202?(_reply), do: false
end
