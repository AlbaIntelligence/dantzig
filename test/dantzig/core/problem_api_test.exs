defmodule Dantzig.Core.ProblemAPITest do
  @moduledoc """
  Tests for Problem module core API functionality.

  This module tests the core Problem API functions including new, new_variable,
  add_constraint, minimize, maximize, and other utility functions.
  """
  use ExUnit.Case

  # T039: Unit tests for Dantzig.Problem module core functionality

  describe "Problem.new/1" do
    test "creates a new problem with default values" do
      problem = Dantzig.Problem.new()

      assert problem.name == nil
      assert problem.description == nil
      assert problem.objective == Dantzig.Polynomial.const(0.0)
      assert problem.direction == nil
      assert problem.variable_defs == %{}
      assert problem.variables == %{}
      assert problem.constraints == %{}
      assert problem.variable_counter == 0
      assert problem.constraint_counter == 0
    end

    test "creates a new problem with name" do
      problem = Dantzig.Problem.new(name: "Test Problem")

      assert problem.name == "Test Problem"
      assert problem.description == nil
    end

    test "creates a new problem with description" do
      problem = Dantzig.Problem.new(description: "Test description")

      assert problem.name == nil
      assert problem.description == "Test description"
    end

    test "creates a new problem with both name and description" do
      problem = Dantzig.Problem.new(name: "Test", description: "Description")

      assert problem.name == "Test"
      assert problem.description == "Description"
    end
  end

  describe "Problem.new_variable/3" do
    test "creates a continuous variable with default bounds" do
      problem = Dantzig.Problem.new()
      {updated_problem, poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      assert Dantzig.Polynomial.variables(poly) == ["x"]
      assert Map.has_key?(updated_problem.variable_defs, "x")
      var_def = updated_problem.variable_defs["x"]
      assert var_def.name == "x"
      assert var_def.type == :continuous
      assert var_def.min == nil
      assert var_def.max == nil
    end

    test "creates a binary variable with default bounds [0, 1]" do
      problem = Dantzig.Problem.new()
      {updated_problem, poly} = Dantzig.Problem.new_variable(problem, "x", type: :binary)

      assert Dantzig.Polynomial.variables(poly) == ["x"]
      var_def = updated_problem.variable_defs["x"]
      assert var_def.type == :binary
      assert var_def.min == 0
      assert var_def.max == 1
    end

    test "creates a variable with custom bounds" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :continuous,
          min_bound: 5.0,
          max_bound: 10.0
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min == 5.0
      assert var_def.max == 10.0
    end

    test "creates a variable with description" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :continuous,
          description: "Amount of x"
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.description == "Amount of x"
    end

    test "creates binary variable with custom max bound" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :binary,
          max_bound: 2
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min == 0
      assert var_def.max == 2
    end

    test "creates binary variable with custom min bound" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :binary,
          min_bound: -1
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min == -1
      assert var_def.max == 1
    end
  end

  describe "Problem.add_constraint/2" do
    test "adds a constraint to the problem" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      updated_problem = Dantzig.Problem.add_constraint(problem, constraint)

      assert map_size(updated_problem.constraints) == 1
      assert updated_problem.constraint_counter == 1
    end

    test "generates unique constraint IDs" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint1 = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      constraint2 = Dantzig.Constraint.new_linear(x_poly, :>=, Dantzig.Polynomial.const(0.0))

      problem = Dantzig.Problem.add_constraint(problem, constraint1)
      problem = Dantzig.Problem.add_constraint(problem, constraint2)

      assert map_size(problem.constraints) == 2
      assert problem.constraint_counter == 2

      # Constraint IDs should be unique
      ids = Map.keys(problem.constraints)
      assert length(Enum.uniq(ids)) == 2
    end
  end

  describe "Problem.minimize/2 and Problem.maximize/2" do
    test "sets minimization objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      updated_problem = Dantzig.Problem.minimize(problem, x_poly)

      assert updated_problem.direction == :minimize
      assert updated_problem.objective == x_poly
    end

    test "sets maximization objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      updated_problem = Dantzig.Problem.maximize(problem, x_poly)

      assert updated_problem.direction == :maximize
      assert updated_problem.objective == x_poly
    end

    test "can change from minimize to maximize" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      assert problem.direction == :minimize

      problem = Dantzig.Problem.maximize(problem, x_poly)
      assert problem.direction == :maximize
    end
  end

  describe "Problem.set_objective/2" do
    test "sets objective without changing direction" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      assert problem.direction == :minimize

      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)
      problem = Dantzig.Problem.set_objective(problem, y_poly)

      # Direction unchanged
      assert problem.direction == :minimize
      assert problem.objective == y_poly
    end
  end

  describe "Problem.increment_objective/2" do
    test "adds to existing objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      initial_objective = problem.objective

      problem = Dantzig.Problem.increment_objective(problem, y_poly)

      expected = Dantzig.Polynomial.add(initial_objective, y_poly)
      assert problem.objective == expected
    end
  end

  describe "Problem.get_variable/2" do
    test "retrieves existing variable definition" do
      problem = Dantzig.Problem.new()
      {problem, _poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      var_def = Dantzig.Problem.get_variable(problem, "x")

      assert var_def != nil
      assert var_def.name == "x"
      assert var_def.type == :continuous
    end

    test "returns nil for non-existent variable" do
      problem = Dantzig.Problem.new()

      var_def = Dantzig.Problem.get_variable(problem, "nonexistent")

      assert var_def == nil
    end
  end

  describe "Problem.get_constraint/2" do
    test "retrieves existing constraint" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint)

      constraint_id = List.first(Map.keys(problem.constraints))
      retrieved = Dantzig.Problem.get_constraint(problem, constraint_id)

      assert retrieved != nil
      assert retrieved == constraint
    end

    test "returns nil for non-existent constraint" do
      problem = Dantzig.Problem.new()

      constraint = Dantzig.Problem.get_constraint(problem, "nonexistent")

      assert constraint == nil
    end
  end

  describe "Problem.get_variables_nd/2 and Problem.put_variables_nd/3" do
    test "stores and retrieves N-dimensional variable sets" do
      problem = Dantzig.Problem.new()
      {problem, x1_poly} = Dantzig.Problem.new_variable(problem, "x_1", type: :continuous)
      {problem, x2_poly} = Dantzig.Problem.new_variable(problem, "x_2", type: :continuous)

      var_map = %{1 => x1_poly, 2 => x2_poly}
      problem = Dantzig.Problem.put_variables_nd(problem, "x", var_map)

      retrieved = Dantzig.Problem.get_variables_nd(problem, "x")

      assert retrieved == var_map
    end

    test "returns nil for non-existent variable set" do
      problem = Dantzig.Problem.new()

      result = Dantzig.Problem.get_variables_nd(problem, "nonexistent")

      assert result == nil
    end
  end

  describe "Problem.new_variables/3" do
    test "creates multiple variables at once" do
      problem = Dantzig.Problem.new()

      {updated_problem, polys} =
        Dantzig.Problem.new_variables(problem, ["x", "y", "z"], type: :continuous)

      assert length(polys) == 3
      assert Map.has_key?(updated_problem.variable_defs, "x")
      assert Map.has_key?(updated_problem.variable_defs, "y")
      assert Map.has_key?(updated_problem.variable_defs, "z")
    end

    test "applies same options to all variables" do
      problem = Dantzig.Problem.new()

      {updated_problem, _polys} =
        Dantzig.Problem.new_variables(problem, ["x", "y"],
          type: :binary,
          min_bound: 0,
          max_bound: 1
        )

      x_def = updated_problem.variable_defs["x"]
      y_def = updated_problem.variable_defs["y"]

      assert x_def.type == :binary
      assert y_def.type == :binary
      assert x_def.min == 0
      assert y_def.min == 0
    end
  end

  describe "Problem.solve_for_all_variables/1" do
    test "solves constraints for all variables" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)

      # Add constraint: x + y == 10
      sum_poly = Dantzig.Polynomial.add(x_poly, y_poly)
      constraint = Dantzig.Constraint.new_linear(sum_poly, :==, Dantzig.Polynomial.const(10.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint)

      # Add constraint: x - y == 0
      diff_poly = Dantzig.Polynomial.subtract(x_poly, y_poly)
      constraint2 = Dantzig.Constraint.new_linear(diff_poly, :==, Dantzig.Polynomial.const(0.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint2)

      solved = Dantzig.Problem.solve_for_all_variables(problem)

      # Should have solutions for both x and y
      assert Map.has_key?(solved, "x")
      assert Map.has_key?(solved, "y")
    end

    test "returns empty map when no constraints" do
      problem = Dantzig.Problem.new()
      {problem, _x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      solved = Dantzig.Problem.solve_for_all_variables(problem)

      assert solved == %{}
    end
  end
end

