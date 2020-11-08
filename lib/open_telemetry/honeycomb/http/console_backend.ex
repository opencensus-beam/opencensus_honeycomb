defmodule OpenTelemetry.Honeycomb.Http.ConsoleBackend do
  @moduledoc """
  A console HTTP back end.

  Lets you see what you'd send, without sending it.
  """

  alias OpenTelemetry.Honeycomb.Exporter
  alias OpenTelemetry.Honeycomb.Http.WriteKeyMissingBackend

  @behaviour OpenTelemetry.Honeycomb.Http

  @impl true
  def request(:post, url, headers, body, _) do
    %{host: host, path: path} = URI.parse(url)

    # %{atom: key_c, string: value_c, binary: body_c} =
    #   :syntax_colors |> IEx.Config.color() |> Enum.into(%{})

    key_c = :cyan
    value_c = :green
    body_c = :default_color

    :ok =
      [
        [:reset, "\n"],
        ["POST ", value_c, path, :reset, " HTTP/1.1\n"],
        [key_c, "Host: ", value_c, host, :reset, "\n"],
        for {key, value} <- headers do
          [key_c, "#{key}: ", value_c, value, :reset, "\n"]
        end,
        "\n",
        [body_c, pretty(body), "\n"]
      ]
      |> IO.ANSI.format()
      |> IO.puts()

    {:ok, 204, [], ""}
  end

  @spec pretty(json :: iodata()) :: iodata()
  cond do
    # I am not willing to pass the JSON back end details through to request/5.
    # I am willing to try a couple likely contenders and punt if they're absent, though.
    Code.ensure_loaded?(Poison) ->
      defp pretty(json), do: json |> Poison.decode!() |> Poison.encode!(pretty: true)

    Code.ensure_loaded?(Jason) ->
      defp pretty(json), do: json |> Jason.decode!() |> Jason.encode!(pretty: true)

    true ->
      defp pretty(json), do: json
  end

  @doc """
  Activate the console back end.
  """
  def activate do
    opts = [http_module: __MODULE__, write_key: "HONEYCOMB_WRITEKEY"]
    :otel_batch_processor.set_exporter(Exporter, opts)
    {:ok, {Exporter, opts}}
  end

  @config_path [:processors, :otel_batch_processor, :exporter]

  @doc """
  Deactivate the console back end, re-installing your configured exporter.
  """
  def deactivate do
    :opentelemetry
    |> Application.get_all_env()
    |> get_in(@config_path)
    |> case do
      nil ->
        IO.warn("no value at #{inspect(@config_path)}; installing default")

        :otel_batch_processor.set_exporter(Exporter,
          http_module: WriteKeyMissingBackend,
          write_key: "HONEYCOMB_WRITEKEY"
        )

        {:ok, WriteKeyMissingBackend}

      {module, options} ->
        :otel_batch_processor.set_exporter(module, options)
        {:ok, {module, options}}

      module ->
        :otel_batch_processor.set_exporter(module)
        {:ok, module}
    end
  end
end
