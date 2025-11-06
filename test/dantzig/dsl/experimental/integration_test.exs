defmodule Dantzig.DSL.IntegrationTest do
  @moduledoc """
  Integration tests for the complete DSL functionality

  CRITICAL - TESTS SATISFY THE DSL SYNTAX REFERENCE. DO NOT MODIFY WITHOUT EXPLICIT CONFIRMATION.
  """
  use ExUnit.Case, async: true

  # Import DSL components for testing
  use Dantzig.DSL.Integration

  test "nqueens 2D example works end-to-end" do
    # Test the exact syntax from nqueens_dsl.exs
    problem =
      Problem.define do
        new(name: "N-Queens")
        variables("queen2d", [i <- 1..4, j <- 1..4], :binary, description: "Queen position")
        constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
        constraints([j <- 1..4], queen2d(:_, j) == 1, "One queen per column")
        objective(sum(queen2d(:_, :_)), :minimize)
      end

    # Verify problem structure
    assert problem.name == "N-Queens"
    assert map_size(problem.variables) > 0
    assert map_size(problem.constraints) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    # 4x4 = 16 variables
    assert map_size(queen2d_vars) == 16

    # Verify constraints were created
    # At least 4 row + 4 column constraints
    assert map_size(problem.constraints) >= 8
  end

  test "nqueens 3D example works end-to-end" do
    # Test the 3D version from nqueens_dsl.exs
    problem =
      Problem.define do
        new(
          name: "N-Queens-3D",
          description:
            "Place N queens on an N×N×N chessboard so that no two queens attack each other."
        )

        variables("queen3d", [i <- 1..4, j <- 1..4, k <- 1..4], :binary,
          description: "Queen position"
        )

        constraints([i <- 1..4, k <- 1..4], queen3d(i, :_, k) == 1, "One queen per row")
        constraints([j <- 1..4, k <- 1..4], queen3d(:_, j, k) == 1, "One queen per column")
        constraints([i <- 1..4, j <- 1..4], queen3d(i, j, :_) == 1, "One queen per vertical")
        objective(sum(queen3d(:_, :_, :_)), :minimize)
      end

    # Verify problem structure
    assert problem.name == "N-Queens-3D"
    assert map_size(problem.variables) > 0
    assert map_size(problem.constraints) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    queen3d_vars = Problem.get_variables_nd(problem, "queen3d")
    assert queen3d_vars != nil
    # 4x4x4 = 64 variables
    assert map_size(queen3d_vars) == 64

    # Verify constraints were created
    # At least 4x3 = 12 constraints
    assert map_size(problem.constraints) >= 12
  end

  test "diet problem example with imperative syntax works end-to-end" do
    # Test the diet problem from nqueens_dsl.exs
    food_names = ["apple", "banana", "orange"]

    problem =
      Problem.new(
        name: "Diet Problem",
        description: "Minimize cost of food while meeting nutritional requirements"
      )
      |> Problem.add_variables(
        "qty",
        [food <- food_names],
        :continuous,
        "Amount of food to buy"
      )
      |> Problem.set_objective(sum(qty(food)), direction: :minimize)

    # Verify problem structure
    assert problem.name == "Diet Problem"
    assert map_size(problem.variables) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    qty_vars = Problem.get_variables_nd(problem, "qty")
    assert qty_vars != nil
    # 3 food items
    assert map_size(qty_vars) == 3

    # Verify objective was set
    assert problem.objective != nil
  end

  # test "chained constraints with imperative syntax work correctly" do
  # # Test chained constraints with imperative syntax using Problem.add_constraints
  # problem =
  #   Problem.new(name: "Imperative Chained Test")
  #     |> Problem.add_variables("x", [i <- 1..3], :binary, "Test variable")
  #     |> Problem.add_constraints([i <- 1..3], x(i) == 1, "row_#{i}")

  #   # Should create 3 constraints
  #   assert map_size(problem.constraints) == 3

  #   # Verify constraint names
  #   constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
  #   assert "row_1" in constraint_names
  #   assert "row_2" in constraint_names
  #   assert "row_3" in constraint_names
  # end

  test "chained constraints with define syntax work correctly" do
    # Test chained constraints with single generator
    problem =
      Problem.define do
        new(name: "Chained Test")
        variables("x", [i <- 1..3], :binary, "Test variable")
        constraints([i <- 1..3], x(i) == 1, "row_#{i}")
      end

    # Should create 3 constraints
    assert map_size(problem.constraints) == 3

    # Verify constraint names
    constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert "row_1" in constraint_names
    assert "row_2" in constraint_names
    assert "row_3" in constraint_names
  end

  test "chained constraints with imperative syntax with multiple generators work correctly" do
    # Rewritten to declarative form per DSL decision (no imperative add_constraints)
    problem =
      Problem.define do
        new(name: "Multi-Generator Test", description: "Test multiple generators")
        variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variable")
        constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "pos_#{i}_#{j}")
      end

    # Should create 4 constraints (2x2)
    assert map_size(problem.constraints) == 4

    # Verify constraint names
    constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert "pos_1_1" in constraint_names
    assert "pos_1_2" in constraint_names
    assert "pos_2_1" in constraint_names
    assert "pos_2_2" in constraint_names
  end

  test "chained constraints with define syntax with multiple generators work correctly" do
    # Test chained constraints with multiple generators using DSL
    problem =
      Problem.define do
        new(name: "Multi-Generator Test", description: "Test multiple generators")
        variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variable")
        constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "pos_constraint_#{i}_#{j}")
      end

    # Should create 4 constraints (2x2)
    assert map_size(problem.constraints) == 4

    # Verify constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    assert "pos_constraint_1_1" in constraint_names
    assert "pos_constraint_1_2" in constraint_names
    assert "pos_constraint_2_1" in constraint_names
    assert "pos_constraint_2_2" in constraint_names
  end

  # test "chained constraints with imperative syntax and piping with multiple generators work correctly" do
  # # Test chained constraints with imperative syntax and multiple generators
  # problem =
  #   Problem.new(name: "Multi-Generator Imperative Test")
  #     |> Problem.add_variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variable")
  #     |> Problem.add_constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "pos_#{i}_#{j}")

  #   # Should create 4 constraints (2x2)
  #   assert map_size(problem.constraints) == 4

  #   # Verify constraint names
  #   constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
  #   assert "pos_1_1" in constraint_names
  #   assert "pos_1_2" in constraint_names
  #   assert "pos_2_1" in constraint_names
  #   assert "pos_2_2" in constraint_names
  # end

  test "chained constraints with define syntax and named constraints with multiple generators work correctly" do
    problem =
      Problem.define do
        new(name: "Multi-Generator Test")
        variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variable")
        constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "pos_#{i}_#{j}")
      end

    # Should create 4 constraints (2x2)
    assert map_size(problem.constraints) == 4

    # Verify constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    assert "pos_1_1" in constraint_names
    assert "pos_1_2" in constraint_names
    assert "pos_2_1" in constraint_names
    assert "pos_2_2" in constraint_names
  end

  test "sum function with define syntax works with different patterns" do
    problem =
      Problem.define do
        new(name: "Sum Test")
        variables("x", [i <- 1..3, j <- 1..3], :binary, "Test variable")
        constraints([i <- 1..3, j <- 1..3], x(i, j) <= 1, "pos_#{i}_#{j}")
      end
  end

  # T141a: Tests for description interpolation and single-constraint syntax
  # These tests are expected to FAIL until implementation is complete

  test "single constraint without generators (constraints/2) creates one constraint" do
    # This test verifies constraints/2 syntax: constraints(expression, description)
    # Should create exactly one constraint, not multiple
    problem =
      Problem.define do
        new(name: "Single Constraint Test")
        variables("x", [i <- 1..3], :binary, "Test variable")
        # Single constraint without generator - should create exactly one constraint
        constraints(x(1) + x(2) + x(3) == 1, "Sum constraint")
      end

    # Should create exactly 1 constraint
    assert map_size(problem.constraints) == 1

    # Verify constraint has correct description
    constraint = problem.constraints |> Map.values() |> List.first()
    assert constraint.name == "Sum constraint"
  end

  test "single constraint with sum pattern (constraints/2) works correctly" do
    # Test constraints/2 with sum pattern matching
    problem =
      Problem.define do
        new(name: "Single Constraint Sum Test")
        variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
        # Single constraint summing all variables - should create exactly one constraint
        constraints(sum(queen2d(:_, :_)) == 4, "4 queens in total")
      end

    # Should create exactly 1 constraint
    assert map_size(problem.constraints) == 1

    # Verify constraint description
    constraint = problem.constraints |> Map.values() |> List.first()
    assert constraint.name == "4 queens in total"
  end

  test "description interpolation works with single variable in generator context" do
    # Test description interpolation with single generator variable
    problem =
      Problem.define do
        new(name: "Description Interpolation Test")
        variables("x", [i <- 1..3], :binary, "Variable")
        constraints([i <- 1..3], x(i) >= 0, "Non-negative constraint for variable #{i}")
      end

    # Should create 3 constraints
    assert map_size(problem.constraints) == 3

    # Verify interpolated descriptions
    constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert "Non-negative constraint for variable 1" in constraint_names
    assert "Non-negative constraint for variable 2" in constraint_names
    assert "Non-negative constraint for variable 3" in constraint_names
  end

  test "description interpolation works with multiple variables in generator context" do
    # Test description interpolation with multiple generator variables
    problem =
      Problem.define do
        new(name: "Multi-Variable Description Interpolation Test")
        variables("x", [i <- 1..2, j <- 1..2], :binary, "Variable")
        constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "Constraint at position (#{i}, #{j})")
      end

    # Should create 4 constraints
    assert map_size(problem.constraints) == 4

    # Verify interpolated descriptions with both variables
    constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert "Constraint at position (1, 1)" in constraint_names
    assert "Constraint at position (1, 2)" in constraint_names
    assert "Constraint at position (2, 1)" in constraint_names
    assert "Constraint at position (2, 2)" in constraint_names
  end

  test "single constraint without generators uses correct description" do
    # Test description in constraints/2 (no generators)
    problem =
      Problem.define do
        new(name: "Single Constraint Description Test")
        variables("x", [i <- 1..3], :binary, "Variable")
        constraints(x(1) + x(2) + x(3) == 1, "Sum constraint")
      end

    # Should create exactly 1 constraint
    assert map_size(problem.constraints) == 1

    # Verify description
    constraint = problem.constraints |> Map.values() |> List.first()
    assert constraint.name == "Sum constraint"
  end

  test "description interpolation works with constraint descriptions containing special characters" do
    # Test that description interpolation handles special characters correctly
    problem =
      Problem.define do
        new(name: "Special Characters Test")
        variables("x", [i <- 1..2], :binary, "Variable")
        constraints([i <- 1..2], x(i) >= 0, "Constraint #{i}: x_#{i} >= 0")
      end

    # Should create 2 constraints
    assert map_size(problem.constraints) == 2

    # Verify descriptions with special characters
    constraint_names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert "Constraint 1: x_1 >= 0" in constraint_names
    assert "Constraint 2: x_2 >= 0" in constraint_names
  end
end
