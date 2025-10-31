defmodule Dantzig.DSL.SimpleGeneratorTest do
  @moduledoc """
  The syntax in this module is _golden_.
  It should be considered the canonical way to write generator syntax.
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  test "Simple generator syntax" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    # 2 variables + 1 base
    assert map_size(problem.variables) == 3
    assert Map.has_key?(problem.variables, "qty_bread")
    assert Map.has_key?(problem.variables, "qty_milk")
  end

  test "Generator with objective" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(qty(:_)), :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
