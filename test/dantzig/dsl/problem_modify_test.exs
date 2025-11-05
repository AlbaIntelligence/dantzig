defmodule Dantzig.DSL.ProblemModifyTest do
  use ExUnit.Case, async: true

  use Dantzig.DSL.Integration

  test "Problem.modify can add constraints after initial define" do
    base =
      Problem.define do
        new(name: "Modify Base")
        variables("x", [i <- 1..2], :binary, "x_#{i}")
      end

    modified =
      Problem.modify(base) do
        constraints([i <- 1..2], x(i) <= 1, "c_#{i}")
      end

    assert map_size(modified.constraints) == 2
    names = modified.constraints |> Map.values() |> Enum.map(& &1.name)
    assert Enum.sort(names) == ["c_1", "c_2"]
  end
end
