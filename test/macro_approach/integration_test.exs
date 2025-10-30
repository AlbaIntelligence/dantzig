defmodule MacroApproach.IntegrationTest do
  use ExUnit.Case

  @moduledoc """
  LEGACY: Mock DSL prototype tests.
  Tests verify a mock DSL implementation that was superseded by the real Problem.define.
  The actual DSL functionality is tested in test/dantzig/dsl/experimental/
  
  Marked as @tag :legacy - can be skipped in test runs.
  """

  @tag :legacy
  # Mock implementation of the complete approach
  defmodule MockDSL do
    def define(env \\ %{}, do: block) do
      # Parse and reorder the block
      {ordered_exprs, _} = parse_and_reorder_block(block)

      # Convert each expression to imperative form
      imperative_calls =
        Enum.map(ordered_exprs, fn expr ->
          convert_to_imperative(expr, env)
        end)

      # Generate the final code
      quote do
        problem = MacroApproach.IntegrationTest.MockProblem.new(unquote(Macro.escape(env)))
        unquote_splicing(imperative_calls)
      end
    end

    defp parse_and_reorder_block(block) do
      exprs =
        case block do
          {:__block__, _, list} -> list
          single -> [single]
        end

      # For now, just return as-is (we'll add reordering later)
      {exprs, %{}}
    end

    defp convert_to_imperative(
           {:variables, _, [var_name, generators, var_type, description]},
           env
         ) do
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
        # Build the interpolation for all accumulated variables
        all_vars = Enum.reverse([var | acc_vars])
        interpolations = Enum.map(all_vars, fn v -> quote(do: unquote(v)) end)

        quote do
          problem =
            Enum.reduce(unquote(range), unquote(problem_var(depth)), fn unquote(var),
                                                                        acc_problem ->
              var_name_with_indices =
                [unquote(var_name) | unquote(interpolations)] |> Enum.join("_")

              {new_problem, _} =
                MacroApproach.IntegrationTest.MockProblem.new_variable(
                  acc_problem,
                  var_name_with_indices,
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
          problem =
            Enum.reduce(unquote(range), unquote(problem_var(depth)), fn unquote(var),
                                                                        acc_problem ->
              unquote(inner_loop)
            end)
        end
      end
    end

    defp problem_var(0), do: quote(do: problem)
    defp problem_var(_depth), do: quote(do: acc_problem)

    defp generate_var_name_template(base_name, indices) do
      # Generate code that creates the variable name at runtime
      var_refs =
        Enum.map(indices, fn
          {var_name, _, _} when is_atom(var_name) -> var_name
          var_name when is_atom(var_name) -> var_name
          other -> other
        end)

      quote do
        index_str = unquote(var_refs) |> Enum.map(&to_string/1) |> Enum.join("_")
        "#{unquote(base_name)}_#{index_str}"
      end
    end
  end

  defmodule MockProblem do
    def new(_env \\ %{}), do: %{type: :problem, vars: %{}, constraints: [], objective: nil}

    def new_variable(problem, name, opts),
      do: {Map.put(problem, :vars, Map.put(problem.vars, name, opts)), name}
  end

  test "complete DSL transformation works" do
    env = %{nRows: 2, nCols: 2}

    # This should generate imperative code
    result =
      MockDSL.define env do
        quote do
          variables("queen2d", [i <- 1..nRows, j <- 1..nCols], :binary, "Queen position")
        end
      end

    # Debug: print the generated code
    IO.puts("Generated code:")
    IO.puts(Macro.to_string(result))
    IO.puts("---")

    # Execute the generated code
    problem = Code.eval_quoted(result) |> elem(0)

    # Verify the result
    assert problem.type == :problem
    assert Map.keys(problem.vars) == ["queen2d_1_1", "queen2d_1_2", "queen2d_2_1", "queen2d_2_2"]
  end

  test "handles single iterator" do
    env = %{nRows: 3}

    result =
      MockDSL.define env do
        quote do
          variables("x", [i <- 1..nRows], :binary, "Simple variable")
        end
      end

    problem = Code.eval_quoted(result) |> elem(0)

    assert Map.keys(problem.vars) == ["x_1", "x_2", "x_3"]
  end

  test "handles list ranges" do
    env = %{food_names: ["apple", "banana"]}

    result =
      MockDSL.define env do
        quote do
          variables("food", [f <- food_names], :binary, "Food choice")
        end
      end

    problem = Code.eval_quoted(result) |> elem(0)

    assert Map.keys(problem.vars) == ["food_apple", "food_banana"]
  end

  test "handles complex expressions" do
    env = %{nRows: 2, offset: 1}

    result =
      MockDSL.define env do
        quote do
          variables("x", [i <- offset..(nRows + offset)], :binary, "Complex range")
        end
      end

    problem = Code.eval_quoted(result) |> elem(0)

    # Should generate x_1, x_2, x_3 (from 1..3)
    assert Map.keys(problem.vars) == ["x_1", "x_2", "x_3"]
  end

  test "handles 4D queen problem with correct index order" do
    env = %{maxRows: 2, maxCols: 2, maxDim3: 3, maxDim4: 4}

    result =
      MockDSL.define env do
        quote do
          variables(
            "queen4d",
            [r <- 1..maxRows, c <- 1..maxCols, d3 <- 1..maxDim3, d4 <- 1..maxDim4],
            :binary,
            "4D Queen position"
          )
        end
      end

    # Debug: print the generated code
    IO.puts("\n=== QUEEN4D GENERATED CODE ===")
    IO.puts(Macro.to_string(result))
    IO.puts("=== END GENERATED CODE ===\n")

    problem = Code.eval_quoted(result) |> elem(0)

    # Debug: print some of the generated variable names
    IO.puts("Generated variable names (first 10):")
    Map.keys(problem.vars) |> Enum.take(10) |> Enum.each(&IO.puts/1)
    IO.puts("Total variables: #{length(Map.keys(problem.vars))}")

    # Should generate queen4d_{row}_{col}_{dim3}_{dim4} for all combinations
    # Total: 2 * 2 * 3 * 4 = 48 variables
    assert length(Map.keys(problem.vars)) == 48

    # Check a few specific variables to ensure correct naming pattern
    assert "queen4d_1_1_1_1" in Map.keys(problem.vars)
    assert "queen4d_1_1_1_2" in Map.keys(problem.vars)
    assert "queen4d_1_2_3_4" in Map.keys(problem.vars)
    assert "queen4d_2_2_3_4" in Map.keys(problem.vars)

    # Verify the pattern: queen4d_{row}_{col}_{dim3}_{dim4}
    for r <- 1..2, c <- 1..2, d3 <- 1..3, d4 <- 1..4 do
      expected_name = "queen4d_#{r}_#{c}_#{d3}_#{d4}"
      assert expected_name in Map.keys(problem.vars), "Missing variable: #{expected_name}"
    end
  end
end
