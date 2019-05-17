defmodule Opencensus.Honeycomb.CleanerTest do
  use ExUnit.Case
  alias Opencensus.Honeycomb.Cleaner
  doctest Opencensus.Honeycomb.Cleaner

  defmodule UnexpectedSpanishInquisition do
    defstruct []
  end

  describe "clean/1" do
    test "booleans" do
      assert %{bool: true} |> Cleaner.clean() == %{"bool" => true}
    end

    test "integers" do
      assert %{int: 1} |> Cleaner.clean() == %{"int" => 1}
    end

    test "floats" do
      assert %{float: 1.23} |> Cleaner.clean() == %{"float" => 1.23}
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
