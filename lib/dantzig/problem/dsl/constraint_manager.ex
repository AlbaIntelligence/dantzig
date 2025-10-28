defmodule Dantzig.Problem.DSL.ConstraintManager do
  @moduledoc """
  Manages constraint creation and objective setting for the Dantzig DSL.

  This module handles:
  - Constraint creation with pattern-based generators
  - Objective function parsing and setting
  - Constraint expression parsing and validation
  - Integration with the core Problem module
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial

  # Public implementation entrypoints used by macros in Dantzig.Problem.DSL
  def add_constraints(problem, generators, constraint_expr, description) do
    parsed_generators = parse_generators(generators)
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    Enum.reduce(combinations, problem, fn index_vals, current_problem ->
      bindings = create_bindings(parsed_generators, index_vals)
      constraint = parse_constraint_expression(constraint_expr, bindings, current_problem)

      constraint_name =
        if description, do: create_constraint_name(description, bindings, index_vals), else: nil

      constraint = if constraint_name, do: %{constraint | name: constraint_name}, else: constraint
      Problem.add_constraint(current_problem, constraint)
    end)
  end

  def set_objective(problem, objective_expr, opts) do
    direction =
      cond do
        is_atom(opts) and opts in [:minimize, :maximize] -> opts
        is_list(opts) -> Keyword.get(opts, :direction)
        true -> nil
      end

    if direction not in [:minimize, :maximize] do
      raise ArgumentError,
            "Objective direction must be :minimize or :maximize, got: #{inspect(direction)}"
    end

    objective = parse_objective_expression(objective_expr, problem)
    %{problem | objective: objective, direction: direction}
  end

  def parse_constraint_expression(constraint_expr, bindings, problem) do
    case constraint_expr do
      {:==, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :==, right_poly)

      {:<=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :<=, right_poly)

      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :>=, right_poly)

      _ ->
        raise ArgumentError, "Unsupported constraint expression: #{inspect(constraint_expr)}"
    end
  end

  def parse_objective_expression(objective_expr, problem) do
    expr = normalize_sum_ast(objective_expr)

    case expr do
      {:sum, expr} -> parse_sum_expression(expr, %{}, problem)
      expr when is_tuple(expr) -> parse_expression_to_polynomial(expr, %{}, problem)
      value when is_number(value) -> Polynomial.const(value)
      _ -> raise ArgumentError, "Unsupported objective expression: #{inspect(expr)}"
    end
  end

  def create_constraint_name(description, bindings, index_vals) do
    # New approach: handle variable interpolation in constraint names
    # This replaces variable names in the description with actual values
    case description do
      # If description contains variable placeholders like "Constraint for i"
      desc when is_binary(desc) ->
        # Check if description contains variable placeholders
        if String.contains?(desc, " ") do
          # For descriptions with spaces, try to interpolate variables
          interpolated_desc = interpolate_variables_in_description(desc, index_vals)
          interpolated_desc
        else
          # Simple case: just append index values
          index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
          "#{desc}_#{index_str}"
        end

      # Handle interpolated binaries (AST like {:<<>>, ...}) by evaluating with actual generator bindings
      desc_ast when is_tuple(desc_ast) ->
        # Convert bindings map to a variable list acceptable to Code.eval_quoted
        var_bindings = Map.to_list(bindings)

        try do
          {evaluated, _} = Code.eval_quoted(desc_ast, var_bindings)
          to_string(evaluated)
        rescue
          _ ->
            # Fallback to simple suffix if evaluation fails
            index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
            "constraint_#{index_str}"
        end

      # If description is nil, generate a generic name
      nil ->
        index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
        "constraint_#{index_str}"
    end
  end

  # Helper function to interpolate variables in constraint descriptions
  defp interpolate_variables_in_description(description, index_vals) do
    # Proper variable interpolation: replace variable placeholders with actual values
    # This should create names like "One queen per diagonal i_1" instead of "One queen per ma1n d1agonal"

    # Common variable names that might appear in descriptions
    variable_names = ["i", "j", "k", "l", "m", "n"]

    # Replace variable names with their corresponding values in a meaningful way
    # Use word boundaries to avoid replacing letters within words
    Enum.reduce(Enum.with_index(variable_names), description, fn {var_name, index}, acc_desc ->
      if index < length(index_vals) do
        value = Enum.at(index_vals, index)
        # Use regex with word boundaries to replace only complete variable names
        # This prevents replacing "i" in "main" -> "mai_1n"
        pattern = ~r/\b#{var_name}\b/
        String.replace(acc_desc, pattern, "#{var_name}_#{value}")
      else
        acc_desc
      end
    end)
  end

  # Import functions from VariableManager
  def parse_generators(generators),
    do: Dantzig.Problem.DSL.VariableManager.parse_generators(generators)

  def generate_combinations_from_parsed_generators(generators),
    do:
      Dantzig.Problem.DSL.VariableManager.generate_combinations_from_parsed_generators(generators)

  def create_bindings(generators, index_vals),
    do: Dantzig.Problem.DSL.VariableManager.create_bindings(generators, index_vals)

  def parse_expression_to_polynomial(expr, bindings, problem),
    do:
      Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(expr, bindings, problem)

  def parse_sum_expression(expr, bindings, problem),
    do: Dantzig.Problem.DSL.ExpressionParser.parse_sum_expression(expr, bindings, problem)

  def normalize_sum_ast(expr), do: Dantzig.Problem.DSL.ExpressionParser.normalize_sum_ast(expr)
end
