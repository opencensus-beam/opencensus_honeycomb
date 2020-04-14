defmodule OpenTelemetry.Honeycomb.JsonBackend do
  @moduledoc """
  JSON back end.

  The OpenTelemetry Honeycomb Exporter uses a Jason/Poison-style JSON encoder via a behaviour so
  you can adapt it to your preferred JSON encoder or decode/encode options.
  """

  alias OpenTelemetry.Honeycomb.JsonBackend.PoisonBackend

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

  @doc """
  Return the default back end's module.
  """
  def default_module, do: PoisonBackend

  @typedoc "Configuration for `decode!/2` and `encode_to_iodata!/2`."
  @type config :: %{
          required(:json_module) => module(),
          optional(any()) => any()
        }

  @doc """
  Decode a term from JSON using the configured back end.
  """
  @spec decode!(
          config :: config(),
          data :: iodata()
        ) :: encodable_term() | no_return()
  def decode!(%{json_module: json_module}, data) do
    json_module.decode!(data)
  end

  @doc """
  Encode a term to JSON using the configured back end.
  """
  @spec encode_to_iodata!(
          config :: config(),
          term :: encodable_term()
        ) :: iodata() | no_return()
  def encode_to_iodata!(%{json_module: json_module}, term) do
    json_module.encode_to_iodata!(term)
  end
end

defmodule OpenTelemetry.Honeycomb.JsonBackend.PoisonBackend do
  @moduledoc false
  @behaviour OpenTelemetry.Honeycomb.JsonBackend
  @impl true
  def decode!(data), do: Poison.decode!(data)

  @impl true
  def encode_to_iodata!(data), do: Poison.Encoder.encode(data, %{})
end
