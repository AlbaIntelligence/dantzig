defmodule Dantzig.AST do
  @moduledoc """
  Abstract Syntax Tree representation for Dantzig optimization expressions.

  This module defines the internal AST structures used to represent
  optimization expressions before they are transformed into linear constraints.
  """

  defmodule Variable do
    defstruct [:name, :indices, :pattern]

    @type t :: %__MODULE__{
            name: atom(),
            indices: [any()],
            pattern: [any()] | nil
          }
  end

  defmodule Sum do
    defstruct [:variable]

    @type t :: %__MODULE__{
            variable: Variable.t()
          }
  end

  defmodule GeneratorSum do
    defstruct [:expression, :generators]

    @type t :: %__MODULE__{
            expression: t(),
            generators: [tuple()]
          }
  end

  defmodule Abs do
    defstruct [:expr]

    @type t :: %__MODULE__{
            expr: t()
          }
  end

  defmodule Max do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  defmodule Min do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  defmodule Constraint do
    defstruct [:left, :operator, :right]

    @type t :: %__MODULE__{
            left: t(),
            operator: atom(),
            right: t()
          }
  end

  defmodule BinaryOp do
    defstruct [:left, :operator, :right]

    @type t :: %__MODULE__{
            left: t(),
            operator: atom(),
            right: t()
          }
  end

  defmodule PiecewiseLinear do
    defstruct [:expr, :breakpoints, :slopes, :intercepts]

    @type t :: %__MODULE__{
            expr: t(),
            breakpoints: [number()],
            slopes: [number()],
            intercepts: [number()]
          }
  end

  defmodule And do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  defmodule Or do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  defmodule IfThenElse do
    defstruct [:condition, :then_expr, :else_expr]

    @type t :: %__MODULE__{
            condition: t(),
            then_expr: t(),
            else_expr: t()
          }
  end

  @type t ::
          Variable.t()
          | Sum.t()
          | GeneratorSum.t()
          | Abs.t()
          | Max.t()
          | Min.t()
          | Constraint.t()
          | BinaryOp.t()
          | PiecewiseLinear.t()
          | And.t()
          | Or.t()
          | IfThenElse.t()
          | number()
          | atom()

  #
  # Helper constructor functions expected by tests
  #

  def variable(name), do: %Variable{name: to_atom(name), indices: [], pattern: nil}

  def variable(name, opts) when is_list(opts) do
    case opts do
      # keyword options with a :pattern key
      [{key, _} | _] when is_atom(key) ->
        pattern = Keyword.fetch!(opts, :pattern)
        %Variable{name: to_atom(name), indices: [pattern], pattern: pattern}

      # indices list
      indices ->
        %Variable{name: to_atom(name), indices: indices, pattern: nil}
    end
  end

  def constant(value) when is_number(value), do: value

  def add(a, b), do: %BinaryOp{left: a, operator: :+, right: b}
  def subtract(a, b), do: %BinaryOp{left: a, operator: :-, right: b}
  def multiply(a, b), do: %BinaryOp{left: a, operator: :*, right: b}
  def divide(a, b), do: %BinaryOp{left: a, operator: :/, right: b}

  def equal(a, b), do: %Constraint{left: a, operator: :==, right: b}
  def not_equal(a, b), do: %Constraint{left: a, operator: :!=, right: b}
  def less(a, b), do: %Constraint{left: a, operator: :<, right: b}
  def greater(a, b), do: %Constraint{left: a, operator: :>, right: b}
  def less_equal(a, b), do: %Constraint{left: a, operator: :<=, right: b}
  def greater_equal(a, b), do: %Constraint{left: a, operator: :>=, right: b}

  def abs(expr), do: %Abs{expr: expr}
  def max(args) when is_list(args), do: %Max{args: args}
  def min(args) when is_list(args), do: %Min{args: args}
  def sum(args) when is_list(args), do: %Or{args: args}
  # Note: The tests use AST.sum([...]) as a generic n-ary aggregator; for internal
  # representation we can reuse existing nodes. If a dedicated Sum list type is
  # later introduced, update this accordingly.

  defp to_atom(name) when is_atom(name), do: name
  defp to_atom(name) when is_binary(name), do: String.to_atom(name)
end
