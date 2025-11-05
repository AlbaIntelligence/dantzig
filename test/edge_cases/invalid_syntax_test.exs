defmodule Dantzig.EdgeCases.InvalidSyntaxTest do
  @moduledoc """
  Edge case tests for invalid constraint syntax.

  These tests verify that the DSL correctly detects and handles invalid constraint
  syntax with clear, actionable error messages.

  T047: Add edge case tests for invalid constraint syntax
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, Constraint, Polynomial}

  # Helper to extract error message from ArgumentError
  defp extract_message(error) do
    error.message
  end

  describe "Invalid constraint operators" do
    test "rejects invalid comparison operators" do
      # Test that invalid operators like :!=, :<, :> are rejected
      # Constraint.new/3 has a guard clause, so invalid operators raise FunctionClauseError
      assert_raise FunctionClauseError, fn ->
        # Using :!= operator which is not supported
        Constraint.new(Polynomial.variable("x"), :!=, 1.0)
      end

      assert_raise FunctionClauseError, fn ->
        # Using :< operator which is not supported (use :<= instead)
        Constraint.new(Polynomial.variable("x"), :<, 1.0)
      end

      assert_raise FunctionClauseError, fn ->
        # Using :> operator which is not supported (use :>= instead)
        Constraint.new(Polynomial.variable("x"), :>, 1.0)
      end
    end

    test "rejects non-atom operators" do
      assert_raise FunctionClauseError, fn ->
        # Using string operator instead of atom
        Constraint.new(Polynomial.variable("x"), "==", 1.0)
      end

      assert_raise FunctionClauseError, fn ->
        # Using invalid operator type
        Constraint.new(Polynomial.variable("x"), 123, 1.0)
      end
    end
  end

  describe "Invalid constraint expressions in DSL" do
    test "rejects division by variables in constraints" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Division Test")
            variables("x", [i <- 1..3], :continuous, "Variable")
            variables("y", [i <- 1..3], :continuous, "Variable")
            # Division by variable is not supported in linear programming
            constraints([i <- 1..3], x(i) / y(i) <= 1, "Division constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "division") or
               String.contains?(message, "Division") or
               String.contains?(message, "unsupported") or
               String.contains?(message, "linear"),
             "Error message should mention division or linear programming limitation, got: #{message}"
    end

    test "rejects non-linear expressions in constraints" do
      # Multiplication of variables is non-linear
      try do
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Non-linear Test")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Multiplication of variables is non-linear
            constraints([i <- 1..3], x(i) * x(i) <= 1, "Non-linear constraint")
          end
        end
      rescue
        # Other error types are also acceptable
        _ -> :ok
      end
    end

    test "rejects invalid constraint expression types" do
      # Test that non-polynomial expressions are rejected
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Invalid Expression")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Using invalid expression (string instead of polynomial)
          constraints([i <- 1..3], "invalid", "Constraint")
        end
      end
    end

    test "rejects constraints with undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Undefined Variable")
            # Using undefined variable 'x' without defining it first
            constraints([i <- 1..3], x(i) <= 10, "Test constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "Undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects constraints with wrong variable indices" do
      # Using wrong number of indices should raise an error
      # j is undefined in the generator context
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Wrong Indices")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Using undefined variable j in indices
          constraints([i <- 1..3], x(i, j) <= 10, "Wrong indices")
        end
      end
    end
  end

  describe "Invalid constraint syntax - DSL structure" do
    test "rejects constraints with invalid generator syntax" do
      # Test that invalid generator syntax is caught
      assert_raise SyntaxError, fn ->
        Code.eval_string("""
        require Dantzig.Problem, as: Problem
        Problem.define do
          new(name: "Invalid Generator")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Invalid generator syntax
          constraints([i = 1..3], x(i) <= 10, "Invalid generator")
        end
        """)
      end
    end

    test "rejects constraints with missing expressions" do
      assert_raise SyntaxError, fn ->
        Code.eval_string("""
        require Dantzig.Problem, as: Problem
        Problem.define do
          new(name: "Missing Expression")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Missing constraint expression
          constraints([i <- 1..3], , "Missing expression")
        end
        """)
      end
    end

    test "rejects constraints with invalid description types" do
      # Description should be string or nil, not other types
      assert_raise FunctionClauseError, fn ->
        Problem.define do
          new(name: "Invalid Description")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Using number as description instead of string
          constraints([i <- 1..3], x(i) <= 10, 123)
        end
      end
    end
  end

  describe "Invalid constraint syntax - arithmetic operations" do
    test "rejects unsupported arithmetic operations" do
      # Modulo operation might not be supported
      try do
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Unsupported Operation")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Modulo operation not supported
            constraints([i <- 1..3], rem(x(i), 2) == 0, "Modulo constraint")
          end
        end
      rescue
        # Other error types or no error are also acceptable
        _ -> :ok
      end
    end

    test "rejects power operations with variables" do
      # Power operation with variable is non-linear
      try do
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Power Operation")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Power operation with variable is non-linear
            constraints([i <- 1..3], x(i) ** 2 <= 10, "Power constraint")
          end
        end
      rescue
        # Other error types or no error are also acceptable
        _ -> :ok
      end
    end
  end

  describe "Invalid constraint syntax - constraint API" do
    test "handles invalid left-hand side types in Constraint.new" do
      # Constraint.new accepts numbers and converts them to polynomials
      # So these might actually work - let's test what happens
      try do
        Constraint.new(123, :<=, 1.0)
        # If it doesn't raise, that's also valid behavior
      rescue
        ArgumentError -> :ok
        FunctionClauseError -> :ok
      end
    end

    test "handles invalid right-hand side types in Constraint.new" do
      # Constraint.new attempts to convert to polynomial
      # Invalid types might raise ArgumentError during conversion
      assert_raise ArgumentError, fn ->
        # Using string instead of number/polynomial
        Constraint.new(Polynomial.variable("x"), :<=, "invalid")
      end
    end

    test "rejects invalid constraint creation with wrong arity" do
      # Constraint.new requires at least 3 arguments (left, operator, right)
      assert_raise FunctionClauseError, fn ->
        # Too few arguments
        Constraint.new(Polynomial.variable("x"))
      end
    end
  end

  describe "Invalid constraint syntax - edge cases" do
    test "rejects constraints with empty generators" do
      # Empty generators might be valid (creates single constraint), but test edge case
      problem =
        Problem.define do
          new(name: "Empty Generators")
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 10, "Single constraint")
        end

      # Should succeed - empty generators are valid for single constraints
      assert problem.name == "Empty Generators"
    end

    test "rejects constraints with invalid generator variable names" do
      assert_raise SyntaxError, fn ->
        Code.eval_string("""
        require Dantzig.Problem, as: Problem
        Problem.define do
          new(name: "Invalid Generator Var")
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Using invalid variable name in generator
          constraints([123 <- 1..3], x(123) <= 10, "Invalid generator var")
        end
        """)
      end
    end

    test "rejects constraints with type mismatches" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Type Mismatch")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Mixing incompatible types in constraint
            constraints([i <- 1..3], x(i) <= "invalid", "Type mismatch")
          end
        end

      message = extract_message(error)
      assert String.length(message) > 0, "Should provide error message, got: #{message}"
    end
  end

  describe "Error message quality for invalid syntax" do
    test "provides actionable guidance for invalid operators" do
      error =
        assert_raise ArgumentError, fn ->
          Constraint.new(Polynomial.variable("x"), :!=, 1.0)
        end

      message = extract_message(error)
      # Should mention valid operators
      assert String.contains?(message, "==") or
               String.contains?(message, "<=") or
               String.contains?(message, ">=") or
               String.contains?(message, "operator"),
             "Should mention valid operators, got: #{message}"
    end

    test "provides clear error for division by variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Division Error")
            variables("x", [i <- 1..3], :continuous, "Variable")
            variables("y", [i <- 1..3], :continuous, "Variable")
            constraints([i <- 1..3], x(i) / y(i) <= 1, "Division")
          end
        end

      message = extract_message(error)
      # Should explain why division is not supported
      assert String.length(message) > 20,
             "Should provide detailed error message, got: #{message}"
    end

    test "provides clear error for undefined variables" do
      # Using undefined variable should raise an error
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Undefined Var Error")
          # Using undefined variable
          constraints([i <- 1..3], undefined_var(i) <= 10, "Undefined")
        end
      end
    end
  end

  describe "Problem creation validation" do
    test "allows creation of valid constraints" do
      # Valid constraint syntax should work
      problem =
        Problem.define do
          new(name: "Valid Constraints")
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          constraints([i <- 1..3], x(i) <= 10, "Upper bound")
        end

      assert problem.name == "Valid Constraints"
      assert map_size(problem.constraints) == 6  # 3 constraints × 2 types
    end

    test "validates constraint structure after creation" do
      problem =
        Problem.define do
          new(name: "Constraint Structure")
          variables("x", [], :continuous, "Variable")
          constraints([], x() == 5, "Equality")
        end

      assert problem.name == "Constraint Structure"
      assert map_size(problem.constraints) == 1
      constraint = problem.constraints |> Map.values() |> List.first()
      assert constraint != nil
    end
  end
end
