defmodule Dantzig.Problem.DSLReducer do
  @moduledoc """
  DSL reduction functions for Problem.define and Problem.modify macros.

  This module contains the complex pattern matching logic that reduces
  DSL expressions into runtime function calls.
  """

  require Dantzig.Problem, as: Problem

  # Validate bounds based on variable type
  defp validate_bounds_for_single_variable!(var_type, min_bound, max_bound) do
    case var_type do
      :binary ->
        if min_bound != nil or max_bound != nil do
          raise ArgumentError, "Binary variables cannot have bounds"
        end

      :integer ->
        if min_bound != nil and is_float(min_bound) do
          raise ArgumentError, "Integer variables cannot have floating point bounds"
        end

        if max_bound != nil and is_float(max_bound) do
          raise ArgumentError, "Integer variables cannot have floating point bounds"
        end

      :continuous ->
        :ok

      _ ->
        raise ArgumentError, "Unknown variable type"
    end
  end

  #
  # TODO: __define_reduce__ and __modify_reduce__ are essentially the same thing.
  #       In a sense `define` modifies for the first time.
  #       There is an enormous amount of code duplication that should be refactored into a single code set.
  #

  # Helper used by the macro to reduce the block at compile-time into runtime calls
  def __define_reduce__(exprs) when is_list(exprs) do
    {initial_problem, rest} =
      case exprs do
        [{:new, _, [opts]} | tail] -> {Problem.new(opts), tail}
        [{:new, _, []} | tail] -> {Problem.new([]), tail}
        _ -> raise ArgumentError, "First expression inside define must be new/1"
      end

    # TODO: I think the following would be easire to read if there was a first case/switch on `:for`, `variables`, `constraints`,
    #       ans then within each case, pattern matching on signature. More logical.
    Enum.reduce(rest, initial_problem, fn
      # Support simple for-comprehension inside define for variables expansion
      # Example: for food <- food_names, do: variables("qty", [food], :continuous, "desc")
      {:for, _, [{:<-, _, [var_ast, domain_expr]}, [do: inner_ast]]} = _ast, acc ->
        # Evaluate domain in caller env
        values = Dantzig.Problem.DSL.VariableManager.evaluate_expression(domain_expr)

        Enum.reduce(values, acc, fn value, acc_problem ->
          case {var_ast, inner_ast} do
            {head_var_ast, {:variables, _meta, [name, gen_list, type, desc]}}
            when is_list(gen_list) ->
              # If inner is variables("base", [var], type, desc), expand to scalar variables/3
              expanded_problem =
                case gen_list do
                  [gen_var_ast] ->
                    # Compare variable names ignoring meta
                    head_atom =
                      case head_var_ast do
                        {atom, _, _} when is_atom(atom) -> atom
                        atom when is_atom(atom) -> atom
                        _ -> nil
                      end

                    gen_atom =
                      case gen_var_ast do
                        {atom, _, _} when is_atom(atom) -> atom
                        atom when is_atom(atom) -> atom
                        _ -> nil
                      end

                    if head_atom && gen_atom && head_atom == gen_atom do
                      # Sanitize variable names for LP format compatibility (CPLEX-compatible)
                      sanitized_value =
                        to_string(value)
                        |> String.replace(~r/[eE](?![a-zA-Z_])/, "x_")
                        |> String.replace(~r/[eE]+/, "x_")
                        |> String.replace(~r/[\+\-\*\^\[\]]/, "_")
                        |> String.replace(~r/[^A-Za-z0-9_!"#\$%&()\,\.\;\?@_'~]/, "_")
                        |> String.trim("_")

                      # Create variable name with parentheses-based indexing
                      new_name = "#{name}(#{sanitized_value})"

                      # Interpolate variable description with current index when possible
                      interp_desc =
                        case desc do
                          # Interpolated binary AST, evaluate with current binding
                          {:<<>>, _m, _parts} = ast ->
                            try do
                              {val, _} = Code.eval_quoted(ast, [{head_atom, value}])
                              to_string(val)
                            rescue
                              _ -> desc
                            end

                          # Plain string: replace occurrences of the generator var name with value
                          bin when is_binary(bin) ->
                            pattern = ~r/\b#{Regex.escape(to_string(head_atom))}\b/
                            String.replace(bin, pattern, to_string(value))

                          _ ->
                            desc
                        end

                      {new_p, _} =
                        Problem.new_variable(acc_problem, new_name,
                          type: type,
                          description: interp_desc
                        )

                      new_p
                    else
                      raise ArgumentError,
                            "Unsupported for-comprehension body: #{inspect(inner_ast)}"
                    end

                  _ ->
                    raise ArgumentError,
                          "Unsupported for-comprehension body: #{inspect(inner_ast)}"
                end

              expanded_problem

            _ ->
              raise ArgumentError,
                    "Unsupported for-comprehension structure: #{inspect({var_ast, inner_ast})}"
          end
        end)

      # Simple syntax: variables("name", :type, "description") - 4-element AST with binary description
      {:variables, _, [name, type, description]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_binary(description) ->
        # Create single variable with simple syntax
        {new_problem, _} = Problem.new_variable(acc, name, type: type, description: description)
        new_problem

      # Simple syntax with bounds in opts: variables("name", :type, [bounds...]) - 4-element AST with opts list
      {:variables, _, [name, [], type, opts]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_list(opts) and not is_binary(hd(opts)) ->
        # Extract description and bounds from opts
        description = Keyword.get(opts, :description, "")
        min_bound = Keyword.get(opts, :min)
        max_bound = Keyword.get(opts, :max)

        # Validate bounds before creating variable
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Build variable options - convert bounds to the format expected by new_variable
        var_opts = [type: type, description: description]
        var_opts = if min_bound != nil, do: Keyword.put(var_opts, :min, min_bound), else: var_opts
        var_opts = if max_bound != nil, do: Keyword.put(var_opts, :max, max_bound), else: var_opts

        {new_problem, _} = Problem.new_variable(acc, name, var_opts)

        new_problem

      # Simple syntax with options: variables("name", :type, description: "desc", min_bound: 0, max_bound: 1)
      {:variables, _, [name, type | remaining]} = _ast, acc
      when is_binary(name) and is_atom(type) ->
        # Extract description and bounds from the remaining elements
        {description, bounds_list} =
          case remaining do
            [desc, [min_bound: _, max_bound: _] = bounds] when is_binary(desc) ->
              {desc, bounds}

            [desc, bounds] when is_binary(desc) and is_list(bounds) ->
              {desc, bounds}

            [[min_bound: _, max_bound: _] = bounds] ->
              {"", bounds}

            [bounds] when is_list(bounds) ->
              {"", bounds}

            _ ->
              {"", []}
          end

        # Extract bounds from bounds_list
        min_bound = Keyword.get(bounds_list, :min)
        max_bound = Keyword.get(bounds_list, :max)

        # Validate bounds before creating variable
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Build variable options - convert bounds to the format expected by new_variable
        var_opts = [type: type, description: description]
        var_opts = if min_bound != nil, do: Keyword.put(var_opts, :min, min_bound), else: var_opts
        var_opts = if max_bound != nil, do: Keyword.put(var_opts, :max, max_bound), else: var_opts

        {new_problem, _} = Problem.new_variable(acc, name, var_opts)

        new_problem

      # Generator syntax with bounds: variables("name", [generators], :type, description, bounds_opts) - MATCH FIRST
      {:variables, _, [name, generators, type, description, bounds_opts]} = _ast, acc
      when is_binary(name) and is_list(generators) and is_atom(type) and is_binary(description) and
             is_list(bounds_opts) ->
        # Extract bounds and merge with description
        {min_bound, max_bound} =
          case bounds_opts do
            [min_bound: min_val, max_bound: max_val] -> {min_val, max_val}
            [max_bound: max_val, min_bound: min_val] -> {min_val, max_val}
            [min_bound: min_val] -> {min_val, nil}
            [max_bound: max_val] -> {nil, max_val}
            _ -> {nil, nil}
          end

        # Validate bounds before creating variables
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Create options with bounds - keep min_bound/max_bound format for VariableManager
        var_opts = [type: type, description: description]

        var_opts =
          if min_bound != nil, do: Keyword.put(var_opts, :min_bound, min_bound), else: var_opts

        var_opts =
          if max_bound != nil, do: Keyword.put(var_opts, :max_bound, max_bound), else: var_opts

        Problem.variables(
          acc,
          name,
          generators,
          type,
          var_opts
        )

      # Generator syntax: variables("name", [generators], :type, opts_or_desc) - MATCH SECOND
      {:variables, _, [name, generators, type, opts_or_desc]} = _ast, acc ->
        # Allow either description string or keyword opts; if interpolated binary AST, skip description
        case opts_or_desc do
          desc when is_binary(desc) ->
            Problem.variables(acc, name, generators, type, description: desc)

          opts when is_list(opts) ->
            Problem.variables(acc, name, generators, type, opts)
        end

      # Generator syntax without description: variables("name", [generators], :type)
      {:variables, _, [name, generators, type]} = _ast, acc
      when is_binary(name) and is_list(generators) and is_atom(type) ->
        Problem.variables(acc, name, generators, type, [])



      # Generator-based constraints: constraints(generators, expr, desc)
      {:constraints, _, [generators, constraint_expr, desc]} = _ast, acc when is_list(generators) ->
        Problem.constraints(acc, generators, constraint_expr, desc)

      # Generator-based constraints: constraints(generators, expr)
      {:constraints, _, [generators, constraint_expr]} = _ast, acc when is_list(generators) ->
        Problem.constraints(acc, generators, constraint_expr, nil)

      # No-generator constraints forms - use single constraint function
      {:constraints, _, [constraint_expr, desc]} = _ast, acc ->
        Problem.constraint(acc, constraint_expr, desc)

      {:constraints, _, [constraint_expr]} = _ast, acc ->
        Problem.constraint(acc, constraint_expr, nil)

      {:objective, _, [objective_expr, opts]} = _ast, acc ->
        transformed = transform_objective_expression_to_ast(objective_expr)
        Problem.objective(acc, transformed, opts)

      # Allow objective([], expr, opts) – ignore first list for now
      {:objective, _, [[], objective_expr, opts]} = _ast, acc ->
        transformed = transform_objective_expression_to_ast(objective_expr)
        Problem.objective(acc, transformed, opts)

      # Allow tap(fun) to inspect/log the current problem and continue
      {:tap, _, [fun_ast]} = _ast, acc ->
        {fun, _} = Code.eval_quoted(fun_ast, [])
        _ = fun.(acc)
        acc

      other, _acc ->
        raise ArgumentError, "Unsupported expression inside define: #{inspect(other)}"
    end)
  end

  # Reduce over modify expressions reusing same handlers as define (minus new/1)
  def __modify_reduce__(%Problem{} = initial_problem, exprs) when is_list(exprs) do
    Enum.reduce(exprs, initial_problem, fn
      {:variables, _, [name, type, description]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_binary(description) ->
        {new_problem, _} = Problem.new_variable(acc, name, type: type, description: description)
        new_problem

      # Simple syntax with bounds in opts for modify: variables("name", :type, [bounds...]) - 4-element AST with opts list
      {:variables, _, [name, [], type, opts]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_list(opts) and not is_binary(hd(opts)) ->
        # Extract description and bounds from opts
        description = Keyword.get(opts, :description, "")
        min_bound = Keyword.get(opts, :min)
        max_bound = Keyword.get(opts, :max)

        # Validate bounds before creating variable
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Build variable options - convert bounds to the format expected by new_variable
        var_opts = [type: type, description: description]
        var_opts = if min_bound != nil, do: Keyword.put(var_opts, :min, min_bound), else: var_opts
        var_opts = if max_bound != nil, do: Keyword.put(var_opts, :max, max_bound), else: var_opts

        {new_problem, _} = Problem.new_variable(acc, name, var_opts)

        new_problem

      {:variables, _, [name, type | remaining]} = _ast, acc
      when is_binary(name) and is_atom(type) ->
        # Extract description and bounds from the remaining elements
        {description, bounds_list} =
          case remaining do
            [desc, [min_bound: _, max_bound: _] = bounds] when is_binary(desc) ->
              {desc, bounds}

            [desc, bounds] when is_binary(desc) and is_list(bounds) ->
              {desc, bounds}

            [[min_bound: _, max_bound: _] = bounds] ->
              {"", bounds}

            [bounds] when is_list(bounds) ->
              {"", bounds}

            _ ->
              {"", []}
          end

        # Extract bounds from bounds_list
        min_bound = Keyword.get(bounds_list, :min)
        max_bound = Keyword.get(bounds_list, :max)

        # Validate bounds before creating variable
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Build variable options - convert bounds to the format expected by new_variable
        var_opts = [type: type, description: description]
        var_opts = if min_bound != nil, do: Keyword.put(var_opts, :min, min_bound), else: var_opts
        var_opts = if max_bound != nil, do: Keyword.put(var_opts, :max, max_bound), else: var_opts

        {new_problem, _} = Problem.new_variable(acc, name, var_opts)

        new_problem

      # Generator syntax with bounds: variables("name", [generators], :type, description, bounds_opts) - MATCH FIRST
      {:variables, _, [name, generators, type, description, bounds_opts]} = _ast, acc
      when is_binary(name) and is_list(generators) and is_atom(type) and is_binary(description) and
             is_list(bounds_opts) ->
        # Extract bounds from bounds_opts and merge with description
        min_bound = Keyword.get(bounds_opts, :min)
        max_bound = Keyword.get(bounds_opts, :max)

        # Validate bounds before creating variables
        validate_bounds_for_single_variable!(type, min_bound, max_bound)

        # Create options with bounds - keep min_bound/max_bound format for VariableManager
        var_opts = [type: type, description: description]

        var_opts =
          if min_bound != nil, do: Keyword.put(var_opts, :min_bound, min_bound), else: var_opts

        var_opts =
          if max_bound != nil, do: Keyword.put(var_opts, :max_bound, max_bound), else: var_opts

        Problem.variables(
          acc,
          name,
          generators,
          type,
          var_opts
        )

      # Generator syntax: variables("name", [generators], :type, opts_or_desc) - MATCH SECOND
      {:variables, _, [name, generators, type, opts_or_desc]} = _ast, acc ->
        case opts_or_desc do
          desc when is_binary(desc) ->
            Problem.variables(acc, name, generators, type, description: desc)

          opts when is_list(opts) ->
            Problem.variables(acc, name, generators, type, opts)
        end

      # Generator syntax without description: variables("name", [generators], :type)
      {:variables, _, [name, generators, type]} = _ast, acc
      when is_binary(name) and is_list(generators) and is_atom(type) ->
        Problem.variables(acc, name, generators, type, [])

      {:constraints, _, [constraint_expr, desc]} = _ast, acc
      when is_tuple(constraint_expr) and is_binary(desc) ->
        constraint = parse_simple_constraint_expression(acc, constraint_expr, desc)
        Problem.add_constraint(acc, constraint)

      {:constraints, _, [constraint_expr]} = _ast, acc when is_tuple(constraint_expr) ->
        constraint = parse_simple_constraint_expression(acc, constraint_expr, nil)
        Problem.add_constraint(acc, constraint)

      {:constraints, _, [generators, constraint_expr, desc]} = _ast, acc ->
        Problem.constraints(acc, generators, constraint_expr, desc)

      {:constraints, _, [generators, constraint_expr]} = _ast, acc ->
        Problem.constraints(acc, generators, constraint_expr, nil)

      {:objective, _, [objective_expr, opts]} = _ast, acc ->
        Problem.objective(acc, objective_expr, opts)

      {:objective, _, [[], objective_expr, opts]} = _ast, acc ->
        Problem.objective(acc, objective_expr, opts)

      {:tap, _, [fun_ast]} = _ast, acc ->
        {fun, _} = Code.eval_quoted(fun_ast, [])
        _ = fun.(acc)
        acc

      other, _acc ->
        raise ArgumentError, "Unsupported expression inside modify: #{inspect(other)}"
    end)
  end

  # Transform helper functions
  defp transform_constraint_expression_to_ast(expr),
    do: Dantzig.Problem.AST.transform_constraint_expression_to_ast(expr)

  defp transform_objective_expression_to_ast(expr),
    do: Dantzig.Problem.AST.transform_objective_expression_to_ast(expr)

  # Parse simple constraint expression
  defp parse_simple_constraint_expression(problem, constraint_expr, description),
    do:
      Dantzig.Problem.ConstraintParser.parse_simple_constraint_expression(
        problem,
        constraint_expr,
        description
      )
end
