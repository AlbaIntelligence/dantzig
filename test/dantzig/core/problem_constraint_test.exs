defmodule Dantzig.Core.ProblemConstraintTest do
  @moduledoc """
  Tests for Problem.constraint/3 functionality.

  This module tests the Problem.constraint/3 function for adding single constraints
  without generators.
  """
  use ExUnit.Case
  require Dantzig.Problem, as: Problem

  # T141f: Tests for Problem.constraint/3 no-generator single constraints
  # Note: Problem.constraint/3 is implemented and working - these tests verify functionality

  describe "Problem.constraint/3" do
    test "adds single constraint without generators" do
      # Test that Problem.constraint/3 can add a single constraint
      # Note: Variable access macros are only available inside Problem.define blocks
      # So we test with quoted expressions that represent constraint ASTs
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      # Problem.constraint accepts quoted constraint expressions
      # The expression is transformed and parsed to create a constraint
      constraint_expr = quote do: x(1) + x(2) + x(3) == 1

      # Should succeed and add the constraint
      updated_problem = Problem.constraint(problem, constraint_expr, "Sum constraint")

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))
    end

    test "adds single constraint without description" do
      # Test that Problem.constraint/3 works without description
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) >= 0

      # Should succeed and add the constraint without description
      updated_problem = Problem.constraint(problem, constraint_expr)

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))
    end

    test "adds single constraint with comparison operators" do
      # Test various comparison operators
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      initial_count = length(Map.keys(problem.constraints))

      # Test <= operator
      constraint_expr1 = quote do: x(1) <= 1
      problem = Problem.constraint(problem, constraint_expr1, "Less than or equal")
      assert length(Map.keys(problem.constraints)) > initial_count

      # Test >= operator
      constraint_expr2 = quote do: x(2) >= 0
      problem = Problem.constraint(problem, constraint_expr2, "Greater than or equal")
      assert length(Map.keys(problem.constraints)) > initial_count + 1

      # Test == operator
      constraint_expr3 = quote do: x(1) == 1
      problem = Problem.constraint(problem, constraint_expr3, "Equal")
      assert length(Map.keys(problem.constraints)) > initial_count + 2
    end

    test "adds single constraint with arithmetic expressions" do
      # Test that arithmetic expressions work in constraints
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) + x(2) == 1

      # Should succeed and add the constraint
      updated_problem = Problem.constraint(problem, constraint_expr, "Sum")

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))
    end

    test "adds single constraint with scaled variables" do
      # Test that scaled variables work: 2*x(1) + 3*x(2) <= 10
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: 2 * x(1) + 3 * x(2) <= 10

      # Should succeed and add the constraint
      updated_problem = Problem.constraint(problem, constraint_expr, "Scaled constraint")

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))
    end

    test "adds single constraint with constant comparisons" do
      # Test constraints comparing to constants
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) >= 0

      # Should succeed and add the constraint
      updated_problem = Problem.constraint(problem, constraint_expr, "Non-negative")

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))
    end

    test "adds multiple single constraints sequentially" do
      # Test that multiple constraints can be added sequentially
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      initial_count = length(Map.keys(problem.constraints))

      constraint_expr1 = quote do: x(1) >= 0
      problem = Problem.constraint(problem, constraint_expr1, "Constraint 1")
      assert length(Map.keys(problem.constraints)) > initial_count

      constraint_expr2 = quote do: x(2) >= 0
      problem = Problem.constraint(problem, constraint_expr2, "Constraint 2")
      assert length(Map.keys(problem.constraints)) > initial_count + 1

      constraint_expr3 = quote do: x(3) >= 0
      problem = Problem.constraint(problem, constraint_expr3, "Constraint 3")
      assert length(Map.keys(problem.constraints)) > initial_count + 2
    end

    test "preserves constraint name from description" do
      # Test that description becomes constraint name
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) <= 1

      # Should succeed and add the constraint with the provided name
      updated_problem = Problem.constraint(problem, constraint_expr, "My constraint name")

      # Verify constraint was added
      assert length(Map.keys(updated_problem.constraints)) > length(Map.keys(problem.constraints))

      # Verify the constraint has the expected name (check that a constraint with this name exists)
      constraint_names =
        updated_problem.constraints
        |> Map.values()
        |> Enum.map(& &1.name)

      assert "My constraint name" in constraint_names
    end
  end
end

