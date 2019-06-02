defmodule Opencensus.Honeycomb.PhoenixIntegrationTest do
  use ExUnit.Case, async: false
  use Phoenix.ConnTest

  alias Jason
  alias Opencensus.Honeycomb.Sender

  defmodule HelloWeb.OpencensusTracePlug do
    use Opencensus.Plug.Trace, attributes: [:release]

    def release(_conn) do
      %{
        branch: "master",
        commit: "ae9e6d8"
      }
    end
  end

  defmodule HelloWeb.Router do
    use Plug.Router

    plug(:match)
    plug(:dispatch)

    Plug.Router.get "/ctx" do
      {:span_ctx, trace_id, span_id, _, _} = :ocp.current_span_ctx()

      body = Jason.encode!(%{"trace_id" => trace_id, "span_id" => span_id})

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> send_resp(200, body)
    end

    match _ do
      send_resp(conn, 404, "oops")
    end
  end

  defmodule HelloWeb.Endpoint do
    # We need an OTP app to host Phoenix, and ours has strong opinions about its configuration, so:
    use Phoenix.Endpoint, otp_app: :opencensus

    def init(_), do: {:ok, []}

    plug(HelloWeb.OpencensusTracePlug)
    # ... your usual chain...
    # plug(Plug.Static)
    # plug(Phoenix.CodeReloader)
    # ...
    plug(HelloWeb.Router)
  end

  setup _ do
    :ok = Application.ensure_started(:mime)
    :ok = Application.ensure_started(:plug_crypto)
    :ok = Application.ensure_started(:plug)
    :ok = Application.ensure_started(:opencensus_honeycomb)
    :ok = Application.ensure_started(:telemetry)
    start_supervised!(HelloWeb.Endpoint, [])
    testpid = self()

    handle_event = fn n, measure, meta, _ ->
      # IO.inspect(n, label: "handle_event/4")
      send(testpid, {__MODULE__, :handle_event, {n, measure, meta}})
    end

    :telemetry.attach_many(__MODULE__, Sender.telemetry_events(), handle_event, nil)
    on_exit(make_ref(), fn -> :telemetry.detach(__MODULE__) end)
    {:ok, []}
  end

  test "Phoenix integration" do
    conn =
      Phoenix.ConnTest.build_conn(:get, "/ctx")
      |> HelloWeb.Endpoint.call([])

    assert %{
             "span_id" => span_id,
             "trace_id" => trace_id
           } = json_response(conn, 200)

    assert is_integer(trace_id)
    assert is_integer(span_id)

    timeout = Application.get_all_env(:opencensus) |> Keyword.get(:send_interval_ms)
    assert timeout == 5
    messages = get_messages(timeout * 4)
    # TODO switch back to regular ExUnit message checks
    # TODO assert [:opencensus, :honeycomb, :start] measurements.count
    # TODO assert [:opencensus, :honeycomb, :start] metadata.events
    # TODO assert [:opencensus, :honeycomb, :start] measurements.count
    # TODO assert [:opencensus, :honeycomb, :start] measurements.ms
    # TODO assert [:opencensus, :honeycomb, :start] metadata.events
    # TODO assert [:opencensus, :honeycomb, :start] metadata.payload
    # TODO investigate why event.data has "http.host" string key but :"trace.trace_id" atom key
  end

  defp get_messages(timeout, messages \\ []) do
    IO.inspect({timeout, length(messages)}, label: "#{__MODULE__}.get_messages/2")

    receive do
      {__MODULE__, _, _} = message ->
        get_messages(timeout, [message | messages])

      %Phoenix.Socket.Message{} ->
        get_messages(timeout, messages)

      _ ->
        get_messages(timeout, messages)
    after
      timeout -> messages
    end
  end
end
