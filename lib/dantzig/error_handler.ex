defmodule Dantzig.ErrorHandler do
  @moduledoc """
  Enhanced error handling for the Dantzig optimization library.

  Provides clear, actionable error messages for common usage mistakes
  and graceful handling of edge cases.

  Implements requirements from 001-robustify specification:
  - FR-006: Clear error messages for common DSL usage mistakes
  - FR-008: Handle edge cases gracefully with appropriate error messages
  """

  @doc """
  Generate a helpful error message for DSL parsing errors.
  """
  @spec dsl_parse_error(atom(), term(), keyword()) :: %Dantzig.Error{
          type: :dsl_parse_error,
          message: String.t(),
          suggestions: [String.t()],
          code_location: {String.t(), integer()}
        }
  def dsl_parse_error(error_type, details, location \\ []) do
    message = case error_type do
      :undefined_variable ->
        "Variable '#{details.variable_name}' is not defined. Available variables: #{Enum.join(details.available_variables, ", ")}"

      :invalid_constraint_expression ->
        "Invalid constraint expression: #{details.expression}. " <>
        "Common issues: " <>
        "• Check variable names match defined variables. " <>
        "• Ensure mathematical operations are valid (no multiplication of variables). " <>
        "• Use sum() for aggregated expressions."

      :unreachable_constraint ->
        "Constraint appears to be infeasible: #{details.constraint}. " <>
        "This constraint cannot be satisfied simultaneously with other constraints. " <>
        "Suggestions: " <>
        "• Review conflicting constraints. " <>
        "• Check if bounds are too restrictive. " <>
        "• Verify constraint logic."

      :malformed_sum_expression ->
        "Malformed sum expression: #{details.expression}. " <>
        "Sum expressions should follow: " <>
        "• sum(for var <- collection, do: expression). " <>
        "• sum(variable_name(index) for index <- range)."

      :invalid_variable_access ->
        "Invalid variable access: #{details.access}. " <>
        "Variable access patterns: " <>
        "• single variable: variable_name. " <>
        "• indexed access: variable_name(index). " <>
        "• sum comprehension: sum(for i <- 1..n, do: variable_name(i))."

      _ ->
        "DSL parsing error: #{inspect(details)}"
    end

    suggestions = get_error_suggestions(error_type, details)
    code_location = get_error_location(location)

    %Dantzig.Error{
      type: :dsl_parse_error,
      message: message,
      suggestions: suggestions,
      code_location: code_location
    }
  end

  @doc """
  Generate a helpful error message for constraint validation errors.
  """
  @spec constraint_validation_error(atom(), term(), keyword()) :: %Dantzig.Error{
          type: :constraint_validation_error,
          message: String.t(),
          suggestions: [String.t()],
          code_location: {String.t(), integer()}
        }
  def constraint_validation_error(error_type, details, location \\ []) do
    message = case error_type do
      :constraint_violation ->
        "Constraint violation detected: #{details.constraint_description}. " <>
        "The constraint is not satisfied by the solution. " <>
        "Violation amount: #{details.violation}."

      :infeasible_problem ->
        "Problem is infeasible - no solution exists that satisfies all constraints. " <>
        "This can occur when: " <>
        "• Constraints are contradictory. " <>
        "• Bounds are too restrictive. " <>
        "• Required resources exceed available resources."

      :unbounded_objective ->
        "Objective function is unbounded - solution can be arbitrarily large. " <>
        "This indicates: " <>
        "• Missing constraints to bound the objective. " <>
        "• Objective coefficients may be incorrect. " <>
        "• Problem formulation may need review."

      :constraint_conflict ->
        "Constraint conflict detected: #{details.conflict_description}" <>
        " Two or more constraints cannot be satisfied simultaneously."

      _ ->
        "Constraint validation error: #{inspect(details)}"
    end

    suggestions = get_constraint_suggestions(error_type, details)
    code_location = get_error_location(location)

    %Dantzig.Error{
      type: :constraint_validation_error,
      message: message,
      suggestions: suggestions,
      code_location: code_location
    }
  end

  @doc """
  Generate a helpful error message for solver integration errors.
  """
  @spec solver_error(atom(), term(), keyword()) :: %Dantzig.Error{
          type: :solver_error,
          message: String.t(),
          suggestions: [String.t()],
          code_location: {String.t(), integer()}
        }
  def solver_error(error_type, details, location \\ []) do
    message = case error_type do
      :solver_not_available ->
        "Optimization solver (HiGHS) is not available."

      :solver_timeout ->
        "Solver timed out after #{details.timeout_ms}ms. " <>
        "This may indicate the problem is too large or complex."

      :solver_failure ->
        "Solver failed to find a solution. " <>
        "Exit code: #{details.exit_code}. " <>
        "Error output: #{details.error_output}."

      :invalid_problem_format ->
        "Problem format is invalid for solver consumption. " <>
        "This may be due to: " <>
        "• Unsupported constraint types. " <>
        "• Invalid bounds (NaN, infinity issues). " <>
        "• Corrupted problem data."

      _ ->
        "Solver error: #{inspect(details)}"
    end

    suggestions = get_solver_suggestions(error_type, details)
    code_location = get_error_location(location)

    %Dantzig.Error{
      type: :solver_error,
      message: message,
      suggestions: suggestions,
      code_location: code_location
    }
  end

  @doc """
  Generate a helpful error message for model parameters issues.
  """
  @spec model_parameter_error(atom(), term(), keyword()) :: %Dantzig.Error{
          type: :model_parameter_error,
          message: String.t(),
          suggestions: [String.t()],
          code_location: {String.t(), integer()}
        }
  def model_parameter_error(error_type, details, location \\ []) do
    message = case error_type do
      :undefined_parameter ->
        "Model parameter '#{details.parameter_name}' is not defined. " <>
        "Available parameters: #{Enum.join(details.available_parameters, ", ")}."

      :invalid_parameter_type ->
        "Invalid parameter type for '#{details.parameter_name}'. " <>
        "Expected: #{details.expected_type}. " <>
        "Got: #{inspect(details.actual_value)}."

      :parameter_evaluation_failed ->
        "Failed to evaluate model parameter '#{details.parameter_name}'. " <>
        "Error: #{details.error_message}."

      _ ->
        "Model parameter error: #{inspect(details)}"
    end

    suggestions = get_parameter_suggestions(error_type, details)
    code_location = get_error_location(location)

    %Dantzig.Error{
      type: :model_parameter_error,
      message: message,
      suggestions: suggestions,
      code_location: code_location
    }
  end

  # Private helper functions

  defp get_error_suggestions(:undefined_variable, details) do
    [
      "Check that the variable name matches exactly (case-sensitive)",
      "Ensure the variable was defined before being used",
      "Verify generator variable names match constraint usage",
      "Available variables: #{Enum.join(details.available_variables, ", ")}"
    ]
  end

  defp get_error_suggestions(:invalid_constraint_expression, _details) do
    [
      "Use valid mathematical expressions (no variable multiplication)",
      "Check that variable names are defined and accessible",
      "Use sum() for aggregated expressions over collections",
      "Ensure proper operator precedence and parentheses"
    ]
  end

  defp get_error_suggestions(:unreachable_constraint, _details) do
    [
      "Review all constraints for conflicts",
      "Check if bounds are too restrictive",
      "Verify the mathematical model is correct",
      "Consider relaxing some constraints or adding variables"
    ]
  end

  defp get_error_suggestions(_error_type, _details) do
    ["Check the documentation for proper DSL syntax",
     "Review examples for correct usage patterns"]
  end

  defp get_constraint_suggestions(:infeasible_problem, _details) do
    [
      "Review all constraints for contradictions",
      "Check if bounds allow feasible solutions",
      "Verify that required resources don't exceed available resources",
      "Consider adding slack variables or adjusting constraint tightness"
    ]
  end

  defp get_constraint_suggestions(:unbounded_objective, _details) do
    [
      "Add constraints to bound the objective function",
      "Check objective function coefficients for errors",
      "Ensure all variables have appropriate bounds",
      "Review the problem formulation for missing constraints"
    ]
  end

  defp get_constraint_suggestions(_error_type, _details) do
    ["Review constraint formulation and bounds",
     "Check mathematical model consistency"]
  end

  defp get_solver_suggestions(:solver_not_available, _details) do
    [
      "Install the HiGHS solver binary",
      "Check that the solver is in the PATH",
      "Verify solver permissions and executability"
    ]
  end

  defp get_solver_suggestions(:solver_timeout, details) do
    [
      "Try simplifying the problem (reduce variables/constraints)",
      "Check if the problem is solvable within reasonable time",
      "Consider using a different solver or formulation",
      "Review problem size: #{details.variable_count} variables, #{details.constraint_count} constraints"
    ]
  end

  defp get_solver_suggestions(_error_type, _details) do
    ["Check problem format and solver compatibility",
     "Verify all bounds and coefficients are valid numbers"]
  end

  defp get_parameter_suggestions(:undefined_parameter, details) do
    [
      "Check parameter name spelling (case-sensitive)",
      "Ensure all required parameters are provided",
      "Available parameters: #{Enum.join(details.available_parameters, ", ")}"
    ]
  end

  defp get_parameter_suggestions(:invalid_parameter_type, details) do
    [
      "Check that parameter values match expected types",
      "Ensure collections are enumerable",
      "Verify numeric parameters are valid numbers"
    ]
  end

  defp get_parameter_suggestions(_error_type, _details) do
    ["Review model parameter documentation",
     "Check parameter examples for correct usage"]
  end

  defp get_error_location(location) do
    file = Keyword.get(location, :file, "unknown")
    line = Keyword.get(location, :line, 0)
    {file, line}
  end
end
