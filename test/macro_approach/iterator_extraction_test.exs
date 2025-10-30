defmodule MacroApproach.IteratorExtractionTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Prototype tests for AST parsing internals.
  Tests verify iterator extraction patterns that are now obsolete.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Test iterator extraction functions
  defp extract_iterators_and_ranges(generators, env) do
    {iterators, ranges} =
      Enum.unzip(
        Enum.map(generators, fn
          {:<-, meta, [var, range_expr]} ->
            # Resolve range expression using environment
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

  test "extracts single iterator" do
    env = %{nRows: 4}
    generators = quote(do: [i <- 1..nRows])

    {iterators, ranges} = extract_iterators_and_ranges(generators, env)

    assert iterators == [quote(do: i)]
    assert ranges == [quote(do: 1..4)]
  end

  test "extracts multiple iterators" do
    env = %{nRows: 4, nCols: 3}
    generators = quote(do: [i <- 1..nRows, j <- 1..nCols])

    {iterators, ranges} = extract_iterators_and_ranges(generators, env)

    assert iterators == [quote(do: i), quote(do: j)]
    assert ranges == [quote(do: 1..4), quote(do: 1..3)]
  end

  test "extracts three iterators" do
    env = %{nRows: 4, nCols: 3, timeSlots: 8}
    generators = quote(do: [i <- 1..nRows, j <- 1..nCols, t <- 1..timeSlots])

    {iterators, ranges} = extract_iterators_and_ranges(generators, env)

    assert iterators == [quote(do: i), quote(do: j), quote(do: t)]
    assert ranges == [quote(do: 1..4), quote(do: 1..3), quote(do: 1..8)]
  end

  test "handles complex range expressions" do
    env = %{nRows: 4, offset: 1}
    generators = quote(do: [i <- offset..(nRows + offset)])

    {iterators, ranges} = extract_iterators_and_ranges(generators, env)

    assert iterators == [quote(do: i)]
    # Should resolve to: 1..(4 + 1) = 1..5
    expected_range = quote(do: 1..(4 + 1))
    assert ranges == [expected_range]
  end

  test "handles list ranges" do
    env = %{food_names: ["apple", "banana", "cherry"]}
    generators = quote(do: [food <- food_names])

    {iterators, ranges} = extract_iterators_and_ranges(generators, env)

    assert iterators == [quote(do: food)]
    assert ranges == [quote(do: ["apple", "banana", "cherry"])]
  end
end
