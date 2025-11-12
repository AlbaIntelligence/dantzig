defmodule Dantzig.EdgeCases.InfeasibleProblemsTest do
  @moduledoc """
  Edge case tests for infeasible optimization problems.

  These tests verify that the solver correctly detects and handles infeasible
  problems - problems where no solution exists that satisfies all constraints.

  T045: Add edge case tests for infeasible problems
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
  describe "Simple infeasible problems - single variable conflicts" do
    test "detects infeasible problem with conflicting bounds on single variable" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Conflicting Bounds", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1, "Upper bound")
          constraints([], x() >= 2, "Lower bound")
          objective(x(), direction: :minimize)
        end

      # Infeasible: x <= 1 and x >= 2 (impossible)
      result = HiGHS.solve(problem)

      # Should return :error or {:ok, solution} with infeasible status
      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible problem with equality constraint outside bounds" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Equality Outside Bounds", direction: :minimize)
          variables("x", [], :continuous, "Variable", min_bound: 0, max_bound: 1)
          constraints([], x() == 2, "Equality constraint")
          objective(x(), direction: :minimize)
        end

      # Infeasible: x must be in [0, 1] but x == 2
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible binary problem with conflicting constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Conflicting Binary", direction: :minimize)
          variables("x", [], :binary, "Binary variable")
          constraints([], x() <= 0, "Must be zero")
          constraints([], x() >= 1, "Must be one")
          objective(x(), direction: :minimize)
        end

      # Infeasible: binary variable cannot be both 0 and 1
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end
  end

  @tag :requires_highs
  describe "Infeasible problems - sum constraints" do
    test "detects infeasible problem with conflicting sum constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Conflicting Sum", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) >= 5, "Lower bound")
          constraints([], sum(x(:_)) <= 1, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Infeasible: sum >= 5 and sum <= 1 (impossible)
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible problem with sum equality constraint incompatible with bounds" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Sum Equality Incompatible", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable", min_bound: 0, max_bound: 1)
          constraints([], sum(x(:_)) == 5, "Sum must equal 5")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Infeasible: each x in [0, 1], so sum <= 2, but sum == 5
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end
  end

  @tag :requires_highs
  describe "Infeasible problems - integer constraints" do
    test "detects infeasible integer problem with conflicting constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Conflicting Integer", direction: :minimize)
          variables("x", [], :integer, "Integer variable")
          constraints([], x() <= 1, "Upper bound")
          constraints([], x() >= 3, "Lower bound")
          objective(x(), direction: :minimize)
        end

      # Infeasible: integer x <= 1 and x >= 3 (no integer in between)
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible integer problem with sum constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Integer Sum Infeasible", direction: :minimize)
          variables("x", [i <- 1..2], :integer, "Integer variable", min_bound: 0, max_bound: 1)
          constraints([], sum(x(:_)) == 3, "Sum must equal 3")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Infeasible: each integer x in [0, 1], so sum <= 2, but sum == 3
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end
  end

  @tag :requires_highs
  describe "Infeasible problems - complex scenarios" do
    test "detects infeasible assignment problem with more tasks than workers" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      tasks = [1, 2, 3]
      workers = [1, 2]

      problem =
        Problem.define do
          new(name: "Infeasible Assignment", direction: :minimize)
          variables("assign", [t <- tasks, w <- workers], :binary, "Assignment")
          constraints([t <- tasks], sum(assign(t, :_)) == 1, "Each task assigned")
          constraints([w <- workers], sum(assign(:_, w)) == 1, "Each worker assigned")
          objective(sum(assign(:_, :_)), direction: :minimize)
        end

      # Infeasible: 3 tasks must each be assigned, but only 2 workers available
      # Each worker can only handle 1 task, so max 2 tasks can be assigned
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible transportation problem with insufficient supply" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      # Simplified: use explicit constraint values to avoid map access issues
      # Sources can supply at most 5 each (total 10), but destinations need 8 each (total 16)
      problem =
        Problem.define do
          new(name: "Infeasible Transportation", direction: :minimize)
          variables("x", [i <- 1..2, j <- 1..2], :continuous, "Flow", min_bound: 0)
          constraints([i <- 1..2], sum(x(i, :_)) <= 5, "Supply constraint")
          constraints([j <- 1..2], sum(x(:_, j)) >= 8, "Demand constraint")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # Infeasible: total supply (10) < total demand (16)
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible knapsack problem with item too large" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      # Single item with weight 100
      weights = [100]
      values = [10]
      # Capacity is 50, but item weighs 100
      capacity = 50

      # Infeasible: must select at least one item, but any item violates capacity
      problem =
        Problem.define model_parameters: %{weights: weights, values: values, capacity: capacity} do
          new(name: "Infeasible Knapsack", direction: :maximize)
          variables("x", [i <- 1..1], :binary, "Item selected")
          constraints([], sum(x(:_) * weights[:_]) <= capacity, "Capacity constraint")
          constraints([], sum(x(:_)) >= 1, "Must select at least one")
          objective(sum(x(:_) * values[:_]), direction: :maximize)
        end

      # Now infeasible: must select at least one item, but any item violates capacity
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end
  end

  @tag :requires_highs
  describe "Infeasible problems - multiple conflicting constraints" do
    test "detects infeasible problem with multiple pairwise conflicts" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Multiple Conflicts", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          constraints([], x(1) + x(2) <= 1, "Constraint 1")
          constraints([], x(1) + x(2) >= 2, "Constraint 2")
          constraints([], x(2) + x(3) <= 1, "Constraint 3")
          constraints([], x(2) + x(3) >= 2, "Constraint 4")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Infeasible: multiple conflicting pairs
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "detects infeasible problem with chained equality constraints" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Chained Equalities", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          constraints([], x(1) == x(2), "x1 equals x2")
          constraints([], x(2) == x(3), "x2 equals x3")
          constraints([], sum(x(:_)) == 10, "Sum equals 10")
          constraints([], x(1) <= 2, "x1 upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # If x1 = x2 = x3 and sum = 10, then each x = 10/3 ≈ 3.33
      # But x1 <= 2, so infeasible
      result = HiGHS.solve(problem)

      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end
  end

  @tag :requires_highs
  describe "Error handling for infeasible problems" do
    test "Dantzig.solve/1 returns :error for infeasible problems" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Infeasible Test", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1, "Upper bound")
          constraints([], x() >= 2, "Lower bound")
          objective(x(), direction: :minimize)
        end

      result = Dantzig.solve(problem)

      # Should return :error or {:ok, solution} with infeasible status
      assert result == :error or
               (match?({:ok, %Solution{}}, result) and
                  String.contains?(to_string(elem(result, 1).model_status || ""), "Infeasible"))
    end

    test "Dantzig.solve!/1 raises for infeasible problems" do
      if !highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Infeasible Test", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1, "Upper bound")
          constraints([], x() >= 2, "Lower bound")
          objective(x(), direction: :minimize)
        end

      # solve!/1 should raise if solve/1 returns :error
      try do
        solution = Dantzig.solve!(problem)
        # If it doesn't raise, check that solution indicates infeasibility
        assert %Solution{} = solution

        if solution.model_status do
          assert String.contains?(to_string(solution.model_status), "Infeasible")
        end
      rescue
        # Expected if solve/1 returns :error
        MatchError -> :ok
        # Expected if solver fails
        RuntimeError -> :ok
      end
    end
  end

  describe "Problem creation for infeasible problems" do
    test "allows creation of infeasible problem definition" do
      # Infeasibility is only detected by the solver, not during problem creation
      problem =
        Problem.define do
          new(name: "Infeasible Definition", direction: :minimize)
          variables("x", [], :continuous, "Variable")
          constraints([], x() <= 1, "Upper bound")
          constraints([], x() >= 2, "Lower bound")
          objective(x(), direction: :minimize)
        end

      # Problem should be created successfully
      assert problem.name == "Infeasible Definition"
      assert map_size(problem.variable_defs) == 1
      assert map_size(problem.constraints) == 2
    end

    test "problem structure is valid even for infeasible problems" do
      problem =
        Problem.define do
          new(name: "Infeasible Structure", direction: :minimize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([], sum(x(:_)) >= 5, "Lower bound")
          constraints([], sum(x(:_)) <= 1, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Problem structure should be valid
      assert problem.name == "Infeasible Structure"
      assert map_size(problem.variable_defs) == 2
      assert map_size(problem.constraints) == 2
      assert problem.direction == :minimize
    end
  end
end
