defmodule MacroApproach.NestedLoopGenerationTest do
  use ExUnit.Case

  # Test nested loop generation functions
  defp generate_combinations_loop(
         var_name,
         iterator_vars,
         ranges,
         var_type,
         description,
         depth \\ 0
       ) do
    if iterator_vars == [] do
      # Base case: no more iterators
      quote do
        unquote(problem_var(depth))
      end
    else
      [var | rest_vars] = iterator_vars
      [range | rest_ranges] = ranges

      if rest_vars == [] do
        # Single variable case
        quote do
          Enum.reduce(unquote(range), unquote(problem_var(depth)), fn unquote(var), acc_problem ->
            var_name_with_indices = create_var_name(unquote(var_name), [unquote(var)])

            {new_problem, _} =
              Problem.new_variable(acc_problem, var_name_with_indices,
                type: unquote(var_type),
                description: unquote(description)
              )

            new_problem
          end)
        end
      else
        # Nested case - generate all combinations
        generate_nested_loops(var_name, iterator_vars, ranges, var_type, description, depth)
      end
    end
  end

  defp generate_nested_loops(var_name, iterator_vars, ranges, var_type, description, depth) do
    # Generate nested loops for all combinations
    generate_nested_loops_recursive(
      var_name,
      iterator_vars,
      ranges,
      var_type,
      description,
      depth,
      []
    )
  end

  defp generate_nested_loops_recursive(var_name, [], [], var_type, description, _depth, acc_vars) do
    # Base case: generate the variable creation
    quote do
      var_name_with_indices = create_var_name(unquote(var_name), unquote(acc_vars))

      {new_problem, _} =
        Problem.new_variable(acc_problem, var_name_with_indices,
          type: unquote(var_type),
          description: unquote(description)
        )

      new_problem
    end
  end

  defp generate_nested_loops_recursive(
         var_name,
         [var | rest_vars],
         [range | rest_ranges],
         var_type,
         description,
         depth,
         acc_vars
       ) do
    if rest_vars == [] do
      # Last variable - create the variable
      quote do
        Enum.reduce(unquote(range), acc_problem, fn unquote(var), acc_problem ->
          var_name_with_indices = create_var_name(unquote(var_name), unquote([var | acc_vars]))

          {new_problem, _} =
            Problem.new_variable(acc_problem, var_name_with_indices,
              type: unquote(var_type),
              description: unquote(description)
            )

          new_problem
        end)
      end
    else
      # More variables - continue nesting
      inner_loop =
        generate_nested_loops_recursive(
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
  defp problem_var(1), do: quote(do: acc_problem)
  defp problem_var(_depth), do: quote(do: acc_problem)

  defp create_var_name(base_name, indices) do
    index_str = indices |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{base_name}_#{index_str}"
  end

  test "generates single loop for one iterator" do
    var_name = "queen2d"
    iterator_vars = [quote(do: i)]
    ranges = [quote(do: 1..4)]
    var_type = :binary
    description = "Queen position"

    result = generate_combinations_loop(var_name, iterator_vars, ranges, var_type, description)

    # Should generate: Enum.reduce(1..4, problem, fn i, acc_problem -> ... end)
    expected =
      quote do
        Enum.reduce(1..4, problem, fn i, acc_problem ->
          var_name_with_indices = create_var_name("queen2d", [i])

          {new_problem, _} =
            Problem.new_variable(acc_problem, var_name_with_indices,
              type: :binary,
              description: "Queen position"
            )

          new_problem
        end)
      end

    # Compare the structure (simplified comparison)
    assert Macro.to_string(result) =~ "Enum.reduce(1..4, problem"
    assert Macro.to_string(result) =~ "fn i, acc_problem"
  end

  test "generates nested loops for two iterators" do
    var_name = "queen2d"
    iterator_vars = [quote(do: i), quote(do: j)]
    ranges = [quote(do: 1..4), quote(do: 1..3)]
    var_type = :binary
    description = "Queen position"

    result = generate_combinations_loop(var_name, iterator_vars, ranges, var_type, description)

    # Should generate nested Enum.reduce calls
    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..4, problem"
    assert result_str =~ "fn i, acc_problem"
    assert result_str =~ "Enum.reduce(1..3, acc_problem"
    assert result_str =~ "fn j, acc_problem"
  end

  test "generates triple nested loops for three iterators" do
    var_name = "schedule"
    iterator_vars = [quote(do: i), quote(do: j), quote(do: t)]
    ranges = [quote(do: 1..4), quote(do: 1..3), quote(do: 1..8)]
    var_type = :binary
    description = "Schedule"

    result = generate_combinations_loop(var_name, iterator_vars, ranges, var_type, description)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce(1..4, problem"
    assert result_str =~ "fn i, acc_problem"
    assert result_str =~ "Enum.reduce(1..3, acc_problem"
    assert result_str =~ "fn j, acc_problem"
    assert result_str =~ "Enum.reduce(1..8, acc_problem"
    assert result_str =~ "fn t, acc_problem"
  end

  test "handles different range types" do
    var_name = "food"
    iterator_vars = [quote(do: f)]
    ranges = [quote(do: ["apple", "banana", "cherry"])]
    var_type = :binary
    description = "Food choice"

    result = generate_combinations_loop(var_name, iterator_vars, ranges, var_type, description)

    result_str = Macro.to_string(result)
    assert result_str =~ "Enum.reduce([\"apple\", \"banana\", \"cherry\"], problem"
    assert result_str =~ "fn f, acc_problem"
  end
end
