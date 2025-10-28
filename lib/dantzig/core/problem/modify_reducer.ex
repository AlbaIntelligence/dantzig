defmodule Dantzig.Problem.ModifyReducer do
  @moduledoc false

  # Thin facade to allow gradual extraction of the modify reducer logic.
  # For now we delegate to the existing implementation to avoid behavior drift.

  def reduce(problem, exprs) when is_list(exprs) do
    Dantzig.Problem.__modify_reduce__(problem, exprs)
  end
end


