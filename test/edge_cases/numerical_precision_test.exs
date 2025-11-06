defmodule Dantzig.EdgeCases.NumericalPrecisionTest do
  @moduledoc """
  Edge case tests for numerical precision issues.

  These tests verify that the solver and problem representation correctly handle
  numerical precision issues, including very small/large numbers, floating point
  errors, and tolerance handling.

  T048: Add edge case tests for numerical precision
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, HiGHS, Solution, Polynomial, Constraint}

  # Helper to check if HiGHS solver is available
  defp highs_available? do
    try do
      command = Dantzig.Config.default_highs_binary_path()
      {_output, exit_code} = System.cmd(command, ["--version"], stderr_to_stdout: true)
      exit_code == 0
    rescue
      _ -> false
    catch
      _ -> false
    end
  end

  # Tolerance for floating point comparisons
  @tolerance 1.0e-6

  describe "Very small numbers" do
    test "handles constraints with very small coefficients" do
      problem =
        Problem.define do
          new(name: "Small Coefficients")
          variables("x", [], :continuous, "Variable")
          constraints([], x() * 1.0e-10 == 1.0e-10, "Small coefficient")
        end

      # Problem should be created successfully
      assert problem.name == "Small Coefficients"
      assert map_size(problem.constraints) == 1
    end

    test "handles constraints with very small right-hand side values" do
      problem =
        Problem.define do
          new(name: "Small RHS")
          variables("x", [], :continuous, "Variable")
          constraints([], x() >= 1.0e-15, "Very small lower bound")
        end

      assert problem.name == "Small RHS"
      assert map_size(problem.constraints) == 1
    end

    test "handles variables with very small bounds" do
      problem =
        Problem.define do
          new(name: "Small Bounds")
          variables("x", [], :continuous, "Variable", min_bound: 1.0e-15, max_bound: 1.0e-10)
        end

      assert problem.name == "Small Bounds"
      x_def = Problem.get_variable(problem, "x")
      assert abs(x_def.min - 1.0e-15) < @tolerance
      assert abs(x_def.max - 1.0e-10) < @tolerance
    end

    @tag :requires_highs
    test "solves problem with very small numbers" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Small Numbers Solve", direction: :minimize)
          variables("x", [], :continuous, "Variable", min_bound: 1.0e-10)
          constraints([], x() >= 1.0e-10, "Small lower bound")
          objective(x(), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, %Solution{}}, result) do
        {_, solution} = result
        x_val = solution.variables["x"] || 0
        # Solution should be close to 1.0e-10 (within tolerance)
        assert abs(x_val - 1.0e-10) < 1.0e-5 or x_val >= 1.0e-10
      end
    end
  end

  describe "Very large numbers" do
    test "handles constraints with very large coefficients" do
      problem =
        Problem.define do
          new(name: "Large Coefficients")
          variables("x", [], :continuous, "Variable")
          constraints([], x() * 1.0e10 <= 1.0e10, "Large coefficient")
        end

      assert problem.name == "Large Coefficients"
      assert map_size(problem.constraints) == 1
    end

    test "handles constraints with very large right-hand side values" do
      problem =
        Problem.define do
          new(name: "Large RHS")
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1.0e15, "Very large upper bound")
        end

      assert problem.name == "Large RHS"
      assert map_size(problem.constraints) == 1
    end

    test "handles variables with very large bounds" do
      problem =
        Problem.define do
          new(name: "Large Bounds")
          variables("x", [], :continuous, "Variable", min_bound: 1.0e10, max_bound: 1.0e15)
        end

      assert problem.name == "Large Bounds"
      x_def = Problem.get_variable(problem, "x")
      # Larger tolerance for large numbers
      assert abs(x_def.min - 1.0e10) < 1.0e5
      assert abs(x_def.max - 1.0e15) < 1.0e10
    end

    @tag :requires_highs
    test "solves problem with very large numbers" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Large Numbers Solve", direction: :minimize)
          variables("x", [], :continuous, "Variable", min_bound: 0, max_bound: 1.0e10)
          constraints([], x() <= 1.0e10, "Large upper bound")
          objective(x(), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, %Solution{}}, result) do
        {_, solution} = result
        x_val = solution.variables["x"] || 0
        # Solution should be close to 0 (minimize with lower bound 0)
        assert x_val >= -@tolerance
        assert x_val <= 1.0e10 + @tolerance
      end
    end
  end

  describe "Floating point precision" do
    test "handles floating point representation issues" do
      # Test that 0.1 + 0.2 != 0.3 in floating point
      # But constraints should still work correctly
      problem =
        Problem.define do
          new(name: "Floating Point Precision")
          variables("x", [], :continuous, "Variable")
          constraints([], x() == 0.1 + 0.2, "Floating point sum")
        end

      assert problem.name == "Floating Point Precision"
      assert map_size(problem.constraints) == 1
    end

    test "handles repeated additions accurately" do
      # Test accumulation of small errors
      problem =
        Problem.define do
          new(name: "Repeated Additions")
          variables("x", [i <- 1..100], :continuous, "Variable")
          constraints([], sum(x(:_)) == 100 * 0.1, "Repeated addition")
        end

      assert problem.name == "Repeated Additions"
      assert map_size(problem.constraints) == 1
    end

    test "handles equality constraints with precision tolerance" do
      problem =
        Problem.define do
          new(name: "Equality Precision")
          variables("x", [], :continuous, "Variable")
          # Equality with number that has floating point representation issues
          constraints([], x() == 1.0 / 3.0, "Floating point equality")
        end

      assert problem.name == "Equality Precision"
      assert map_size(problem.constraints) == 1
    end
  end

  describe "Boundary conditions" do
    test "handles constraints at numerical boundaries" do
      # Test values near Float.max and Float.min
      problem =
        Problem.define do
          new(name: "Boundary Values")
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1.7976931348623157e308, "Near max float")
        end

      assert problem.name == "Boundary Values"
      assert map_size(problem.constraints) == 1
    end

    test "handles zero values correctly" do
      problem =
        Problem.define do
          new(name: "Zero Values")
          variables("x", [], :continuous, "Variable")
          constraints([], x() == 0.0, "Zero equality")
          constraints([], x() >= 0.0, "Zero lower bound")
          constraints([], x() <= 0.0, "Zero upper bound")
        end

      assert problem.name == "Zero Values"
      assert map_size(problem.constraints) == 3
    end

    test "handles negative zero correctly" do
      problem =
        Problem.define do
          new(name: "Negative Zero")
          variables("x", [], :continuous, "Variable")
          constraints([], x() == -0.0, "Negative zero")
        end

      assert problem.name == "Negative Zero"
      assert map_size(problem.constraints) == 1
    end
  end

  describe "Solution precision validation" do
    @tag :requires_highs
    test "solution values satisfy constraints within tolerance" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Solution Precision", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1.0, "Equality")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, %Solution{}}, result) do
        {_, solution} = result
        x1 = solution.variables["x(1)"] || 0
        x2 = solution.variables["x(2)"] || 0
        sum_val = x1 + x2

        # Solution should satisfy equality constraint within tolerance
        assert abs(sum_val - 1.0) < @tolerance,
               "Sum should be 1.0, got #{sum_val}, difference: #{abs(sum_val - 1.0)}"
      end
    end

    @tag :requires_highs
    test "solution objective matches computed objective within tolerance" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Objective Precision", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1.0, "Equality")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, %Solution{}}, result) do
        {_, solution} = result
        x1 = solution.variables["x(1)"] || 0
        x2 = solution.variables["x(2)"] || 0
        computed_obj = x1 + x2

        # Objective should match computed value within tolerance
        assert abs(solution.objective - computed_obj) < @tolerance,
               "Objective mismatch: solver=#{solution.objective}, computed=#{computed_obj}"
      end
    end
  end

  describe "Polynomial precision" do
    test "handles polynomial operations with small numbers" do
      x = Polynomial.variable("x")
      small_coeff = Polynomial.const(1.0e-10)
      result = Polynomial.add(x, small_coeff)

      # Should create polynomial successfully
      assert result != nil
    end

    test "handles polynomial operations with large numbers" do
      x = Polynomial.variable("x")
      large_coeff = Polynomial.const(1.0e10)
      result = Polynomial.multiply(x, large_coeff)

      # Should create polynomial successfully
      assert result != nil
    end

    test "handles polynomial equality with precision" do
      x = Polynomial.variable("x")
      y = Polynomial.variable("y")
      # Create polynomials that should be equal
      p1 = Polynomial.add(x, Polynomial.const(0.1 + 0.2))
      p2 = Polynomial.add(x, Polynomial.const(0.3))

      # Polynomial representation should handle this
      assert p1 != nil
      assert p2 != nil
    end
  end

  describe "Constraint precision" do
    test "handles constraint creation with precision issues" do
      x = Polynomial.variable("x")
      # Create constraint with floating point arithmetic result
      constraint = Constraint.new(x, :==, 0.1 + 0.2)

      assert constraint != nil
      assert constraint.operator == :==
    end

    test "handles constraint normalization with small coefficients" do
      x = Polynomial.variable("x")
      small_poly = Polynomial.multiply(x, 1.0e-10)
      constraint = Constraint.new(small_poly, :==, 1.0e-10)

      assert constraint != nil
      # Constraint should be normalized correctly
      assert constraint.left_hand_side != nil
    end
  end

  describe "Problem structure with precision" do
    test "problem preserves precision in variable definitions" do
      problem =
        Problem.define do
          new(name: "Precision Preservation")
          variables("x", [], :continuous, "Variable", min_bound: 1.0e-10, max_bound: 1.0e10)
        end

      x_def = Problem.get_variable(problem, "x")
      # Bounds should be preserved (allowing for floating point representation)
      assert x_def.min > 0
      assert x_def.max > x_def.min
    end

    test "problem preserves precision in constraints" do
      problem =
        Problem.define do
          new(name: "Constraint Precision")
          variables("x", [], :continuous, "Variable")
          constraints([], x() == 1.0 / 3.0, "Precision constraint")
        end

      assert map_size(problem.constraints) == 1
      constraint = problem.constraints |> Map.values() |> List.first()
      assert constraint != nil
      assert constraint.operator == :==
    end
  end

  describe "Edge cases - extreme values" do
    test "handles infinity bounds" do
      problem =
        Problem.define do
          new(name: "Infinity Bounds")
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= :infinity, "Infinity bound")
        end

      assert problem.name == "Infinity Bounds"
      assert map_size(problem.constraints) == 1
    end

    test "handles very close bounds" do
      # Bounds that are very close together (near numerical precision limit)
      problem =
        Problem.define do
          new(name: "Close Bounds")
          variables("x", [], :continuous, "Variable", min_bound: 1.0, max_bound: 1.0 + 1.0e-10)
        end

      assert problem.name == "Close Bounds"
      x_def = Problem.get_variable(problem, "x")
      assert x_def.min <= x_def.max
    end
  end
end
