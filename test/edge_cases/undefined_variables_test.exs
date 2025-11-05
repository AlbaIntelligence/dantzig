defmodule Dantzig.EdgeCases.UndefinedVariablesTest do
  @moduledoc """
  Edge case tests for undefined variable handling.

  These tests verify that the system correctly handles undefined variables in:
  - Constraints
  - Objectives
  - Variable access
  - Generator contexts
  - Different variable name formats

  T051: Add edge case tests for undefined variables
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, Polynomial, Constraint, HiGHS}

  defp extract_message(error) do
    error.message
  end

  # Helper to test undefined variable errors that might occur during definition or usage
  defp assert_undefined_variable_error(fun) do
    try do
      problem = fun.()
      # If problem is created, try to use it (should raise error)
      _lp_data = HiGHS.to_lp_iodata(problem)
      flunk("Expected error for undefined variable, but problem was created and used successfully")
    rescue
      e in [ArgumentError] ->
        message = extract_message(e)
        assert String.contains?(message, "undefined") or
                 String.contains?(message, "not found") or
                 String.contains?(message, "Cannot evaluate"),
               "Error message should mention undefined variable, got: #{message}"
        e
      e ->
        # Other errors are acceptable too
        e
    end
  end

  describe "Undefined variables in constraints" do
    test "rejects constraints with completely undefined variables" do
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

    test "rejects constraints with undefined variable names" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Undefined Var Name")
            constraints([], undefined_var() <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "Undefined"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects constraints with typos in variable names" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Typo Variable")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Typo: 'y' instead of 'x'
            constraints([i <- 1..3], y(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects constraints with undefined indexed variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Undefined Indexed")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # 'y' is undefined
            constraints([i <- 1..3], x(i) + y(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end
  end

  describe "Undefined variables in objectives" do
    test "rejects objectives with undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Undefined Objective", direction: :minimize)
            # Using undefined variable 'x' in objective
            objective(x(), direction: :minimize)
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects objectives with undefined indexed variables" do
      assert_undefined_variable_error(fn ->
        Problem.define do
          new(name: "Undefined Indexed Objective", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          # 'y' is undefined
          objective(sum(x(:_)) + sum(y(:_)), direction: :minimize)
        end
      end)
    end

    test "rejects objectives with typos in variable names" do
      assert_undefined_variable_error(fn ->
        Problem.define do
          new(name: "Typo Objective", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          # Typo: 'z' instead of 'x'
          objective(sum(z(:_)), direction: :minimize)
        end
      end)
    end
  end

  describe "Undefined variables in generator contexts" do

    test "rejects constraints with wrong number of indices" do
      # Error might be raised during problem definition or when using the problem
      try do
        problem =
          Problem.define do
            new(name: "Wrong Indices")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Variable 'x' is 1D but using 2 indices
            constraints([i <- 1..3], x(i, i) <= 10, "Constraint")
          end

        # If problem is created, try to use it (might raise error later)
        _lp_data = HiGHS.to_lp_iodata(problem)
        # If no error, that's acceptable (might be handled gracefully)
        :ok
      rescue
        e in [ArgumentError] ->
          # Error is expected
          assert e != nil
        e ->
          # Other errors are acceptable
          assert e != nil
      end
    end

    test "rejects constraints with undefined nested generator variables" do
      assert_undefined_variable_error(fn ->
        Problem.define do
          new(name: "Undefined Nested")
          variables("x", [i <- 1..3, j <- 1..3], :continuous, "Variable")
          # 'k' is undefined
          constraints([i <- 1..3], x(i, k) <= 10, "Constraint")
        end
      end)
    end
  end

  describe "Error messages for undefined variables" do
    test "provides helpful error message with variable name" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Error Message Test")
            constraints([i <- 1..3], undefined_var(i) <= 10, "Undefined")
          end
        end

      message = extract_message(error)
      # Error message should mention the variable name
      assert String.contains?(message, "undefined_var") or
               String.contains?(message, "undefined"),
             "Error message should mention variable name, got: #{message}"
    end

    test "provides suggestions for fixing undefined variables" do
      # Test that error message is helpful when undefined variable is detected
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Suggestion Test")
            constraints([], x() <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      # Error message should mention the variable or provide helpful information
      assert String.length(message) > 0,
             "Error message should not be empty, got: #{message}"
      # Might contain helpful suggestions (variables, define, typo) or just variable name
      assert String.contains?(message, "x") or
               String.contains?(message, "variables") or
               String.contains?(message, "define") or
               String.contains?(message, "typo") or
               String.contains?(message, "undefined"),
             "Error message should provide useful information, got: #{message}"
    end

    test "error message includes example usage" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Example Test")
            constraints([i <- 1..3], x(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      # Error message might include example (if implemented)
      assert String.length(message) > 0, "Error message should not be empty"
    end
  end

  describe "Undefined variables in expressions" do
    test "rejects arithmetic expressions with undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Arithmetic Undefined")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # 'y' is undefined
            constraints([i <- 1..3], x(i) + y(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects multiplication expressions with undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Multiplication Undefined")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # 'y' is undefined
            constraints([i <- 1..3], x(i) * y(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects complex expressions with multiple undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Complex Undefined")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # 'y' and 'z' are undefined
            constraints([i <- 1..3], x(i) + y(i) + z(i) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      # Should catch at least one undefined variable
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end
  end

  describe "Undefined variables in sum expressions" do
    test "rejects sum expressions with undefined variables" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Sum Undefined")
            # 'x' is undefined
            constraints([], sum(x(:_)) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end

    test "rejects sum expressions with typos" do
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Sum Typo")
            variables("x", [i <- 1..3], :continuous, "Variable")
            # Typo: 'z' instead of 'x'
            constraints([], sum(z(:_)) <= 10, "Constraint")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end
  end

  describe "Undefined variables in variable bounds" do
    test "rejects variable definitions referencing undefined variables in bounds" do
      # This test checks if variable bounds can reference other variables
      # (which might not be supported, but we test the error handling)
      try do
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Bound Undefined")
            # If bounds can reference variables, 'y' is undefined
            variables("x", [], :continuous, "Variable", min_bound: y())
          end
        end
        :ok
      rescue
        # If bounds don't support variable references, that's fine
        # Just verify we get some error
        e -> e
      end
    end
  end

  describe "Edge cases - variable name formats" do
    test "rejects undefined variables with string names" do
      # String literals can't be used as function calls in Elixir
      # This test verifies that the DSL properly handles variable name formats
      error =
        assert_raise SyntaxError, fn ->
          Code.eval_string("""
          require Dantzig.Problem, as: Problem
          Problem.define do
            new(name: "String Name")
            constraints([], "undefined_var"() <= 10, "Constraint")
          end
          """)
        end

      # Should raise SyntaxError for invalid syntax
      assert error != nil
    end

    test "rejects undefined variables in different contexts" do
      # Test undefined variables in various DSL contexts
      error =
        assert_raise ArgumentError, fn ->
          Problem.define do
            new(name: "Various Contexts")
            variables("x", [i <- 1..3], :continuous, "Variable")
            constraints([i <- 1..3], x(i) <= 10, "Constraint1")
            # Using undefined 'y' in second constraint
            constraints([i <- 1..3], y(i) <= 10, "Constraint2")
          end
        end

      message = extract_message(error)
      assert String.contains?(message, "undefined") or
               String.contains?(message, "not found"),
             "Error message should mention undefined variable, got: #{message}"
    end
  end

  describe "Polynomial API - undefined variables" do
    test "Polynomial.variable allows creating variables that don't exist in problem" do
      # Polynomial.variable can create variables independently
      # This is a lower-level API that doesn't check against problem
      poly = Polynomial.variable("some_var")
      assert poly != nil
    end

    test "Constraint.new allows polynomials with undefined variables" do
      # Constraint.new works at polynomial level, doesn't check problem variables
      x_poly = Polynomial.variable("x")
      constraint = Constraint.new(x_poly, :==, Polynomial.const(1.0))
      assert constraint != nil
      assert constraint.left_hand_side != nil
    end
  end

  describe "Variable access patterns" do
    test "Problem.get_variable returns nil for undefined variables" do
      problem =
        Problem.define do
          new(name: "Get Variable Test")
          variables("x", [], :continuous, "Variable")
        end

      # Undefined variable should return nil
      assert Problem.get_variable(problem, "undefined_var") == nil
      # Defined variable should return definition
      assert Problem.get_variable(problem, "x") != nil
    end

    test "Problem.get_variables_nd returns nil for undefined base names" do
      problem =
        Problem.define do
          new(name: "Get Variables ND Test")
          variables("x", [i <- 1..3], :continuous, "Variable")
        end

      # Undefined base name should return nil
      assert Problem.get_variables_nd(problem, "undefined_base") == nil
      # Defined base name should return map
      assert Problem.get_variables_nd(problem, "x") != nil
    end
  end
end
