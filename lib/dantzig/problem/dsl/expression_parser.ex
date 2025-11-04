defmodule Dantzig.Problem.DSL.ExpressionParser do
  @moduledoc """
  Parses and evaluates expressions for the Dantzig DSL.

  This module handles:
  - Polynomial expression parsing and construction
  - Arithmetic expression evaluation
  - Variable access pattern resolution
  - Sum expression processing
  - Complex expression normalization
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Polynomial, as: Polynomial

  def parse_expression_to_polynomial(expr, bindings, problem) do
    expr =
      expr
      |> normalize_sum_ast()
      |> normalize_polynomial_ops()

    case expr do
      {:sum, [], [sum_expr]} ->
        parse_sum_expression(sum_expr, bindings, problem)

      {:sum, sum_expr} ->
        parse_sum_expression(sum_expr, bindings, problem)

      # Unary minus (must come before binary arithmetic)
      {:-, _meta, [v]} ->
        # Check if this is a variable access pattern (e.g., qty(food))
        case v do
          {var_name, _, indices} when is_atom(var_name) and is_list(indices) ->
            # This is a variable access pattern, parse it directly
            case parse_expression_to_polynomial(v, bindings, problem) do
              %Polynomial{} = p ->
                Polynomial.scale(p, -1)

              other ->
                raise ArgumentError,
                      "Unsupported unary minus on variable access: #{inspect(other)}"
            end

          _ ->
            # Try to evaluate as a number first
            case evaluate_expression_with_bindings(v, bindings) do
              val when is_number(val) ->
                Polynomial.const(-val)

              _ ->
                case parse_expression_to_polynomial(v, bindings, problem) do
                  %Polynomial{} = p -> Polynomial.scale(p, -1)
                  other -> raise ArgumentError, "Unsupported unary minus: #{inspect(other)}"
                end
            end
        end

      # Arithmetic between expressions
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_poly_or_val =
          case parse_expression_to_polynomial(left, bindings, problem) do
            %Polynomial{} = p ->
              p

            _ ->
              case evaluate_expression_with_bindings(left, bindings) do
                v when is_number(v) ->
                  Polynomial.const(v)

                nil ->
                  Polynomial.const(0)

                other ->
                  raise ArgumentError,
                        "Cannot use non-numeric value in arithmetic: #{inspect(other)}"
              end
          end

        right_poly_or_val =
          case parse_expression_to_polynomial(right, bindings, problem) do
            %Polynomial{} = p ->
              p

            _ ->
              case evaluate_expression_with_bindings(right, bindings) do
                v when is_number(v) ->
                  Polynomial.const(v)

                nil ->
                  Polynomial.const(0)

                other ->
                  raise ArgumentError,
                        "Cannot use non-numeric value in arithmetic: #{inspect(other)}"
              end
          end

        case {op, left_poly_or_val, right_poly_or_val} do
          {:+, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, p2)

          {:+, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(v))

          {:+, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), p)

          {:-, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, Polynomial.scale(p2, -1))

          {:-, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(-v))

          {:-, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), Polynomial.scale(p, -1))

          {:*, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, %Polynomial{} = p1, %Polynomial{} = p2} ->
            # Handle polynomial * polynomial (e.g., variable * constant polynomial)
            # This should only happen when one is a constant polynomial
            cond do
              Polynomial.constant?(p1) ->
                {_non_constant, constant_val} = Polynomial.split_constant(p1)
                Polynomial.scale(p2, constant_val)

              Polynomial.constant?(p2) ->
                {_non_constant, constant_val} = Polynomial.split_constant(p2)
                Polynomial.scale(p1, constant_val)

              true ->
                raise ArgumentError,
                      "Multiplication of non-constant polynomials is not supported: #{inspect({p1, p2})}"
            end

          {:/, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.scale(p, 1.0 / v)

          {:/, %Polynomial{} = p1, %Polynomial{} = p2} ->
            # Handle polynomial / polynomial (e.g., variable / constant polynomial)
            # This should only happen when the second is a constant polynomial
            if Polynomial.constant?(p2) do
              {_non_constant, constant_val} = Polynomial.split_constant(p2)
              Polynomial.scale(p1, 1.0 / constant_val)
            else
              raise ArgumentError,
                    "Division of non-constant polynomials is not supported: #{inspect({p1, p2})}"
            end

          _ ->
            raise ArgumentError, "Unsupported arithmetic: #{inspect({op, left, right})}"
        end

      # Simple variable access: {var_name, _, nil} (no indices)
      {var_name, _, nil} when is_atom(var_name) or is_binary(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        # For simple variables, check if they exist in the problem
        var_def = Problem.get_variable(problem, var_name_str)

        if var_def do
          Polynomial.variable(var_name_str)
        else
          raise ArgumentError, "Undefined variable: #{var_name_str}"
        end

      # Generator-based variable access: {var_name, _, indices} with indices
      {var_name, _, indices} when is_list(indices) and is_atom(var_name) ->
        resolved_indices =
          Enum.map(indices, fn
            :_ ->
              :_

            {var_atom, _, _} = var_ast when is_atom(var_atom) ->
              # Find the binding by matching the atom name, ignoring line/column info
              Enum.find_value(bindings, fn {key, value} ->
                case key do
                  {^var_atom, _, _} -> value
                  _ -> nil
                end
              end) || var_ast

            var when is_atom(var) ->
              # Try to find the binding by atom, or by full AST node
              Map.get(
                bindings,
                var,
                Enum.find_value(bindings, fn {key, _value} ->
                  case key do
                    {^var, _, _} -> true
                    _ -> false
                  end
                end) || var
              )

            val ->
              val
          end)

        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        var_map = Problem.get_variables_nd(problem, var_name_str)

        cond do
          is_map(var_map) and Enum.any?(resolved_indices, &(&1 == :_)) ->
            matching_vars =
              Enum.filter(var_map, fn {key, _mono} ->
                key_list = Tuple.to_list(key)

                Enum.zip_with(resolved_indices, key_list, fn p, a ->
                  if p == :_, do: true, else: p == a
                end)
                |> Enum.all?()
              end)

            Enum.reduce(matching_vars, Polynomial.const(0), fn {_k, mono}, acc ->
              Polynomial.add(acc, mono)
            end)

          is_map(var_map) ->
            key = List.to_tuple(resolved_indices)
            Map.get(var_map, key, Polynomial.const(0))

          true ->
            Polynomial.const(0)
        end

      val when is_number(val) ->
        Polynomial.const(val)

      # Handle bare atoms that might be variable names (when variable not in scope)
      atom when is_atom(atom) and not is_nil(problem) ->
        var_name_str = to_string(atom)
        # Check if this atom corresponds to a variable name in the problem
        var_def = Problem.get_variable(problem, var_name_str)
        
        if var_def do
          Polynomial.variable(var_name_str)
        else
          # Not a variable - try to evaluate as a constant from model_parameters/environment
          case try_evaluate_constant(expr, bindings) do
            {:ok, val} when is_number(val) ->
              Polynomial.const(val)
            
            {:ok, _other} ->
              raise ArgumentError, 
                "Unsupported expression: #{inspect(expr)}. " <>
                "If #{inspect(atom)} is meant to be a variable, ensure it was created with variables() first."
            
            :error ->
              raise ArgumentError, 
                "Unsupported expression: #{inspect(expr)}. " <>
                "If #{inspect(atom)} is meant to be a variable, ensure it was created with variables() first."
          end
        end

      # Handle variable reference AST nodes like {:queen2d_1_1, [], Elixir} (when variable not in scope)
      {var_name, _meta, context} when is_atom(var_name) and 
                                      tuple_size(expr) == 3 and
                                      var_name not in [:+, :-, :*, :/, :==, :<=, :>=, :!=, :<, :>, :., :|>, :..] ->
        var_name_str = to_string(var_name)
        
        # If problem is provided, check if this corresponds to a variable name
        if not is_nil(problem) do
          var_def = Problem.get_variable(problem, var_name_str)
          
          if var_def do
            Polynomial.variable(var_name_str)
          else
            # Not a variable - try to evaluate as a constant from model_parameters/environment
            case try_evaluate_constant(expr, bindings) do
              {:ok, val} when is_number(val) ->
                Polynomial.const(val)
              
              {:ok, _other} ->
                raise ArgumentError, 
                  "Unsupported expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
              
              :error ->
                raise ArgumentError, 
                  "Unsupported expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
            end
          end
        else
          # No problem context - treat as variable name (for backward compatibility)
          Polynomial.variable(var_name_str)
        end

      # Handle Access.get AST nodes (e.g., multiplier[i], cost[worker][task])
      # Single level: {{:., _, [Access, :get]}, _, [container_ast, key_ast]}
      # Nested: {{:., _, [Access, :get]}, _, [{{:., _, [Access, :get]}, _, [container, key1]}, key2]}
      {{:., _, [Access, :get]}, _, _} = access_expr ->
        case try_evaluate_constant(access_expr, bindings) do
          {:ok, val} when is_number(val) ->
            Polynomial.const(val)
          
          {:ok, non_numeric_val} ->
            raise ArgumentError,
              "Constant access expression evaluated to non-numeric value: #{inspect(access_expr)} => #{inspect(non_numeric_val)}"
          
          :error ->
            raise ArgumentError,
              "Cannot evaluate constant access expression: #{inspect(access_expr)}. " <>
              "Ensure the constant exists in model_parameters and indices are valid."
        end

      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(expr)}"
    end
  end

  # Normalize Dantzig.Polynomial operator calls (from Polynomial.algebra) back to Kernel ops
  defp normalize_polynomial_ops(ast) do
    Macro.prewalk(ast, fn
      {{:., meta1, [Dantzig.Polynomial, :add]}, meta2, [l, r]} ->
        {:+, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [Dantzig.Polynomial, :subtract]}, meta2, [l, r]} ->
        {:-, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [Dantzig.Polynomial, :multiply]}, meta2, [l, r]} ->
        {:*, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [Dantzig.Polynomial, :divide]}, meta2, [l, r]} ->
        {:/, merge_meta(meta1, meta2), [l, r]}

      # Handle __aliases__ form for the module
      {{:., meta1, [{:__aliases__, _, [:Dantzig, :Polynomial]}, :add]}, meta2, [l, r]} ->
        {:+, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [{:__aliases__, _, [:Dantzig, :Polynomial]}, :subtract]}, meta2, [l, r]} ->
        {:-, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [{:__aliases__, _, [:Dantzig, :Polynomial]}, :multiply]}, meta2, [l, r]} ->
        {:*, merge_meta(meta1, meta2), [l, r]}

      {{:., meta1, [{:__aliases__, _, [:Dantzig, :Polynomial]}, :divide]}, meta2, [l, r]} ->
        {:/, merge_meta(meta1, meta2), [l, r]}

      other ->
        other
    end)
  end

  defp merge_meta(m1, m2) do
    case {m1, m2} do
      {m1, m2} when is_list(m1) and is_list(m2) -> Keyword.merge(m1, m2)
      {m1, _} -> m1
    end
  end

  # Evaluate an arbitrary quoted expression to a literal value, using DSL for-loop bindings first
  defp evaluate_expression_with_bindings(expr, bindings) do
    case expr do
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      {:.., _, [from_ast, to_ast]} ->
        from_val = evaluate_expression_with_bindings(from_ast, bindings)
        to_val = evaluate_expression_with_bindings(to_ast, bindings)
        Enum.to_list(from_val..to_val)

      list when is_list(list) ->
        list

      literal when is_number(literal) or is_atom(literal) ->
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

      # Access.get handling with recursion
      {{:., _, [Access, :get]}, _, [container_ast, key_ast]} ->
        container = evaluate_expression_with_bindings(container_ast, bindings)
        key = evaluate_expression_with_bindings(key_ast, bindings)

        cond do
          is_map(container) ->
            case key do
              k when is_binary(k) -> Map.get(container, k) || Map.get(container, safe_to_atom(k))
              _ -> Map.get(container, key)
            end

          is_list(container) ->
            case container do
              # List of maps (struct-like objects)
              [%{} | _] ->
                Enum.find_value(container, fn
                  %{} = m ->
                    cond do
                      Map.has_key?(m, key) -> Map.get(m, key)
                      Map.has_key?(m, :name) and Map.get(m, :name) == key -> m
                      Map.has_key?(m, "name") and Map.get(m, "name") == key -> m
                      true -> nil
                    end

                  _ ->
                    nil
                end)

              # Regular list with integer indexing
              _ when is_list(container) ->
                case key do
                  idx when is_integer(idx) ->
                    # Convert to 1-based indexing if needed (Elixir uses 0-based)
                    # Check if we're accessing with 1-based index (common in DSL)
                    cond do
                      idx >= 1 and idx <= length(container) ->
                        Enum.at(container, idx - 1)
                      idx >= 0 and idx < length(container) ->
                        Enum.at(container, idx)
                      true ->
                        nil
                    end
                  
                  _ ->
                    nil
                end
            end

          true ->
            nil
        end

      # Handle bare atoms that might be constants from environment
      # This must come before the AST node case to match bare atoms first
      atom when is_atom(atom) ->
        # First check bindings (for generator variables)
        case Map.fetch(bindings, atom) do
          {:ok, v} -> v
          :error -> eval_with_env(atom)
        end

      # Variables: prefer loop bindings, then env
      {name, _, _ctx} = var when is_atom(name) ->
        case Map.fetch(bindings, name) do
          {:ok, v} -> v
          :error -> eval_with_env(var)
        end

      {:__aliases__, _, _} = quoted ->
        eval_with_env(quoted)

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  def parse_sum_expression(expr, bindings, problem) do
    expr = normalize_sum_ast(expr)

    case expr do
      # Handle Elixir for-comprehension inside sum/1
      {:for, _, parts} when is_list(parts) ->
        {gens, body} =
          case List.last(parts) do
            [do: do_body] -> {Enum.slice(parts, 0, length(parts) - 1), do_body}
            _ -> {parts, nil}
          end

        if body == nil do
          raise ArgumentError, "for-comprehension in sum/1 must have a do: ... block"
        end

        enumerate_for_bindings(gens, bindings)
        |> Enum.reduce(Polynomial.const(0), fn local_bindings, acc ->
          inner_poly = parse_expression_to_polynomial(body, local_bindings, problem)
          Polynomial.add(acc, inner_poly)
        end)

      {var_name, _, indices} when is_list(indices) and is_atom(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        var_map = Problem.get_variables_nd(problem, var_name_str)

        if var_map do
          resolved_indices =
            Enum.map(indices, fn
              :_ ->
                :_

              {var_atom, _, _} when is_atom(var_atom) ->
                Map.get(bindings, var_atom, {var_atom, [], nil})

              var when is_atom(var) ->
                Map.get(bindings, var, var)

              val ->
                val
            end)

          matching =
            Enum.filter(var_map, fn {key, _m} ->
              key_list = Tuple.to_list(key)

              Enum.zip_with(resolved_indices, key_list, fn p, a ->
                if p == :_, do: true, else: p == a
              end)
              |> Enum.all?()
            end)

          Enum.reduce(matching, Polynomial.const(0), fn {_k, mono}, acc ->
            Polynomial.add(acc, mono)
          end)
        else
          Polynomial.const(0)
        end

      _ ->
        raise ArgumentError, "Unsupported sum expression: #{inspect(expr)}"
    end
  end

  # Expand a list of for-comprehension generators (and ignore filters for now)
  defp enumerate_for_bindings([], bindings), do: [bindings]

  defp enumerate_for_bindings([{:<-, _, [var, domain_ast]} | rest], bindings) do
    # Use evaluate_expression_with_bindings to check environment for constants
    domain_values = evaluate_expression_with_bindings(domain_ast, bindings)

    Enum.flat_map(domain_values, fn v ->
      enumerate_for_bindings(rest, Map.put(bindings, var, v))
    end)
  end

  # Skip unsupported items (e.g., filters) for now
  defp enumerate_for_bindings([_other | rest], bindings) do
    enumerate_for_bindings(rest, bindings)
  end

  def normalize_sum_ast(expr) do
    case expr do
      {{:., _, [Dantzig.Problem.DSL, :sum]}, _, [inner]} -> {:sum, [], [normalize_sum_ast(inner)]}
      {:sum, _, _} = s -> s
      {op, meta, args} when is_list(args) -> {op, meta, Enum.map(args, &normalize_sum_ast/1)}
      other -> other
    end
  end

  # Expression evaluation for generators (imported from VariableManager)
  def evaluate_expression(expr), do: Dantzig.Problem.DSL.VariableManager.evaluate_expression(expr)

  # Environment evaluation helper
  defp eval_with_env(quoted) do
    case Process.get(:dantzig_eval_env) do
      env when is_list(env) ->
        # Handle bare atoms by looking them up directly
        # Handle AST nodes like {:workers, [], nil} by extracting the atom
        atom_to_lookup =
          case quoted do
            atom when is_atom(atom) ->
              atom
            
            {atom, _, _} when is_atom(atom) ->
              atom
            
            # For other expressions, evaluate as quoted expression
            _ ->
              nil
          end
        
        if atom_to_lookup do
          Keyword.get(env, atom_to_lookup) || 
            raise ArgumentError, "Cannot evaluate atom '#{atom_to_lookup}' - not found in model_parameters/environment"
        else
          {value, _} = Code.eval_quoted(quoted, env)
          value
        end

      _ ->
        raise ArgumentError, "Cannot evaluate expression without environment: #{inspect(quoted)}"
    end
  end

  # Safe atom conversion
  defp safe_to_atom(bin) when is_binary(bin) do
    try do
      String.to_existing_atom(bin)
    rescue
      ArgumentError -> nil
    end
  end

  # Try to evaluate an expression as a constant from model_parameters/environment
  # Returns {:ok, value} if successful, :error if not
  defp try_evaluate_constant(expr, bindings) do
    try do
      val = evaluate_expression_with_bindings(expr, bindings)
      {:ok, val}
    rescue
      ArgumentError -> :error
      Protocol.UndefinedError -> :error
    end
  end
end
