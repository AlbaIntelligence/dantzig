defmodule Dantzig.Problem.DSL.ExpressionParser.SumProcessing do
  @moduledoc """
  Sum expression processing for DSL.
  
  Handles:
  - For-comprehension expansion in sum/1
  - Variable wildcard expansion
  - Generator binding enumeration
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Polynomial, as: Polynomial

  alias Dantzig.Problem.DSL.ExpressionParser
  alias Dantzig.Problem.DSL.ExpressionParser.ConstantEvaluation
  alias Dantzig.Problem.DSL.ExpressionParser.WildcardExpansion

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
          inner_poly = ExpressionParser.parse_expression_to_polynomial(body, merged_bindings, problem)
          Polynomial.add(acc, inner_poly)
        end)

      {var_name, _, indices}
      when is_list(indices) and is_atom(var_name) and var_name not in [:+, :-, :*, :/, :==, :<=, :>=, :<, :>] ->
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

      # Wildcard arithmetic expression handler
      # Handles expressions like: qty(:_) * foods[:_][nutrient]
      expr ->
        if WildcardExpansion.contains_wildcard?(expr) do
          WildcardExpansion.expand_wildcard_sum(expr, bindings, problem)
        else
          raise ArgumentError, "Unsupported sum expression: #{inspect(expr)}"
        end
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
    domain_values = ConstantEvaluation.evaluate_expression_with_bindings(domain_ast, bindings)

    if not is_list(domain_values) do
      raise ArgumentError,
            "Generator domain must evaluate to a list, got: #{inspect(domain_values)}"
    end

    # For each value in the domain, create a binding and recurse
    Enum.flat_map(domain_values, fn value ->
      new_bindings = Map.put(bindings, var_name, value)
      enumerate_for_bindings(rest, new_bindings)
    end)
  end

  def enumerate_for_bindings([_other | rest], bindings) do
    # Ignore filters and other for-comprehension clauses for now
    enumerate_for_bindings(rest, bindings)
  end

  # Normalize sum AST to handle different sum/1 call patterns
  def normalize_sum_ast(expr) do
    case expr do
      {:sum, _, [arg]} -> arg
      {:sum, _, args} when is_list(args) -> List.first(args)
      other -> other
    end
  end
end
