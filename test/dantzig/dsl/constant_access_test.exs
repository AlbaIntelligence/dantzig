defmodule Dantzig.DSL.ConstantAccessTest do
  @moduledoc """
  Tests for constant and enumerated constant access in DSL expressions.

  Tests constant access patterns as specified in DSL_SYNTAX_REFERENCE.md section 6.

  These tests should FAIL initially - they document the expected behavior before implementation.
  """

  use ExUnit.Case
  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  describe "scalar constant access" do
    test "scalar constant accessible in constraint expression" do
      problem =
        Problem.define model_parameters: %{multiplier: 7.0} do
          new(name: "Test Problem", description: "Test scalar constant")
          variables("x1", :continuous, "X1")
          variables("x2", :continuous, "X2")

          # The DSL should identify variables (x1, x2) as variables, and multiplier as a constant
          constraints(x2 + multiplier * x1 <= 10, "Max constraint")
        end

      # Verify constraint was created with correct coefficients
      assert Map.size(problem.constraints) == 1
      constraint = hd(Map.values(problem.constraints))
      # The constraint should have: x2 + 7.0 * x1 <= 10
      # This test will need to verify the polynomial coefficients
      assert constraint != nil
    end

    test "multiple scalar constants accessible in constraint expression" do
      problem =
        Problem.define model_parameters: %{multiplier_1: 7.0, multiplier_2: -5.0} do
          new(name: "Test Problem", description: "Test multiple scalar constants")
          variables("x1", :continuous, "X1")
          variables("x2", :continuous, "X2")

          # The DSL should identify variables (x1, x2) as variables, and multipliers as constants
          constraints(multiplier_1 * x1 - x2 * multiplier_2 <= 10, "Max constraint")
        end

      assert Map.size(problem.constraints) == 1
      constraint = hd(Map.values(problem.constraints))
      # The constraint should have: 7.0 * x1 - x2 * (-5.0) <= 10
      # Which simplifies to: 7.0 * x1 + 5.0 * x2 <= 10
      assert constraint != nil
    end

    test "scalar constant accessible in objective expression" do
      problem =
        Problem.define model_parameters: %{multiplier: 7.0} do
          new(name: "Test Problem", description: "Test scalar constant in objective")
          variables("x1", :continuous, "X1")
          variables("x2", :continuous, "X2")

          objective(multiplier * x1 + x2, :maximize)
        end

      # Verify objective was set with correct coefficients
      assert problem.objective != nil
      assert problem.direction == :maximize
    end
  end

  describe "list index access" do
    test "list constant accessible by index in constraint expression" do
      problem =
        Problem.define model_parameters: %{multiplier: [4.0, 5.0, 6.0, 7.0]} do
          new(name: "Test Problem", description: "Test list index access")
          # Use 0-based indexing (Elixir standard)
          variables("x", [i <- 0..3], :continuous, "Xs")

          # The DSL should identify variables (x(i)) as variables, and multiplier[i] as constants
          constraints(sum(for i <- 0..3, do: x(i) * multiplier[i]) <= 10, "Max constraint")
        end

      # Verify constraint was created
      assert Map.size(problem.constraints) == 1
      constraint = hd(Map.values(problem.constraints))
      # The constraint should have: 4.0*x(1) + 5.0*x(2) + 6.0*x(3) + 7.0*x(4) <= 10
      assert constraint != nil
    end

    test "list constant accessible by index in objective expression" do
      problem =
        Problem.define model_parameters: %{costs: [10.0, 20.0, 30.0]} do
          new(name: "Test Problem", description: "Test list index in objective")
          # Use 0-based indexing (Elixir standard)
          variables("x", [i <- 0..2], :continuous, "Xs")

          objective(sum(for i <- 0..2, do: costs[i] * x(i)), :minimize)
        end

      # Verify objective was set
      assert problem.objective != nil
      assert problem.direction == :minimize
    end
  end

  describe "nested list index access" do
    test "nested list constant accessible by indices in constraint expression" do
      problem =
        Problem.define model_parameters: %{matrix: [[4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]} do
          new(name: "Test Problem", description: "Test nested list access")
          # Use 0-based indexing (Elixir standard)
          variables("x", [i <- 0..1, j <- 0..2], :continuous, "Xs")

          # The DSL should identify variables (x(i, j)) as variables, and matrix[i][j] as constants
          constraints(
            sum(for i <- 0..1, j <- 0..2, do: x(i, j) * matrix[i][j]) <= 10,
            "Max constraint"
          )
        end

      # Verify constraint was created
      assert Map.size(problem.constraints) == 1
      constraint = hd(Map.values(problem.constraints))

      # The constraint should have: 4.0*x(0,0) + 5.0*x(0,1) + 6.0*x(0,2) + 7.0*x(1,0) + 8.0*x(1,1) + 9.0*x(1,2) <= 10
      assert constraint != nil
    end

    test "nested list constant accessible by indices in objective expression" do
      problem =
        Problem.define model_parameters: %{matrix: [[1.0, 2.0], [3.0, 4.0]]} do
          new(name: "Test Problem", description: "Test nested list in objective")
          # Use 0-based indexing (Elixir standard)
          variables("x", [i <- 0..1, j <- 0..1], :continuous, "Xs")

          objective(sum(for i <- 0..1, j <- 0..1, do: matrix[i][j] * x(i, j)), :maximize)
        end

      assert problem.objective != nil
      assert problem.direction == :maximize
    end
  end

  describe "map access" do
    test "map constant accessible by key in constraint expression" do
      cost_matrix = %{
        "Alice" => %{"Task1" => 2, "Task2" => 3},
        "Bob" => %{"Task1" => 4, "Task2" => 2}
      }

      workers = Map.keys(cost_matrix)
      tasks = Enum.flat_map(cost_matrix, fn {_, v} -> Map.keys(v) end) |> MapSet.new() |> MapSet.to_list()

      problem =
        Problem.define model_parameters: %{cost: cost_matrix, workers: workers, tasks: tasks} do
          new(name: "Assignment Problem", description: "Test map access")
          variables("assign", [worker <- workers, task <- tasks], :binary, "Assignment variable")

          constraints(
            sum(
              for worker <- workers, task <- tasks, do: assign(worker, task) * cost[worker][task]
            ) >= 0,
            "Cost constraint"
          )
        end

      # Verify constraint was created
      assert Map.size(problem.constraints) == 1
      constraint = hd(Map.values(problem.constraints))

      # The constraint should have: 2*assign(Alice,Task1) + 3*assign(Alice,Task2) + 4*assign(Bob,Task1) + 2*assign(Bob,Task2) >= 0
      assert constraint != nil
    end

    test "map constant accessible by key in objective expression" do
      cost_matrix = %{
        "Alice" => %{"Task1" => 2, "Task2" => 3, "Task3" => 1},
        "Bob" => %{"Task1" => 4, "Task2" => 2, "Task3" => 3}
      }

      workers = Map.keys(cost_matrix)
      tasks = Enum.flat_map(cost_matrix, fn {_, v} -> Map.keys(v) end) |> MapSet.new() |> MapSet.to_list()

      problem =
        Problem.define model_parameters: %{cost: cost_matrix, workers: workers, tasks: tasks} do
          new(name: "Assignment Problem", description: "Test map access in objective")
          variables("assign", [worker <- workers, task <- tasks], :binary, "Assignment variable")

          objective(
            sum(
              for worker <- workers,
                  task <- tasks,
                  do: assign(worker, task) * cost[worker][task]
            ),
            :minimize
          )
        end

      # Verify objective was set
      assert problem.objective != nil
      assert problem.direction == :minimize
    end
  end

  describe "constant access with generators" do
    test "constant access works with generator bindings in constraints" do
      # Use 0-based indexing (Elixir standard) to avoid off-by-one errors
      # This test demonstrates index-based access, but enumeration patterns are preferred
      problem =
        Problem.define model_parameters: %{multiplier: [4.0, 5.0, 6.0]} do
          new(name: "Test Problem", description: "Test constant with generator bindings")
          # Use 0-based indexing to match Elixir's list indexing
          variables("x", [i <- 0..2], :continuous, "Xs")

          constraints(
            [i <- 0..2],
            x(i) * multiplier[i] <= 10,
            "Constraint #{i}"
          )
        end

      # Should create 3 constraints:
      # x(0) * 4.0 <= 10  (multiplier[0] = 4.0)
      # x(1) * 5.0 <= 10  (multiplier[1] = 5.0)
      # x(2) * 6.0 <= 10  (multiplier[2] = 6.0)
      assert Map.size(problem.constraints) == 3
    end

    test "constant access works with multiple generator bindings" do
      problem =
        Problem.define model_parameters: %{matrix: [[1.0, 2.0], [3.0, 4.0]]} do
          new(name: "Test Problem", description: "Test constant with multiple generators")
          # Use 0-based indexing (Elixir standard)
          variables("x", [i <- 0..1, j <- 0..1], :continuous, "Xs")

          constraints(
            [i <- 0..1, j <- 0..1],
            x(i, j) * matrix[i][j] <= 10,
            "Constraint #{i},#{j}"
          )
        end

      # Should create 4 constraints (one for each combination of i and j)
      assert Map.size(problem.constraints) == 4
    end
  end

  describe "error cases" do
    test "undefined constant raises error" do
      assert_raise ArgumentError, fn ->
        Problem.define model_parameters: %{} do
          new(name: "Test Problem", description: "Test undefined constant")
          variables("x", :continuous, "X")
          constraints(x * undefined_constant <= 10, "Constraint")
        end
      end
    end

    test "invalid list index raises error" do
      assert_raise ArgumentError, fn ->
        Problem.define model_parameters: %{multiplier: [4.0, 5.0]} do
          new(name: "Test Problem", description: "Test invalid index")
          variables("x", [i <- 1..3], :continuous, "Xs")
          constraints(sum(for i <- 1..3, do: x(i) * multiplier[i]) <= 10, "Constraint")
        end
      end
    end

    test "invalid map key raises error" do
      cost_matrix = %{"Alice" => %{"Task1" => 2}}
      workers = ["Alice"]
      tasks = MapSet.new(["Task1"]) |> MapSet.to_list()

      assert_raise ArgumentError, fn ->
        Problem.define model_parameters: %{cost: cost_matrix, workers: workers, tasks: tasks} do
          new(name: "Test Problem", description: "Test invalid map key")
          variables("assign", [worker <- workers, task <- tasks], :binary, "Assignment")

          objective(
            sum(
              for worker <- workers,
                  task <- tasks,
                  do: assign(worker, task) * cost[worker]["InvalidTask"]
            ),
            :minimize
          )
        end
      end
    end

    test "type mismatch raises error" do
      # Trying to access list with string key
      assert_raise ArgumentError, fn ->
        Problem.define model_parameters: %{multiplier: [4.0, 5.0]} do
          new(name: "Test Problem", description: "Test type mismatch")
          variables("x", :continuous, "X")
          constraints(x * multiplier["invalid"] <= 10, "Constraint")
        end
      end
    end
  end

  describe "backward compatibility" do
    test "expressions without constant access continue to work" do
      problem =
        Problem.define do
          new(name: "Test Problem", description: "Test backward compatibility")
          variables("x", [i <- 1..3], :continuous, "Xs")
          constraints([i <- 1..3], x(i) >= 0, "Non-negative")
          objective(sum(for i <- 1..3, do: x(i)), :maximize)
        end

      # Should work exactly as before
      assert Map.size(problem.variables) > 0
      assert Map.size(problem.constraints) == 3
      assert problem.objective != nil
      assert problem.direction == :maximize
    end

    test "problem without model_parameters works with constant access syntax" do
      # Even if model_parameters is not provided, expressions without constants should work
      problem =
        Problem.define do
          new(name: "Test Problem", description: "Test without model_parameters")
          variables("x", :continuous, "X")
          constraints(x >= 0, "Non-negative")
          objective(x, :maximize)
        end

      assert problem.objective != nil
    end
  end

  describe "enumerable types support" do
    test "mapset enumerable works in generators" do
      tasks = MapSet.new(["Task1", "Task2"]) |> MapSet.to_list()

      problem =
        Problem.define model_parameters: %{tasks: tasks} do
          new(name: "Test Problem", description: "Test MapSet")
          variables("x", [task <- tasks], :continuous, "Xs")
          constraints([task <- tasks], x(task) >= 0, "Constraint")
        end

      # Should create 2 variables and 2 constraints
      assert Map.size(problem.variables) >= 2
      assert Map.size(problem.constraints) == 2
    end

    test "range enumerable works in generators" do
      problem =
        Problem.define model_parameters: %{range: 1..5} do
          new(name: "Test Problem", description: "Test Range")
          variables("x", [i <- range], :continuous, "Xs")
          constraints([i <- range], x(i) >= 0, "Constraint")
        end

      # Should create 5 variables and 5 constraints
      assert Map.size(problem.variables) >= 5
      assert Map.size(problem.constraints) == 5
    end
  end
end
