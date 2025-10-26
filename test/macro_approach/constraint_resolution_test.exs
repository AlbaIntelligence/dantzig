defmodule MacroApproach.ConstraintResolutionTest do
  use ExUnit.Case

  # Test constraint expression resolution functions
  defp resolve_constraint_with_iterators(constraint_expr, iterator_values, _env) do
    # Replace iterator variables in constraint expression
    Macro.prewalk(constraint_expr, fn
      {var_name, meta, indices} when is_atom(var_name) and is_list(indices) ->
        resolved_indices =
          Enum.map(indices, fn
            # Keep wildcards as-is
            :_ ->
              :_

            var when is_atom(var) ->
              # Look up iterator value by comparing variable names
              Enum.find_value(iterator_values, fn {iter_var, value} ->
                # Extract the variable name from the quoted variable
                case iter_var do
                  {iter_var_name, _, _} when is_atom(iter_var_name) ->
                    if iter_var_name == var, do: value, else: nil

                  _ ->
                    nil
                end
              end) || var

            {var, meta, context} when is_atom(var) ->
              # Look up iterator value by comparing variable names
              Enum.find_value(iterator_values, fn {iter_var, value} ->
                # Extract the variable name from the quoted variable
                case iter_var do
                  {iter_var_name, _, _} when is_atom(iter_var_name) ->
                    if iter_var_name == var, do: value, else: nil

                  _ ->
                    nil
                end
              end) || {var, meta, context}

            other ->
              other
          end)

        {var_name, meta, resolved_indices}

      other ->
        other
    end)
  end

  test "resolves single iterator in constraint expression" do
    # queen2d(i, :_) with i=2 becomes queen2d(2, :_)
    constraint_expr = quote(do: queen2d(i, :_) == 1)
    iterator_values = [{quote(do: i), 2}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: queen2d(2, :_) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "resolves multiple iterators in constraint expression" do
    # schedule(i, j, :_) with i=1, j=3 becomes schedule(1, 3, :_)
    constraint_expr = quote(do: schedule(i, j, :_) == 1)
    iterator_values = [{quote(do: i), 1}, {quote(do: j), 3}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: schedule(1, 3, :_) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "keeps wildcards unchanged" do
    # queen2d(:_, j) with j=2 becomes queen2d(:_, 2)
    constraint_expr = quote(do: queen2d(:_, j) == 1)
    iterator_values = [{quote(do: j), 2}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: queen2d(:_, 2) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "handles complex constraint expressions" do
    # sum(queen2d(i, :_)) + sum(queen2d(:_, j)) with i=1, j=2
    constraint_expr = quote(do: sum(queen2d(i, :_)) + sum(queen2d(:_, j)) <= 2)
    iterator_values = [{quote(do: i), 1}, {quote(do: j), 2}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: sum(queen2d(1, :_)) + sum(queen2d(:_, 2)) <= 2)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "handles nested function calls" do
    # sum(queen2d(i, j)) with i=1, j=2
    constraint_expr = quote(do: sum(queen2d(i, j)) == 1)
    iterator_values = [{quote(do: i), 1}, {quote(do: j), 2}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: sum(queen2d(1, 2)) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "handles arithmetic with iterators" do
    # queen2d(i, i+1) with i=1 becomes queen2d(1, 2)
    constraint_expr = quote(do: queen2d(i, i + 1) == 1)
    iterator_values = [{quote(do: i), 1}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: queen2d(1, 1 + 1) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end

  test "handles unknown variables gracefully" do
    # queen2d(i, k) with only i=1 defined, k should remain unchanged
    constraint_expr = quote(do: queen2d(i, k) == 1)
    iterator_values = [{quote(do: i), 1}]
    env = %{}

    result = resolve_constraint_with_iterators(constraint_expr, iterator_values, env)
    expected = quote(do: queen2d(1, k) == 1)

    assert Macro.to_string(result) == Macro.to_string(expected)
  end
end
