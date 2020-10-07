defmodule Opencensus.Honeycomb.Config do
  @moduledoc """
  Configuration.

  Out of the box, we supply suitable defaults for everything except `write_key`. To override the
  defaults, set the application environment in `config/config.exs` using keys from `t:t/0`:

  ```elixir
  config :opencensus,
    reporters: [{Opencensus.Honeycomb.Reporter, []}],
    send_interval_ms: 1000

  config :opencensus_honeycomb,
    dataset: "opencensus",
    service_name: "your_app",
    samplerate_key: "samplerate",
    write_key: System.get_env("HONEYCOMB_WRITEKEY")
  ```

  If you're using `Mix`, you probably won't need to use `effective/0`, `get/0`, and `put/1`.
  """

  @app :opencensus_honeycomb

  @defaults [
    api_endpoint: "https://api.honeycomb.io",
    batch_size: 100,
    dataset: "opencensus",
    decorator: nil,
    samplerate_key: nil,
    service_name: "-",
    write_key: nil
  ]

  @keys Keyword.keys(@defaults)

  defstruct @keys

  @typedoc """
  The module and keyword arguments for your `Opencensus.Honeycomb.Decorator` implementation.
  """
  @type decorator :: {module(), keyword()}

  @typedoc """
  Our configuration struct.

  * `api_endpoint`: the API endpoint
  * `batch_size`: the batch size
  * `dataset`: the dataset
  * `decorator`: the decorator module and arguments (`nil` disables decoration)
  * `service_name`: the service name
  * `samplerate_key`: the sample rate key (`nil` disables setting the sample rate)
  * `write_key`: the write key (`nil` disables sending spans)

  Default values:

  #{for {k, v} <- @defaults, do: ["* `", Atom.to_string(k), "`: `", inspect(v), "`\n"]}
  """
  @type t :: %__MODULE__{
          api_endpoint: String.t() | nil,
          batch_size: integer() | nil,
          dataset: String.t() | nil,
          decorator: decorator() | nil,
          service_name: String.t() | nil,
          write_key: String.t() | nil,
          samplerate_key: String.t() | nil
        }

  @doc """
  Get the effective configuration, using default values where necessary.
  """
  @spec effective() :: t()
  def effective do
    fields = get() |> Map.to_list() |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    __MODULE__ |> struct!(@defaults) |> struct!(fields)
  end

  @doc """
  Get the application configuration _without_ using default values.
  """
  @spec get() :: t()
  def get do
    fields = @app |> Application.get_all_env() |> sane()
    struct!(__MODULE__, fields)
  end

  @doc """
  Put to the application configuration.

  Returns the result of `get/0`, _not_ `effective/0`.

  When called with a map, replaces known fields that are not specified with `nil`. Does _not_
  delete or modify unknown keys present in the application configuration.

  Crashes with a `KeyError` if any keys are invalid; see `Kernel.struct!/2`.
  """
  @spec put(map() | t()) :: t()
  def put(config) when is_map(config) do
    config = struct!(__MODULE__, Map.to_list(config))
    config |> Map.to_list() |> into()
  end

  @doc """
  Inserts into the application configuration.

  Returns the result of `get/0`, _not_ `effective/0`.

  Does not replace fields that are not specified. To "delete" a field from the config so the
  default takes effect in `effective/0`, set it to `nil`. Consider `put/1`, instead.

  Crashes with a `KeyError` if any keys are invalid; see `Kernel.struct!/2`.
  """
  @spec into(keyword()) :: t()
  def into(fields) do
    fields |> lint!() |> Enum.each(&put_env/1)
    get()
  end

  defp put_env({k, v}), do: Application.put_env(@app, k, v)

  defp lint!(fields) when is_list(fields) do
    fields = sane(fields)
    struct!(__MODULE__, fields)
    fields
  end

  defp sane(fields) when is_list(fields) do
    Enum.filter(fields, fn {k, _} -> k != :__struct__ end)
  end
end
