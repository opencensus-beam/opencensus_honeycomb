defmodule Opencensus.Honeycomb.CleanerTest do
  use ExUnit.Case
  alias Opencensus.Honeycomb.Cleaner
  doctest Opencensus.Honeycomb.Cleaner

  defmodule UnexpectedSpanishInquisition do
    defstruct []
  end

  describe "clean/1" do
    test "map to booleans" do
      assert Cleaner.clean(%{bool: true}) == %{"bool" => true}
    end

    test "map to integers" do
      assert Cleaner.clean(%{int: 1}) == %{"int" => 1}
    end

    test "map to floats" do
      assert Cleaner.clean(%{float: 1.23}) == %{"float" => 1.23}
    end

    test "not a map" do
      assert Cleaner.clean(nil) == %{}
      assert Cleaner.clean([]) == %{}
    end
  end

  describe "clean/1 flattens" do
    test "maps" do
      assert %{map: %{a: 1, b: %{c: 2}}} |> Cleaner.clean() == %{"map.a" => 1, "map.b.c" => 2}
    end
  end

  describe "clean/1 drops" do
    test "nil" do
      assert %{nil: nil} |> Cleaner.clean() == %{}
    end

    test "lists" do
      assert %{list: [1, 2, 3]} |> Cleaner.clean() == %{}
    end

    test "tuples" do
      assert %{tuple: {:ok}} |> Cleaner.clean() == %{}
    end

    test "unexpected structs" do
      assert %{struct: %UnexpectedSpanishInquisition{}} |> Cleaner.clean() == %{}
    end
  end
end
