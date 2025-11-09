defmodule Dantzig.DSL.WildcardNestedAccessTest do
  @moduledoc """
  Test wildcard placeholders (:_) combined with nested map access.

  TDD Approach: Tests written FIRST, expected to FAIL, then implement to make them PASS.

  This validates the concise wildcard syntax:
  - sum(qty(:_) * foods[:_][nutrient]) - wildcard with bracket nested access
  - sum(qty(:_) * foods[:_].cost) - wildcard with dot nested access

  Goal: Make these as expressive as explicit for comprehensions.
  """

  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem

  describe "Wildcard with Bracket Nested Access - TDD Red Phase" do
    test "wildcard with nested bracket access in constraints" do
      # Test the concise syntax: qty(:_) * foods[:_][nutrient]
      # Expected to FAIL initially

      foods = %{
        bread: %{calories: 100, protein: 3, cost: 2.0},
        milk: %{calories: 150, protein: 8, cost: 1.0}
      }

      problem =
        Problem.define model_parameters: %{
                         foods: foods,
                         food_names: [:bread, :milk],
                         nutrient_names: [:calories, :protein]
                       } do
          new(name: "Diet Wildcard Bracket", direction: :minimize)

          variables("qty", [food <- [:bread, :milk]], :continuous)

          # CRITICAL TEST: This should work but currently produces coefficient 0
          constraints(
            [nutrient <- [:calories, :protein]],
            sum(qty(:_) * foods[:_][nutrient]) >= 200,
            "Min"
          )

          objective(sum(qty(:_) * foods[:_].cost), :minimize)
        end

      # Should have 2 constraints (one for each nutrient)
      assert map_size(problem.constraints) == 2

      # Extract constraints
      constraint_list = Map.values(problem.constraints)
      [constraint1, constraint2] = constraint_list

      # CRITICAL ASSERTION: Coefficients should NOT be zero
      # First constraint (calories): 100*qty(bread) + 150*qty(milk) >= 200
      bread_coeff_1 = constraint1.left_hand_side.simplified[["qty(bread)"]] || 0
      milk_coeff_1 = constraint1.left_hand_side.simplified[["qty(milk)"]] || 0

      assert bread_coeff_1 != 0, "Bread coefficient should not be zero (currently failing)"
      assert milk_coeff_1 != 0, "Milk coefficient should not be zero (currently failing)"

      # Verify actual values match the data
      # One constraint should have calories (100, 150), other should have protein (3, 8)
      coeffs_1 = {bread_coeff_1, milk_coeff_1}
      bread_coeff_2 = constraint2.left_hand_side.simplified[["qty(bread)"]] || 0
      milk_coeff_2 = constraint2.left_hand_side.simplified[["qty(milk)"]] || 0
      coeffs_2 = {bread_coeff_2, milk_coeff_2}

      # Should be one of these two combinations
      assert coeffs_1 in [{100, 150}, {3, 8}]
      assert coeffs_2 in [{100, 150}, {3, 8}]
      # They should be different
      assert coeffs_1 != coeffs_2
    end

    test "wildcard with dot notation in objective" do
      # Test: sum(qty(:_) * foods[:_].cost)

      foods = %{
        bread: %{cost: 2.0, calories: 100},
        milk: %{cost: 1.0, calories: 150}
      }

      problem =
        Problem.define model_parameters: %{
                         foods: foods
                       } do
          new(name: "Wildcard Dot Test", direction: :minimize)

          variables("qty", [food <- [:bread, :milk]], :continuous)

          # Wildcard with dot notation in objective
          objective(sum(qty(:_) * foods[:_].cost), :minimize)
        end

      # Objective should have correct coefficients
      # minimize: 2.0*qty(bread) + 1.0*qty(milk)
      assert problem.objective.simplified[["qty(bread)"]] == 2.0
      assert problem.objective.simplified[["qty(milk)"]] == 1.0
    end
  end

  describe "Simple Toy Example to Understand Current Behavior" do
    test "current behavior: wildcard with simple nested access" do
      # Simplest possible test to see what currently happens

      data = %{a: %{x: 10}, b: %{x: 20}}

      problem =
        Problem.define model_parameters: %{data: data} do
          new(name: "Toy", direction: :minimize)
          variables("v", [i <- [:a, :b]], :continuous)

          # What happens with: v(:_) * data[:_].x?
          objective(sum(v(:_) * data[:_].x), :minimize)
        end

      # Debug: Print what we got
      IO.inspect(problem.objective, label: "Objective polynomial")

      # Expected: 10*v(a) + 20*v(b)
      # Currently might get: 0*v(a) + 0*v(b) or error
      assert problem.objective.simplified[["v(a)"]] == 10
      assert problem.objective.simplified[["v(b)"]] == 20
    end
  end
end
