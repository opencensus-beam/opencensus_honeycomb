defmodule Opencensus.Honeycomb.ConfigTest do
  use ExUnit.Case
  alias Opencensus.Honeycomb.Config

  setup do
    config = get_app_config()

    on_exit(fn ->
      put_app_config(config)
    end)
  end

  test "effective/0 with defaults only" do
    delete_app_config()

    assert Config.effective() == %Config{
             api_endpoint: "https://api.honeycomb.io",
             batch_size: 100,
             write_key: nil,
             dataset: "opencensus",
             service_name: "-"
           }
  end

  test "effective/0 with complete config" do
    put_app_config(
      api_endpoint: "https://api-custom.example.com",
      batch_size: 23,
      write_key: "custom_write_key",
      dataset: "custom_dataset",
      service_name: "custom_service_name"
    )

    assert Config.effective() == %Config{
             api_endpoint: "https://api-custom.example.com",
             batch_size: 23,
             write_key: "custom_write_key",
             dataset: "custom_dataset",
             service_name: "custom_service_name"
           }
  end

  test "effective/0 with mixed defaults and config" do
    put_app_config(
      dataset: "custom_dataset",
      service_name: "custom_service_name",
      write_key: "0000000000000000"
    )

    assert Config.effective() == %Config{
             api_endpoint: "https://api.honeycomb.io",
             batch_size: 100,
             write_key: "0000000000000000",
             dataset: "custom_dataset",
             service_name: "custom_service_name"
           }
  end

  test "put/1" do
    delete_app_config()

    config = %Config{
      api_endpoint: "https://api-custom.example.com",
      batch_size: 23,
      write_key: "custom_write_key",
      dataset: "custom_dataset",
      service_name: "custom_service_name"
    }

    assert is_map(config)
    Config.put(config)

    assert get_app_config() == [
             api_endpoint: "https://api-custom.example.com",
             batch_size: 23,
             dataset: "custom_dataset",
             service_name: "custom_service_name",
             write_key: "custom_write_key"
           ]
  end

  test "into/1 update" do
    delete_app_config()

    result = Config.into(write_key: "custom_write_key")

    # The return value shows you all the holes in your config...
    assert result == %Config{
             api_endpoint: nil,
             write_key: "custom_write_key",
             dataset: nil,
             service_name: nil
           }

    # The application configuration, meanwhile, is shorter because we only put one field:
    assert get_app_config() == [
             write_key: "custom_write_key"
           ]

    # After filling in the defaults, our effective configuration is:
    assert Config.effective() == %Config{
             api_endpoint: "https://api.honeycomb.io",
             batch_size: 100,
             write_key: "custom_write_key",
             dataset: "opencensus",
             service_name: "-"
           }
  end

  test "into/1 removal" do
    put_app_config(
      api_endpoint: "https://api-custom.example.com",
      write_key: "left alone"
    )

    result = Config.into(api_endpoint: nil)

    assert result == %Config{
             api_endpoint: nil,
             write_key: "left alone",
             dataset: nil,
             service_name: nil
           }

    assert get_app_config() == [
             api_endpoint: nil,
             write_key: "left alone"
           ]
  end

  defp get_app_config() do
    :opencensus_honeycomb
    |> Application.get_all_env()
    |> Enum.sort()
  end

  defp put_app_config(config) do
    delete_app_config()
    config |> Enum.each(fn {k, v} -> Application.put_env(:opencensus_honeycomb, k, v) end)
  end

  defp delete_app_config() do
    Application.get_all_env(:opencensus_honeycomb)
    |> Keyword.keys()
    |> Enum.each(&Application.delete_env(:opencensus_honeycomb, &1))
  end
end
