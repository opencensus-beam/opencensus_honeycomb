defmodule Opencensus.Honeycomb.Cleaner do
  @moduledoc false

  @type attribute_key :: String.t()
  @type attribute_value :: String.t() | integer() | boolean() | float()

  @spec clean(map()) :: map()
  def clean(map)

  def clean(map) when is_map(map) do
    map |> Map.to_list() |> Enum.map(&clean_pair/1) |> List.flatten() |> Enum.into(%{})
  end

  def clean(_) do
    %{}
  end

  @spec clean_pair({String.t(), term()}) :: [{String.t(), attribute_value()}]
  defp clean_pair(key_value_pair)

  # If the key is an atom, convert it to a string:
  defp clean_pair({k, v}) when is_atom(k), do: {k |> Atom.to_string(), v} |> clean_pair()

  # If the key isn't a string, drop the pair.
  defp clean_pair({k, _}) when not is_binary(k), do: []

  # If the value is nil, drop the pair:
  defp clean_pair({_, v}) when is_nil(v), do: []

  # If the value is simple, keep it:
  defp clean_pair({k, v})
       when is_number(v) or
              is_binary(v) or
              is_boolean(v) or
              is_nil(v),
       do: [{k, v}]

  # If the value is an atom, convert it to a string:
  defp clean_pair({k, v}) when is_atom(v), do: [{k, v |> Atom.to_string()}]

  # Flatten maps:
  defp clean_pair({k, map}) when is_map(map) do
    map
    |> Map.to_list()
    |> destruct()
    |> Enum.map(&nest(&1, k))
    |> Enum.map(&clean_pair/1)
    |> List.flatten()
  end

  # Give up:
  defp clean_pair(_), do: []

  # Remove __struct__:
  defp destruct(list), do: list |> Enum.filter(fn {k, _} -> k !== :__struct__ end)

  # Nest a key pair under another key:
  defp nest({k, v}, prefix), do: {"#{prefix}.#{k}", v}
end
