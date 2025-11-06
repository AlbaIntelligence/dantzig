defmodule Dantzig.DSL.SimpleIntegrationTest do
  @moduledoc """
  Simple integration tests for the DSL functionality
  """
  use ExUnit.Case, async: true

  # Import DSL components for testing
  use Dantzig.DSL.Integration

  alias Dantzig.Problem, as: Problem

  test "basic DSL functionality works" do
    # Test that basic DSL functionality works end-to-end
    problem =
      Problem.define do
        new(name: "Basic DSL Test")
        variables("x", [i <- 1..3], :continuous)
        constraints([i <- 1..3], x(i) >= 0, "non_neg_#{i}")
        objective(sum(for i <- 1..3, do: x(i)), :maximize)
      end

    # Verify problem structure
    assert problem.name == "Basic DSL Test"
    assert map_size(problem.variables) > 0
    assert map_size(problem.constraints) == 3
    assert problem.direction == :maximize
  end

  test "variable access macros work" do
    # Test that variable access macros work in expressions
    problem =
      Problem.define do
        new(name: "Variable Access Test")
        variables("x", [i <- 1..2], :continuous)
        variables("y", [j <- 1..2], :continuous)
        constraints(x(1) + x(2) <= 10, "sum_constraint")
        constraints([i <- 1..2], x(i) + y(i) >= 0, "pair_#{i}")
      end

    # Should create 3 constraints total
    assert map_size(problem.constraints) == 3

    # Should have both x and y variables
    x_vars = Problem.get_variables_nd(problem, "x")
    y_vars = Problem.get_variables_nd(problem, "y")
    assert map_size(x_vars) == 2
    assert map_size(y_vars) == 2
  end

  test "sum function works" do
    # Test that sum function works in various contexts
    problem =
      Problem.define do
        new(name: "Sum Function Test")
        variables("x", [i <- 1..3], :continuous)
        constraints(sum(for i <- 1..3, do: x(i)) <= 10, "sum_constraint")
        objective(sum(for i <- 1..3, do: 2 * x(i)), :maximize)
      end

    # Verify problem structure
    assert problem.name == "Sum Function Test"
    assert map_size(problem.constraints) == 1
    assert problem.direction == :maximize

    # Verify variables were created
    x_vars = Problem.get_variables_nd(problem, "x")
    assert map_size(x_vars) == 3
  end
end
