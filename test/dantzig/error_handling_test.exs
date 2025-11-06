defmodule Dantzig.ErrorHandlingTest do
  @moduledoc """
  Tests for enhanced error handling functionality.

  Validates that error messages are clear and actionable for
  common usage mistakes (FR-006 requirement).
  """

  use ExUnit.Case, async: true

  alias Dantzig.ErrorHandler
  alias Dantzig.Error

  describe "DSL parsing error handling" do
    test "undefined variable error provides helpful suggestions" do
      details = %{
        variable_name: "x",
        available_variables: ["y", "z"]
      }

      error = ErrorHandler.dsl_parse_error(:undefined_variable, details)

      assert %Error{
               type: :dsl_parse_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Variable 'x' is not defined"
      assert message =~ "Available variables: y, z"
      assert Enum.any?(suggestions, &(&1 =~ "variable name matches exactly"))
    end

    test "invalid constraint expression error provides guidance" do
      details = %{
        expression: "x * y <= 10"
      }

      error = ErrorHandler.dsl_parse_error(:invalid_constraint_expression, details)

      assert %Error{
               type: :dsl_parse_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Invalid constraint expression"
      assert message =~ "Common issues:"
      assert Enum.any?(suggestions, &(&1 =~ "valid mathematical expressions"))
    end

    test "unreachable constraint error explains infeasibility" do
      details = %{
        constraint: "x >= 10 AND x <= 5"
      }

      error = ErrorHandler.dsl_parse_error(:unreachable_constraint, details)

      assert %Error{
               type: :dsl_parse_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Constraint appears to be infeasible"
      assert message =~ "cannot be satisfied simultaneously"
      assert Enum.any?(suggestions, &(&1 =~ "Review conflicting constraints"))
    end
  end

  describe "constraint validation error handling" do
    test "infeasible problem error explains common causes" do
      details = %{
        constraint_list: ["x >= 10", "x <= 5"]
      }

      error = ErrorHandler.constraint_validation_error(:infeasible_problem, details)

      assert %Error{
               type: :constraint_validation_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Problem is infeasible"
      assert message =~ "no solution exists"
      assert Enum.any?(suggestions, &(&1 =~ "Review all constraints"))
    end

    test "unbounded objective error provides guidance" do
      details = %{
        objective_direction: :maximize,
        unbounded_variables: ["x", "y"]
      }

      error = ErrorHandler.constraint_validation_error(:unbounded_objective, details)

      assert %Error{
               type: :constraint_validation_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Objective function is unbounded"
      assert message =~ "solution can be arbitrarily large"
      assert Enum.any?(suggestions, &(&1 =~ "Add constraints to bound"))
    end
  end

  describe "solver error handling" do
    test "solver not available error provides installation guidance" do
      details = %{}

      error = ErrorHandler.solver_error(:solver_not_available, details)

      assert %Error{
               type: :solver_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Optimization solver (HiGHS) is not available"
      assert Enum.any?(suggestions, &(&1 =~ "Install the HiGHS solver"))
    end

    test "solver timeout error provides performance guidance" do
      details = %{
        timeout_ms: 60000,
        variable_count: 1000,
        constraint_count: 500
      }

      error = ErrorHandler.solver_error(:solver_timeout, details)

      assert %Error{
               type: :solver_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Solver timed out after 60000ms"
      assert message =~ "problem is too large or complex"
      assert Enum.any?(suggestions, &(&1 =~ "Try simplifying the problem"))
      assert Enum.any?(suggestions, &(&1 =~ "1000 variables"))
    end
  end

  describe "model parameter error handling" do
    test "undefined parameter error shows available parameters" do
      details = %{
        parameter_name: "missing_param",
        available_parameters: ["n", "max_value", "costs"]
      }

      error = ErrorHandler.model_parameter_error(:undefined_parameter, details)

      assert %Error{
               type: :model_parameter_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Model parameter 'missing_param' is not defined"
      assert message =~ "Available parameters: n, max_value, costs"
      assert Enum.any?(suggestions, &(&1 =~ "Check parameter name spelling"))
    end

    test "invalid parameter type error explains expected type" do
      details = %{
        parameter_name: "n",
        expected_type: "integer",
        actual_value: "not_a_number"
      }

      error = ErrorHandler.model_parameter_error(:invalid_parameter_type, details)

      assert %Error{
               type: :model_parameter_error,
               message: message,
               suggestions: suggestions
             } = error

      assert message =~ "Invalid parameter type for 'n'"
      assert message =~ "Expected: integer"
      assert message =~ "Got: \"not_a_number\""
      assert Enum.any?(suggestions, &(&1 =~ "Check that parameter values match"))
    end
  end

  describe "error structure validation" do
    test "all errors have required fields" do
      error_types = [
        {:dsl_parse_error, :undefined_variable,
         %{variable_name: "x", available_variables: ["y"]}},
        {:constraint_validation_error, :infeasible_problem, %{}},
        {:solver_error, :solver_not_available, %{}},
        {:model_parameter_error, :undefined_parameter,
         %{parameter_name: "x", available_parameters: ["y"]}}
      ]

      Enum.each(error_types, fn {module, error_type, details} ->
        error = apply(ErrorHandler, :"#{error_type}_error", [error_type, details])

        assert %Error{} = error, "#{module} should return Error struct"
        assert error.type == module, "Error type should be #{module}"
        assert is_binary(error.message), "Error message should be string"
        assert is_list(error.suggestions), "Suggestions should be list"
        assert is_tuple(error.code_location), "Code location should be tuple"
        assert is_binary(elem(error.code_location, 0)), "Code location file should be string"
        assert is_integer(elem(error.code_location, 1)), "Code location line should be integer"
      end)
    end

    test "error messages are user-friendly and actionable" do
      error =
        ErrorHandler.dsl_parse_error(:undefined_variable, %{
          variable_name: "z",
          available_variables: ["x", "y"]
        })

      # Messages should be informative but not overly technical
      assert byte_size(error.message) > 50, "Error messages should be substantial"
      assert byte_size(error.message) < 500, "Error messages should be concise"

      # Suggestions should be actionable
      suggestions_text = Enum.join(error.suggestions, " ")
      assert suggestions_text =~ "Check", "Should provide check instructions"
      assert suggestions_text =~ "Ensure", "Should provide verification steps"
    end
  end
end
