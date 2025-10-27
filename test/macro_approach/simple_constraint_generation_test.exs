defmodule MacroApproach.SimpleConstraintGenerationTest do
  use ExUnit.Case

  # Test constraint generation functions with simple expressions
  defp generate_constraint_loop(
         generators,
         constraint_expr,
         constraint_name,
         env \\ %{}
       ) do
    {iterator_vars, ranges} = extract_iterators_and_ranges(generators, env)

    if length(iterator_vars) == 1 do
      generate_single_generator_constraints(
        iterator_vars,
        ranges,
        constraint_expr,
        constraint_name
      )
    else
      generate_multiple_generator_constraints(
        iterator_vars,
        ranges,
        constraint_expr,
        constraint_name
      )
    end
  end

  defp extract_iterators_and_ranges(generators, env) do
    {iterators, ranges} =
      Enum.unzip(
        Enum.map(generators, fn
          {:<-, _meta, [var, range_expr]} ->
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

  defp generate_single_generator_constraints([var], [range], constraint_expr, constraint_name) do
    quote do
      Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
        # Substitute variable in expression
        substituted_expr =
          Macro.prewalk(unquote(constraint_expr), fn
            ^unquote(var) -> unquote(var)
            other -> other
          end)

        # Build constraint name with actual value - use the same pattern as variable generation
        substituted_name =
          String.replace(
            unquote(constraint_name),
            to_string(unquote(var)),
            to_string(unquote(var))
          )

        constraint = {substituted_expr, substituted_name}
        [constraint | acc_constraints]
      end)
      |> Enum.reverse()
    end
  end

  defp create_constraint_name(name_template, var_values) when is_list(var_values) do
    # For multiple variables, interpolate each one
    Enum.reduce(var_values, name_template, fn {var, value}, acc_name ->
      String.replace(acc_name, to_string(var), to_string(value))
    end)
  end

  defp create_constraint_name(name_template, var, value) do
    # Simple string interpolation - replace variable name with value
    String.replace(name_template, to_string(var), to_string(value))
  end

  defp generate_multiple_generator_constraints(
         iterator_vars,
         ranges,
         constraint_expr,
         constraint_name
       ) do
    generate_multiple_generator_constraints_recursive(
      iterator_vars,
      ranges,
      constraint_expr,
      constraint_name,
      []
    )
  end

  defp generate_multiple_generator_constraints_recursive(
         [],
         [],
         constraint_expr,
         constraint_name,
         acc_vars
       ) do
    # Base case: generate the constraint
    quote do
      # Substitute all variables in expression
      substituted_expr =
        Enum.reduce(unquote(acc_vars), unquote(constraint_expr), fn {var, value}, acc_expr ->
          Macro.prewalk(acc_expr, fn
            ^var -> value
            other -> other
          end)
        end)

      # Substitute all variables in name using helper function
      substituted_name = create_constraint_name(unquote(constraint_name), unquote(acc_vars))

      {substituted_expr, substituted_name}
    end
  end

  defp generate_multiple_generator_constraints_recursive(
         [var | rest_vars],
         [range | rest_ranges],
         constraint_expr,
         constraint_name,
         acc_vars
       ) do
    if rest_vars == [] do
      # Last variable - create the constraint
      quote do
        Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
          all_vars = Enum.reverse([{unquote(var), unquote(var)} | unquote(acc_vars)])

          # Substitute all variables in expression
          substituted_expr =
            Enum.reduce(all_vars, unquote(constraint_expr), fn {var, value}, acc_expr ->
              Macro.prewalk(acc_expr, fn
                ^var -> value
                other -> other
              end)
            end)

          # Substitute all variables in name using helper function
          substituted_name = create_constraint_name(unquote(constraint_name), all_vars)

          constraint = {substituted_expr, substituted_name}
          [constraint | acc_constraints]
        end)
        |> Enum.reverse()
      end
    else
      # More variables - continue nesting
      inner_loop =
        generate_multiple_generator_constraints_recursive(
          rest_vars,
          rest_ranges,
          constraint_expr,
          constraint_name,
          [{var, var} | acc_vars]
        )

      quote do
        Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
          inner_constraints = unquote(inner_loop)
          [inner_constraints | acc_constraints]
        end)
        |> List.flatten()
        |> Enum.reverse()
      end
    end
  end

  # Phase 1: Single Generator Constraints with Simple Expressions
  test "generates single generator basic constraint with simple expression" do
    generators = [quote(do: i <- 1..4)]
    constraint_expr = quote(do: i + 1 == 2)
    constraint_name = "Simple constraint"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    # Should generate 4 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check first constraint
    {_expr, name} = Enum.at(constraints, 0)
    assert name == "Simple constraint"
  end

  test "generates single generator with dynamic names" do
    generators = [quote(do: i <- 1..4)]
    constraint_expr = quote(do: i * 2 == 4)
    constraint_name = "Constraint for i"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check constraint names have been interpolated
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "Constraint for 1"
    assert name2 == "Constraint for 2"
    assert name3 == "Constraint for 3"
    assert name4 == "Constraint for 4"
  end

  # Phase 2: Multiple Generator Constraints
  test "generates two generators all combinations" do
    generators = [quote(do: i <- 1..2), quote(do: j <- 1..2)]
    constraint_expr = quote(do: i + j == 3)
    constraint_name = "Sum constraint"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    # 2x2 = 4 combinations
    assert length(constraints) == 4

    # All constraints should have the same name
    for {_expr, name} <- constraints do
      assert name == "Sum constraint"
    end
  end

  test "generates multiple generators with dynamic names" do
    generators = [quote(do: i <- 1..2), quote(do: j <- 1..2)]
    constraint_expr = quote(do: i * j == 2)
    constraint_name = "Product constraint for i and j"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check constraint names have been interpolated with both variables
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "Product constraint for 1 and 1"
    assert name2 == "Product constraint for 1 and 2"
    assert name3 == "Product constraint for 2 and 1"
    assert name4 == "Product constraint for 2 and 2"
  end

  # Phase 3: Complex Expressions
  test "generates complex constraint expressions" do
    generators = [quote(do: i <- 1..2)]
    constraint_expr = quote(do: i * 2 + 1 <= 5)
    constraint_name = "Complex constraint for i"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 2

    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)

    assert name1 == "Complex constraint for 1"
    assert name2 == "Complex constraint for 2"
  end

  # Phase 4: Integration Tests
  test "handles environment variables" do
    env = %{nRows: 2, nCols: 2}
    generators = [quote(do: i <- 1..nRows), quote(do: j <- 1..nCols)]
    constraint_expr = quote(do: i + j == 3)
    constraint_name = "Environment constraint for i and j"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name, env)

    constraints = Code.eval_quoted(result) |> elem(0)
    # 2x2 = 4 combinations
    assert length(constraints) == 4

    # Check constraint names
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "Environment constraint for 1 and 1"
    assert name2 == "Environment constraint for 1 and 2"
    assert name3 == "Environment constraint for 2 and 1"
    assert name4 == "Environment constraint for 2 and 2"
  end

  test "handles list ranges" do
    env = %{items: ["apple", "banana"]}
    generators = [quote(do: item <- items)]
    constraint_expr = quote(do: item == "apple")
    constraint_name = "Item constraint for item"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name, env)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 2

    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)

    assert name1 == "Item constraint for apple"
    assert name2 == "Item constraint for banana"
  end
end
