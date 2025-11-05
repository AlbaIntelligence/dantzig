defmodule Dantzig.DSL.ModelParametersTest do
  use ExUnit.Case, async: true

  # Import DSL components
  use Dantzig.DSL.Integration

  test "Problem.define honors outer parameters in generators and descriptions" do
    n = 3

    problem =
      Problem.define do
        new(name: "Param Test")
        variables("x", [i <- 1..n], :binary, "x_#{i}")
        constraints([i <- 1..n], x(i) == 1, "c_#{i}")
        objective(sum(x(:_)), :minimize)
      end

    x_vars = Problem.get_variables_nd(problem, "x")
    assert x_vars != nil
    assert map_size(x_vars) == n

    # Names should reflect description interpolation
    names = problem.constraints |> Map.values() |> Enum.map(& &1.name)
    assert Enum.sort(names) == ["c_1", "c_2", "c_3"]
  end
end


