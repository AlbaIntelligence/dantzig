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
end
