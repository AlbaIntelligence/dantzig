defmodule Dantzig.Problem.DefineReducer do
  @moduledoc false

  # Thin facade to allow gradual extraction of the define reducer logic.
  # For now we delegate to the existing implementation to avoid behavior drift.

  def reduce(exprs) when is_list(exprs) do
    Dantzig.Problem.__define_reduce__(exprs)
  end
end
