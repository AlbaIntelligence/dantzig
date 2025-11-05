defmodule Dantzig.Problem.AST do
  @moduledoc false

  alias Dantzig.Polynomial

  # Generator transformation helpers
  def transform_generators_to_ast(generators) do
    case generators do
      list when is_list(list) ->
        if Enum.all?(list, fn
             {:<-, _, [var, _range]} when is_atom(var) -> true
             _ -> false
           end) do
          Enum.map(list, fn {:<-, meta, [var, range]} ->
            {:<-, meta, [quote(do: unquote(var)), range]}
          end)
        else
          generators
        end

      other ->
        other
    end
  end

  # Expression transformers (objective/constraint normalization)
  # Transform constraint expressions to ensure variable references are properly formatted
  # Handles patterns like queen2d(i, :_) or qty(food) where variables come from generators
  def transform_constraint_expression_to_ast(expr) do
    # Walk the AST and normalize variable references in function call patterns
    # e.g., queen2d(i, :_) or qty(food) where i/food are generator variables
    Macro.prewalk(expr, fn
      # Variable reference pattern: var_name(var1, var2, ...)
      {var_name, meta, args} when is_atom(var_name) and is_list(args) ->
        # Check if this looks like a variable reference (function call syntax for variables)
        # Transform variable references in args to ensure they're in the right format
        normalized_args =
          Enum.map(args, fn
            # AST tuple representing a generator variable: {:i, [], Elixir} -> :i
            # Extract the atom so ExpressionParser can look it up in bindings
            {atom, _, ctx} when is_atom(atom) and (is_atom(ctx) or is_nil(ctx)) ->
              # Normalize to just the atom for bindings lookup
              atom
            
            # Pattern matching for :_ wildcard - keep as-is
            :_ ->
              :_
            
            # Already normalized atom - keep as-is
            atom when is_atom(atom) ->
              atom
            
            # Numeric literals and other values - keep as-is
            other ->
              other
          end)
        
        {var_name, meta, normalized_args}
      
      # Other AST nodes - keep as-is
      other ->
        other
    end)
  end

  # Prepare objective expressions for the DSL parser by rewriting
  # simple generator sums like:
  #   sum(qty(food) for food <- food_names)
  # into the pattern-based form:
  #   sum(qty(:_))
  # This keeps implementation simple while tests can use generator syntax.
  def transform_objective_expression_to_ast(expr) do
    normalized =
      Macro.prewalk(expr, fn
        # Normalize variable reference arguments in function-style variable access
        {var_name, meta, args} when is_atom(var_name) and is_list(args) ->
          normalized_args =
            Enum.map(args, fn
              # AST tuple representing a generator variable: {:i, [], Elixir} -> :i
              # Extract the atom so ExpressionParser can look it up in bindings
              {atom, _, ctx} when is_atom(atom) and (is_atom(ctx) or is_nil(ctx)) ->
                # Normalize to just the atom for bindings lookup
                atom
              
              # Pattern matching for :_ wildcard - keep as-is
              :_ ->
                :_
              
              # Already normalized atom - keep as-is
              atom when is_atom(atom) ->
                atom
              
              # Numeric literals and other values - keep as-is
              other ->
                other
            end)

          {var_name, meta, normalized_args}

        other ->
          other
      end)

    case normalized do
      # Handle unqualified sum macro passed through Problem.define prewalk
      {:sum, {:for, inner_expr, generators}} ->
        rewrite_generator_sum(inner_expr, generators)

      # Handle qualified sum (e.g., Dantzig.Problem.DSL.sum(...)) normalized earlier
      {{:., _, [_, :sum]}, _, [{:for, inner_expr, generators}]} ->
        rewrite_generator_sum(inner_expr, generators)

      other ->
        other
    end
  end

  def transform_description_to_ast(description) do
    # If it's already a plain string, return as-is
    case description do
      str when is_binary(str) ->
        description

      # String interpolation AST: {:<<>>, [], [parts]}
      {:<<>>, meta, parts} ->
        # Walk the parts and normalize generator variables in interpolations
        normalized_parts =
          Enum.map(parts, fn
            # String literal - keep as-is
            str when is_binary(str) ->
              str

            # Type annotation for interpolation: {:"::", [], [to_string_call, type]}
            {:"::", type_meta, [to_string_call, type]} ->
              # Normalize the to_string call
              normalized_call = normalize_interpolation_call(to_string_call)
              {:"::", type_meta, [normalized_call, type]}

            # Other parts - keep as-is
            other ->
              other
          end)

        {:<<>>, meta, normalized_parts}

      # Other AST forms - keep as-is
      other ->
        other
    end
  end

  # Normalize Kernel.to_string call that contains generator variable
  defp normalize_interpolation_call(ast) do
    case ast do
      # Kernel.to_string call with generator variable: {{:., [], [Kernel, :to_string]}, _, [{:i, [], Elixir}]}
      {{:., dot_meta, [Kernel, :to_string]}, call_meta, [var_ast]} ->
        # Extract and normalize the generator variable
        normalized_var = normalize_generator_variable(var_ast)
        {{:., dot_meta, [Kernel, :to_string]}, call_meta, [normalized_var]}

      # Other forms - keep as-is
      other ->
        other
    end
  end

  # Normalize generator variable AST tuple to atom for bindings lookup
  defp normalize_generator_variable(ast) do
    case ast do
      # AST tuple representing generator variable: {:i, [], Elixir} -> :i
      {atom, _, ctx} when is_atom(atom) and (is_atom(ctx) or is_nil(ctx)) ->
        # Normalize to just the atom for bindings lookup
        atom

      # Already normalized atom - keep as-is
      atom when is_atom(atom) ->
        atom

      # Other forms - keep as-is (may be expressions like i + j)
      other ->
        # For expressions, recursively normalize any generator variables
        Macro.prewalk(other, fn
          {atom, _, ctx} when is_atom(atom) and (is_atom(ctx) or is_nil(ctx)) ->
            atom

          other ->
            other
        end)
    end
  end

  # Internal: rewrite a simple generator sum into a pattern sum
  defp rewrite_generator_sum(inner_expr, generators) do
    case {inner_expr, generators} do
      # sum(qty(food) for food <- food_names) => sum(qty(:_))
      {{var_fun, meta, [arg]}, [{:<-, _gmeta, [gen_var, _domain]}]}
      when is_atom(var_fun) ->
        # Check that arg matches the generator variable name
        arg_atom = extract_var_atom(arg)
        gen_atom = extract_var_atom(gen_var)

        if arg_atom && gen_atom && arg_atom == gen_atom do
          {:sum, {var_fun, meta, [:_]}}
        else
          {:sum, {var_fun, meta, [:_]}}
        end

      # Fallback: return original generator sum
      _ ->
        {:sum, {:for, inner_expr, generators}}
    end
  end

  defp extract_var_atom(ast) do
    case ast do
      {name, _, _} when is_atom(name) -> name
      name when is_atom(name) -> name
      _ -> nil
    end
  end

  # Simple evaluation helpers
  def evaluate_simple_expression(expr) do
    case expr do
      val when is_number(val) ->
        val

      {:-, _, [v]} ->
        -evaluate_simple_expression(v)

      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_val = evaluate_simple_expression(left)
        right_val = evaluate_simple_expression(right)

        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end

      _ ->
        raise ArgumentError, "Cannot evaluate to number: #{inspect(expr)}"
    end
  end

  # Parse simple expressions to polynomials (with optional problem context for variable lookup)
  def parse_simple_expression_to_polynomial(expr, problem \\ nil) do
    case expr do
      # Support Polynomial.variable("x") (with or without full alias) within simple constraints
      {{:., _, [{:__aliases__, _, [:Dantzig, :Polynomial]}, :variable]}, _, [name]} ->
        var_name =
          case name do
            n when is_binary(n) -> n
            n when is_atom(n) -> to_string(n)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(name)}"
          end
        Polynomial.variable(var_name)

      {{:., _, [{:__aliases__, _, [:Polynomial]}, :variable]}, _, [name]} ->
        var_name =
          case name do
            n when is_binary(n) -> n
            n when is_atom(n) -> to_string(n)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(name)}"
          end
        Polynomial.variable(var_name)

      {var_name, _, nil} when is_atom(var_name) or is_binary(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        Polynomial.variable(var_name_str)

      # Handle variable reference AST nodes like {:queen2d_1_1, [], Elixir} (when variable not in scope)
      # These occur when a variable name is used but not defined in the current scope
      # Exclude operators and other special forms
      {var_name, _meta, _context} when is_atom(var_name) and 
                                      tuple_size(expr) == 3 and
                                      var_name not in [:+, :-, :*, :/, :==, :<=, :>=, :!=, :<, :>, :., :|>, :..] ->
        var_name_str = to_string(var_name)
        
        # If problem is provided, check if this corresponds to a variable name
        if not is_nil(problem) do
          var_def = Dantzig.Problem.get_variable(problem, var_name_str)
          
          if var_def do
            Polynomial.variable(var_name_str)
          else
            # Not a variable - try to evaluate as a constant from model_parameters/environment
            case try_evaluate_constant_from_env(expr) do
              {:ok, val} when is_number(val) ->
                Polynomial.const(val)
              
              {:ok, _other} ->
                raise ArgumentError, 
                  "Unsupported simple expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
              
              :error ->
                raise ArgumentError, 
                  "Unsupported simple expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
            end
          end
        else
          # No problem context - treat as variable name (for backward compatibility)
          Polynomial.variable(var_name_str)
        end

      {:-, _meta, [v]} ->
        case parse_simple_expression_to_polynomial(v, problem) do
          %Polynomial{} = p -> Polynomial.scale(p, -1)
          other -> raise ArgumentError, "Unsupported unary minus: #{inspect(other)}"
        end

      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_poly = parse_simple_expression_to_polynomial(left, problem)
        right_poly = parse_simple_expression_to_polynomial(right, problem)

        case {op, left_poly, right_poly} do
          {:+, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, p2)

          {:+, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(v))

          {:+, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), p)

          {:-, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, Polynomial.scale(p2, -1))

          {:-, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(-v))

          {:-, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), Polynomial.scale(p, -1))

          {:*, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, %Polynomial{} = p1, %Polynomial{} = p2} ->
            # Handle polynomial * polynomial (limited cases)
            case {p1, p2} do
              {%Polynomial{simplified: %{[] => val1}}, %Polynomial{simplified: %{[] => val2}}} ->
                # Both are constants
                Polynomial.const(val1 * val2)
              {%Polynomial{simplified: %{[] => val}}, %Polynomial{}} ->
                # First is constant, second is polynomial
                Polynomial.scale(p2, val)
              {%Polynomial{}, %Polynomial{simplified: %{[] => val}}} ->
                # First is polynomial, second is constant
                Polynomial.scale(p1, val)
              _ ->
                raise ArgumentError, "Unsupported polynomial multiplication: #{inspect({p1, p2})}"
            end

          _ ->
            try do
              left_val = evaluate_simple_expression(left)
              right_val = evaluate_simple_expression(right)

              result_val =
                case op do
                  :+ -> left_val + right_val
                  :- -> left_val - right_val
                  :* -> left_val * right_val
                  :/ -> left_val / right_val
                end

              Polynomial.const(result_val)
            rescue
              _ -> raise ArgumentError, "Unsupported arithmetic: #{inspect({op, left, right})}"
            end
        end

      # Handle variable reference AST nodes like {:queen2d_1_1, [], Elixir} (when variable not in scope)
      # These occur when a variable name is used but not defined in the current scope
      # Exclude operators and other special forms
      {var_name, _meta, _context} when is_atom(var_name) and 
                                      tuple_size(expr) == 3 and
                                      var_name not in [:+, :-, :*, :/, :==, :<=, :>=, :!=, :<, :>, :., :|>, :..] ->
        var_name_str = to_string(var_name)
        
        # If problem is provided, check if this corresponds to a variable name
        if not is_nil(problem) do
          var_def = Dantzig.Problem.get_variable(problem, var_name_str)
          
          if var_def do
            Polynomial.variable(var_name_str)
          else
            # Not a variable - try to evaluate as a constant from model_parameters/environment
            case try_evaluate_constant_from_env(expr) do
              {:ok, val} when is_number(val) ->
                Polynomial.const(val)
              
              {:ok, _other} ->
                raise ArgumentError, 
                  "Unsupported simple expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
              
              :error ->
                raise ArgumentError, 
                  "Unsupported simple expression: #{inspect(expr)}. " <>
                  "If #{inspect(var_name)} is meant to be a variable, ensure it was created with variables() first."
            end
          end
        else
          # No problem context - treat as variable name (for backward compatibility)
          Polynomial.variable(var_name_str)
        end

      # Handle bare atoms that might be variable names (fallback for cases where AST was simplified)
      atom when is_atom(atom) and not is_nil(problem) ->
        var_name_str = to_string(atom)
        # Check if this atom corresponds to a variable name in the problem
        var_def = Dantzig.Problem.get_variable(problem, var_name_str)
        
        if var_def do
          Polynomial.variable(var_name_str)
        else
          # Try to evaluate as a constant from model_parameters/environment
          case try_evaluate_constant_from_env(expr) do
            {:ok, val} when is_number(val) ->
              Polynomial.const(val)
            
            {:ok, _other} ->
              raise ArgumentError, 
                "Unsupported simple expression: #{inspect(expr)}. " <>
                "If #{inspect(atom)} is meant to be a variable, ensure it was created with variables() first."
            
            :error ->
              raise ArgumentError, 
                "Unsupported simple expression: #{inspect(expr)}. " <>
                "If #{inspect(atom)} is meant to be a variable, ensure it was created with variables() first."
          end
        end
    end
  end

  # Try to evaluate an expression as a constant from model_parameters/environment
  # Returns {:ok, value} if successful, :error if not
  defp try_evaluate_constant_from_env(expr) do
    case Process.get(:dantzig_eval_env) do
      env when is_list(env) ->
        try do
          # Handle bare atoms by looking them up directly in the environment
          value =
            case expr do
              atom when is_atom(atom) ->
                # Look up the atom in the environment (keyword list)
                Keyword.get(env, atom)
              
              # For AST nodes like {:multiplier, [], Elixir}, extract the atom
              {atom, _, _} when is_atom(atom) ->
                Keyword.get(env, atom)
              
              # For other expressions, try to evaluate them
              other ->
                {val, _} = Code.eval_quoted(other, env)
                val
            end
          
          if is_nil(value) do
            :error
          else
            {:ok, value}
          end
        rescue
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
