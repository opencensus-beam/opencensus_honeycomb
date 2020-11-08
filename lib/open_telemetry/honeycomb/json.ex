defmodule OpenTelemetry.Honeycomb.Json do
  @moduledoc """
  JSON back end.

  The OpenTelemetry Honeycomb Exporter uses a `Jason`-style JSON encoder via a behaviour so you
  can adapt it to your preferred JSON encoder or decode/encode options.

  To use `Poison`, install it. The exporter defaults `json_backend` to
  `OpenTelemetry.Honeycomb.Json.PoisonBackend`, which adapts `Poison` to the subset of the
  `Jason` API we document with this behaviour.

  To use `Jason`, install it and configure it as the `json_backend`:

  ```
  config :opentelemetry,
    processors: [
      otel_batch_processor: %{
        exporter: OpenTelemetry.Honeycomb.Exporter,
        json_backend: Jason
      }
    ]
  ```
  """

  alias OpenTelemetry.Honeycomb.Json.PoisonBackend

  @typedoc "A term that we can encode to JSON, or decode from JSON."
  @type encodable_term ::
          nil
          | boolean()
          | float()
          | integer()
          | String.t()
          | [encodable_term]
          | %{optional(String.t()) => encodable_term()}

  @doc """
  Decode a term from JSON.
  """
  @callback decode!(iodata()) :: encodable_term() | no_return()

  @doc """
  Encode a term to JSON.
  """
  @callback encode_to_iodata!(encodable_term()) :: iodata() | no_return()

  @typedoc """
  Configuration for `decode!/2` and `encode_to_iodata!/2`:

  * `json_module`: the JSON back end module
  """
  @type config_opt :: {:json_module, module()}

  @doc """
  Return the default configuration for `decode!/2` and `encode_to_iodata!/2`.
  """
  def default_config, do: [json_module: PoisonBackend]

  @doc """
  Decode a term from JSON using the configured back end.
  """
  @spec decode!(
          config :: [config_opt()],
          data :: iodata()
        ) :: encodable_term() | no_return()
  def decode!(config, data) do
    json_module = Keyword.fetch!(config, :json_module)
    json_module.decode!(data)
  end

  @doc """
  Encode a term to JSON using the configured back end.
  """
  @spec encode_to_iodata!(
          config :: [config_opt()],
          term :: encodable_term()
        ) :: iodata() | no_return()
  def encode_to_iodata!(config, term) do
    json_module = Keyword.fetch!(config, :json_module)
    json_module.encode_to_iodata!(term)
  end
end
