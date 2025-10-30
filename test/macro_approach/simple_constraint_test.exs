defmodule MacroApproach.SimpleConstraintTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Prototype tests for macro generation internals.
  These tests verify AST manipulation and macro generation patterns that are now obsolete.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Test the simplest possible constraint generation
  defp generate_simple_constraint(var, range, constraint_expr, constraint_name) do
    # Build the interpolation for the variable - same pattern as variable generation
    interpolations = [quote(do: unquote(var))]

    quote do
      Enum.reduce(unquote(range), [], fn unquote(var), acc_constraints ->
        # Substitute variable in expression
        substituted_expr =
          Macro.prewalk(unquote(constraint_expr), fn
            ^unquote(var) -> unquote(var)
            other -> other
          end)

        # Build constraint name with actual value using the same pattern as variable generation
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

  @tag :legacy
  test "simplest single generator constraint" do
    var = quote(do: i)
    range = quote(do: 1..3)
    constraint_expr = quote(do: i == 1)
    constraint_name = "Simple constraint"

    result = generate_simple_constraint(var, range, constraint_expr, constraint_name)

    # Should generate 3 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 3

    # Check constraint names
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)

    assert name1 == "Simple constraint"
    assert name2 == "Simple constraint"
    assert name3 == "Simple constraint"
  end

  @tag :legacy
  test "constraint with variable in name - this should fail initially" do
    var = quote(do: i)
    range = quote(do: 1..3)
    constraint_expr = quote(do: i == 1)
    constraint_name = "Constraint for i"

    result = generate_simple_constraint(var, range, constraint_expr, constraint_name)

    # Should generate 3 constraints
    constraints = Code.eval_quoted(result) |> elem(0)
    assert length(constraints) == 3

    # Check constraint names - these should be "Constraint for i" (not interpolated yet)
    {_expr1, name1} = Enum.at(constraints, 0)
    {_expr2, name2} = Enum.at(constraints, 1)
    {_expr3, name3} = Enum.at(constraints, 2)

    # This test will fail initially - that's expected!
    assert name1 == "Constraint for 1"
    assert name2 == "Constraint for 2"
    assert name3 == "Constraint for 3"
  end
end
