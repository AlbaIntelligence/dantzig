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

      # Propagate both name and human description
      constraint =
        cond do
          constraint_name ->
            # When we have a generated name, also attempt to populate description
            updated = %{constraint | name: constraint_name}

            cond do
              is_tuple(description) ->
                var_bindings = Map.to_list(bindings)

                evaluated =
                  try do
                    {val, _} = Code.eval_quoted(description, var_bindings)
                    to_string(val)
                  rescue
                    _ -> nil
                  end

                if evaluated, do: %{updated | description: String.trim(evaluated)}, else: updated

              is_binary(description) ->
                interp_desc =
                  interpolate_variables_in_description(to_string(description), bindings, index_vals)
                  |> String.trim()

                %{updated | description: interp_desc}

              true ->
                updated
            end

          is_tuple(description) ->
            # Evaluate AST description like {:<<>>, ...} using current bindings
            var_bindings = Map.to_list(bindings)

            evaluated =
              try do
                {val, _} = Code.eval_quoted(description, var_bindings)
                to_string(val)
              rescue
                _ -> nil
              end

            if evaluated, do: %{constraint | description: evaluated}, else: constraint

          is_binary(description) ->
            interp_desc =
              interpolate_variables_in_description(to_string(description), bindings, index_vals)
              |> String.trim()

            %{constraint | description: interp_desc}

          true ->
            constraint
        end

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
            :infinity -> :infinity  # Pass :infinity directly, not as polynomial
            _ -> 
              # Try to evaluate as constant first (might be :infinity or a number)
              case Dantzig.Problem.DSL.ExpressionParser.try_evaluate_constant(right_value, bindings) do
                {:ok, :infinity} -> :infinity  # Pass :infinity directly
                {:ok, val} when is_number(val) -> Polynomial.const(val)
                _ -> parse_expression_to_polynomial(right_value, bindings, problem)
              end
          end

        Constraint.new_linear(left_poly, :<=, right_poly)

      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            :infinity -> :infinity  # Pass :infinity directly, not as polynomial
            _ -> 
              # Try to evaluate as constant first (might be :infinity or a number)
              case Dantzig.Problem.DSL.ExpressionParser.try_evaluate_constant(right_value, bindings) do
                {:ok, :infinity} -> :infinity  # Pass :infinity directly
                {:ok, val} when is_number(val) -> Polynomial.const(val)
                _ -> parse_expression_to_polynomial(right_value, bindings, problem)
              end
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
        # Replace any binding keys (like l_name, i, j) with their bound values if present
        interpolated = interpolate_variables_in_description(desc, bindings, index_vals)
        interpolated

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
  defp interpolate_variables_in_description(description, bindings, index_vals) when is_binary(description) do
    # Handle string interpolation syntax like "Variable #{i}"
    # First, check if description contains interpolation syntax
    # Build "#{" using character codes to avoid string interpolation syntax issues
    interpolation_pattern = [35, 123] |> List.to_string()
    result = if String.contains?(description, interpolation_pattern) do
      # This is string interpolation syntax - use string replacement for simple cases
      Enum.reduce(bindings, description, fn {var_atom, value}, acc_desc ->
        var_name = to_string(var_atom)
        # Replace #{var_name} patterns - use simple string replacement
        # Build pattern string by concatenating parts to avoid interpolation syntax issues  
        pattern_str = [35, 123] |> List.to_string() |> Kernel.<>(var_name) |> Kernel.<>(List.to_string([125]))
        String.replace(acc_desc, pattern_str, to_string(value))
      end)
    else
      # Standard string replacement for non-interpolation strings
      # First, replace any named bindings, e.g., l_name -> "calories"
      by_binding =
        Enum.reduce(bindings, description, fn {var_atom, value}, acc_desc ->
          var_name = to_string(var_atom)
          pattern = ~r/\b#{Regex.escape(var_name)}\b/
          String.replace(acc_desc, pattern, to_string(value))
        end)

      # Then, for conventional i/j/k ... placeholders (when numeric), append index values like i_1
      variable_names = ["i", "j", "k", "l", "m", "n"]

      Enum.reduce(Enum.with_index(variable_names), by_binding, fn {var_name, index}, acc_desc ->
        if index < length(index_vals) do
          value = Enum.at(index_vals, index)
          pattern = ~r/\b#{Regex.escape(var_name)}\b/
          String.replace(acc_desc, pattern, "#{var_name}_#{value}")
        else
          acc_desc
        end
      end)
    end
    
    result
  end

  # Handle AST interpolation forms (from transform_description_to_ast)
  defp interpolate_variables_in_description(description_ast, bindings, index_vals) when is_tuple(description_ast) do
    # Handle AST forms like {:<<>>, ...} from string interpolation
    # Convert bindings to keyword list for Code.eval_quoted
    var_bindings = Map.to_list(bindings)
    
    try do
      # Reconstruct evaluable AST (replace normalized atoms with variable references)
      evaluable_ast = reconstruct_evaluable_ast(description_ast, bindings)
      {evaluated, _} = Code.eval_quoted(evaluable_ast, var_bindings)
      to_string(evaluated)
    rescue
      _ ->
        # Fallback: try string replacement
        desc_str = inspect(description_ast)
        interpolate_variables_in_description(desc_str, bindings, index_vals)
    end
  end

  # Reconstruct AST with variable references that Code.eval_quoted can resolve
  defp reconstruct_evaluable_ast(ast, bindings) do
    Macro.prewalk(ast, fn
      # Normalized atom that's in bindings - convert back to variable reference
      atom when is_atom(atom) ->
        if Map.has_key?(bindings, atom) do
          # Create a variable reference that Code.eval_quoted can resolve
          {atom, [], nil}
        else
          atom
        end

      other ->
        other
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
