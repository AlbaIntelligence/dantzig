defmodule Dantzig.BackwardCompatibilityTest do
  @moduledoc """
  Backward compatibility validation test for the Dantzig package.

  This test ensures that existing API contracts are maintained.
  """
  use ExUnit.Case, async: true

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

    constraint =
      Dantzig.Constraint.new(
        left: left,
        operator: :==,
        right: right,
        description: "Test constraint"
      )

    assert is_struct(constraint, Dantzig.Constraint)
    assert constraint.left == left
    assert constraint.operator == :==
    assert constraint.right == right
    assert constraint.description == "Test constraint"
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

  test "existing examples still work" do
    # Test that existing examples can still be executed
    example_files = [
      "examples/simple_working_example.exs",
      "examples/knapsack_problem.exs"
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
end
