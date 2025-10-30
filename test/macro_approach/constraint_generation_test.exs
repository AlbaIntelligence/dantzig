defmodule MacroApproach.ConstraintGenerationTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Prototype tests for macro generation internals.
  Tests verify AST manipulation and macro generation patterns that are now obsolete.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Test constraint generation functions
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

        # Substitute variable in name
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

      # Substitute all variables in name
      substituted_name =
        Enum.reduce(unquote(acc_vars), unquote(constraint_name), fn {var, value}, acc_name ->
          String.replace(acc_name, to_string(var), to_string(value))
        end)

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

          # Substitute all variables in name
          substituted_name =
            Enum.reduce(all_vars, unquote(constraint_name), fn {var, value}, acc_name ->
              String.replace(acc_name, to_string(var), to_string(value))
            end)

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

  # Phase 1: Single Generator Constraints
  test "generates single generator basic constraint" do
    generators = [quote(do: i <- 1..4)]
    constraint_expr = quote(do: sum(queen2d(i, :_)) == 1)
    constraint_name = "One queen per row"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    # Should generate 4 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check first constraint
    {_expr, name} = Enum.at(constraints, 0)
    assert name == "One queen per row"
    # Note: We can't easily test the expression structure without more complex AST comparison
  end

  test "generates single generator with dynamic names" do
    generators = [quote(do: i <- 1..4)]
    constraint_expr = quote(do: sum(queen2d(i, :_)) == 1)
    constraint_name = "One queen on row i"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check constraint names have been interpolated
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "One queen on row 1"
    assert name2 == "One queen on row 2"
    assert name3 == "One queen on row 3"
    assert name4 == "One queen on row 4"
  end

  # Phase 2: Multiple Generator Constraints
  test "generates two generators all combinations" do
    generators = [quote(do: i <- 1..2), quote(do: k <- 1..2)]
    constraint_expr = quote(do: sum(queen3d(i, :_, k)) == 1)
    constraint_name = "One queen per row"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    # 2x2 = 4 combinations
    assert length(constraints) == 4

    # All constraints should have the same name
    for {_expr, name} <- constraints do
      assert name == "One queen per row"
    end
  end

  test "generates multiple generators with dynamic names" do
    generators = [quote(do: i <- 1..2), quote(do: k <- 1..2)]
    constraint_expr = quote(do: sum(queen3d(i, :_, k)) == 1)
    constraint_name = "Row i axis k"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check constraint names have been interpolated with both variables
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "Row 1 axis 1"
    assert name2 == "Row 1 axis 2"
    assert name3 == "Row 2 axis 1"
    assert name4 == "Row 2 axis 2"
  end

  # Phase 3: Complex Expressions
  test "generates complex constraint expressions" do
    generators = [quote(do: i <- 1..2)]
    constraint_expr = quote(do: queen2d(i, 1) + queen2d(i, 2) <= 1)
    constraint_name = "Complex constraint i"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name)

    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 2

    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)

    assert name1 == "Complex constraint 1"
    assert name2 == "Complex constraint 2"
  end

  # Phase 4: Integration Tests
  test "handles environment variables" do
    env = %{nRows: 2, nCols: 2}
    generators = [quote(do: i <- 1..nRows), quote(do: j <- 1..nCols)]
    constraint_expr = quote(do: sum(queen2d(i, j)) == 1)
    constraint_name = "Queen at i,j"

    result = generate_constraint_loop(generators, constraint_expr, constraint_name, env)

    constraints = Code.eval_quoted(result) |> elem(0)
    # 2x2 = 4 combinations
    assert length(constraints) == 4

    # Check constraint names
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    assert name1 == "Queen at 1,1"
    assert name2 == "Queen at 1,2"
    assert name3 == "Queen at 2,1"
    assert name4 == "Queen at 2,2"
  end
end
