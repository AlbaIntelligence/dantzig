defmodule MacroApproach.CompleteTransformationTest do
  use ExUnit.Case

  # Mock Problem module for testing
  defmodule MockProblem do
    def new(_env \\ %{}), do: %{type: :problem, vars: %{}, constraints: [], objective: nil}

    def new_variable(problem, name, opts),
      do: {Map.put(problem, :vars, Map.put(problem.vars, name, opts)), name}

    def add_constraint(problem, constraint, description),
      do: Map.put(problem, :constraints, [constraint | problem.constraints])

    def set_objective(problem, objective, opts),
      do: Map.put(problem, :objective, {objective, opts})
  end

  # Test complete transformation functions
  defp convert_to_imperative({:variables, _, [var_name, generators, var_type, description]}, env) do
    convert_variables_to_imperative(var_name, generators, var_type, description, env)
  end

  defp convert_variables_to_imperative(var_name, generators, var_type, description, env) do
    {iterator_vars, ranges} = extract_iterators_and_ranges(generators, env)
    generate_nested_loops(var_name, iterator_vars, ranges, var_type, description)
  end

  defp extract_iterators_and_ranges(generators, env) do
    {iterators, ranges} =
      Enum.unzip(
        Enum.map(generators, fn
          {:<-, meta, [var, range_expr]} ->
            resolved_range = resolve_expression_with_env(range_expr, env)
            {var, resolved_range}
        end)
      )

    {iterators, ranges}
  end

  defp resolve_expression_with_env(expr, env) do
    Macro.prewalk(expr, fn
      var when is_atom(var) ->
        case Map.get(env, var) do
          nil -> var
          value -> value
        end

      # Handle quoted variables like {:nRows, [], Module}
      {var, meta, context} when is_atom(var) and is_list(meta) and is_atom(context) ->
        case Map.get(env, var) do
          nil -> {var, meta, context}
          value -> value
        end

      other ->
        other
    end)
  end

  defp generate_nested_loops(var_name, iterator_vars, ranges, var_type, description) do
    generate_combinations_loop(var_name, iterator_vars, ranges, var_type, description, 0)
  end

  defp generate_combinations_loop(
         var_name,
         [var | rest_vars],
         [range | rest_ranges],
         var_type,
         description,
         depth,
         acc_vars \\ []
       ) do
    if rest_vars == [] do
      # Single variable case
      quote do
        Enum.reduce(unquote(range), unquote(problem_var(depth)), fn unquote(var), acc_problem ->
          var_name_with_indices = create_var_name(unquote(var_name), unquote([var | acc_vars]))

          {new_problem, _} =
            MockProblem.new_variable(acc_problem, var_name_with_indices,
              type: unquote(var_type),
              description: unquote(description)
            )

          new_problem
        end)
      end
    else
      # Nested case
      inner_loop =
        generate_combinations_loop(
          var_name,
          rest_vars,
          rest_ranges,
          var_type,
          description,
          depth + 1,
          [var | acc_vars]
        )

      quote do
        Enum.reduce(unquote(range), unquote(problem_var(depth)), fn unquote(var), acc_problem ->
          unquote(inner_loop)
        end)
      end
    end
  end

  defp problem_var(0), do: quote(do: problem)
  defp problem_var(_depth), do: quote(do: acc_problem)

  defp create_var_name(base_name, indices) do
    index_str = indices |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{base_name}_#{index_str}"
  end

  test "transforms simple variables DSL to imperative" do
    env = %{nRows: 4, nCols: 3}

    dsl_expr =
      quote(do: variables("queen2d", [i <- 1..nRows, j <- 1..nCols], :binary, "Queen position"))

    result = convert_to_imperative(dsl_expr, env)

    # Should generate nested loops
    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..4, problem"
    assert result_str =~ "fn i, acc_problem"
    assert result_str =~ "Enum.reduce(1..3, acc_problem"
    assert result_str =~ "fn j, acc_problem"
    assert result_str =~ "MockProblem.new_variable"
    assert result_str =~ "create_var_name(\"queen2d\""
  end

  test "transforms single iterator variables" do
    env = %{nRows: 4}
    dsl_expr = quote(do: variables("x", [i <- 1..nRows], :binary, "Simple variable"))

    result = convert_to_imperative(dsl_expr, env)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..4, problem"
    assert result_str =~ "fn i, acc_problem"
    assert result_str =~ "create_var_name(\"x\""
  end

  test "transforms three iterator variables" do
    env = %{nRows: 2, nCols: 2, timeSlots: 3}

    dsl_expr =
      quote(
        do:
          variables(
            "schedule",
            [i <- 1..nRows, j <- 1..nCols, t <- 1..timeSlots],
            :binary,
            "Schedule"
          )
      )

    result = convert_to_imperative(dsl_expr, env)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..2, problem"
    assert result_str =~ "fn i, acc_problem"
    assert result_str =~ "Enum.reduce(1..2, acc_problem"
    assert result_str =~ "fn j, acc_problem"
    assert result_str =~ "Enum.reduce(1..3, acc_problem"
    assert result_str =~ "fn t, acc_problem"
  end

  test "handles list ranges" do
    env = %{food_names: ["apple", "banana"]}
    dsl_expr = quote(do: variables("food", [f <- food_names], :binary, "Food choice"))

    result = convert_to_imperative(dsl_expr, env)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce([\"apple\", \"banana\"], problem"
    assert result_str =~ "fn f, acc_problem"
  end

  test "handles complex range expressions" do
    env = %{nRows: 4, offset: 1}

    dsl_expr =
      quote(do: variables("x", [i <- offset..(nRows + offset)], :binary, "Complex range"))

    result = convert_to_imperative(dsl_expr, env)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..(4 + 1), problem"
    assert result_str =~ "fn i, acc_problem"
  end
end
