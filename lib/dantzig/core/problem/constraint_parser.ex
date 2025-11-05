defmodule Dantzig.Problem.ConstraintParser do
  @moduledoc """
  Constraint parsing utilities for the Problem module.

  This module handles parsing of constraint expressions into Constraint structs.
  """

  alias Dantzig.Polynomial
  alias Dantzig.Constraint

  # Check if expression contains complex constructs (sum, for, Access.get)
  defp is_complex_expression?(expr) do
    check_for_complex(expr, false)
  end

  defp check_for_complex(expr, _found) when is_atom(expr) or is_number(expr) or is_binary(expr),
    do: false

  defp check_for_complex({:sum, _, _}, _found), do: true
  defp check_for_complex({:for, _, _}, _found), do: true
  defp check_for_complex({{:., _, [Access, :get]}, _, _}, _found), do: true

  defp check_for_complex({op, _, args}, found) when is_atom(op) and is_list(args) do
    Enum.reduce(args, found, fn arg, acc ->
      acc or check_for_complex(arg, acc)
    end)
  end

  defp check_for_complex(tuple, found) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.reduce(found, fn elem, acc ->
      acc or check_for_complex(elem, acc)
    end)
  end

  defp check_for_complex(list, found) when is_list(list) do
    Enum.reduce(list, found, fn elem, acc ->
      acc or check_for_complex(elem, acc)
    end)
  end

  defp check_for_complex(_, _found), do: false

  # Parse simple constraint expressions (no generators)
  def parse_simple_constraint_expression(problem, constraint_expr, description) do
    # Check if this is a complex expression (sum, for, Access.get) that needs the full parser
    if is_complex_expression?(constraint_expr) do
      # Use the full expression parser with empty bindings (for expressions create their own bindings)
      parse_constraint_with_full_parser(problem, constraint_expr, description, %{})
    else
      # Use simple parser for basic expressions
      case constraint_expr do
        {:==, _, [left_expr, right_value]} ->
          left_poly = parse_simple_expression_to_polynomial(problem, left_expr)

          right_poly =
            case right_value do
              val when is_number(val) -> Polynomial.const(val)
              _ -> parse_simple_expression_to_polynomial(problem, right_value)
            end

          c = Constraint.new_linear(left_poly, :==, right_poly, name: description)
          if is_binary(description), do: %{c | description: description}, else: c

        {:<=, _, [left_expr, right_value]} ->
          left_poly = parse_simple_expression_to_polynomial(problem, left_expr)

          right_poly =
            case right_value do
              val when is_number(val) -> Polynomial.const(val)
              _ -> parse_simple_expression_to_polynomial(problem, right_value)
            end

          c = Constraint.new_linear(left_poly, :<=, right_poly, name: description)
          if is_binary(description), do: %{c | description: description}, else: c

        {:>=, _, [left_expr, right_value]} ->
          left_poly = parse_simple_expression_to_polynomial(problem, left_expr)

          right_poly =
            case right_value do
              val when is_number(val) -> Polynomial.const(val)
              _ -> parse_simple_expression_to_polynomial(problem, right_value)
            end

          c = Constraint.new_linear(left_poly, :>=, right_poly, name: description)
          if is_binary(description), do: %{c | description: description}, else: c

        _ ->
          raise ArgumentError,
                "Unsupported simple constraint expression: #{inspect(constraint_expr)}"
      end
    end
  end

  # Parse constraint using the full expression parser (handles sum, for, Access.get)
  defp parse_constraint_with_full_parser(problem, constraint_expr, description, bindings) do
    case constraint_expr do
      {:==, _, [left_expr, right_value]} ->
        left_poly =
          Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
            left_expr,
            bindings,
            problem
          )

        right_poly =
          case right_value do
            val when is_number(val) ->
              Polynomial.const(val)

            _ ->
              Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
                right_value,
                bindings,
                problem
              )
          end

        c = Constraint.new_linear(left_poly, :==, right_poly, name: description)
        if is_binary(description), do: %{c | description: description}, else: c

      {:<=, _, [left_expr, right_value]} ->
        left_poly =
          Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
            left_expr,
            bindings,
            problem
          )

        right_poly =
          case right_value do
            val when is_number(val) ->
              Polynomial.const(val)

            _ ->
              Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
                right_value,
                bindings,
                problem
              )
          end

        c = Constraint.new_linear(left_poly, :<=, right_poly, name: description)
        if is_binary(description), do: %{c | description: description}, else: c

      {:>=, _, [left_expr, right_value]} ->
        left_poly =
          Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
            left_expr,
            bindings,
            problem
          )

        right_poly =
          case right_value do
            val when is_number(val) ->
              Polynomial.const(val)

            _ ->
              Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(
                right_value,
                bindings,
                problem
              )
          end

        c = Constraint.new_linear(left_poly, :>=, right_poly, name: description)
        if is_binary(description), do: %{c | description: description}, else: c

      _ ->
        raise ArgumentError,
              "Unsupported constraint expression: #{inspect(constraint_expr)}"
    end
  end

  # Parse simple expressions to polynomials (with problem context for variable lookup)
  defp parse_simple_expression_to_polynomial(problem, expr),
    do: Dantzig.Problem.AST.parse_simple_expression_to_polynomial(expr, problem)
end
