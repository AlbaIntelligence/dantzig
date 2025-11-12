defmodule Dantzig.DSL.IntegrationTest do
  @moduledoc """
  Comprehensive integration tests for DSL functionality.

  These tests verify that the DSL works end-to-end, combining multiple features
  to ensure they work together correctly. Tests cover:
  - Basic problem definition
  - Variable creation with generators
  - Constraint definition with generators
  - Objective functions
  - Sum operations
  - Variable patterns (wildcards)
  - Model parameters
  - Complex multi-feature scenarios
  """
  use ExUnit.Case, async: true

  # Import DSL components for testing
  use Dantzig.DSL.Integration

  # T043: Integration tests for DSL functionality

  describe "Basic DSL syntax" do
    test "creates a simple minimization problem" do
      problem =
        Problem.define do
          new(name: "Simple Problem", direction: :minimize)
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert problem.name == "Simple Problem"
      assert problem.direction == :minimize
      assert map_size(problem.variable_defs) == 3
      assert map_size(problem.constraints) == 3
    end

    test "creates a maximization problem" do
      problem =
        Problem.define do
          new(name: "Max Problem", direction: :maximize)
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :maximize)
        end

      assert problem.name == "Max Problem"
      assert problem.direction == :maximize
    end

    test "creates problem with binary variables" do
      problem =
        Problem.define do
          new(name: "Binary Problem")
          variables("x", [i <- 1..3], :binary, "Binary variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.variable_defs) == 3
      # Verify variables are binary
      x1 = Problem.get_variable(problem, "x(1)")
      assert x1.type == :binary
    end

    test "creates problem with integer variables" do
      problem =
        Problem.define do
          new(name: "Integer Problem")
          variables("x", [i <- 1..2], :integer, "Integer variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.variable_defs) == 2
      x1_def = Map.get(problem.variable_defs, "x(1)")
      assert x1_def.type == :integer
    end

    test "creates problem with custom variable bounds" do
      problem =
        Problem.define do
          new(name: "Bounded Problem")
          variables("x", [i <- 1..2], :continuous, "Variable", min_bound: 0, max_bound: 10)
          objective(sum(x(:_)), direction: :minimize)
        end

      x1 = Problem.get_variable(problem, "x(1)")
      assert x1.min_bound == 0
      assert x1.max_bound == 10
    end
  end

  describe "Generator syntax" do
    test "creates variables with single generator" do
      problem =
        Problem.define do
          new(name: "Single Generator")
          variables("x", [i <- 1..5], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.variable_defs) == 5
      # Verify all variables exist
      for i <- 1..5 do
        assert Problem.get_variable(problem, "x(#{i})") != nil
      end
    end

    test "creates variables with multiple generators (2D)" do
      problem =
        Problem.define do
          new(name: "2D Generator")
          variables("x", [i <- 1..3, j <- 1..2], :continuous, "Variable")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # 3 × 2 = 6 variables
      assert map_size(problem.variable_defs) == 6
      vars = Problem.get_variables_nd(problem, "x")
      assert map_size(vars) == 6
    end

    test "creates variables with multiple generators (3D)" do
      problem =
        Problem.define do
          new(name: "3D Generator")
          variables("x", [i <- 1..2, j <- 1..2, k <- 1..2], :continuous, "Variable")
          objective(sum(x(:_, :_, :_)), direction: :minimize)
        end

      # 2 × 2 × 2 = 8 variables
      assert map_size(problem.variable_defs) == 8
    end

    test "creates constraints with generators" do
      problem =
        Problem.define do
          new(name: "Generator Constraints")
          variables("x", [i <- 1..3], :continuous, "Variable")
          constraints([i <- 1..3], x(i) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Should create 3 constraints (one per i)
      assert map_size(problem.constraints) == 3
    end

    test "creates constraints with multiple generators" do
      problem =
        Problem.define do
          new(name: "Multi-Generator Constraints")
          variables("x", [i <- 1..2, j <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2, j <- 1..2], x(i, j) >= 0, "Non-negativity")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # Should create 2 × 2 = 4 constraints
      assert map_size(problem.constraints) == 4
    end
  end

  describe "Sum operations" do
    test "sums over all variables" do
      problem =
        Problem.define do
          new(name: "Sum All")
          variables("x", [i <- 1..3], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Objective should be sum of all x variables
      assert problem.objective != nil
    end

    test "sums over subset with fixed index" do
      problem =
        Problem.define do
          new(name: "Sum Subset")
          variables("x", [i <- 1..3, j <- 1..2], :continuous, "Variable")
          constraints([i <- 1..3], sum(x(i, :_)) == 1, "Row sum")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # Should create 3 constraints, one per row
      assert map_size(problem.constraints) == 3
    end

    test "sums with multiple wildcards" do
      problem =
        Problem.define do
          new(name: "Multi-Wildcard Sum")
          variables("x", [i <- 1..2, j <- 1..2, k <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], sum(x(i, :_, :_)) == 1, "Dimension sum")
          objective(sum(x(:_, :_, :_)), direction: :minimize)
        end

      # Should create 2 constraints
      assert map_size(problem.constraints) == 2
    end
  end

  describe "Variable patterns and wildcards" do
    test "uses wildcard pattern in constraints" do
      problem =
        Problem.define do
          new(name: "Wildcard Pattern")
          variables("x", [i <- 1..3, j <- 1..2], :continuous, "Variable")
          constraints([i <- 1..3], sum(x(i, :_)) == 1, "Row constraint")
          constraints([j <- 1..2], sum(x(:_, j)) == 1, "Column constraint")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # Should create 3 + 2 = 5 constraints
      assert map_size(problem.constraints) == 5
    end

    test "uses multiple wildcards in single expression" do
      problem =
        Problem.define do
          new(name: "Multiple Wildcards")
          variables("x", [i <- 1..2, j <- 1..2, k <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], sum(x(i, :_, :_)) == 1, "First dimension")
          objective(sum(x(:_, :_, :_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 2
    end
  end

  describe "Constraint operators" do
    test "creates equality constraints" do
      problem =
        Problem.define do
          new(name: "Equality Constraints")
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) == 5, "Fixed value")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 2
    end

    test "creates less-than-or-equal constraints" do
      problem =
        Problem.define do
          new(name: "LE Constraints")
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) <= 10, "Upper bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 2
    end

    test "creates greater-than-or-equal constraints" do
      problem =
        Problem.define do
          new(name: "GE Constraints")
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Lower bound")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 2
    end
  end

  describe "Model parameters" do
    test "uses model parameters in variable bounds" do
      data = %{max_val: 10}

      problem =
        Problem.define model_parameters: %{data: data} do
          new(name: "Model Params")
          variables("x", [i <- 1..2], :continuous, "Variable", max_bound: data[:max_val])
          objective(sum(x(:_)), direction: :minimize)
        end

      x1_def = Map.get(problem.variable_defs, "x(1)")
      assert x1_def.max_bound == 10
    end

    test "uses model parameters in constraint bounds" do
      data = %{limit: 5}

      problem =
        Problem.define model_parameters: %{data: data} do
          new(name: "Params in Constraints")
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) <= data[:limit], "Limit constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 2
    end

    test "uses nested model parameters" do
      data = %{bounds: %{min_bound: 0, max_bound: 10}}

      problem =
        Problem.define model_parameters: %{data: data} do
          new(name: "Nested Params")

          variables("x", [i <- 1..2], :continuous, "Variable",
            min_bound: data[:bounds][:min],
            max_bound: data[:bounds][:max]
          )

          objective(sum(x(:_)), direction: :minimize)
        end

      x1 = Problem.get_variable(problem, "x(1)")
      assert x1.min_bound == 0
      assert x1.max_bound == 10
    end
  end

  describe "Complex scenarios" do
    test "N-Queens problem (2D)" do
      problem =
        Problem.define do
          new(name: "N-Queens", direction: :minimize)
          variables("queen", [i <- 1..4, j <- 1..4], :binary, "Queen position")
          constraints([i <- 1..4], sum(queen(i, :_)) == 1, "One queen per row")
          constraints([j <- 1..4], sum(queen(:_, j)) == 1, "One queen per column")
          objective(sum(queen(:_, :_)), direction: :minimize)
        end

      assert problem.name == "N-Queens"
      # 4×4 = 16 variables
      vars = Problem.get_variables_nd(problem, "queen")
      assert map_size(vars) == 16
      # 4 row + 4 column = 8 constraints
      assert map_size(problem.constraints) == 8
    end

    test "Knapsack problem" do
      weights = [10, 20, 30]
      values = [60, 100, 120]
      capacity = 50

      problem =
        Problem.define model_parameters: %{weights: weights, values: values, capacity: capacity} do
          new(name: "Knapsack", direction: :maximize)
          variables("x", [i <- 1..3], :binary, "Item selected")
          constraints([], sum(x(:_) * weights[:_]) <= capacity, "Capacity constraint")
          objective(sum(x(:_) * values[:_]), direction: :maximize)
        end

      assert problem.name == "Knapsack"
      assert problem.direction == :maximize
      assert map_size(problem.variable_defs) == 3
    end

    test "Transportation problem" do
      sources = [1, 2]
      destinations = [1, 2, 3]
      supply = %{1 => 100, 2 => 150}
      demand = %{1 => 50, 2 => 80, 3 => 120}

      problem =
        Problem.define model_parameters: %{supply: supply, demand: demand} do
          new(name: "Transportation", direction: :minimize)
          variables("x", [i <- sources, j <- destinations], :continuous, "Flow", min_bound: 0)
          constraints([i <- sources], sum(x(i, :_)) <= supply[i], "Supply constraint")
          constraints([j <- destinations], sum(x(:_, j)) >= demand[j], "Demand constraint")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      assert problem.name == "Transportation"
      # 2 × 3 = 6 variables
      vars = Problem.get_variables_nd(problem, "x")
      assert map_size(vars) == 6
      # 2 supply + 3 demand = 5 constraints
      assert map_size(problem.constraints) == 5
    end

    test "Assignment problem" do
      tasks = [1, 2, 3]
      workers = [1, 2, 3]

      problem =
        Problem.define do
          new(name: "Assignment", direction: :minimize)
          variables("assign", [t <- tasks, w <- workers], :binary, "Assignment")
          constraints([t <- tasks], sum(assign(t, :_)) == 1, "Each task assigned")
          constraints([w <- workers], sum(assign(:_, w)) == 1, "Each worker assigned")
          objective(sum(assign(:_, :_)), direction: :minimize)
        end

      assert problem.name == "Assignment"
      # 3 × 3 = 9 variables
      vars = Problem.get_variables_nd(problem, "assign")
      assert map_size(vars) == 9
      # 3 task + 3 worker = 6 constraints
      assert map_size(problem.constraints) == 6
    end
  end

  describe "Objective functions" do
    test "minimizes sum of variables" do
      problem =
        Problem.define do
          new(name: "Minimize Sum")
          variables("x", [i <- 1..3], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "maximizes sum of variables" do
      problem =
        Problem.define do
          new(name: "Maximize Sum")
          variables("x", [i <- 1..3], :continuous, "Variable")
          objective(sum(x(:_)), direction: :maximize)
        end

      assert problem.direction == :maximize
      assert problem.objective != nil
    end

    test "uses weighted objective" do
      weights = [1, 2, 3]

      problem =
        Problem.define model_parameters: %{weights: weights} do
          new(name: "Weighted Objective")
          variables("x", [i <- 1..3], :continuous, "Variable")
          objective(sum(x(:_) * weights[:_]), direction: :minimize)
        end

      assert problem.objective != nil
    end
  end

  describe "Description interpolation" do
    test "interpolates variables in constraint descriptions" do
      problem =
        Problem.define do
          new(name: "Description Interpolation")
          variables("x", [i <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2], x(i) >= 0, "Constraint #{i}")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Verify constraints have interpolated descriptions
      constraints = Map.values(problem.constraints)
      descriptions = Enum.map(constraints, & &1.description)
      assert Enum.any?(descriptions, &String.contains?(&1, "1"))
      assert Enum.any?(descriptions, &String.contains?(&1, "2"))
    end

    test "interpolates multiple variables in descriptions" do
      problem =
        Problem.define do
          new(name: "Multi-Interpolation")
          variables("x", [i <- 1..2, j <- 1..2], :continuous, "Variable")
          constraints([i <- 1..2, j <- 1..2], x(i, j) >= 0, "Constraint #{i}_#{j}")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      constraints = Map.values(problem.constraints)
      descriptions = Enum.map(constraints, & &1.description)
      # Should have interpolated descriptions like "Constraint 1_1", "Constraint 1_2", etc.
      assert length(descriptions) == 4
    end
  end

  describe "Edge cases" do
    test "handles single variable problem" do
      problem =
        Problem.define do
          new(name: "Single Variable")
          variables("x", [], :continuous)
          objective(x(), direction: :minimize)
        end

      assert map_size(problem.variable_defs) == 1
      x_def = Map.get(problem.variable_defs, "x")
      assert x_def != nil
    end

    test "handles problem with no constraints" do
      problem =
        Problem.define do
          new(name: "No Constraints")
          variables("x", [i <- 1..2], :continuous, "Variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.constraints) == 0
      assert map_size(problem.variable_defs) == 2
    end

    test "handles problem with multiple variable types" do
      problem =
        Problem.define do
          new(name: "Mixed Types")
          variables("x", [i <- 1..2], :continuous, "Variable")
          variables("y", [i <- 1..2], :binary, "Binary variable")
          variables("z", [i <- 1..2], :integer, "Integer variable")
          objective(sum(x(:_)), direction: :minimize)
        end

      assert map_size(problem.variable_defs) == 6
      x1_def = Map.get(problem.variable_defs, "x(1)")
      y1_def = Map.get(problem.variable_defs, "y(1)")
      z1_def = Map.get(problem.variable_defs, "z(1)")
      assert x1_def.type == :continuous
      assert y1_def.type == :binary
      assert z1_def.type == :integer
    end
  end
end
