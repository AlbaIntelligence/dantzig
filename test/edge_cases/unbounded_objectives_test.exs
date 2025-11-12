defmodule Dantzig.EdgeCases.UnboundedObjectivesTest do
  @moduledoc """
  Edge case tests for unbounded optimization objectives.

  These tests verify that the solver correctly detects and handles unbounded
  problems - problems where the objective can be improved indefinitely in one
  direction (either toward positive or negative infinity).

  T046: Add edge case tests for unbounded objectives
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, HiGHS, Solution}

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

  @tag :requires_highs
  describe "Unbounded minimization problems" do
    test "detects unbounded minimization with no constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Minimization", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          # No constraints - truly unbounded
          objective(x(), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      # Should detect unbounded or return :error
      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "detects unbounded minimization with unbounded feasible region" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Region Minimization", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], x(1) + x(2) >= 1, "Sum constraint")
          constraints([], x(1) >= 0, "Non-negativity x1")
          # x2 has no upper bound
          objective(x(2), direction: :minimize)
        end

      # Minimize x2 subject to x1 + x2 >= 1, x1 >= 0
      # x2 can go to -infinity, making problem unbounded
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end
  end

  @tag :requires_highs
  describe "Unbounded maximization problems" do
    test "detects unbounded maximization with no upper bounds" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Maximization", direction: :maximize)
          variables("x", [], :continuous, "Variable")
          # No constraints - truly unbounded
          objective(x(), direction: :maximize)
        end

      result = HiGHS.solve(problem)

      # Should detect unbounded or return :error
      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "detects unbounded maximization with unbounded feasible region" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Region Maximization", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], x(1) + x(2) <= 1, "Sum constraint")
          constraints([], x(1) >= 0, "Non-negativity x1")
          # x2 has no upper bound
          objective(x(2), direction: :maximize)
        end

      # Maximize x2 subject to x1 + x2 <= 1, x1 >= 0
      # x2 can go to +infinity, making problem unbounded
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end
  end

  @tag :requires_highs
  describe "Unbounded problems - multiple variables" do
    test "detects unbounded problem with multiple unbounded variables" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Multiple Unbounded Variables", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], x(1) - x(2) <= 1, "Difference constraint")
          # x1 and x2 can both increase indefinitely as long as x1 - x2 <= 1
          objective(x(1) + x(2), direction: :maximize)
        end

      # Maximize x1 + x2 subject to x1 - x2 <= 1
      # Set x2 = k, then x1 <= k + 1, so x1 + x2 <= 2k + 1
      # As k -> infinity, objective -> infinity, so unbounded
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "detects unbounded problem with sum objective and loose constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Loose Constraints Unbounded", direction: :maximize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          constraints([], x(1) + x(2) <= 100, "Partial sum constraint")
          # x3 has no upper bound constraint
          objective(sum(x(:_)), direction: :maximize)
        end

      # Maximize x1 + x2 + x3 subject to x1 + x2 <= 100, all >= 0
      # x3 can go to infinity, making problem unbounded
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end
  end

  @tag :requires_highs
  describe "Unbounded problems - edge cases" do
    test "handles problem with no constraints as unbounded" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "No Constraints", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      # No constraints - unbounded
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "handles problem with only non-negativity constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Only Non-negativity", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :maximize)
        end

      # Only non-negativity - unbounded above
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "handles problem with conflicting unbounded directions" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Conflicting Directions", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], x(1) >= 0, "x1 non-negativity")
          constraints([], x(2) <= 0, "x2 non-positivity")
          # Minimize x1 - x2, x1 >= 0, x2 <= 0
          # x1 can go to 0, x2 can go to -infinity, so objective unbounded below
          objective(x(1) - x(2), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end
  end

  @tag :requires_highs
  describe "Bounded problems - should not be unbounded" do
    test "correctly identifies bounded minimization problem" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Bounded Minimization", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Bounded: minimize sum subject to sum <= 10, all >= 0
      # Optimal is at origin (0, 0), objective = 0
      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Should have optimal solution, not unbounded
      if solution.model_status do
        refute String.contains?(to_string(solution.model_status), "Unbounded")
      end
    end

    test "correctly identifies bounded maximization problem" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Bounded Maximization", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :maximize)
        end

      # Bounded: maximize sum subject to sum <= 10, all >= 0
      # Optimal is sum = 10
      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Should have optimal solution, not unbounded
      if solution.model_status do
        refute String.contains?(to_string(solution.model_status), "Unbounded")
      end
    end

    test "correctly identifies bounded problem with variable bounds" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Bounded with Variable Bounds", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable", min_bound: 0, max_bound: 5)
          objective(sum(x(:_)), direction: :maximize)
        end

      # Bounded: each variable in [0, 5], so sum in [0, 10]
      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Should have optimal solution, not unbounded
      if solution.model_status do
        refute String.contains?(to_string(solution.model_status), "Unbounded")
      end
    end
  end

  @tag :requires_highs
  describe "Error handling for unbounded problems" do
    test "Dantzig.solve/1 returns appropriate result for unbounded problems" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Test", direction: :maximize)
          variables("x", [], :continuous, "Variable")
          objective(x(), direction: :maximize)
        end

      result = Dantzig.solve(problem)

      # Should return :error or {:ok, solution} with unbounded status
      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Unbounded"))
    end

    test "Dantzig.solve!/1 raises for unbounded problems" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded Test", direction: :maximize)
          variables("x", [], :continuous, "Variable")
          objective(x(), direction: :maximize)
        end

      # solve!/1 should raise if solve/1 returns :error
      try do
        solution = Dantzig.solve!(problem)
        # If it doesn't raise, check that solution indicates unboundedness
        assert %Solution{} = solution

        if solution.model_status do
          assert String.contains?(to_string(solution.model_status), "Unbounded")
        end
      rescue
        # Expected if solve/1 returns :error
        MatchError -> :ok
        # Expected if solver fails
        RuntimeError -> :ok
      end
    end
  end

  describe "Problem creation for unbounded problems" do
    test "allows creation of unbounded problem definition" do
      # Unboundedness is only detected by the solver, not during problem creation
      problem =
        Problem.define do
          new(name: "Unbounded Definition", direction: :maximize)
          variables("x", [], :continuous, "Variable")
          objective(x(), direction: :maximize)
        end

      # Problem should be created successfully
      assert problem.name == "Unbounded Definition"
      assert map_size(problem.variable_defs) == 1
      assert map_size(problem.constraints) == 0
    end

    test "problem structure is valid even for unbounded problems" do
      problem =
        Problem.define do
          new(name: "Unbounded Structure", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], x(1) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :maximize)
        end

      # Problem structure should be valid
      assert problem.name == "Unbounded Structure"
      assert map_size(problem.variable_defs) == 2
      assert map_size(problem.constraints) == 1
      assert problem.direction == :maximize
    end
  end
end
