defmodule Dantzig.Problem do
  @moduledoc """
  Optimization model: variables, constraints, and objective.

  A problem holds:

  - `:direction` – `:maximize` or `:minimize`
  - `:objective` – a `Dantzig.Polynomial` (linear or quadratic)
  - `:variable_defs` – map of scalar variable name to `%Dantzig.ProblemVariable{}` containing
    optional bounds and `:type`
  - `:variables` – map of variable set name to index-to-monomial mapping
    (N‑D families; scalars appear with the empty tuple key `{}`)
  - `:constraints` – map of unique constraint id to `%Dantzig.Constraint{}`

  Build a problem by creating variables, adding constraints, and adjusting
  the objective. Then solve with `Dantzig.solve/1`.
  """
  alias Dantzig.Polynomial
  alias Dantzig.ProblemVariable
  alias Dantzig.Constraint
  alias Dantzig.SolvedConstraint

  @nr_of_zeros 8

  @type t :: %__MODULE__{}

  defstruct variable_counter: 0,
            constraint_counter: 0,
            objective: Polynomial.const(0.0),
            direction: nil,
            name: nil,
            description: nil,
            variable_defs: %{},
            variables: %{},
            constraints: %{},
            contraints_metadata: %{}

  @spec solve_for_all_variables(t()) :: %{
          ProblemVariable.variable_namme() => SolvedConstraint.t()
        }
  def solve_for_all_variables(%__MODULE__{} = problem) do
    Enum.reduce(problem.constraints, %{}, fn {_id, constraint}, acc ->
      variable_names = Polynomial.variables(constraint.left_hand_side)

      Enum.reduce(variable_names, acc, fn variable_name, acc2 ->
        solved_constraint = Constraint.solve_for_variable(constraint, variable_name)

        if solved_constraint do
          Map.put(acc2, variable_name, solved_constraint)
        else
          acc2
        end
      end)
    end)
  end

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    name = Keyword.get(opts, :name)
    description = Keyword.get(opts, :description)

    %__MODULE__{
      name: name,
      description: description
    }
  end

  @spec add_constraint(t(), Constraint.t()) :: t()
  def add_constraint(problem, constraint) do
    constraint_id = generate_constraint_id(problem.constraint_counter)
    new_constraint_counter = problem.constraint_counter + 1

    %{
      problem
      | constraints: Map.put(problem.constraints, constraint_id, constraint),
        constraint_counter: new_constraint_counter
    }
  end

  @spec new_variable(t(), String.t(), keyword()) :: {t(), Polynomial.t()}
  def new_variable(problem, name, opts \\ []) do
    type = Keyword.get(opts, :type, :continuous)
    min_bound = Keyword.get(opts, :min, nil)
    max_bound = Keyword.get(opts, :max, nil)
    description = Keyword.get(opts, :description, nil)

    # Set default bounds for binary variables if not specified
    {final_min, final_max} =
      case {type, min_bound, max_bound} do
        {:binary, nil, nil} -> {0, 1}
        {:binary, nil, max_val} -> {0, max_val}
        {:binary, min_val, nil} -> {min_val, 1}
        _ -> {min_bound, max_bound}
      end

    variable = %ProblemVariable{
      name: name,
      type: type,
      min: final_min,
      max: final_max,
      description: description
    }

    new_problem = %{
      problem
      | variable_defs: Map.put(problem.variable_defs, name, variable),
        variable_counter: problem.variable_counter + 1
    }

    monomial = Polynomial.variable(name)

    # mirror scalar in N-D map with empty tuple key
    existing_map = Map.get(new_problem.variables, name, %{})
    updated_map = Map.put(existing_map, {}, monomial)

    newer_problem = %{
      new_problem
      | variables: Map.put(new_problem.variables, name, updated_map)
    }

    {newer_problem, monomial}
  end

  @spec new_unmangled_variable(t(), String.t(), keyword()) :: {t(), Polynomial.t()}
  def new_unmangled_variable(problem, name, opts \\ []) do
    new_variable(problem, name, opts)
  end

  @doc """
  Compatibility: add a variable with default settings.
  Returns {problem, monomial}.
  """
  def add_variable(problem, name) do
    new_variable(problem, name, [])
  end

  @spec new_variables(t(), [String.t()], keyword()) :: {t(), [Polynomial.t()]}
  def new_variables(problem, names, opts \\ []) do
    Enum.reduce(names, {problem, []}, fn name, {current_problem, monomials} ->
      {new_problem, monomial} = new_variable(current_problem, name, opts)
      {new_problem, [monomial | monomials]}
    end)
    |> then(fn {final_problem, monomials} -> {final_problem, Enum.reverse(monomials)} end)
  end

  @spec minimize(t(), Polynomial.t()) :: t()
  def minimize(problem, objective) do
    %{problem | objective: objective, direction: :minimize}
  end

  @spec maximize(t(), Polynomial.t()) :: t()
  def maximize(problem, objective) do
    %{problem | objective: objective, direction: :maximize}
  end

  @spec set_objective(t(), Polynomial.t()) :: t()
  def set_objective(problem, objective) do
    %{problem | objective: objective}
  end

  @spec increment_objective(t(), Polynomial.t()) :: t()
  def increment_objective(problem, objective_increment) do
    new_objective = Polynomial.add(problem.objective, objective_increment)
    %{problem | objective: new_objective}
  end

  @spec get_variable(t(), String.t()) :: ProblemVariable.t() | nil
  def get_variable(problem, name) do
    Map.get(problem.variable_defs, name)
  end

  @spec get_constraint(t(), String.t()) :: Constraint.t() | nil
  def get_constraint(problem, constraint_id) do
    Map.get(problem.constraints, constraint_id)
  end

  @spec get_variables_nd(t(), String.t()) :: map() | nil
  def get_variables_nd(problem, set_name) do
    Map.get(problem.variables, set_name)
  end

  @spec put_variables_nd(t(), String.t(), map()) :: t()
  def put_variables_nd(problem, set_name, var_map) do
    %{problem | variables: Map.put(problem.variables, set_name, var_map)}
  end

  # Imperative API functions for integration tests

  @doc """
  Add variables to a problem using imperative syntax.

  This macro supports the imperative API used in integration tests.
  """
  defmacro add_variables(problem, var_name, generators, var_type, description \\ nil) do
    # Transform raw generator syntax to proper AST format using the same approach as define macro
    transformed_generators =
      Macro.prewalk(generators, fn
        {:<-, meta, [var, range]} ->
          # Handle variables from outer scope by properly quoting them
          {:<-, meta, [quote(do: unquote(var)), range]}

        other ->
          other
      end)

    quote do
      # Ensure modules/macros are available in the generated context
      require Dantzig.Problem.DSL, as: DSL

      # Process the generators with the current environment
      unquote(__MODULE__).__add_variables_with_env__(
        unquote(problem),
        unquote(Macro.escape(transformed_generators)),
        unquote(var_name),
        unquote(var_type),
        unquote(description),
        binding()
      )
    end
  end

  @doc """
  Set objective function using imperative syntax.

  This macro supports the imperative API used in integration tests.
  """
  defmacro set_objective(problem, objective_expr, opts) do
    quote do
      # Ensure modules/macros are available in the generated context
      require Dantzig.Problem.DSL, as: DSL

      # Process the objective with the current environment
      unquote(__MODULE__).__set_objective_with_env__(
        unquote(problem),
        unquote(Macro.escape(objective_expr)),
        unquote(opts),
        binding()
      )
    end
  end

  # Helper functions for imperative API macro transformation

  @doc false
  defp transform_generators_to_ast(generators),
    do: Dantzig.Problem.AST.transform_generators_to_ast(generators)

  @doc false
  defp transform_constraint_expression_to_ast(expr),
    do: Dantzig.Problem.AST.transform_constraint_expression_to_ast(expr)

  @doc false
  defp transform_objective_expression_to_ast(expr),
    do: Dantzig.Problem.AST.transform_objective_expression_to_ast(expr)

  @doc false
  defp transform_description_to_ast(description),
    do: Dantzig.Problem.AST.transform_description_to_ast(description)

  @doc """
  Solve the problem and return both solution and objective value.

  This is a convenience function for the new DSL that returns `{solution, objective}`.
  """
  @spec solve(t(), keyword()) :: {Dantzig.Solution.t(), number()} | :error
  def solve(%__MODULE__{} = problem, opts \\ []) do
    print_optimizer_input = Keyword.get(opts, :print_optimizer_input, false)

    case Dantzig.solve(problem, print_optimizer_input: print_optimizer_input) do
      {:ok, solution} -> {solution, solution.objective}
      :error -> :error
    end
  end

  @doc """
  Macro entrypoint to define a problem with unqualified DSL calls inside a block.

  Supports inside the block:
  - `new(opts)` – initializes the problem
  - `variables(name, generators, type, opts_or_desc)` – adds variables
  - `constraints(generators, expr, desc \\ nil)` – adds constraints
  - `objective(expr, opts)` – sets objective

  Additionally, rewrites nested `sum(...)` calls to `Dantzig.Problem.DSL.sum/1`
  so they expand correctly without requiring explicit imports in user code.
  """
  defmacro define(do: block) do
    define_impl(block, [])
  end

  @doc """
  Macro entrypoint to define a problem with model parameters.

  Accepts `model_parameters:` keyword option to provide runtime values
  accessible within the DSL block.

  Example:
    Problem.define model_parameters: %{food_names: ["bread", "milk"]} do
      variables("qty", [food <- food_names], :continuous, "Amount")
    end
  """
  defmacro define(opts, do: block) when is_list(opts) do
    define_impl(block, opts)
  end

  # Internal implementation shared by define/1 and define/2
  defp define_impl(block, opts) do
    # Extract model_parameters AST from options if provided (will be evaluated at runtime)
    model_params_ast = Keyword.get(opts, :model_parameters, nil)
    
    # Rewrite nested calls that must be qualified (e.g., sum(...))
    # and transform generator syntax [var <- list] into quoted expressions
    rewritten_block =
      Macro.prewalk(block, fn
        {:sum, meta, args} ->
          {{:., meta, [Dantzig.Problem.DSL, :sum]}, meta, args}

        # Transform generator syntax [var <- list] into quoted expressions
        list when is_list(list) ->
          Enum.map(list, fn
            {:<-, meta2, [var2, range2]} ->
              {:<-, meta2, [quote(do: unquote(var2)), range2]}
            other ->
              other
          end)

        other ->
          other
      end)

    # Normalize block to a flat list of expressions
    exprs =
      case rewritten_block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    quote do
      # Ensure modules/macros are available in the generated context
      require Dantzig.Problem.DSL, as: DSL

      # Evaluate model parameters at runtime and merge with caller bindings
      model_params = unquote(model_params_ast || quote(do: %{}))
      caller_binding = binding()
      
      # Merge model parameters into binding for variable resolution
      # Model parameters take precedence over caller bindings if there's a conflict
      extended_binding = 
        case model_params do
          %{} = params_map when map_size(params_map) > 0 ->
            # Convert map to keyword list format for Code.eval_quoted
            Enum.reduce(params_map, caller_binding, fn {key, value}, acc ->
              Keyword.put(acc, key, value)
            end)
          _ ->
            caller_binding
        end

      # Process the block expressions left-to-right, threading the problem
      unquote(__MODULE__).__define_with_env__(unquote(Macro.escape(exprs)), extended_binding)
    end
  end

  @doc """
  Modify an existing problem by applying additional DSL statements inside a block.

  Supports inside the block (same as in define, but without `new/1`):
  - `variables(name, generators, type, opts_or_desc)` – adds variables
  - `constraints(generators, expr, desc \\ nil)` – adds constraints
  - `objective(expr, opts)` – sets or updates objective

  Additionally, rewrites nested `sum(...)` calls to `Dantzig.Problem.DSL.sum/1`
  so they expand correctly without requiring explicit imports in user code.
  """
  defmacro modify(problem, do: block) do
    rewritten_block =
      Macro.prewalk(block, fn
        {:sum, meta, args} ->
          {{:., meta, [Dantzig.Problem.DSL, :sum]}, meta, args}

        list when is_list(list) ->
          case list do
            [{:<-, _, [var, list_expr]}] ->
              [{:<-, [], [quote(do: unquote(var)), list_expr]}]

            _ ->
              list
          end

        other ->
          other
      end)

    exprs =
      case rewritten_block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    quote do
      require Dantzig.Problem.DSL, as: DSL

      unquote(__MODULE__).__modify_with_env__(
        unquote(problem),
        unquote(Macro.escape(exprs)),
        binding()
      )
    end
  end

  # Helper used by the imperative API macros to process with environment
  def __add_variables_with_env__(problem, generators, var_name, var_type, description, env) do
    # Set the environment for variable resolution
    Process.put(:dantzig_eval_env, env)

    try do
      Dantzig.Problem.DSL.__add_variables__(problem, generators, var_name, var_type, description)
    after
      Process.delete(:dantzig_eval_env)
    end
  end

  def __set_objective_with_env__(problem, objective_expr, opts, env) do
    # Set the environment for variable resolution
    Process.put(:dantzig_eval_env, env)

    try do
      Dantzig.Problem.DSL.__set_objective__(problem, objective_expr, opts)
    after
      Process.delete(:dantzig_eval_env)
    end
  end

  # Helper used by the macro to reduce the block at compile-time into runtime calls
  def __define_reduce__(exprs) when is_list(exprs) do
    {initial_problem, rest} =
      case exprs do
        [{:new, _, [opts]} | tail] -> {new(opts), tail}
        [{:new, _, []} | tail] -> {new([]), tail}
        _ -> raise ArgumentError, "First expression inside define must be new/1"
      end

    Enum.reduce(rest, initial_problem, fn
      # Support simple for-comprehension inside define for variables expansion
      # Example: for food <- food_names, do: variables("qty", [food], :continuous, "desc")
      {:for, _, [{:<-, _, [var_ast, domain_expr]}, [do: inner_ast]]} = _ast, acc ->
        # Evaluate domain in caller env
        values = Dantzig.Problem.DSL.VariableManager.evaluate_expression(domain_expr)

        Enum.reduce(values, acc, fn value, acc_problem ->
          case {var_ast, inner_ast} do
            {head_var_ast, {:variables, meta, [name, gen_list, type, desc]}}
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
                      new_name = name <> "_" <> to_string(value)

                      {new_p, _} =
                        new_variable(acc_problem, new_name, type: type, description: desc)

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

      # Simple syntax: variables("name", :type, "description")
      {:variables, _, [name, type, description]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_binary(description) ->
        # Create single variable with simple syntax
        {new_problem, _} = new_variable(acc, name, type: type, description: description)
        new_problem

      # Simple syntax with options: variables("name", :type, description: "desc", min: 0, max: 1)
      {:variables, _, [name, type | opts]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_list(opts) ->
        # Extract description from opts if present, otherwise use nil
        description = Keyword.get(opts, :description)
        var_opts = Keyword.delete(opts, :description)

        {new_problem, _} =
          new_variable(acc, name, [type: type, description: description] ++ var_opts)

        new_problem

      # Generator syntax: variables("name", [generators], :type, opts_or_desc)
      {:variables, _, [name, generators, type, opts_or_desc]} = _ast, acc ->
        # Allow either description string or keyword opts; if interpolated binary AST, skip description
        case opts_or_desc do
          desc when is_binary(desc) ->
            variables(acc, name, generators, type, description: desc)

          {:<<>>, _meta, _parts} ->
            # Interpolated binary with generator vars – defer naming; pass no description
            variables(acc, name, generators, type, [])

          opts when is_list(opts) ->
            variables(acc, name, generators, type, opts)
        end

      # Simple constraints: constraints(expr, desc) - no generators
      {:constraints, _, [constraint_expr, desc]} = _ast, acc
      when is_tuple(constraint_expr) and is_binary(desc) ->
        # For simple constraints, parse the expression directly without generators
        transformed = transform_constraint_expression_to_ast(constraint_expr)
        constraint = parse_simple_constraint_expression(transformed, desc)
        Dantzig.Problem.add_constraint(acc, constraint)

      # Simple constraints: constraints(expr) - no generators, no description
      {:constraints, _, [constraint_expr]} = _ast, acc when is_tuple(constraint_expr) ->
        # For simple constraints, parse the expression directly without generators
        transformed = transform_constraint_expression_to_ast(constraint_expr)
        constraint = parse_simple_constraint_expression(transformed, nil)
        Dantzig.Problem.add_constraint(acc, constraint)

      # Generator-based constraints: constraints(generators, expr, desc)
      {:constraints, _, [generators, constraint_expr, desc]} = _ast, acc ->
        constraints(acc, generators, constraint_expr, desc)

      # Generator-based constraints: constraints(generators, expr)
      {:constraints, _, [generators, constraint_expr]} = _ast, acc ->
        constraints(acc, generators, constraint_expr, nil)

      # No-generator constraints forms
      {:constraints, _, [constraint_expr, desc]} = _ast, acc ->
        constraints(acc, [], constraint_expr, desc)

      {:constraints, _, [constraint_expr]} = _ast, acc ->
        constraints(acc, [], constraint_expr, nil)

      {:objective, _, [objective_expr, opts]} = _ast, acc ->
        transformed = transform_objective_expression_to_ast(objective_expr)
        objective(acc, transformed, opts)

      # Allow objective([], expr, opts) – ignore first list for now
      {:objective, _, [[], objective_expr, opts]} = _ast, acc ->
        transformed = transform_objective_expression_to_ast(objective_expr)
        objective(acc, transformed, opts)

      # Allow tap(fun) to inspect/log the current problem and continue
      {:tap, _, [fun_ast]} = _ast, acc ->
        {fun, _} = Code.eval_quoted(fun_ast, [])
        _ = fun.(acc)
        acc

      other, _acc ->
        raise ArgumentError, "Unsupported expression inside define: #{inspect(other)}"
    end)
  end

  # Internal helper to run reduce with caller's runtime bindings available
  def __define_with_env__(exprs, env) when is_list(exprs) and is_list(env) do
    previous = Process.get(:dantzig_eval_env)
    Process.put(:dantzig_eval_env, env)

    try do
      __define_reduce__(exprs)
    after
      if previous do
        Process.put(:dantzig_eval_env, previous)
      else
        Process.delete(:dantzig_eval_env)
      end
    end
  end

  # Internal helper to run modify with caller's runtime bindings available
  def __modify_with_env__(%__MODULE__{} = problem, exprs, env)
      when is_list(exprs) and is_list(env) do
    previous = Process.get(:dantzig_eval_env)
    Process.put(:dantzig_eval_env, env)

    try do
      __modify_reduce__(problem, exprs)
    after
      if previous do
        Process.put(:dantzig_eval_env, previous)
      else
        Process.delete(:dantzig_eval_env)
      end
    end
  end

  # Reduce over modify expressions reusing same handlers as define (minus new/1)
  def __modify_reduce__(%__MODULE__{} = initial_problem, exprs) when is_list(exprs) do
    Enum.reduce(exprs, initial_problem, fn
      {:variables, _, [name, type, description]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_binary(description) ->
        {new_problem, _} = new_variable(acc, name, type: type, description: description)
        new_problem

      {:variables, _, [name, type | opts]} = _ast, acc
      when is_binary(name) and is_atom(type) and is_list(opts) ->
        description = Keyword.get(opts, :description)
        var_opts = Keyword.delete(opts, :description)

        {new_problem, _} =
          new_variable(acc, name, [type: type, description: description] ++ var_opts)

        new_problem

      {:variables, _, [name, generators, type, opts_or_desc]} = _ast, acc ->
        case opts_or_desc do
          desc when is_binary(desc) ->
            variables(acc, name, generators, type, description: desc)

          opts when is_list(opts) ->
            variables(acc, name, generators, type, opts)
        end

      {:constraints, _, [constraint_expr, desc]} = _ast, acc
      when is_tuple(constraint_expr) and is_binary(desc) ->
        constraint = parse_simple_constraint_expression(constraint_expr, desc)
        Dantzig.Problem.add_constraint(acc, constraint)

      {:constraints, _, [constraint_expr]} = _ast, acc when is_tuple(constraint_expr) ->
        constraint = parse_simple_constraint_expression(constraint_expr, nil)
        Dantzig.Problem.add_constraint(acc, constraint)

      {:constraints, _, [generators, constraint_expr, desc]} = _ast, acc ->
        constraints(acc, generators, constraint_expr, desc)

      {:constraints, _, [generators, constraint_expr]} = _ast, acc ->
        constraints(acc, generators, constraint_expr, nil)

      {:objective, _, [objective_expr, opts]} = _ast, acc ->
        objective(acc, objective_expr, opts)

      {:objective, _, [[], objective_expr, opts]} = _ast, acc ->
        objective(acc, objective_expr, opts)

      {:tap, _, [fun_ast]} = _ast, acc ->
        {fun, _} = Code.eval_quoted(fun_ast, [])
        _ = fun.(acc)
        acc

      other, _acc ->
        raise ArgumentError, "Unsupported expression inside modify: #{inspect(other)}"
    end)
  end

  # New DSL Functions (JuMP-like API)

  @doc """
  Create variables with JuMP-like syntax.

  ## Examples

      # Single variable
      problem = Problem.variable(problem, "x", :continuous, min: 0, max: 10)

      # Multiple variables with generators
      problem = Problem.variables(problem, "x", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  """
  @spec variables(t(), String.t(), list(), atom(), keyword()) :: t()
  def variables(problem, var_name, generators, var_type, opts \\ []) do
    description = Keyword.get(opts, :description)

    # Use the existing DSL implementation
    Dantzig.Problem.DSL.__add_variables__(
      problem,
      generators,
      var_name,
      var_type,
      description
    )
  end

  @doc """
  Create a single variable with JuMP-like syntax.

  ## Examples

      problem = Problem.variable(problem, "x", :continuous, min: 0, max: 10)
  """
  @spec variable(t(), String.t(), atom(), keyword()) :: {t(), Polynomial.t()}
  def variable(problem, var_name, var_type, opts \\ []) do
    min_bound = Keyword.get(opts, :min)
    max_bound = Keyword.get(opts, :max)
    _description = Keyword.get(opts, :description)

    new_variable(problem, var_name, type: var_type, min: min_bound, max: max_bound)
  end

  # Public: Add constraints with JuMP-like syntax.
  # Used by both the define/modify reducers and publicly in tests.
  @spec constraints(t(), list(), any(), String.t() | nil) :: t()
  def constraints(problem, generators, constraint_expr, description \\ nil) do
    # Use the working constraint manager implementation
    Dantzig.Problem.DSL.ConstraintManager.add_constraints(
      problem,
      generators,
      constraint_expr,
      description
    )
  end

  @doc """
  Add a single constraint with JuMP-like syntax.

  ## Examples

      problem = Problem.constraint(problem, x <= 10, "Variable bound")
  """
  @spec constraint(t(), any(), String.t() | nil) :: t()
  def constraint(_problem, _constraint_expr, _description \\ nil) do
    # For single constraints, we need to parse the expression
    # This is a simplified version - full implementation would need expression parsing
    # For now, raise a helpful error explaining this limitation
    raise ArgumentError, """
    Single constraint syntax is not yet fully implemented.

    For now, please use:
    - Problem.constraints/4 for pattern-based constraints
    - Problem.add_constraint/2 for manually created constraints

    Example:
        # Instead of: Problem.constraint(problem, x <= 10)
        # Use: Problem.constraints(problem, [], x <= 10)
        # Or create constraint manually: Problem.add_constraint(problem, Constraint.new_linear(x <= 10))
    """
  end

  @doc """
  Set objective with JuMP-like syntax.

  ## Examples

      problem = Problem.objective(problem, x + 2*y, direction: :maximize)
  """
  @spec objective(t(), any(), keyword()) :: t()
  def objective(problem, objective_expr, opts \\ []) do
    # Use the existing DSL implementation
    Dantzig.Problem.DSL.__set_objective__(
      problem,
      objective_expr,
      opts
    )
  end

  # Private functions

  defp generate_constraint_id(counter) do
    "c#{String.pad_leading(to_string(counter), 8, "0")}"
  end

  # Parse simple constraint expressions (no generators)
  defp parse_simple_constraint_expression(constraint_expr, description) do
    case constraint_expr do
      {:==, _, [left_expr, right_value]} ->
        left_poly = parse_simple_expression_to_polynomial(left_expr)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_simple_expression_to_polynomial(right_value)
          end

        Constraint.new_linear(left_poly, :==, right_poly, name: description)

      {:<=, _, [left_expr, right_value]} ->
        left_poly = parse_simple_expression_to_polynomial(left_expr)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_simple_expression_to_polynomial(right_value)
          end

        Constraint.new_linear(left_poly, :<=, right_poly, name: description)

      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_simple_expression_to_polynomial(left_expr)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_simple_expression_to_polynomial(right_value)
          end

        Constraint.new_linear(left_poly, :>=, right_poly, name: description)

      _ ->
        raise ArgumentError,
              "Unsupported simple constraint expression: #{inspect(constraint_expr)}"
    end
  end

  # Evaluate simple expressions to numeric values where possible
  defp evaluate_simple_expression(expr),
    do: Dantzig.Problem.AST.evaluate_simple_expression(expr)

  # Parse simple expressions to polynomials (no bindings needed for simple variables)
  defp parse_simple_expression_to_polynomial(expr),
    do: Dantzig.Problem.AST.parse_simple_expression_to_polynomial(expr)
end
