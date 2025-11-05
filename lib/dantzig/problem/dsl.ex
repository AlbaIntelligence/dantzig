defmodule Dantzig.Problem.DSL do
  @moduledoc """
  Domain-specific language for building optimization problems with natural syntax.

  This module provides the exact DSL syntax as specified by the user.
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial
  alias Dantzig.Problem.DSL.Internal

  # Import DSL components
  import Dantzig.DSL.SumFunction, only: [sum: 1, sum: 3]

  # Test functions for experimental features
  defmacro access_variable_test(var_name, indices) do
    quote do
      {:access_test, unquote(var_name), unquote(indices)}
    end
  end

  defmacro access_transform_test(var_name, indices) do
    quote do
      {:access_transform, unquote(var_name), unquote(indices)}
    end
  end

  defmacro access_proof_of_concept(var_name, indices) do
    quote do
      {:access_proof_of_concept, unquote(var_name), unquote(indices)}
    end
  end

  # Variables with bounds - var_name, generators, type, description, opts (MOST SPECIFIC - 5 args)
  defmacro variables(var_name, generators, type, description, opts)
           when is_list(generators) and is_atom(type) and is_binary(description) and is_list(opts) do
    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # Variables with bounds - var_name, generators, type, opts (4 args with bounds)
  defmacro variables(var_name, generators, type, opts)
           when is_list(generators) and is_atom(type) and is_list(opts) do
    description = Keyword.get(opts, :description) || ""

    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # Variables without bounds - var_name, generators, type, description (4 args, no bounds)
  defmacro variables(var_name, generators, type, description)
           when is_list(generators) and is_atom(type) and is_binary(description) do
    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type),
         unquote(description)
       ]}
    end
  end

  # Variables with bounds - var_name, type, description, opts (4 args, no generators)
  defmacro variables(var_name, type, description, opts)
           when is_atom(type) and is_binary(description) and is_list(opts) do
    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         [],
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # Variables with bounds - var_name, type, opts (3 args with bounds)
  defmacro variables(var_name, type, opts)
           when is_atom(type) and is_list(opts) and not is_binary(hd(opts)) do
    description = Keyword.get(opts, :description) || ""

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         [],
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # Variables without bounds - var_name, type, description (3 args, no bounds)
  defmacro variables(var_name, type, description) when is_atom(type) and is_binary(description) do
    quote do
      {:variables, [],
       [
         unquote(var_name),
         [],
         unquote(type),
         unquote(description)
       ]}
    end
  end

  # DEPRECATED: Backward compatibility wrapper for tests that call DSL.variables with problem as first arg
  # Use add_variables/5 instead
  @deprecated "Use add_variables/5 instead of variables/5"
  defmacro variables(problem, var_name, generators, var_type, opts) do
    quote do
      Dantzig.Problem.DSL.VariableManager.add_variables(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(var_type),
        unquote(opts)
      )
    end
  end

  @doc """
  External API for adding variables to an existing problem.
  This is the preferred way to add variables outside of Problem.define/modify blocks.

  ## Examples

      # Add variables with generators
      problem = DSL.add_variables(problem, "x", [i <- 1..4], :continuous, "Decision variables")

      # Add single variable
      problem = DSL.add_variables(problem, "y", [], :binary, "Binary variable")
  """
  defmacro add_variables(problem, var_name, generators, var_type, description) do
    quote do
      Dantzig.Problem.DSL.VariableManager.add_variables(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(var_type),
        unquote(description)
      )
    end
  end

  @doc """
  Main DSL macro for defining optimization problems.

  This macro provides a declarative syntax for defining problems with variables,
  constraints, and objectives. It generates individual Problem.add_constraint calls.

  Example:
    problem = Problem.define do
      new(name: "My Problem")
      variables("x", [i <- 1..3], :continuous)
      constraints([i <- 1..3], x(i) <= 1)
      objective(sum(x(i) for i <- 1..3), :maximize)
    end
  """
  defmacro define(do: block) do
    quote do
      Dantzig.Problem.define do
        unquote(block)
      end
    end
  end

  @doc """
  Main DSL macro for defining optimization problems with model parameters.

  This macro provides a declarative syntax for defining problems with variables,
  constraints, and objectives, with access to model parameters.

  Example:
    problem = Problem.define(model_parameters: params) do
      new(name: "My Problem")
      variables("x", [i <- 1..params.n], :continuous)
      constraints([i <- 1..params.n], x(i) <= params.max_val)
      objective(sum(x(i) for i <- 1..params.n), :maximize)
    end
  """
  defmacro define(opts, do: block) do
    quote do
      Dantzig.Problem.define unquote(opts) do
        unquote(block)
      end
    end
  end

  @doc """
  Macro to handle sum expressions with 'in' syntax.
  This transforms sum(expr in var <- list) into valid Elixir.

  Example:
    sum(qty(food) * foods[food]["cost"] in food <- food_names)

  Future: Will support 'where' for filtering:
    sum(qty(food) in food <- food_names where food != "ice_cream")
  """
  defmacro sum(expr) do
    case expr do
      # Handle sum(expr in var <- list) syntax
      {:in, meta, [inner_expr, [{:<-, _, [var, list]}]]} ->
        # Transform the in syntax into a sum expression
        quote do
          {:sum, [],
           [
             {:in, unquote(meta),
              [unquote(inner_expr), [{:<-, [], [unquote(var), unquote(list)]}]]}
           ]}
        end

      # Handle simple sum expressions
      simple_expr ->
        quote do
          {:sum, [], [unquote(simple_expr)]}
        end
    end
  end

  @doc """
  Macro to handle generator syntax like [i <- 1..4, j <- 1..4].
  This transforms the invalid Elixir syntax into proper AST representation.
  """
  defmacro generators(generator_list) do
    # Handle both direct lists and quoted expressions
    case generator_list do
      {:quote, _, [[do: list]]} ->
        # Handle quoted expressions like quote(do: [i <- 1..4, j <- 1..4])
        transformed_generators =
          Enum.map(list, fn
            {:<-, meta, [var, range]} ->
              # Convert to proper AST format
              {:<-, meta, [quote(do: unquote(var)), range]}

            other ->
              other
          end)

        quote do
          unquote(transformed_generators)
        end

      list when is_list(list) ->
        # Handle direct lists
        transformed_generators =
          Enum.map(list, fn
            {:<-, meta, [var, range]} ->
              # Convert to proper AST format
              {:<-, meta, [quote(do: unquote(var)), range]}

            other ->
              other
          end)

        quote do
          unquote(transformed_generators)
        end

      other ->
        quote do
          unquote(other)
        end
    end
  end

  @doc """
  Internal DSL syntax for variables inside Problem.define/modify blocks.
  This is the clean syntax used within define blocks without needing to pass the problem.

  Supports:
  - variables("name", :type, "description")
  - variables("name", :type, "description", min_bound: 0, max_bound: 100)
  - variables("name", [generators], :type, "description")
  - variables("name", [generators], :type, "description", min_bound: 0, max_bound: 100)
  """
  # variables("name", :type, "description")
  defmacro variables(var_name, type, description) when is_atom(type) and is_binary(description) do
    quote do
      {:variables, [],
       [
         unquote(var_name),
         [],
         unquote(type),
         unquote(description)
       ]}
    end
  end

  # variables("name", :type, "description", min_bound: X, max_bound: Y)
  defmacro variables(var_name, type, description, opts)
           when is_atom(type) and is_binary(description) and is_list(opts) do
    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # variables("name", :type, opts_with_bounds)
  defmacro variables(var_name, type, opts)
           when is_atom(type) and is_list(opts) and not is_binary(hd(opts)) do
    description = Keyword.get(opts, :description) || ""

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # variables("name", [generators], :type, "description")
  defmacro variables(var_name, generators, type, description)
           when is_list(generators) and is_atom(type) and is_binary(description) do
    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type),
         unquote(description)
       ]}
    end
  end

  # variables("name", [generators], :type, "description", min_bound: X, max_bound: Y)
  defmacro variables(var_name, generators, type, description, opts)
           when is_list(generators) and is_atom(type) and is_binary(description) and is_list(opts) do
    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  # variables("name", [generators], :type, opts_with_bounds)
  defmacro variables(var_name, generators, type, opts)
           when is_list(generators) and is_atom(type) and is_list(opts) do
    description = Keyword.get(opts, :description) || ""

    # Normalize generator syntax like [i <- 1..n] to quoted var AST
    transformed_generators =
      Enum.map(generators, fn
        {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
        other -> other
      end)

    quote do
      min_bound = unquote(Keyword.get(opts, :min_bound))
      max_bound = unquote(Keyword.get(opts, :max_bound))

      {:variables, [],
       [
         unquote(var_name),
         unquote(transformed_generators),
         unquote(type)
         | [description: unquote(description)] ++
             if(min_bound != nil, do: [min_bound: min_bound], else: []) ++
             if(max_bound != nil, do: [max_bound: max_bound], else: [])
       ]}
    end
  end

  @doc """
  Public DSL macro for constraints - matches nqueens_dsl.exs syntax.
  """
  defmacro constraints(problem, generators, constraint_expr, description \\ nil) do
    # Normalize any generator list entries like [i <- 1..4] to quoted var AST
    transformed_generators =
      case generators do
        list when is_list(list) ->
          Enum.map(list, fn
            {:<-, meta, [var, range]} -> {:<-, meta, [quote(do: unquote(var)), range]}
            other -> other
          end)

        other ->
          other
      end

    # Handle description interpolation - convert string literals with #{var} to AST
    transformed_description =
      case description do
        # If description is a string literal with interpolation, convert to AST
        {:<<>>, meta, parts} when is_list(parts) ->
          # This is already an interpolated string AST, pass it through
          description

        # If description is a simple string, pass it through
        desc when is_binary(desc) ->
          description

        # If description is nil, pass it through
        nil ->
          description

        # For other cases, pass through
        other ->
          other
      end

    quote do
      Problem.constraints(
        unquote(problem),
        unquote(transformed_generators),
        unquote(constraint_expr),
        unquote(transformed_description)
      )
    end
  end

  @doc """
  Public DSL macro for objective - matches nqueens_dsl.exs syntax.

  Supports two forms:
  1. `objective(problem, objective_expr, opts)` - external API (when first arg is a variable)
  2. `objective(objective_expr, opts)` - internal DSL (inside Problem.define/modify blocks)
  """
  # Pattern match: if first arg is a 3-tuple AST (like {:problem, [], Elixir}), it's external API
  defmacro objective({problem_var, _, _} = problem, objective_expr, opts)
           when is_atom(problem_var) do
    # External API form - call the function directly
    quote do
      unquote(__MODULE__).__set_objective__(
        unquote(problem),
        unquote(objective_expr),
        unquote(opts)
      )
    end
  end

  # Pattern match: if first arg is not a 3-tuple, it's the internal DSL form
  defmacro objective(objective_expr, opts) do
    # Internal DSL form - capture as AST for Problem.define/modify blocks
    quote do
      {:objective, [], [unquote(objective_expr), unquote(opts)]}
    end
  end

  defmacro objective(objective_expr) do
    # Internal DSL form with no opts
    quote do
      {:objective, [], [unquote(objective_expr), []]}
    end
  end

  @doc """
  Backward-compatible helper used by experimental tests to build bracket variable access AST.

  Example:
      var_bracket(:queen2d, [:_, :_])
  """
  defmacro var_bracket(var_name, indices) do
    quote do
      {unquote(var_name), [], unquote(indices)}
    end
  end

  # Backward compatibility shims - delegate to new Problem module functions
  # These maintain compatibility with existing code while providing new API

  @doc """
  Shim for backward compatibility - delegates to Problem.variables/5
  """
  def add_variables_shim(problem, generators, var_name, var_type, description) do
    Problem.variables(problem, var_name, generators, var_type, description: description)
  end

  @doc """
  Set the objective function with direction.

  ## Examples

      # Minimize total cost
      problem = Problem.DSL.set_objective(problem, sum(x[_, _]), direction: :minimize)
  """
  defmacro set_objective(problem, objective_expr, opts \\ []) do
    quote do
      unquote(__MODULE__).__set_objective__(
        unquote(problem),
        unquote(objective_expr),
        unquote(opts)
      )
    end
  end

  @doc """
  Shim for backward compatibility - delegates to Problem.objective/3
  """
  def set_objective_shim(problem, objective_expr, opts) do
    Problem.objective(problem, objective_expr, opts)
  end

  # Implementation functions

  def __add_variables__(problem, generators, var_name, var_type, opts_or_description),
    do:
      Dantzig.Problem.DSL.VariableManager.add_variables(
        problem,
        generators,
        var_name,
        var_type,
        opts_or_description
      )

  def __set_objective__(problem, objective_expr, opts),
    do: Internal.set_objective(problem, objective_expr, opts)

  # Experimental bracket syntax functions for testing

  @doc """
  Test function for double bracket access syntax like queen2d[[i, :_]]
  """
  def double_bracket_access(var_name, indices) do
    {var_name, [], [indices]}
  end

  @doc """
  Test function for tuple bracket access syntax like queen2d[{i, :_}]
  """
  def tuple_bracket_access(var_name, indices) do
    {var_name, [], [indices]}
  end

  @doc """
  Test function for bracket syntax like queen2d[i, :_]
  """
  def test_bracket_syntax(var_name, indices) do
    {var_name, [], indices}
  end

  @doc """
  Test function for Access protocol usage
  """
  def test_access_protocol(var_name, indices) do
    {var_name, [], indices}
  end

  @doc """
  Test function for dynamic macro creation
  """
  def test_dynamic_macro(var_name, indices) do
    {var_name, [], indices}
  end

  @doc """
  Test function for transforming invalid syntax
  """
  def transform_invalid_syntax(var_name, indices) do
    {var_name, [], indices}
  end

  # Helper functions for AST creation (used in tests)

  @doc """
  Create a function call AST for variable access syntax.
  Used for testing realistic syntax approaches.

  Example: func_call(:queen2d, [1, :_]) creates AST for queen2d(1, :_)
  """
  def func_call(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Create a variable helper AST for variable access syntax.
  Used for testing realistic syntax approaches.

  Example: var_helper("queen3d", [1, 2, 3]) creates AST for queen3d(1, 2, 3)
  """
  def var_helper(var_name, args) when is_binary(var_name) do
    {String.to_atom(var_name), [], args}
  end

  def var_helper(var_name, args) when is_atom(var_name) do
    {var_name, [], args}
  end

  @doc """
  Create a single bracket access AST for variable access syntax.
  Used for testing realistic syntax approaches.

  Example: single_bracket(:queen2d, [1]) creates AST for queen2d[1]
  """
  def single_bracket(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Create a dynamic variable access AST for variable access syntax.
  Used for testing realistic syntax approaches.

  Example: dynamic_var_access(:queen2d, [1, :_]) creates AST for queen2d(1, :_)
  """
  def dynamic_var_access(var_name, args) do
    {var_name, [], args}
  end

  # Additional test helper functions for bracket syntax experiments

  @doc """
  Test function for bracket breakthrough syntax.
  """
  def bracket_breakthrough(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for syntax transformer.
  """
  def syntax_transformer(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for access protocol.
  """
  def access_protocol_test(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for alternative bracket syntax.
  """
  def alternative_bracket(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for bracket macro.
  """
  def bracket_macro_test(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for multi-argument bracket syntax.
  """
  def multi_arg_bracket(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for bracket access syntax.
  """
  def bracket_access(var_name, args) do
    {var_name, [], args}
  end

  @doc """
  Test function for variable access syntax.
  """
  def var_access(var_name, args) do
    {var_name, [], args}
  end

  # TODO: REMOVE THE FOLLOWING UNUSED PLACEHOLDER FUNCTIONS AFTER CHECKING THEY ARE ACTUALLY UNUSED
  # Removed placeholder process_define_block/1 to avoid drift with Problem.define

  defp parse_generators(generators), do: Internal.parse_generators(generators)

  defp evaluate_expression(expr), do: Internal.evaluate_expression(expr)

  defp generate_combinations_from_parsed_generators(parsed_generators),
    do: Internal.generate_combinations_from_parsed_generators(parsed_generators)

  defp create_bindings(parsed_generators, index_vals),
    do: Internal.create_bindings(parsed_generators, index_vals)

  defp parse_constraint_expression(constraint_expr, bindings, problem),
    do: Internal.parse_constraint_expression(constraint_expr, bindings, problem)

  defp parse_expression_to_polynomial(expr, bindings, problem),
    do: Internal.parse_expression_to_polynomial(expr, bindings, problem)

  defp parse_objective_expression(objective_expr, problem),
    do: Internal.parse_objective_expression(objective_expr, problem)

  defp parse_sum_expression(expr, bindings, problem),
    do: Internal.parse_sum_expression(expr, bindings, problem)

  # Normalize remote-call sum ASTs into tuple form expected by the parser
  defp normalize_sum_ast(expr), do: Internal.normalize_sum_ast(expr)

  defp create_var_name(var_name, index_vals), do: Internal.create_var_name(var_name, index_vals)

  defp create_constraint_name(description, index_vals),
    do: Internal.create_constraint_name(description, index_vals)
end
