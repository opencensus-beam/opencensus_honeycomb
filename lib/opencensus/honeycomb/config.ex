defmodule Opencensus.Honeycomb.Config do
  @moduledoc """
  Configuration.

  Out of the box, we supply a default value for everything except `write_key`. To override the
  defaults, set the application environment in `config/config.exs` using keys from `t:t/0`:

  ```elixir
  config :opencensus,
    reporters: [{Opencensus.Honeycomb.Reporter, []}],
    send_interval_ms: 1000

  config :opencensus_honeycomb,
    dataset: "opencensus",
    service_name: "your_app",
    write_key: System.get_env("HONEYCOMB_WRITEKEY")
  ```

  If you're using `Mix`, you probably won't need to use `effective/0`, `get/0`, and `put/1`.
  """

  @app :opencensus_honeycomb

  @default_api_endpoint "https://api.honeycomb.io"
  @default_dataset "opencensus"
  @default_samplers []
  @default_service_name "-"
  @default_write_key nil
  @default_batch_size 100

  defstruct [
    :api_endpoint,
    :batch_size,
    :dataset,
    :samplers,
    :service_name,
    :write_key
  ]

  @typedoc "An `Opencensus.Honeycomb.Sampler` and its options."
  @type sampler :: module :: atom() | {module :: atom} | {module :: atom(), options :: keyword()}

  @typedoc """
  Our configuration struct.

  * `api_endpoint`: the API endpoint (default:`#{inspect(@default_api_endpoint)})`
  * `batch_size`: the write key (default:`#{inspect(@default_batch_size)})`
  * `dataset`: the dataset (default:`#{inspect(@default_dataset)})`
  * `samplers`: the samplers (default:`#{inspect(@default_samplers)}`
  * `service_name`: the service name (default:`#{inspect(@default_service_name)}`
  * `write_key`: the write key (default:`#{inspect(@default_write_key)})`

  A `write_key` of `nil` disables sending to Honeycomb.
  """
  @type t :: %__MODULE__{
          api_endpoint: String.t() | nil,
          batch_size: integer() | nil,
          dataset: String.t() | nil,
          samplers: list(sampler()) | nil,
          service_name: String.t() | nil,
          write_key: String.t() | nil
        }

  @doc """
  Get the effective configuration, using default values where necessary.
  """
  @spec effective() :: t() | no_return
  def effective() do
    fields = get() |> Map.to_list() |> Enum.filter(fn {_, v} -> not is_nil(v) end)

    struct!(defaults(), fields)
  end

  defmodule BadConfigError do
    @moduledoc false
    defexception [:key]

    @impl true
    def exception(%KeyError{key: key}) do
      %BadConfigError{key: key}
    end

    @impl true
    def message(err) do
      "Bad config key: #{err.key}"
    end
  end

  @doc """
  Get the application configuration _without_ using default values.
  """
  @spec get() :: t() | no_return
  def get() do
    fields = @app |> Application.get_all_env() |> sane()

    struct!(__MODULE__, fields)
  rescue
    e in KeyError ->
      raise BadConfigError, e
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

  defp defaults() do
    %__MODULE__{
      api_endpoint: @default_api_endpoint,
      batch_size: @default_batch_size,
      dataset: @default_dataset,
      samplers: @default_samplers,
      service_name: @default_service_name,
      write_key: @default_write_key
    }
  end

  defp lint!(fields) when is_list(fields) do
    fields = sane(fields)
    struct!(__MODULE__, fields)
    fields
  end

  defp sane(fields) when is_list(fields) do
    Enum.filter(fields, fn {k, _} -> k != :__struct__ end)
  end
end
