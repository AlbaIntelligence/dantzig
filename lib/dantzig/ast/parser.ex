defmodule Dantzig.AST.Parser do
  @moduledoc """
  Parser for converting Elixir AST to Dantzig AST representation.

  Handles parsing of:
  - Variable expressions: x[i, j], x[_, j]
  - Sum expressions: sum(x[i, _])
  - Generator-based sum expressions: sum(expr for i <- list, j <- list)
  - Constraint expressions: sum(x[i, _]) == 1
  - Binary operations: x + y, x * 2
  - Non-linear functions: abs(x), max(x, y), min(x, y)
  """

  alias Dantzig.AST

  @doc """
  Parse a variable expression like x[i, j] or x[_, j]
  """
  def parse_variable_expression(ast) do
    case ast do
      # x[i, j] syntax
      {var_name, _, indices} when is_list(indices) ->
        %AST.Variable{name: var_name, indices: indices, pattern: nil}

      # Handle other cases
      var_name when is_atom(var_name) ->
        %AST.Variable{name: var_name, indices: [], pattern: nil}

      _ ->
        raise ArgumentError, "Invalid variable expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse a constraint expression like sum(x[i, _]) == 1
  """
  def parse_constraint_expression(ast) do
    case ast do
      # sum(x[i, _]) == 1
      {op, _, [left, right]} when op in [:==, :!=, :<=, :>=, :<, :>] ->
        %AST.Constraint{
          left: parse_expression(left),
          operator: op,
          right: parse_expression(right)
        }

      _ ->
        raise ArgumentError, "Invalid constraint expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse any expression into AST representation
  """
  def parse_expression(ast) do
    case ast do
      # Comparisons -> constraints
      {op, _, [left, right]} when op in [:==, :!=, :<=, :>=, :<, :>] ->
        %AST.Constraint{
          left: parse_expression(left),
          operator: op,
          right: parse_expression(right)
        }

      # Access-based indexed variable: x[[i, j]] and x[_]
      {{:., _, [Access, :get]}, _, [var_ast, indices_ast]} when is_list(indices_ast) ->
        %AST.Variable{
          name: extract_var_name(var_ast),
          indices: indices_ast,
          pattern: nil
        }

      # Unary minus on numbers
      {:-, _, [number]} when is_number(number) ->
        -number

      # n-ary sum like sum(x, y, z)
      {:sum, _, args} when is_list(args) and length(args) >= 2 ->
        Dantzig.AST.sum(Enum.map(args, &parse_expression/1))

      # sum(expr, :for, generators) - generator-based sum
      {:sum, _, [expr, :for, generators]} ->
        %AST.GeneratorSum{
          expression: parse_expression(expr),
          generators: parse_generators_for_sum(generators)
        }

      # sum(x[i, _]) - pattern-based sum
      {:sum, _, [var_expr]} ->
        Dantzig.AST.sum([parse_variable_expression(var_expr)])

      # abs(x[i, j])
      {:abs, _, [expr]} ->
        %AST.Abs{expr: parse_expression(expr)}

      # max(x, y, z, ...) or max(x[_])
      {:max, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Max{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Max{args: Enum.map(args, &parse_expression/1)}
        end

      # min(x, y, z, ...) or min(x[_])
      {:min, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Min{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Min{args: Enum.map(args, &parse_expression/1)}
        end

      # x + y, x * 2, etc.
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        %AST.BinaryOp{
          left: parse_expression(left),
          operator: op,
          right: parse_expression(right)
        }

      # x AND y AND z AND ... or x[_] AND y[_]
      {:and, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.And{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.And{args: Enum.map(args, &parse_expression/1)}
        end

      # x OR y OR z OR ... or x[_] OR y[_]
      {:or, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Or{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Or{args: Enum.map(args, &parse_expression/1)}
        end

      # IF condition THEN x ELSE y
      {:if, _, [condition, [do: then_expr, else: else_expr]]} ->
        %AST.IfThenElse{
          condition: parse_expression(condition),
          then_expr: parse_expression(then_expr),
          else_expr: parse_expression(else_expr)
        }

      # Literals
      literal when is_number(literal) ->
        literal

      # Variables (bare atom)
      var when is_atom(var) ->
        %AST.Variable{name: var, indices: [], pattern: nil}

      # Variable expressions with indices x[[...]] and general {name, _, indices}
      {var_name, _, indices} when is_list(indices) ->
        %AST.Variable{name: var_name, indices: indices, pattern: nil}

      # Bare variable AST tuple {name, _, _}
      {var_name, _, _ctx} when is_atom(var_name) ->
        %AST.Variable{name: var_name, indices: [], pattern: nil}

      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse generators from for comprehension syntax: [i <- 1..8, j <- 1..8]
  """
  def parse_generators(generators) do
    case generators do
      [] ->
        raise ArgumentError, "Invalid generator: []"

      list when is_list(list) ->
        Enum.map(list, fn
          {:<-, _, [var, range]} when is_struct(range, Range) ->
            {normalize_var(var), Enum.to_list(range)}

          {:<-, _, [var, list]} when is_list(list) ->
            {normalize_var(var), list}

          {:<-, _, [var, expr]} ->
            {normalize_var(var), evaluate_expression(expr)}

          # Filters are kept as {:filter, expr} with normalized variable nodes
          expr ->
            {:filter, normalize_var_nodes(expr)}
        end)

      other ->
        raise ArgumentError, "Invalid generator: #{inspect(other)}"
    end
  end

  @doc """
  Parse generators for sum expressions: i <- 1..8, j <- 1..8
  """
  def parse_generators_for_sum(generators) do
    case generators do
      # Single generator: i <- 1..3
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        [{normalize_var(var), Enum.to_list(range)}]

      # Single generator with list: i <- [1, 2, 3]
      {:<-, _, [var, list]} when is_list(list) ->
        [{normalize_var(var), list}]

      # Multiple generators: [i <- 1..2, j <- 1..2]
      list when is_list(list) ->
        Enum.map(list, fn
          {:<-, _, [var, range]} when is_struct(range, Range) ->
            {normalize_var(var), Enum.to_list(range)}

          {:<-, _, [var, list]} when is_list(list) ->
            {normalize_var(var), list}

          {:<-, _, [var, expr]} ->
            {normalize_var(var), evaluate_expression(expr)}

          _ ->
            raise ArgumentError, "Invalid generator in sum: #{inspect(list)}"
        end)

      _ ->
        raise ArgumentError, "Invalid generators in sum: #{inspect(generators)}"
    end
  end

  @doc """
  Detect if function arguments contain pattern-based expressions like x[_]
  """
  def detect_pattern_based_args(args) do
    Enum.map(args, fn
      # Pattern args like x[_]
      {{:., _, [Access, :get]}, _, [var_ast, indices_ast]} when is_list(indices_ast) ->
        %AST.Variable{name: extract_var_name(var_ast), indices: indices_ast, pattern: :_}

      # Bare variable
      {var_name, _, _} when is_atom(var_name) ->
        %AST.Variable{name: var_name, indices: [], pattern: nil}

      # Fallback
      other ->
        parse_expression(other)
    end)
  end

  @doc """
  Evaluate a simple expression to get its value
  """
  def evaluate_expression(expr) do
    case expr do
      # Range
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      # Range AST like 1..4
      {:.., _, [left, right]} ->
        left_val = evaluate_expression(left)
        right_val = evaluate_expression(right)
        Enum.to_list(left_val..right_val)

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

      # Function calls
      {func, _, [arg]} when is_atom(func) ->
        arg_val = evaluate_expression(arg)

        case func do
          # Simplified - would need more sophisticated function handling
          :rem -> rem(arg_val, 2)
        end

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  # Normalize variable AST node to atom name
  defp normalize_var({name, _, _}) when is_atom(name), do: name
  defp normalize_var(name) when is_atom(name), do: name

  # Walk expression AST and replace variable nodes with atoms
  defp normalize_var_nodes(expr) do
    Macro.prewalk(expr, fn
      {name, _, ctx} when is_atom(name) and not is_list(ctx) -> name
      other -> other
    end)
  end

  defp extract_var_name({name, _, _}) when is_atom(name), do: name
end
