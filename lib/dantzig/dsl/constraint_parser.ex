defmodule Dantzig.DSL.ConstraintParser do
  @moduledoc """
  Parser for constraint expressions in the DSL
  
  This module handles parsing of constraint expressions like:
  
      queen2d(i, :_) == 1
      sum(queen2d(:_, :_)) == 4
      sum(qty(food)) <= 10
  """
  
  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial
  # alias Dantzig.DSL.SumFunction
  # alias Dantzig.DSL.VariableAccess
  
  @doc """
  Parse a constraint expression into a Dantzig.Constraint struct.
  
  ## Examples
  
      parse_constraint_expression(quote do: queen2d(i, :_) == 1, %{i: 1}, problem)
      parse_constraint_expression(quote do: sum(queen2d(:_, :_)) == 4, %{}, problem)
  """
  def parse_constraint_expression(constraint_ast, bindings, problem) do
    case constraint_ast do
      # Handle equality: expr == value
      {:==, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)
        right_poly = parse_value_to_polynomial(right_value, bindings, problem)
        Constraint.new_linear(left_poly, :==, right_poly)
      
      # Handle inequality: expr <= value
      {:<=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)
        right_poly = parse_value_to_polynomial(right_value, bindings, problem)
        Constraint.new_linear(left_poly, :<=, right_poly)
      
      # Handle inequality: expr >= value
      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)
        right_poly = parse_value_to_polynomial(right_value, bindings, problem)
        Constraint.new_linear(left_poly, :>=, right_poly)
      
      # Handle inequality: expr < value
      {:<, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)
        right_poly = parse_value_to_polynomial(right_value, bindings, problem)
        Constraint.new_linear(left_poly, :<, right_poly)
      
      # Handle inequality: expr > value
      {:>, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)
        right_poly = parse_value_to_polynomial(right_value, bindings, problem)
        Constraint.new_linear(left_poly, :>, right_poly)
      
      _ ->
        raise ArgumentError, "Unsupported constraint expression: #{inspect(constraint_ast)}"
    end
  end
  
  @doc """
  Parse an expression into a polynomial.
  
  This handles various expression types including sum expressions and variable access.
  """
  def parse_expression_to_polynomial(expr, bindings, problem) do
    case expr do
      # Handle sum expressions (unexpanded macro call forms)
      {:sum, _meta, [sum_arg]} ->
        parse_sum_expression(sum_arg, bindings, problem)

      # Handle already-normalized tuple form {:sum, inner}
      {:sum, sum_expr} ->
        parse_sum_expression(sum_expr, bindings, problem)

      # Handle qualified calls like Dantzig.Problem.DSL.sum(...)
      {{:., _m, [_mod, :sum]}, _meta, [sum_arg]} ->
        parse_sum_expression(sum_arg, bindings, problem)
      
      # Handle variable access: {"var_name", [], indices}
      {var_name, [], indices} when is_list(indices) ->
        parse_variable_access(var_name, indices, bindings, problem)
      
      # Handle constants
      val when is_number(val) ->
        Polynomial.const(val)
      
      # Handle binary operations
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_poly = parse_expression_to_polynomial(left, bindings, problem)
        right_poly = parse_expression_to_polynomial(right, bindings, problem)
        
        case op do
          :+ -> Polynomial.add(left_poly, right_poly)
          :- -> Polynomial.subtract(left_poly, right_poly)
          :* -> Polynomial.multiply(left_poly, right_poly)
          :/ -> Polynomial.divide(left_poly, right_poly)
        end
      
      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(expr)}"
    end
  end
  
  @doc """
  Parse a value (right-hand side) into a polynomial.
  
  This handles both numeric values and variable references.
  """
  def parse_value_to_polynomial(value, bindings, problem) do
    case value do
      # Handle numeric values
      val when is_number(val) ->
        Polynomial.const(val)
      
      # Handle variable references
      var when is_atom(var) ->
        case Map.get(bindings, var) do
          nil ->
            raise ArgumentError, "Variable #{var} not found in bindings: #{inspect(bindings)}"
          
          val ->
            Polynomial.const(val)
        end
      
      # Handle complex expressions
      expr when is_tuple(expr) ->
        parse_expression_to_polynomial(expr, bindings, problem)
      
      _ ->
        raise ArgumentError, "Unsupported value: #{inspect(value)}"
    end
  end
  
  @doc """
  Parse a sum expression into a polynomial.
  
  This handles both pattern-based sums and generator-based sums.
  """
  def parse_sum_expression(sum_expr, bindings, problem) do
    case sum_expr do
      # Pattern-based sum: sum(queen2d(:_, :_))
      {var_name, [], indices} when is_list(indices) ->
        parse_pattern_sum(var_name, indices, bindings, problem)
      
      # Generator-based sum: sum(expr for var <- list)
      {:for, expr, generators} ->
        parse_generator_sum(expr, generators, bindings, problem)
      
      _ ->
        raise ArgumentError, "Unsupported sum expression: #{inspect(sum_expr)}"
    end
  end
  
  @doc """
  Parse a pattern-based sum expression.
  
  This handles expressions like sum(queen2d(:_, :_)) where we sum all variables
  matching a pattern.
  """
  def parse_pattern_sum(var_name, indices, bindings, problem) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, to_string(var_name))
    
    if var_map do
      # Create pattern from bindings
      pattern = create_pattern(indices, bindings)
      
      # Sum all matching variables
      sum_poly =
        var_map
        |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, pattern) end)
        |> Enum.reduce(Polynomial.const(0), fn {_key, monomial}, acc ->
          Polynomial.add(acc, monomial)
        end)
      
      sum_poly
    else
      raise ArgumentError, "Variable map not found for: #{var_name}"
    end
  end
  
  @doc """
  Parse a generator-based sum expression.
  
  This handles expressions like sum(qty(food) for food <- food_names).
  """
  def parse_generator_sum(expr, generators, bindings, problem) do
    parsed_generators = parse_generators(generators)

    # Separate variable generators and filters
    {var_gens, filters} =
      Enum.split_with(parsed_generators, fn
        {var, vals} when is_atom(var) and is_list(vals) -> true
        _ -> false
      end)

    # Generate combinations only for variable generators
    combinations = generate_combinations(var_gens)

    Enum.reduce(combinations, Polynomial.const(0), fn combination, acc ->
      combination_bindings = create_combination_bindings(var_gens, combination, bindings)

      # Apply filters; skip combination if any filter fails
      if Enum.all?(filters, &evaluate_filter(&1, combination_bindings)) do
        expr_poly = parse_expression_to_polynomial(expr, combination_bindings, problem)
        Polynomial.add(acc, expr_poly)
      else
        acc
      end
    end)
  end
  
  @doc """
  Parse a variable access expression.
  
  This handles expressions like queen2d(i, :_) where we access specific variables
  or patterns of variables.
  """
  def parse_variable_access(var_name, indices, bindings, problem) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, to_string(var_name))
    
    if var_map do
      # Create key from indices and bindings
      key = create_key_from_indices(indices, bindings)
      
      # Look up the monomial
      case Map.get(var_map, key) do
        nil ->
          raise ArgumentError, "Variable not found: #{var_name}#{inspect(key)}"
        
        monomial ->
          monomial
      end
    else
      raise ArgumentError, "Variable map not found for: #{var_name}"
    end
  end
  
  # Helper functions
  
  defp create_pattern(indices, bindings) do
    Enum.map(indices, fn
      :_ -> :_
      var when is_atom(var) -> Map.get(bindings, var, var)
      {name, _, _} when is_atom(name) -> Map.get(bindings, name, name)
      literal -> literal
    end)
  end
  
  defp matches_pattern(key, pattern) do
    key_list = Tuple.to_list(key)
    pattern_list = pattern
    
    if length(key_list) == length(pattern_list) do
      Enum.zip(key_list, pattern_list)
      |> Enum.all?(fn {key_val, pattern_val} ->
        pattern_val == :_ or pattern_val == key_val
      end)
    else
      false
    end
  end
  
  defp create_key_from_indices(indices, bindings) do
    values =
      Enum.map(indices, fn
        var when is_atom(var) -> Map.get(bindings, var, var)
        {name, _, _} when is_atom(name) -> Map.get(bindings, name, name)
        literal -> literal
      end)
    
    List.to_tuple(values)
  end
  
  defp parse_generators(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        {var, Enum.to_list(range)}

      {:<-, _, [var, list]} when is_list(list) ->
        {var, list}

      {:<-, _, [var, expr]} ->
        {var, evaluate_expression(expr)}

      # Treat any non-generator term as a filter condition
      other ->
        {:filter, other}
    end)
  end
  
  defp evaluate_expression(expr) do
    case expr do
      # Range
      range when is_struct(range, Range) ->
        Enum.to_list(range)
      
      # List
      list when is_list(list) ->
        list
      
      # Literal
      literal when is_number(literal) or is_atom(literal) ->
        literal
      
      # Binary operations
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_val = evaluate_expression(left)
        right_val = evaluate_expression(right)
        
        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end
      
      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  defp evaluate_filter({:filter, filter_ast}, bindings) do
    evaluate_condition(filter_ast, bindings)
  end

  defp evaluate_filter(_, _bindings), do: true

  # Minimal condition evaluator for guards/filters in generators
  defp evaluate_condition(ast, bindings) do
    case ast do
      true -> true
      false -> false

      # Comparison ops
      {op, _, [l, r]} when op in [:==, :!=, :<, :>, :<=, :>=] ->
        lv = eval_term(l, bindings)
        rv = eval_term(r, bindings)
        apply(Kernel, op, [lv, rv])

      # Boolean ops
      {:and, _, [l, r]} -> evaluate_condition(l, bindings) and evaluate_condition(r, bindings)
      {:or, _, [l, r]} -> evaluate_condition(l, bindings) or evaluate_condition(r, bindings)
      {:not, _, [x]} -> not evaluate_condition(x, bindings)

      # Membership: elem in list/range
      {:in, _, [elem_ast, coll_ast]} ->
        elem_val = eval_term(elem_ast, bindings)
        coll_val =
          case eval_term(coll_ast, bindings) do
            range when is_struct(range, Range) -> Enum.to_list(range)
            list when is_list(list) -> list
            other -> other
          end

        Enum.member?(coll_val, elem_val)

      # Fallback: treat as truthy if evals to non-false/nil
      other ->
        case eval_term(other, bindings) do
          v when v in [false, nil] -> false
          _ -> true
        end
    end
  end

  defp eval_term(term, bindings) do
    case term do
      v when is_number(v) or is_binary(v) or is_atom(v) ->
        Map.get(bindings, v, v)

      {name, _, _} when is_atom(name) ->
        Map.get(bindings, name, name)

      {op, _, [l, r]} when op in [:+, :-, :*, :/] ->
        lv = eval_term(l, bindings)
        rv = eval_term(r, bindings)
        apply(Kernel, op, [lv, rv])

      other ->
        other
    end
  end
  
  defp generate_combinations(parsed_generators) do
    # Extract value lists from generators
    {_var_names, value_lists} = Enum.unzip(parsed_generators)
    
    # Generate cartesian product
    generate_cartesian_product(value_lists)
  end
  
  defp generate_cartesian_product([]), do: [[]]
  
  defp generate_cartesian_product([values | rest]) do
    for value <- values,
        combination <- generate_cartesian_product(rest) do
      [value | combination]
    end
  end
  
  defp create_combination_bindings(parsed_generators, combination, original_bindings) do
    # Create a map of variable names to their values for this combination
    {var_names, _value_lists} = Enum.unzip(parsed_generators)
    
    new_bindings =
      Enum.zip(var_names, combination)
      |> Enum.reduce(original_bindings, fn {var_name, value}, acc ->
        Map.put(acc, var_name, value)
      end)
    
    new_bindings
  end
end
