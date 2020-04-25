defmodule OpenTelemetry.Honeycomb do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc "Get the version string for the OpenTelemetry Honeycomb exporter."
  def version do
    case :application.get_key(:opentelemetry_honeycomb, :vsn) do
      {:ok, version} -> String.Chars.to_string(version)
      :undefined -> "0.0.0"
    end
  end
end
