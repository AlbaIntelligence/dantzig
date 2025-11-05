defmodule Dantzig.DSL.DescriptionInterpolationTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  test "constraint descriptions interpolate generator variables" do
    problem =
      Problem.define do
        new(name: "Interp", description: "desc")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row #{i}")
      end

    # Expect two constraints with names/descriptions containing interpolated i values
    assert map_size(problem.constraints) == 2
    descs = Enum.map(problem.constraints, fn {_id, c} -> c.description end)
    assert Enum.any?(descs, &(&1 =~ "row 1")) or Enum.any?(descs, &(&1 =~ "Row 1"))
    assert Enum.any?(descs, &(&1 =~ "row 2")) or Enum.any?(descs, &(&1 =~ "Row 2"))
  end

  test "single-constraint syntax works with description" do
    problem =
      Problem.define do
        new(name: "Simple", description: "desc")
        variables("x", [], :continuous, "x var")
        constraints(Polynomial.variable("x") <= 10, "Upper bound")
      end

    assert map_size(problem.constraints) == 1
    [{_id, c}] = Map.to_list(problem.constraints)
    assert c.description == "Upper bound"
  end
end
