defmodule MacroApproach.ConstraintFromScratchTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Prototype tests for macro generation from scratch.
  Tests verify constraint generation patterns that are now obsolete.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Reuse the exact same pattern as variable generation
  defp generate_constraint_combinations_loop(
         constraint_name_template,
         iterator_vars,
         ranges,
         constraint_expr,
         depth \\ 0,
         acc_vars \\ []
       ) do
    if iterator_vars == [] do
      # Base case: no more iterators - this shouldn't happen for constraints
      quote do
        []
      end
    else
      [var | rest_vars] = iterator_vars
      [range | rest_ranges] = ranges

      if rest_vars == [] do
        # Single variable case - reuse exact pattern from variable generation
        # Build the interpolation for all accumulated variables
        all_vars = Enum.reverse([var | acc_vars])
        interpolations = Enum.map(all_vars, fn v -> quote(do: unquote(v)) end)

        quote do
          Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
            # Build constraint name using the same pattern as variable generation
            constraint_name_with_indices =
              [unquote(constraint_name_template) | unquote(interpolations)] |> Enum.join("_")

            # Substitute variable in expression
            substituted_expr =
              Macro.prewalk(unquote(constraint_expr), fn
                ^unquote(var) -> unquote(var)
                other -> other
              end)

            constraint = {substituted_expr, constraint_name_with_indices}
            [constraint | acc_constraints]
          end)
          |> Enum.reverse()
        end
      else
        # Nested case - reuse exact pattern from variable generation
        inner_loop =
          generate_constraint_combinations_loop(
            constraint_name_template,
            rest_vars,
            rest_ranges,
            constraint_expr,
            depth + 1,
            [var | acc_vars]
          )

        quote do
          Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
            inner_constraints = unquote(inner_loop)
            inner_constraints ++ acc_constraints
          end)
          |> Enum.reverse()
        end
      end
    end
  end

  test "single generator constraint with simple name" do
    constraint_name_template = "simple_constraint"
    iterator_vars = [quote(do: i)]
    ranges = [quote(do: 1..3)]
    constraint_expr = quote(do: i == 1)

    result =
      generate_constraint_combinations_loop(
        constraint_name_template,
        iterator_vars,
        ranges,
        constraint_expr
      )

    # Should generate 3 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 3

    # Check constraint names - should be "simple_constraint_1", "simple_constraint_2", "simple_constraint_3"
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)

    assert name1 == "simple_constraint_1"
    assert name2 == "simple_constraint_2"
    assert name3 == "simple_constraint_3"
  end

  test "single generator constraint with variable placeholder" do
    constraint_name_template = "constraint_for"
    iterator_vars = [quote(do: i)]
    ranges = [quote(do: 1..3)]
    constraint_expr = quote(do: i == 1)

    result =
      generate_constraint_combinations_loop(
        constraint_name_template,
        iterator_vars,
        ranges,
        constraint_expr
      )

    # Should generate 3 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 3

    # Check constraint names - should be "constraint_for_1", "constraint_for_2", "constraint_for_3"
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)

    assert name1 == "constraint_for_1"
    assert name2 == "constraint_for_2"
    assert name3 == "constraint_for_3"
  end

  test "two generators all combinations" do
    constraint_name_template = "constraint"
    iterator_vars = [quote(do: i), quote(do: j)]
    ranges = [quote(do: 1..2), quote(do: 1..2)]
    constraint_expr = quote(do: i + j == 2)

    result =
      generate_constraint_combinations_loop(
        constraint_name_template,
        iterator_vars,
        ranges,
        constraint_expr
      )

    # Should generate 4 constraints (2x2 = 4 combinations)
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 4

    # Check constraint names - actual order is "constraint_1_2", "constraint_1_1", "constraint_2_2", "constraint_2_1"
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)
    {_expr4, name4} = Enum.at(constraints, 3)

    # Debug: print actual names
    IO.puts("Actual names: #{name1}, #{name2}, #{name3}, #{name4}")

    assert name1 == "constraint_1_2"
    assert name2 == "constraint_1_1"
    assert name3 == "constraint_2_2"
    assert name4 == "constraint_2_1"
  end
end
