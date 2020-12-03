defmodule OpenTelemetry.Honeycomb.Attributes.CleaningTest do
  use ExUnit.Case
  alias OpenTelemetry.Honeycomb.Attributes
  doctest OpenTelemetry.Honeycomb.Attributes

  defmodule UnexpectedSpanishInquisition do
    defstruct []
  end

  describe "clean/1 passes through" do
    test "strings" do
      assert %{string: "string"} |> Attributes.clean() == [{"string", "string"}]
    end

    test "booleans" do
      assert %{bool: true} |> Attributes.clean() == [{"bool", true}]
    end

    test "integers" do
      assert %{int: 1} |> Attributes.clean() == [{"int", 1}]
    end

    test "floats" do
      assert %{float: 1.23} |> Attributes.clean() == [{"float", 1.23}]
    end
  end

  describe "clean/1 inspects" do
    test "atoms" do
      assert %{atom: :atom} |> Attributes.clean() == [{"atom", "atom"}]
    end

    test "tuples" do
      assert %{tuple: {:ok}} |> Attributes.clean() == [{"tuple", "{:ok}"}]
    end

    test "lists" do
      assert %{list: [1, 2, 3]} |> Attributes.clean() == [{"list", "[1, 2, 3]"}]
    end

    test "pids" do
      pid = :erlang.list_to_pid('<0.23.0>')
      assert %{pid: pid} |> Attributes.clean() == [{"pid", "#PID<0.23.0>"}]
    end

    test "ports" do
      port = :erlang.list_to_port('#Port<0.23>')
      assert %{port: port} |> Attributes.clean() == [{"port", "#Port<0.23>"}]
    end

    test "functions" do
      assert %{fun: &IO.puts/1} |> Attributes.clean() == [{"fun", "&IO.puts/1"}]
    end
  end

  describe "clean/1 flattens" do
    test "maps" do
      assert %{map: %{a: 1, b: %{c: 2}}} |> Attributes.clean() == [{"map.a", 1}, {"map.b.c", 2}]
    end
  end

  describe "clean/1 drops" do
    test "nil" do
      assert %{nil: nil} |> Attributes.clean() == []
    end

    test "unexpected structs" do
      assert %{struct: %UnexpectedSpanishInquisition{}} |> Attributes.clean() == []
    end
  end
end
