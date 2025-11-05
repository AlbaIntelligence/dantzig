defmodule Dantzig.DSL.AlternativeValidSyntaxTest do
  @moduledoc """
  Test alternative valid syntax that might work for bracket notation.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "can we use queen2d[[i, :_]] instead of queen2d[i, :_]?" do
    # Test if we can use queen2d[[i, :_]] (list as single argument)
    # This is valid Elixir syntax!

    # Create a quoted expression that represents queen2d[[i, :_]]
    quoted_expr = quote do: queen2d[[1, :_]]

    # This should be valid syntax
    assert is_tuple(quoted_expr)

    # Let's see what the AST looks like
    IO.inspect(quoted_expr, label: "queen2d[[1, :_]] AST")

    # The AST should be Access protocol call: {{:., [from_brackets: true], [Access, :get]}, [from_brackets: true], [var, args]}
    assert elem(quoted_expr, 0) == {:., [from_brackets: true], [Access, :get]}
    assert elem(quoted_expr, 1) == [from_brackets: true]

    # The third element should be a list containing the variable and arguments
    args = elem(quoted_expr, 2)
    assert is_list(args)
    assert length(args) == 2

    # The first argument should be the variable name
    var_name = hd(args)
    assert elem(var_name, 0) == :queen2d

    # The second argument should be [1, :_]
    second_arg = hd(tl(args))
    assert second_arg == [1, :_]
  end

  test "can we create a macro that handles queen2d[[i, :_]] syntax?" do
    # Test if we can create a macro that handles this valid syntax

    # Create a macro that can handle queen2d[[i, :_]]
    result = DSL.double_bracket_access(:queen2d, [1, :_])

    # This should create the proper AST
    assert is_tuple(result)
    assert elem(result, 0) == :queen2d
    # Note: double brackets
    assert elem(result, 2) == [[1, :_]]
  end

  test "can we use queen2d[{i, :_}] instead?" do
    # Test if we can use queen2d[{i, :_}] (tuple as single argument)
    # This is also valid Elixir syntax!

    # Create a quoted expression that represents queen2d[{i, :_}]
    quoted_expr = quote do: queen2d[{1, :_}]

    # This should be valid syntax
    assert is_tuple(quoted_expr)

    # Let's see what the AST looks like
    IO.inspect(quoted_expr, label: "queen2d[{1, :_}] AST")

    # The AST should be Access protocol call: {{:., [from_brackets: true], [Access, :get]}, [from_brackets: true], [var, args]}
    assert elem(quoted_expr, 0) == {:., [from_brackets: true], [Access, :get]}
    assert elem(quoted_expr, 1) == [from_brackets: true]

    # The third element should be a list containing the variable and arguments
    args = elem(quoted_expr, 2)
    assert is_list(args)
    assert length(args) == 2

    # The first argument should be the variable name
    var_name = hd(args)
    assert elem(var_name, 0) == :queen2d

    # The second argument should be {1, :_}
    second_arg = hd(tl(args))
    assert second_arg == {1, :_}
  end

  test "can we create a macro that handles queen2d[{i, :_}] syntax?" do
    # Test if we can create a macro that handles this valid syntax

    # Create a macro that can handle queen2d[{i, :_}]
    result = DSL.tuple_bracket_access(:queen2d, {1, :_})

    # This should create the proper AST
    assert is_tuple(result)
    assert elem(result, 0) == :queen2d
    # Note: tuple in list
    assert elem(result, 2) == [{1, :_}]
  end

  test "comparison of different valid syntaxes" do
    # Compare different valid syntaxes

    # queen2d[[i, :_]] - list as single argument
    list_expr = quote do: queen2d[[1, :_]]

    # queen2d[{i, :_}] - tuple as single argument
    tuple_expr = quote do: queen2d[{1, :_}]

    # Both should be valid
    assert is_tuple(list_expr)
    assert is_tuple(tuple_expr)

    # Both should be Access protocol calls
    assert elem(list_expr, 0) == {:., [from_brackets: true], [Access, :get]}
    assert elem(tuple_expr, 0) == {:., [from_brackets: true], [Access, :get]}

    # But they should have different arguments
    list_args = elem(list_expr, 2)
    tuple_args = elem(tuple_expr, 2)

    # Both should have the variable name as first argument
    list_var = hd(list_args)
    tuple_var = hd(tuple_args)
    assert elem(list_var, 0) == :queen2d
    assert elem(tuple_var, 0) == :queen2d

    # List argument should be [1, :_]
    list_second_arg = hd(tl(list_args))
    assert list_second_arg == [1, :_]
    # Tuple argument should be {1, :_}
    tuple_second_arg = hd(tl(tuple_args))
    assert tuple_second_arg == {1, :_}

    IO.inspect(list_args, label: "List syntax args")
    IO.inspect(tuple_args, label: "Tuple syntax args")
  end
end
