defmodule Dantzig.Problem.DSL.ExpressionParser.WildcardExpansion do
  @moduledoc """
  Wildcard expansion for nested map access in DSL expressions.
  
  Supports concise wildcard syntax like:
    sum(qty(:_) * foods[:_][nutrient])
  Instead of verbose for comprehensions:
    sum(for food <- food_names, do: qty(food) * foods[food][nutrient])
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Polynomial, as: Polynomial

  # Detect if :_ appears anywhere in the AST
  def contains_wildcard?(expr) do
    {_, found?} =
      Macro.traverse(
        expr,
        false,
        fn node, acc -> {node, acc or node == :_} end,
        fn node, acc -> {node, acc} end
      )

    found?
  end

  # Expand sum(...) when the body contains :_
  def expand_wildcard_sum(expr, bindings, problem) do
    domain = resolve_wildcard_domain(expr, bindings, problem)

    Enum.reduce(domain, Polynomial.const(0), fn value, acc ->
      inst_expr = replace_wildcards(expr, value)
      # Use the parent module to avoid circular dependency
      term_poly = Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(inst_expr, bindings, problem)
      Polynomial.add(acc, term_poly)
    end)
  end

  # Infer the wildcard domain from:
  # - variables with :_ in their indices (e.g., qty(:_))
  # - Access.get with :_ (e.g., foods[:_])
  # If multiple sources are found, intersect them.
  defp resolve_wildcard_domain(expr, bindings, problem) do
    var_sets = collect_var_domains_for_wildcard(expr, problem)
    acc_sets = collect_access_domains_for_wildcard(expr, bindings, problem)
    sets = var_sets ++ acc_sets

    case sets do
      [] ->
        raise ArgumentError,
              "Wildcard :_ used in sum/1, but no domain could be inferred. " <>
                "Use a declared indexed variable or a constant map like foods[:_]."

      [single] ->
        MapSet.to_list(single)

      _ ->
        inter = Enum.reduce(sets, hd(sets), &MapSet.intersection/2)

        if MapSet.size(inter) == 0 do
          raise ArgumentError,
                "Inferred wildcard domains do not overlap (empty intersection). " <>
                  "Ensure variable indices and constant keys align."
        end

        MapSet.to_list(inter)
    end
  end

  # For variable accesses like qty(:_) or x(:_, j), infer the value set from the variable map keys
  defp collect_var_domains_for_wildcard(expr, problem) do
    # List of operators to exclude from variable matching
    operators = [:+, :-, :*, :/, :==, :<=, :>=, :<, :>, :., :{}, :|>, :&, :and, :or, :not]

    {_, sets} =
      Macro.traverse(
        expr,
        [],
        fn
          {var_name, _, indices} = node, acc when is_list(indices) and is_atom(var_name) ->
            if var_name not in operators and Enum.any?(indices, &(&1 == :_)) do
              var_map = Problem.get_variables_nd(problem, to_string(var_name)) || %{}

              # Use the first wildcard position for domain
              pos =
                indices
                |> Enum.with_index()
                |> Enum.find_value(fn
                  {:_, i} -> i
                  _ -> nil
                end)

              values =
                for {key_tuple, _mono} <- var_map do
                  # var_map keys are tuples even for 1-D
                  elem(key_tuple, pos)
                end

              {node, [MapSet.new(values) | acc]}
            else
              {node, acc}
            end

          node, acc ->
            {node, acc}
        end,
        fn node, acc -> {node, acc} end
      )

    sets
  end

  # For constant map access like foods[:_][nutrient] or foods[:_].cost
  defp collect_access_domains_for_wildcard(expr, bindings, _problem) do
    {_, sets} =
      Macro.traverse(
        expr,
        [],
        fn
          {{:., _, [Access, :get]}, _, [container_ast, key_ast]} = node, acc ->
            if key_ast == :_ do
              # Evaluate the container, which might be a constant from model_parameters
              container =
                case Dantzig.Problem.DSL.ExpressionParser.try_evaluate_constant(container_ast, bindings) do
                  {:ok, val} -> val
                  :error ->
                    # If try_evaluate_constant fails, fall back to direct evaluation
                    Dantzig.Problem.DSL.ExpressionParser.evaluate_expression_with_bindings(container_ast, bindings)
                end

              domain =
                cond do
                  is_map(container) -> Map.keys(container)
                  is_list(container) -> 0..(length(container) - 1) |> Enum.to_list()
                  true -> []
                end

              {node, [MapSet.new(domain) | acc]}
            else
              {node, acc}
            end

          node, acc ->
            {node, acc}
        end,
        fn node, acc -> {node, acc} end
      )

    sets
  end

  # Replace all occurrences of :_ with the concrete value
  defp replace_wildcards(expr, value) do
    Macro.postwalk(expr, fn
      :_ -> value
      other -> other
    end)
  end
end
