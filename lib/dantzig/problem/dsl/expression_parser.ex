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
                        """
                        Cannot use non-numeric value in arithmetic expression: #{inspect(other)}

                        Arithmetic operations (+, -, *, /) require numeric values or polynomials.
                        Got: #{inspect(other)}

                        Common causes:
                        1. Using a string or atom where a number is expected
                        2. Accessing an undefined variable or constant
                        3. Using a generator variable outside its scope

                        Example of correct usage:
                          x(i) + y(j)        # Adding variables
                          x(i) * 2.5         # Multiplying by a number
                          cost[i] * x(i)     # Using constants from model_parameters
                        """
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
            # Guard ensures v is a number - convert to float then negate
            v_float = if is_integer(v), do: :erlang.float(v), else: v
            # Explicit float operation - type checker needs literal float
            neg_val = -1.0 * v_float
            Polynomial.add(p, Polynomial.const(neg_val))

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
            # Guard ensures v is a number - convert to float explicitly
            v_float = case v do
              n when is_integer(n) -> :erlang.float(n)
              n when is_float(n) -> n
            end
            Polynomial.scale(p, 1.0 / v_float)

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
            raise ArgumentError,
                  """
                  Unsupported arithmetic operation: #{op}

                  Operation: #{op}
                  Left operand: #{inspect(left)}
                  Right operand: #{inspect(right)}

                  Supported arithmetic operations in DSL expressions:
                  - Addition (+): x(i) + y(j), x(i) + 5.0
                  - Subtraction (-): x(i) - y(j), x(i) - 5.0
                  - Multiplication (*): x(i) * 2.0, cost[i] * x(i)
                  - Division (/): x(i) / 2.0

                  Note: Division by variables is not supported in linear programming.
                  Only division by constants (numbers) is allowed.

                  Example of correct usage:
                    constraints([i <- 1..n], x(i) + y(i) <= 10)
                    constraints([i <- 1..n], cost[i] * x(i) <= budget)
                  """
        end

      # Simple variable access: {var_name, _, nil} (no indices)
      {var_name, _, nil} when is_atom(var_name) or is_binary(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        # Check if this is a base variable name that has indexed variants
        var_map = Problem.get_variables_nd(problem, var_name_str)

        if var_map do
          # This is a base variable name with indexed variants (e.g., "qty" with "qty_chicken", "qty_hamburger")
          # Return the sum of all indexed variants
          Enum.reduce(var_map, Polynomial.const(0), fn {_key, poly}, acc ->
            Polynomial.add(acc, poly)
          end)
        else
          # Check for simple variables (no indices)
          var_def = Problem.get_variable(problem, var_name_str)

          if var_def do
            Polynomial.variable(var_name_str)
          else
            raise ArgumentError,
                  """
                  Undefined variable: #{var_name_str}

                  To fix this:
                  1. Make sure you've defined the variable using `variables("#{var_name_str}", ...)` in your Problem.define block
                  2. Check for typos in the variable name
                  3. If using indexed variables (e.g., x(i)), ensure the indices match your generator variables

                  Example:
                    Problem.define do
                      variables("#{var_name_str}", [i <- 1..n], :continuous)
                      constraints([i <- 1..n], #{var_name_str}(i) <= 10)
                    end
                  """
          end
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
      {var_name, _meta, _context}
      when is_atom(var_name) and
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
                      """
                      Unsupported expression in constraint/objective: #{inspect(expr)}

                      The expression #{inspect(var_name)} was evaluated as a constant from model_parameters,
                      but it cannot be used directly in a constraint or objective expression.

                      If #{inspect(var_name)} is meant to be a variable:
                        1. Define it using `variables("#{var_name}", ...)` in your Problem.define block
                        2. Use it with proper indexing: #{var_name}(i) or #{var_name}(i, j)

                      If #{inspect(var_name)} is meant to be a constant:
                        1. Access it directly by name in expressions: #{var_name}
                        2. Use it in arithmetic: cost[i] * x(i) where cost is from model_parameters

                      Example:
                        Problem.define model_parameters: %{max_val: 10} do
                          variables("x", [i <- 1..n], :continuous)
                          constraints([i <- 1..n], x(i) <= max_val)  # max_val from model_parameters
                        end
                      """

              :error ->
                raise ArgumentError,
                      """
                      Cannot evaluate expression: #{inspect(expr)}

                      The expression #{inspect(var_name)} could not be evaluated as:
                      - A variable (not found in problem variables)
                      - A constant from model_parameters (not found in model_parameters map)

                      To fix this:
                      1. If #{inspect(var_name)} should be a variable:
                         - Define it using `variables("#{var_name}", ...)` before using it
                         - Check for typos in the variable name

                      2. If #{inspect(var_name)} should be a constant:
                         - Add it to model_parameters: `Problem.define model_parameters: %{#{var_name}: value} do`
                         - Or use a literal value instead

                      Example:
                        Problem.define model_parameters: %{n: 10} do
                          variables("x", [i <- 1..n], :continuous)
                          constraints([i <- 1..n], x(i) <= 10)
                        end
                      """
            end
          end
        else
          # No problem context - treat as variable name (for backward compatibility)
          Polynomial.variable(var_name_str)
        end

      # Handle struct field access after map/list access (e.g., items_dict[item].weight)
      # Pattern: {{:., meta}, [Access.get_result, field_atom], []}
      {{:., _, [container_ast, field_atom]}, _, []} when is_atom(field_atom) ->
        # Evaluate the container (which might be an Access.get result)
        expr_with_field = {{:., [], [container_ast, field_atom]}, [], []}

        case try_evaluate_constant(expr_with_field, bindings) do
          {:ok, val} when is_number(val) ->
            Polynomial.const(val)

          {:ok, :infinity} ->
            # Allow :infinity for constraint bounds (handled by constraint manager)
            Polynomial.const(:infinity)

          {:ok, non_numeric_val} ->
            raise ArgumentError,
                  """
                  Constant access expression evaluated to non-numeric value: #{inspect(expr_with_field)} => #{inspect(non_numeric_val)}

                  In constraint/objective expressions, constants from model_parameters must evaluate to numbers.
                  Got: #{inspect(non_numeric_val)}

                  Common causes:
                  1. Accessing a non-numeric field from a map/struct (e.g., items_dict[item].name instead of items_dict[item].weight)
                  2. The constant in model_parameters is not a number (e.g., it's a string or list)

                  Example of correct usage:
                    # In model_parameters: %{items: [%{weight: 5.0, name: "item1"}]}
                    constraints([i <- 1..n], x(i) * items[i].weight <= 10)  # ✓ weight is numeric
                    # NOT: constraints([i <- 1..n], x(i) * items[i].name <= 10)  # ✗ name is string
                  """

          :error ->
            raise ArgumentError,
                  """
                  Cannot evaluate constant access expression: #{inspect(expr_with_field)}

                  Ensure:
                  1. The constant exists in model_parameters
                  2. All indices are valid (within range for lists, keys exist for maps)
                  3. Generator variables used in indices are bound (e.g., i <- 1..n)

                  Example:
                    Problem.define model_parameters: %{costs: [10, 20, 30]} do
                      variables("x", [i <- 1..3], :continuous)
                      constraints([i <- 1..3], x(i) * costs[i] <= 100)  # costs[i] accesses model_parameters
                    end
                  """
        end

      # Handle Access.get AST nodes (e.g., multiplier[i], cost[worker][task])
      # Single level: {{:., _, [Access, :get]}, _, [container_ast, key_ast]}
      # Nested: {{:., _, [Access, :get]}, _, [{{:., _, [Access, :get]}, _, [container, key1]}, key2]}
      # The key itself might also be an Access.get expression (e.g., foods_dict[food][nutrient_to_atom[limit]])
      {{:., _, [Access, :get]}, _, _} = access_expr ->
        # Recursively evaluate nested Access.get expressions using evaluate_expression_with_bindings
        # which handles nested Access.get correctly
        case try_evaluate_constant(access_expr, bindings) do
          {:ok, val} when is_number(val) ->
            Polynomial.const(val)

          {:ok, nil} ->
            raise ArgumentError,
                  "Cannot evaluate constant access expression: #{inspect(access_expr)}. " <>
                    "The expression evaluated to nil. Ensure the constant exists in model_parameters and indices are valid."

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
            case eval_with_env(atom) do
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
        resolved_key =
          case key_ast do
            # Check if this is a bare atom that should be treated as a literal key
            # First handle bare atoms (like :calories)
            atom when is_atom(atom) and not is_map_key(bindings, atom) ->
              # This is a bare atom that's not a generator variable - treat as literal key
              atom

            # Handle AST node atoms (like {:calories, [], Elixir})
            {atom_name, _, _} when is_atom(atom_name) ->
              # Check if this atom exists as a generator variable in bindings
              # If it exists, it's a generator variable - resolve it
              # If it doesn't exist, it's a literal atom - use it as-is
              case Map.fetch(bindings, atom_name) do
                {:ok, value} when is_binary(value) or is_atom(value) ->
                  # This is a generator variable, use its value
                  value

                _ ->
                  # Not a generator variable - treat as literal atom
                  atom_name
              end

            # For other expressions, evaluate normally
            _ ->
              evaluate_expression_with_bindings(key_ast, bindings)
          end

        key = resolved_key

        cond do
          is_map(container) ->
            case resolved_key do
              k when is_binary(k) ->
                # Try string key first, then atom key
                result = Map.get(container, k) || Map.get(container, safe_to_atom(k))

                if is_nil(result) do
                  raise ArgumentError,
                        "Key '#{k}' not found in map. Available keys: #{inspect(Map.keys(container))}"
                end

                result

              k when is_atom(k) ->
                # Try atom key first, then string key
                result = Map.get(container, k) || Map.get(container, Atom.to_string(k))

                if is_nil(result) do
                  raise ArgumentError,
                        "Key '#{k}' not found in map. Available keys: #{inspect(Map.keys(container))}"
                end

                result

              _ ->
                result = Map.get(container, resolved_key)

                if is_nil(result) do
                  raise ArgumentError,
                        "Key #{inspect(resolved_key)} not found in map. Available keys: #{inspect(Map.keys(container))}"
                end

                result
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
            raise ArgumentError,
                  "Cannot access element with key #{inspect(key)} from non-map/non-list container: #{inspect(container)}"
        end

      # Variables: prefer loop bindings, then env
      {name, _, _ctx} = var when is_atom(name) ->
        case Map.fetch(bindings, name) do
          {:ok, v} ->
            v

          :error ->
            case eval_with_env(var) do
              nil ->
                raise ArgumentError,
                      "Cannot evaluate variable '#{name}' - not found in model_parameters/environment"

              value ->
                value
            end
        end

      {:__aliases__, _, _} = quoted ->
        case eval_with_env(quoted) do
          nil -> raise ArgumentError, "Cannot evaluate expression: #{inspect(quoted)}"
          value -> value
        end

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

        # Merge outer bindings with inner generator bindings to ensure both are available
        enumerate_for_bindings(gens, bindings)
        |> Enum.reduce(Polynomial.const(0), fn local_bindings, acc ->
          # Merge outer bindings with inner bindings (inner takes precedence)
          merged_bindings = Map.merge(bindings, local_bindings)
          inner_poly = parse_expression_to_polynomial(body, merged_bindings, problem)
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
  def enumerate_for_bindings([], bindings), do: [bindings]

  def enumerate_for_bindings([{:<-, _, [var, domain_ast]} | rest], bindings) do
    # Extract the atom name from the variable AST node
    # var can be {:food, [], Elixir} (AST node) or :food (atom)
    var_name =
      case var do
        {name, _, _} when is_atom(name) -> name
        name when is_atom(name) -> name
        _ -> raise ArgumentError, "Invalid generator variable: #{inspect(var)}"
      end

    # Use evaluate_expression_with_bindings to check environment for constants
    domain_values = evaluate_expression_with_bindings(domain_ast, bindings)

    Enum.flat_map(domain_values, fn v ->
      enumerate_for_bindings(rest, Map.put(bindings, var_name, v))
    end)
  end

  # Skip unsupported items (e.g., filters) for now
  def enumerate_for_bindings([_other | rest], bindings) do
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
    env = Process.get(:dantzig_eval_env)

    case env do
      env_list when is_list(env_list) ->
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
          # Try Keyword.fetch first (for keyword list format)
          case Keyword.fetch(env_list, atom_to_lookup) do
            {:ok, value} ->
              value

            :error ->
              # Try Keyword.get as fallback (handles duplicate keys)
              Keyword.get(env_list, atom_to_lookup)
          end
        else
          # For non-atom expressions, use Code.eval_quoted
          try do
            {value, _} = Code.eval_quoted(quoted, env_list)
            value
          rescue
            _ -> nil
          end
        end

      _ ->
        nil
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
  def try_evaluate_constant(expr, bindings) do
    try do
      val = evaluate_expression_with_bindings(expr, bindings)
      {:ok, val}
    rescue
      e in ArgumentError ->
        # Re-raise with more context for debugging nested Access.get issues
        raise ArgumentError,
              "Error evaluating expression #{inspect(expr)}: #{Exception.message(e)}"

      Protocol.UndefinedError ->
        :error
    end
  end
end
