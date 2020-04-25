defmodule OpenTelemetry.Honeycomb.Attributes do
  @moduledoc """
  Attribute cleaning and flattening.

  #{
    "README.md"
    |> File.read!()
    |> String.split("<!-- ADOC !-->")
    |> Enum.fetch!(1)
  }
  """

  @inspect_limit 5

  @typedoc "A key/value pair that hasn't been cleaned."
  @type dirty_pair :: {term(), term()}

  @typedoc "A key/value list that hasn't been cleaned."
  @type dirty_list :: [dirty_pair() | term()]

  @typedoc "A map that hasn't been cleaned."
  @type dirty_map :: map()

  @typedoc "A key/value pair that has been cleaned."
  @type clean_pair :: {OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()}

  @typedoc "A key/value list that has been cleaned."
  @type clean_list :: OpenTelemetry.attributes()

  @doc """
  Merge two sorted attribute lists, eliminating duplicate keys.

  Drops members of the second list that duplicate keys from the first.
  """
  @spec merge(clean_list(), clean_list()) :: clean_list()
  def merge(att1, att2), do: :lists.ukeymerge(1, att1, att2)

  @doc """
  Sort an attribute list, eliminating duplicate keys.

  Drops members that duplicate already-seen keys.
  """
  @spec sort(clean_list()) :: clean_list()
  def sort(att), do: :lists.ukeysort(1, att)

  @doc """
  Clean and flatten span attributes, dropping data that can't be cleaned.
  """
  @spec clean(dirty_map() | dirty_list() | term()) :: clean_list()
  def clean(map) when is_map(map), do: map |> Map.to_list() |> clean()
  def clean(list) when is_list(list), do: list |> Enum.flat_map(&clean_pair/1) |> sort()
  def clean(_), do: []

  @spec clean_pair(dirty_pair :: dirty_pair()) :: clean_list()
  defp clean_pair(dirty_pair)

  # If the key is an atom, convert it to a string:
  defp clean_pair({k, v}) when is_atom(k), do: {Atom.to_string(k), v} |> clean_pair()

  # If the key isn't a string, drop the pair.
  defp clean_pair({k, _}) when not is_binary(k), do: []

  # If the value is nil, drop the pair:
  defp clean_pair({_, v}) when is_nil(v), do: []

  # If the value is supported, keep it:
  defp clean_pair({k, v})
       when is_number(v) or
              is_binary(v) or
              is_boolean(v),
       do: [{k, v}]

  # If the value is an atom, convert it to a string without ':' or 'Elixir.' prefix
  defp clean_pair({k, v}) when is_atom(v) do
    case inspect(v) do
      ":" <> repr -> {k, repr}
      repr -> {k, repr}
    end
  end

  # Flatten maps:
  defp clean_pair({k, map}) when is_map(map) do
    map
    |> Map.to_list()
    |> destruct()
    |> Enum.map(&nest(&1, k))
    |> Enum.map(&clean_pair/1)
    |> List.flatten()
  end

  # Use inspect/2 with a short limit:
  defp clean_pair({k, v}), do: [{k, inspect(v, limit: @inspect_limit)}]

  # Drop anything else:
  defp clean_pair(_), do: []

  # Remove __struct__:
  defp destruct(list), do: list |> Enum.filter(fn {k, _} -> k !== :__struct__ end)

  # Nest a key pair under another key:
  defp nest({k, v}, prefix), do: {"#{prefix}.#{k}", v}

  @hc_value_limit 49_127
  @endpoint @hc_value_limit - 7

  @doc """
  Trim strings longer than #{@hc_value_limit} bytes.

  #{
    "README.md"
    |> File.read!()
    |> String.split("<!-- TRIMDOC !-->")
    |> Enum.fetch!(1)
  }
  """
  def trim_long_strings({k, <<_::binary-size(@hc_value_limit)>> = v}), do: {k, v}

  def trim_long_strings({k, <<keep::binary-size(@endpoint), maybe::binary-size(4), _::binary>>}) do
    <<a::8, b::8, c::8, d::8>> = maybe

    cond do
      d < 128 -> {k, <<keep::binary, maybe::binary, "..."::binary>>}
      c < 128 -> {k, <<keep::binary, a::8, b::8, c::8, "...."::binary>>}
      b < 128 -> {k, <<keep::binary, a::8, b::8, "....."::binary>>}
      a < 128 -> {k, <<keep::binary, a::8, "......"::binary>>}
      true -> {k, <<keep::binary, "......."::binary>>}
    end
  end

  def trim_long_strings({k, v}), do: {k, v}
end
