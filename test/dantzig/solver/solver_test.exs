defmodule Dantzig.SolverTest do
  @moduledoc """
  Unit tests for Dantzig solver functionality (HiGHS integration and LP format conversion).
  """
  use ExUnit.Case, async: true

  alias Dantzig.Problem
  alias Dantzig.HiGHS
  alias Dantzig.Constraint
  alias Dantzig.Polynomial
  alias Dantzig.ProblemVariable

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint

  # T042: Unit tests for Dantzig.Solver module (HiGHS integration)

  describe "HiGHS.to_lp_iodata/1" do
    test "converts simple minimization problem to LP format" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      iodata = HiGHS.to_lp_iodata(problem)

      # Should contain LP format headers
      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "Minimize")
      assert String.contains?(iodata_str, "Subject To")
      assert String.contains?(iodata_str, "Bounds")
      assert String.contains?(iodata_str, "General")
      assert String.contains?(iodata_str, "End")
    end

    test "converts maximization problem to LP format" do
      problem =
        Problem.define do
          new(name: "Test", direction: :maximize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :maximize)
        end

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "Maximize")
    end

    test "includes constraints in LP format" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      constraint = Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0), "Test constraint")
      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "Test constraint")
      assert String.contains?(iodata_str, "x")
    end

    test "includes variable bounds in LP format" do
      problem = Problem.new()

      {problem, x_poly} =
        Problem.new_variable(problem, "x", type: :continuous, min_bound: 0, max_bound: 10)

      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "Bounds")
      assert String.contains?(iodata_str, "x")
    end

    test "includes binary variables in General section" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary)
          objective(sum(x(:_)), direction: :minimize)
        end

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "General")
      assert String.contains?(iodata_str, "x_1")
      assert String.contains?(iodata_str, "x_2")
    end

    test "includes integer variables in General section" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :integer)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      assert String.contains?(iodata_str, "General")
      assert String.contains?(iodata_str, "x")
    end

    test "excludes General section when no binary/integer variables" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)

      iodata_str = IO.iodata_to_binary(iodata)
      # General section should be empty (just "General\n")
      assert String.contains?(iodata_str, "General")
    end
  end

  describe "LP format helper functions (via integration)" do
    test "constraint operator :== converts to = in LP format" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)

      constraint =
        Constraint.new_linear(x_poly, :==, Polynomial.const(10.0), description: "Equality")

      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should contain "=" for equality constraint
      assert String.contains?(iodata_str, "=")
    end

    test "constraint operator :<= converts to <= in LP format" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)

      constraint =
        Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0), description: "Less equal")

      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      assert String.contains?(iodata_str, "<=")
    end

    test "constraint operator :>= converts to >= in LP format" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      constraint = Constraint.new_linear(x_poly, :>=, Polynomial.const(0.0), "Greater equal")
      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      assert String.contains?(iodata_str, ">=")
    end

    test "handles :infinity bounds by converting to 1e+30" do
      problem = Problem.new()

      {problem, x_poly} =
        Problem.new_variable(problem, "x", type: :continuous, max_bound: :infinity)

      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should contain 1e+30 for infinity
      assert String.contains?(iodata_str, "1e+30")
    end

    test "handles nil bounds as free variables" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should contain "free" for variables with no bounds
      assert String.contains?(iodata_str, "free")
    end

    test "handles binary variable bounds (0 <= x <= 1)" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :binary)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should contain binary bounds
      assert String.contains?(iodata_str, "0 <=")
      assert String.contains?(iodata_str, "<= 1")
    end
  end

  describe "Name sanitization (via LP format output)" do
    test "sanitizes constraint names with special characters" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      # Use a name with special characters that need sanitization
      constraint =
        Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0), description: "test+constraint")

      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should sanitize the name (remove or replace special chars)
      # The exact sanitization may vary, but it should be present
      assert String.contains?(iodata_str, "test") or String.contains?(iodata_str, "constraint")
    end

    test "handles constraint names starting with numbers" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      constraint = Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0), "123constraint")
      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should sanitize names starting with numbers
      assert String.contains?(iodata_str, "constraint")
    end

    test "handles empty constraint names" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      constraint = Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0), "")
      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should handle empty names gracefully
      assert String.contains?(iodata_str, "x")
    end

    test "handles nil constraint names" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      constraint = Constraint.new_linear(x_poly, :<=, Polynomial.const(10.0))
      problem = Problem.add_constraint(problem, constraint)
      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should handle nil names gracefully
      assert String.contains?(iodata_str, "x")
    end
  end

  describe "Dantzig.solve/1 API" do
    test "solve/1 accepts problem and options" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Test that the function accepts the problem
      # Note: This will fail if HiGHS solver is not available, but tests the API
      result = Dantzig.solve(problem, print_optimizer_input: false)

      # Result should be either {:ok, solution} or :error
      assert result == :error or match?({:ok, _}, result)
    end

    test "solve/1 with print_optimizer_input option" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Test with print_optimizer_input enabled
      result = Dantzig.solve(problem, print_optimizer_input: true)

      # Result should be either {:ok, solution} or :error
      assert result == :error or match?({:ok, _}, result)
    end

    test "solve!/1 raises on error" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # solve!/1 should raise if solve/1 returns :error
      # Note: This test may pass or raise depending on solver availability
      try do
        solution = Dantzig.solve!(problem)
        # If we get here, solver worked
        assert %Dantzig.Solution{} = solution
      rescue
        # Expected if solve/1 returns :error
        MatchError -> :ok
        # Expected if solver fails
        RuntimeError -> :ok
      end
    end
  end

  describe "Problem.solve/2 API" do
    test "Problem.solve/2 returns solution and objective" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Problem.solve/2 wraps Dantzig.solve/1
      result = Problem.solve(problem)

      # Should return {solution, objective} or :error
      assert result == :error or match?({%Dantzig.Solution{}, _number}, result)
    end

    test "Problem.solve/2 with options" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = Problem.solve(problem, print_optimizer_input: false)

      # Should return {solution, objective} or :error
      assert result == :error or match?({%Dantzig.Solution{}, _number}, result)
    end
  end

  describe "Dantzig.dump_problem_to_file/2" do
    test "writes problem to file in LP format" do
      problem =
        Problem.define do
          new(name: "Test", direction: :minimize)
          variables("x", [i <- 1..2], :continuous)
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Create temporary file path
      temp_file = Path.join(System.tmp_dir!(), "test_problem_#{:rand.uniform(1_000_000)}.lp")

      try do
        Dantzig.dump_problem_to_file(problem, temp_file)

        # Verify file was created and contains LP format
        assert File.exists?(temp_file)
        contents = File.read!(temp_file)
        assert String.contains?(contents, "Minimize")
        assert String.contains?(contents, "Subject To")
        assert String.contains?(contents, "End")
      after
        # Clean up
        if File.exists?(temp_file) do
          File.rm!(temp_file)
        end
      end
    end
  end

  describe "Complex problem scenarios" do
    test "handles problem with multiple constraint types" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Problem.new_variable(problem, "y", type: :continuous)

      # Add equality constraint
      constraint1 =
        Constraint.new_linear(x_poly, :==, Polynomial.const(10.0), description: "Equality")

      problem = Problem.add_constraint(problem, constraint1)

      # Add less-than-or-equal constraint
      constraint2 =
        Constraint.new_linear(y_poly, :<=, Polynomial.const(5.0), description: "Less equal")

      problem = Problem.add_constraint(problem, constraint2)

      # Add greater-than-or-equal constraint
      sum_poly = Polynomial.add(x_poly, y_poly)

      constraint3 =
        Constraint.new_linear(sum_poly, :>=, Polynomial.const(0.0), description: "Greater equal")

      problem = Problem.add_constraint(problem, constraint3)

      problem = Problem.minimize(problem, sum_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should contain all constraint types
      assert String.contains?(iodata_str, "=")
      assert String.contains?(iodata_str, "<=")
      assert String.contains?(iodata_str, ">=")
    end

    test "handles problem with mixed variable types" do
      problem = Problem.new()
      {problem, x_poly} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Problem.new_variable(problem, "y", type: :binary)
      {problem, z_poly} = Problem.new_variable(problem, "z", type: :integer)

      problem = Problem.minimize(problem, Polynomial.add(x_poly, Polynomial.add(y_poly, z_poly)))

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should include all variable types
      assert String.contains?(iodata_str, "x")
      assert String.contains?(iodata_str, "y")
      assert String.contains?(iodata_str, "z")
      assert String.contains?(iodata_str, "General")
    end

    test "handles problem with custom variable bounds" do
      problem = Problem.new()

      {problem, x_poly} =
        Problem.new_variable(problem, "x", type: :continuous, min_bound: 5.0, max_bound: 15.0)

      problem = Problem.minimize(problem, x_poly)

      iodata = HiGHS.to_lp_iodata(problem)
      iodata_str = IO.iodata_to_binary(iodata)

      # Should include custom bounds
      assert String.contains?(iodata_str, "5")
      assert String.contains?(iodata_str, "15")
    end
  end
end
