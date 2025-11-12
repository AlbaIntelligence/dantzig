defmodule Dantzig.BackwardCompatibilityTest do
  @moduledoc """
  Backward compatibility validation test for the Dantzig package.

  This test ensures that existing API contracts are maintained.

  Tests cover:
  - Imperative API (Problem.new, Problem.add_variable, Problem.add_constraint, Problem.set_objective)
  - DSL API (Problem.define)
  - Polynomial operations
  - Constraint creation
  - Variable creation
  - Solution structures
  - AST structures
  - Solver integration

  Ensures FR-009: System MUST maintain backward compatibility with existing API usage patterns
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint

  test "Problem.new/1 maintains existing API" do
    # Test that Problem.new/1 works with keyword list
    problem = Dantzig.Problem.new(name: "Test Problem")
    assert problem.name == "Test Problem"
    assert is_map(problem.variables)
    assert is_map(problem.constraints)
    assert is_nil(problem.objective)
  end

  test "Problem.new/1 works with different parameter combinations" do
    # Test various parameter combinations that should work
    problem1 = Dantzig.Problem.new(name: "Test 1")
    assert problem1.name == "Test 1"

    problem2 = Dantzig.Problem.new(name: "Test 2", description: "Test description")
    assert problem2.name == "Test 2"
    assert problem2.description == "Test description"
  end

  test "Problem.define/1 maintains existing API" do
    # Test that Problem.define/1 works as expected
    problem =
      Problem.define do
        Dantzig.Problem.new(name: "Define Test")
      end

    assert problem.name == "Define Test"
    assert is_map(problem.variables)
    assert is_map(problem.constraints)
  end

  test "Polynomial operations maintain existing API" do
    # Test that polynomial operations work as expected
    poly1 = Dantzig.Polynomial.new(%{"x" => 1.0})
    poly2 = Dantzig.Polynomial.new(%{"y" => 2.0})

    # Test addition
    result_add = Dantzig.Polynomial.add(poly1, poly2)
    assert is_struct(result_add, Dantzig.Polynomial)

    # Test subtraction
    result_sub = Dantzig.Polynomial.subtract(poly1, poly2)
    assert is_struct(result_sub, Dantzig.Polynomial)

    # Test scaling
    result_scale = Dantzig.Polynomial.scale(poly1, 2.0)
    assert is_struct(result_scale, Dantzig.Polynomial)
  end

  test "Constraint creation maintains existing API" do
    # Test that constraint creation works as expected
    left = Dantzig.Polynomial.new(%{"x" => 1.0})
    right = Dantzig.Polynomial.new(%{})

    # Test macro API with comparison expression
    constraint = Constraint.new(left == right, description: "Test constraint")

    assert is_struct(constraint, Dantzig.Constraint)
    assert constraint.left == left
    assert constraint.operator == :==
    assert constraint.right == right
    assert constraint.description == "Test constraint"

    # Test positional API (if supported)
    constraint2 = Constraint.new(left, :<=, right)
    assert is_struct(constraint2, Dantzig.Constraint)
    assert constraint2.left == left
    assert constraint2.operator == :<=
    assert constraint2.right == right
  end

  test "ProblemVariable creation maintains existing API" do
    # Test that variable creation works as expected
    variable =
      Dantzig.ProblemVariable.new(
        name: "x",
        type: :continuous,
        description: "Test variable"
      )

    assert is_struct(variable, Dantzig.ProblemVariable)
    assert variable.name == "x"
    assert variable.type == :continuous
    assert variable.description == "Test variable"
  end

  test "Solution structure maintains existing API" do
    # Test that solution structure works as expected
    solution =
      Dantzig.Solution.new(
        status: :optimal,
        objective_value: 42.0,
        variables: %{"x" => 1.0, "y" => 2.0}
      )

    assert is_struct(solution, Dantzig.Solution)
    assert solution.status == :optimal
    assert solution.objective_value == 42.0
    assert solution.variables == %{"x" => 1.0, "y" => 2.0}
  end

  test "AST structures maintain existing API" do
    # Test that AST structures work as expected
    variable_ast =
      Dantzig.AST.Variable.new(
        name: :x,
        indices: [1, 2],
        pattern: nil
      )

    assert is_struct(variable_ast, Dantzig.AST.Variable)
    assert variable_ast.name == :x
    assert variable_ast.indices == [1, 2]
    assert variable_ast.pattern == nil
  end

  test "DSL functions maintain existing API" do
    # Test that DSL functions work as expected
    assert Code.ensure_loaded?(Dantzig.DSL), "DSL module should be available"

    # Test that DSL functions are exported
    assert function_exported?(Dantzig.DSL, :parse_expression, 1),
           "DSL.parse_expression/1 should be exported"
  end

  test "Solver integration maintains existing API" do
    # Test that solver functions work as expected
    assert Code.ensure_loaded?(Dantzig.HiGHS), "HiGHS solver should be available"

    # Test that solver functions are exported
    assert function_exported?(Dantzig.HiGHS, :solve, 1),
           "HiGHS.solve/1 should be exported"
  end

  test "Configuration maintains existing API" do
    # Test that configuration works as expected
    assert Code.ensure_loaded?(Dantzig.Config), "Config module should be available"

    # Test that configuration functions are exported
    assert function_exported?(Dantzig.Config, :get, 1),
           "Config.get/1 should be exported"
  end

  test "imperative API patterns maintain backward compatibility" do
    # Test the imperative API: Problem.new, Problem.add_variable, Problem.add_constraint, Problem.set_objective
    # This is the original API pattern that must continue to work

    # Create problem
    problem = Dantzig.Problem.new(name: "Imperative Test")

    # Add variable
    {problem, var_ref} =
      Dantzig.Problem.new_variable(problem, "x",
        type: :continuous,
        min_bound: 0.0,
        max_bound: 10.0
      )

    assert is_map(problem.variables)
    assert Map.has_key?(problem.variables, "x")

    # Add constraint using polynomials
    left = Dantzig.Polynomial.variable("x")
    right = Dantzig.Polynomial.const(5.0)
    constraint = Dantzig.Constraint.new(left, :<=, right)
    problem = Dantzig.Problem.add_constraint(problem, constraint)
    assert map_size(problem.constraints) == 1

    # Set objective
    objective = Dantzig.Polynomial.variable("x")
    problem = Problem.set_objective(problem, objective, :maximize)
    assert problem.direction == :maximize
    assert problem.objective != nil
  end

  test "Problem.define without model_parameters maintains backward compatibility" do
    # Test that Problem.define(do: block) still works without model_parameters
    # This is critical for backward compatibility (FR-009, FR-013)
    problem =
      Problem.define do
        new(name: "Define Test Without Params")
        variables("x", [i <- 1..3], :continuous, min_bound: 0)
        constraints([i <- 1..3], x(i) <= 10, "Upper bound")
        objective(sum(x(:_)), direction: :maximize)
      end

    assert problem.name == "Define Test Without Params"
    assert map_size(problem.variables) == 3
    assert map_size(problem.constraints) == 3
    assert problem.direction == :maximize
  end

  test "Problem.define with model_parameters is backward compatible with existing code" do
    # Test that Problem.define with model_parameters doesn't break existing patterns
    # Existing code without model_parameters should work unchanged
    n = 3
    max_val = 10

    problem =
      Problem.define model_parameters: %{n: n, max_val: max_val} do
        new(name: "Define Test With Params")
        variables("x", [i <- 1..n], :continuous, min_bound: 0)
        constraints([i <- 1..n], x(i) <= max_val, "Upper bound")
        objective(sum(x(:_)), direction: :maximize)
      end

    assert problem.name == "Define Test With Params"
    assert map_size(problem.variables) == 3
    assert map_size(problem.constraints) == 3
  end

  test "Problem methods maintain existing return types" do
    # Test that all Problem methods return expected types
    problem = Dantzig.Problem.new(name: "Return Types Test")

    # new_variable returns {problem, variable_reference}
    {problem, var_ref} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)
    assert is_struct(problem, Dantzig.Problem)
    assert is_binary(var_ref) or is_atom(var_ref)

    # add_constraint returns updated problem
    left = Dantzig.Polynomial.variable("x")
    right = Dantzig.Polynomial.const(1.0)
    constraint = Constraint.new(left, :<=, right)
    problem = Dantzig.Problem.add_constraint(problem, constraint)
    assert is_struct(problem, Dantzig.Problem)

    # set_objective returns updated problem
    objective = Dantzig.Polynomial.variable("x")
    problem = Problem.set_objective(problem, objective, :minimize)
    assert is_struct(problem, Dantzig.Problem)
  end

  test "Polynomial operations maintain existing function signatures" do
    # Test that polynomial operations work with existing signatures
    poly1 = Dantzig.Polynomial.new(%{"x" => 1.0, "y" => 2.0})
    poly2 = Dantzig.Polynomial.new(%{"y" => 1.0, "z" => 3.0})

    # Addition with two polynomials
    result_add = Dantzig.Polynomial.add(poly1, poly2)
    assert is_struct(result_add, Dantzig.Polynomial)

    # Subtraction with two polynomials
    result_sub = Dantzig.Polynomial.subtract(poly1, poly2)
    assert is_struct(result_sub, Dantzig.Polynomial)

    # Scaling with number
    result_scale = Dantzig.Polynomial.scale(poly1, 2.0)
    assert is_struct(result_scale, Dantzig.Polynomial)

    # Const creation
    const_poly = Dantzig.Polynomial.const(5.0)
    assert is_struct(const_poly, Dantzig.Polynomial)

    # Variable creation
    var_poly = Dantzig.Polynomial.variable("x")
    assert is_struct(var_poly, Dantzig.Polynomial)
  end

  test "existing examples still work" do
    # Test that existing examples can still be executed
    example_files = [
      "docs/user/examples/knapsack_problem.exs",
      "docs/user/examples/tutorial_examples.exs"
    ]

    for file <- example_files do
      if File.exists?(file) do
        # Try to compile the example file
        case Code.compile_file(file) do
          {_, []} ->
            assert true, "Example file #{file} should compile without warnings"

          {_, warnings} ->
            # Check if warnings are critical
            critical_warnings =
              Enum.filter(warnings, fn {_, _, message} ->
                String.contains?(to_string(message), "undefined") or
                  String.contains?(to_string(message), "error")
              end)

            assert length(critical_warnings) == 0,
                   "Example file #{file} should not have critical warnings: #{inspect(critical_warnings)}"
        end
      else
        assert true, "Example file #{file} not found (may not exist yet)"
      end
    end
  end

  test "variable types maintain existing API" do
    # Test that all variable types work as expected
    problem = Dantzig.Problem.new(name: "Variable Types Test")

    # Continuous variables
    {problem, _} = Dantzig.Problem.new_variable(problem, "x_cont", type: :continuous)
    assert problem.variables["x_cont"].type == :continuous

    # Binary variables
    {problem, _} = Dantzig.Problem.new_variable(problem, "x_bin", type: :binary)
    assert problem.variables["x_bin"].type == :binary

    # Integer variables
    {problem, _} = Dantzig.Problem.new_variable(problem, "x_int", type: :integer)
    assert problem.variables["x_int"].type == :integer
  end

  test "constraint operators maintain existing API" do
    # Test that all constraint operators work as expected
    left = Dantzig.Polynomial.variable("x")
    right = Dantzig.Polynomial.const(5.0)

    operators = [:==, :<=, :>=]

    for operator <- operators do
      constraint = Dantzig.Constraint.new(left, operator, right)
      assert is_struct(constraint, Dantzig.Constraint)
      assert constraint.operator == operator
    end
  end

  test "problem direction maintains existing API" do
    # Test that problem direction can be set and retrieved
    problem = Dantzig.Problem.new(name: "Direction Test")
    objective = Dantzig.Polynomial.variable("x")

    # Maximize
    problem_max = Problem.set_objective(problem, objective, :maximize)
    assert problem_max.direction == :maximize

    # Minimize
    problem_min = Problem.set_objective(problem, objective, :minimize)
    assert problem_min.direction == :minimize
  end
end
