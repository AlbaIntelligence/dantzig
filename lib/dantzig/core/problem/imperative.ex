defmodule Dantzig.Problem.Imperative do
  @moduledoc false

  def add_variables(problem, generators, var_name, var_type, description) do
    Dantzig.Problem.__add_variables_with_env__(
      problem,
      generators,
      var_name,
      var_type,
      description,
      Process.get(:dantzig_eval_env) || []
    )
  end

  def set_objective(problem, objective_expr, opts) do
    Dantzig.Problem.__set_objective_with_env__(
      problem,
      objective_expr,
      opts,
      Process.get(:dantzig_eval_env) || []
    )
  end
end
