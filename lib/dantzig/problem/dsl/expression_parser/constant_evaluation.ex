defmodule Dantzig.Problem.DSL.ExpressionParser.ConstantEvaluation do
  @moduledoc """
  Constant evaluation for DSL expressions.

  Handles evaluation of expressions to literal values, including:
  - Generator variable bindings
  - Model parameter lookup
  - Nested map access
  - Range evaluation
  """

  # Evaluate an arbitrary quoted expression to a literal value, using DSL for-loop bindings first
  def evaluate_expression_with_bindings(expr, bindings) do
    case expr do
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      {:.., _, [from_ast, to_ast]} ->
        from_val = evaluate_expression_with_bindings(from_ast, bindings)
        to_val = evaluate_expression_with_bindings(to_ast, bindings)
        Enum.to_list(from_val..to_val)

      list when is_list(list) ->
        list

      # Handle string literals (binaries)
      binary when is_binary(binary) ->
        binary

      # Handle variable AST nodes like {:food, [], Elixir} (from generators)
      # This MUST come before the bare atom case to handle generator variables correctly
      {name, _, _ctx} when is_atom(name) ->
        # First check bindings (for generator variables like 'food' from 'for food <- food_names')
        case Map.fetch(bindings, name) do
          {:ok, v} ->
            v

          :error ->
            # If not in bindings, try the environment (model parameters + caller bindings)
            case eval_with_env({name, [], nil}) do
              nil ->
                raise ArgumentError,
                      "Cannot evaluate variable '#{name}' - not found in model_parameters/environment"

              value ->
                value
            end
        end

      # Handle bare atoms that might be constants from environment
      # This MUST come after the AST node case to allow constant lookup
      atom when is_atom(atom) ->
        # First check bindings (for generator variables)
        case Map.fetch(bindings, atom) do
          {:ok, v} ->
            v

          :error ->
            case eval_with_env({atom, [], nil}) do
              nil ->
                raise ArgumentError,
                      "Cannot evaluate atom '#{atom}' - not found in model_parameters/environment"

              value ->
                value
            end
        end

      # Literal numbers (atoms handled above)
      literal when is_number(literal) ->
        literal

      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        l = evaluate_expression_with_bindings(left, bindings)
        r = evaluate_expression_with_bindings(right, bindings)

        case op do
          :+ -> l + r
          :- -> l - r
          :* -> l * r
          :/ -> l / r
        end

      # Struct field access (e.g., items_dict[item].weight)
      # Pattern: {{:., meta}, [container_result, field_atom]} where container_result might be Access.get result
      {{:., _, [container_ast, field_atom]}, _, []} when is_atom(field_atom) ->
        container = evaluate_expression_with_bindings(container_ast, bindings)

        cond do
          is_map(container) ->
            # Try atom key first, then string key
            Map.get(container, field_atom) || Map.get(container, to_string(field_atom))

          true ->
            nil
        end

      # Access.get handling with recursion
      # Handles nested Access.get: container[key] where container and/or key might themselves be Access.get expressions
      {{:., _, [Access, :get]}, _, [container_ast, key_ast]} ->
        # Recursively evaluate container (might be nested Access.get like foods_dict[food])
        container = evaluate_expression_with_bindings(container_ast, bindings)

        # Handle key evaluation - distinguish between literal atoms and generator variables
        key =
          case key_ast do
            # Generator variable (e.g., 'nutrient' from 'for nutrient <- nutrient_names')
            {key_name, _, _ctx} when is_atom(key_name) ->
              # First check bindings (generator variables take precedence)
              case Map.fetch(bindings, key_name) do
                {:ok, bound_value} ->
                  bound_value

                :error ->
                  # Not in bindings, try as constant from environment
                  case eval_with_env({key_name, [], nil}) do
                    nil -> key_name
                    val -> val
                  end
              end

            # Bare atom key (might be constant or generator variable)
            key_atom when is_atom(key_atom) ->
              case Map.fetch(bindings, key_atom) do
                {:ok, bound_value} -> bound_value
                :error -> eval_with_env(key_atom) || key_atom
              end

            # String literal key
            key_str when is_binary(key_str) ->
              key_str

            # Other key expression - evaluate recursively
            _ ->
              evaluate_expression_with_bindings(key_ast, bindings)
          end

        # Access the container with the evaluated key
        cond do
          is_map(container) ->
            # Try atom key first, then string key (for flexibility)
            case Map.get(container, key) do
              nil when is_atom(key) -> Map.get(container, to_string(key))
              nil when is_binary(key) -> Map.get(container, safe_to_atom(key))
              value -> value
            end

          is_list(container) and is_integer(key) ->
            Enum.at(container, key)

          true ->
            nil
        end

      # Tuple access (e.g., {a, b, c}[1])
      {:__block__, _, [tuple_expr]} when is_tuple(tuple_expr) ->
        tuple_expr

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  defp eval_with_env(quoted) do
    env = Process.get(:dantzig_eval_env)

    if env do
      try do
        Code.eval_quoted(quoted, env)
        |> elem(0)
      rescue
        _ -> nil
      catch
        _ -> nil
      end
    else
      nil
    end
  end

  def safe_to_atom(bin) when is_binary(bin) do
    try do
      String.to_existing_atom(bin)
    rescue
      ArgumentError ->
        String.to_atom(bin)
    end
  end

  # Try to evaluate an expression as a constant (from model_parameters or environment)
  # Returns {:ok, value} if successful, :error if not a constant
  def try_evaluate_constant(expr, bindings) do
    try do
      value = evaluate_expression_with_bindings(expr, bindings)
      {:ok, value}
    rescue
      ArgumentError ->
        :error

      Protocol.UndefinedError ->
        :error
    end
  end
end
