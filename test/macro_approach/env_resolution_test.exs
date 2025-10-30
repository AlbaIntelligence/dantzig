defmodule MacroApproach.EnvResolutionTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Prototype tests for environment resolution internals.
  Tests verify environment resolution patterns that are now obsolete.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Test environment resolution functions
  defp resolve_expression_with_env(expr, env) do
    Macro.prewalk(expr, fn
      # Resolve global environment variables (handle both atoms and quoted atoms)
      var when is_atom(var) ->
        case Map.get(env, var) do
          # Keep as-is if not in environment
          nil -> var
          # Replace with environment value
          value -> value
        end

      # Handle quoted variables like {:nRows, [], Module}
      {var, meta, context} when is_atom(var) and is_list(meta) and is_atom(context) ->
        case Map.get(env, var) do
          # Keep as-is if not in environment
          nil -> {var, meta, context}
          # Replace with environment value
          value -> value
        end

      other ->
        other
    end)
  end

  test "resolves global environment variables" do
    env = %{nRows: 4, nCols: 3, food_names: ["apple", "banana"]}

    # Test range expressions
    assert resolve_expression_with_env(quote(do: 1..nRows), env) == quote(do: 1..4)
    assert resolve_expression_with_env(quote(do: 1..nCols), env) == quote(do: 1..3)

    # Test list expressions
    assert resolve_expression_with_env(quote(do: food_names), env) ==
             quote(do: ["apple", "banana"])

    # Test arithmetic expressions
    assert resolve_expression_with_env(quote(do: nRows * 2), env) == quote(do: 4 * 2)
  end

  test "keeps iterator variables unchanged" do
    env = %{nRows: 4, nCols: 3}

    # Iterator variables should not be resolved from environment
    assert resolve_expression_with_env(quote(do: i), env) == quote(do: i)
    assert resolve_expression_with_env(quote(do: j), env) == quote(do: j)
    assert resolve_expression_with_env(quote(do: k), env) == quote(do: k)
  end

  test "handles mixed expressions" do
    env = %{nRows: 4, nCols: 3}

    # Mixed: global + iterator + literal
    result = resolve_expression_with_env(quote(do: i + nRows), env)
    expected = quote(do: i + 4)
    assert result == expected
  end

  test "handles complex nested expressions" do
    env = %{nRows: 4, nCols: 3, multiplier: 2}

    # Complex expression: (i + nRows) * multiplier
    result = resolve_expression_with_env(quote(do: (i + nRows) * multiplier), env)
    expected = quote(do: (i + 4) * 2)
    assert result == expected
  end
end
