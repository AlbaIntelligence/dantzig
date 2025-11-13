defmodule Dantzig.Core.ProblemTest do
  @moduledoc """
  Tests for Problem module core functionality.

  This module tests basic variable reference functionality in constraints.
  """
  use ExUnit.Case
  require Dantzig.Problem, as: Problem

  describe "constraint expression variable references" do
    test "variable references work in constraints with generators" do
      food_names = ["bread", "milk"]

      # This test checks that qty(food) where food comes from model parameters
      # is properly handled in constraint expressions
      problem =
        Problem.define model_parameters: %{food_names: food_names} do
          new(name: "Test", description: "Test var ref in constraints")
          variables("qty", [food <- food_names], :continuous, "Amount")

          # Variable reference qty(food) should work when food is from generator
          constraints([food <- food_names], qty(food) >= 0, "Non-negativity")
        end

      assert map_size(problem.constraints) == 2
    end
  end
end
