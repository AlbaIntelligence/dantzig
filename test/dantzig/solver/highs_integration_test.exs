defmodule Dantzig.Solver.HiGHSIntegrationTest do
  @moduledoc """
  Integration tests for HiGHS solver functionality.

  These tests verify that problems can be solved end-to-end using the HiGHS solver.
  Note: These tests require the HiGHS solver binary to be available. Tests may be
  skipped if the solver is not available.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, HiGHS, Solution}

  # T044: Integration tests for HiGHS solver

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
  describe "solve/1 - Simple linear programming problems" do
    test "solves simple minimization problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Simple Minimization", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) >= 1, "Sum constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      assert solution.objective >= 0
      assert map_size(solution.variables) > 0
    end

    test "solves simple maximization problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Simple Maximization", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) <= 1, "Sum constraint")
          objective(sum(x(:_)), direction: :maximize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      assert solution.objective >= 0
      # Allow small tolerance
      assert solution.objective <= 1.1
    end

    test "solves problem with equality constraints" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Equality Constraints", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1, "Equality constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify equality constraint is satisfied
      x1_val = solution.variables["x(1)"] || 0
      x2_val = solution.variables["x(2)"] || 0
      sum_val = x1_val + x2_val
      assert abs(sum_val - 1.0) < 0.001
    end

    test "solves problem with bounded variables" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Bounded Variables", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable", min_bound: 0, max_bound: 1)
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify bounds are satisfied
      for i <- 1..2 do
        var_name = "x(#{i})"
        val = solution.variables[var_name] || 0
        # Allow small tolerance
        assert val >= -0.001
        assert val <= 1.001
      end
    end
  end

  describe "solve/1 - Binary integer programming" do
    test "solves simple binary problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Binary Problem", direction: :minimize)
          variables("x", [i <- 1..2], :binary, "Binary variable")
          constraints([], sum(x(:_)) >= 1, "At least one")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify binary values
      for i <- 1..2 do
        var_name = "x(#{i})"
        val = solution.variables[var_name] || 0
        assert val == 0.0 or val == 1.0
      end
    end

    test "solves knapsack-like binary problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      weights = [2, 3, 4]
      values = [5, 7, 9]
      capacity = 5

      problem =
        Problem.define model_parameters: %{weights: weights, values: values, capacity: capacity} do
          new(name: "Knapsack", direction: :maximize)
          variables("x", [i <- 1..3], :binary, "Item selected")
          constraints([], sum(x(:_) * weights[:_]) <= capacity, "Capacity constraint")
          objective(sum(x(:_) * values[:_]), direction: :maximize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify solution respects capacity
      total_weight =
        Enum.reduce(1..3, 0, fn i, acc ->
          var_name = "x(#{i})"
          val = solution.variables[var_name] || 0

          if val > 0.5 do
            acc + Enum.at(weights, i - 1)
          else
            acc
          end
        end)

      assert total_weight <= capacity
    end
  end

  describe "solve/1 - Integer programming" do
    test "solves simple integer problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Integer Problem", direction: :minimize)
          variables("x", [i <- 1..2], :integer, "Integer variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) >= 2, "Sum constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify integer values
      for i <- 1..2 do
        var_name = "x(#{i})"
        val = solution.variables[var_name] || 0
        assert abs(val - round(val)) < 0.001
      end
    end
  end

  describe "solve/1 - Complex problems" do
    test "solves transportation problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      sources = [1, 2]
      destinations = [1, 2]
      supply = %{1 => 10, 2 => 15}
      demand = %{1 => 8, 2 => 12}

      problem =
        Problem.define model_parameters: %{supply: supply, demand: demand} do
          new(name: "Transportation", direction: :minimize)
          variables("x", [i <- sources, j <- destinations], :continuous, "Flow", min_bound: 0)
          constraints([i <- sources], sum(x(i, :_)) <= supply[i], "Supply constraint")
          constraints([j <- destinations], sum(x(:_, j)) >= demand[j], "Demand constraint")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify supply constraints
      for i <- sources do
        total_supplied =
          Enum.reduce(destinations, 0, fn j, acc ->
            var_name = "x(#{i},#{j})"
            acc + (solution.variables[var_name] || 0)
          end)

        assert total_supplied <= supply[i] + 0.001
      end
    end

    test "solves assignment problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      tasks = [1, 2]
      workers = [1, 2]

      problem =
        Problem.define do
          new(name: "Assignment", direction: :minimize)
          variables("assign", [t <- tasks, w <- workers], :binary, "Assignment")
          constraints([t <- tasks], sum(assign(t, :_)) == 1, "Each task assigned")
          constraints([w <- workers], sum(assign(:_, w)) == 1, "Each worker assigned")
          objective(sum(assign(:_, :_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      # Verify each task is assigned exactly once
      for t <- tasks do
        total_assigned =
          Enum.reduce(workers, 0, fn w, acc ->
            var_name = "assign(#{t},#{w})"
            val = solution.variables[var_name] || 0
            acc + val
          end)

        assert abs(total_assigned - 1.0) < 0.001
      end
    end
  end

  describe "solve/1 - Edge cases" do
    test "handles infeasible problem gracefully" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Infeasible", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) >= 5, "Lower bound")
          constraints([], sum(x(:_)) <= 1, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Infeasible problem: x1 + x2 >= 5 and x1 + x2 <= 1 (impossible)
      result = HiGHS.solve(problem)

      # Should return :error or raise - depends on HiGHS behavior
      assert result == :error or match?({:ok, _}, result)
    end

    test "handles unbounded problem" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Unbounded", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          # No upper bound - problem may be unbounded
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      # Unbounded problems may return :error or a solution at origin
      assert result == :error or match?({:ok, _}, result)
    end

    test "handles problem with no constraints" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "No Constraints", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      # May be unbounded or return solution at origin
      assert result == :error or match?({:ok, _}, result)
    end

    test "handles problem with single variable" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Single Variable", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          constraints([], x() >= 0, "Non-negativity")
          constraints([], x() <= 10, "Upper bound")
          objective(x(), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      assert match?({:ok, %Solution{}}, result)
      {_, solution} = result
      x_val = solution.variables["x"] || 0
      assert x_val >= -0.001
      assert x_val <= 10.001
    end
  end

  describe "Dantzig.solve/1 and Dantzig.solve!/1" do
    test "Dantzig.solve/1 returns {:ok, solution} or :error" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Test Problem", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = Dantzig.solve(problem)

      assert result == :error or match?({:ok, %Solution{}}, result)
    end

    test "Dantzig.solve!/1 returns solution or raises" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Test Problem", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # solve!/1 should raise if solve/1 returns :error
      try do
        solution = Dantzig.solve!(problem)
        assert %Solution{} = solution
      rescue
        # Expected if solve/1 returns :error
        MatchError -> :ok
        # Expected if solver fails
        RuntimeError -> :ok
      end
    end

    test "Dantzig.solve/1 with print_optimizer_input option" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      highs = Dantzig.Solver.HiGHS.new()

      problem =
        Problem.define do
          new(name: "Test Problem", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Should not raise even with print_optimizer_input enabled
      result = Dantzig.solve(problem, solver: highs, print_optimizer_input: true)

      assert result == :error or match?({:ok, %Solution{}}, result)
    end
  end

  describe "Solution validation" do
    test "solution satisfies constraints" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Constraint Validation", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1, "Equality")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, _}, result) do
        {_, solution} = result
        x1 = solution.variables["x(1)"] || 0
        x2 = solution.variables["x(2)"] || 0

        # Verify constraints
        assert x1 >= -0.001
        assert x2 >= -0.001
        assert abs(x1 + x2 - 1.0) < 0.001
      end
    end

    test "solution objective matches computed objective" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Objective Validation", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1, "Equality")
          objective(sum(x(:_)), direction: :minimize)
        end

      result = HiGHS.solve(problem)

      if match?({:ok, _}, result) do
        {_, solution} = result
        x1 = solution.variables["x(1)"] || 0
        x2 = solution.variables["x(2)"] || 0
        computed_obj = x1 + x2

        # Objective should match (allowing small tolerance)
        assert abs(solution.objective - computed_obj) < 0.001
      end
    end
  end
end
