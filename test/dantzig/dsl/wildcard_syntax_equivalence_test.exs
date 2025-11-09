defmodule Dantzig.DSL.WildcardSyntaxEquivalenceTest do
  @moduledoc """
  Verify that all four equivalent syntaxes for wildcard + nested access produce identical results.

  This validates the DSL enhancement proposal: four syntaxes should be equivalent:
  A) Explicit for comprehension with bracket access (baseline)
  B) Explicit for comprehension with dot notation
  C) Wildcard with bracket access (concise)
  D) Wildcard with dot notation (concise)
  """

  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem

  describe "Syntax equivalence: constraints" do
    setup do
      foods = %{
        bread: %{calories: 100, protein: 3},
        milk: %{calories: 150, protein: 8}
      }

      {:ok, foods: foods}
    end

    test "Syntax A: explicit for comprehension with bracket access", %{foods: foods} do
      problem =
        Problem.define model_parameters: %{
                         foods: foods,
                         food_names: [:bread, :milk],
                         nutrient_names: [:calories, :protein]
                       } do
          new(name: "Test A", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)

          # Syntax A: Explicit for comprehension with bracket access
          constraints(
            [nutrient <- [:calories, :protein]],
            sum(for food <- [:bread, :milk], do: qty(food) * foods[food][nutrient]) >= 200,
            "Min"
          )
        end

      assert map_size(problem.constraints) == 2
      constraint_list = Map.values(problem.constraints)

      # Extract coefficients from first constraint
      c1 = Enum.at(constraint_list, 0)
      bread_1 = c1.left_hand_side.simplified[["qty(bread)"]] || 0
      milk_1 = c1.left_hand_side.simplified[["qty(milk)"]] || 0

      # Both should be non-zero
      assert bread_1 != 0
      assert milk_1 != 0

      # Store for comparison
      {:ok, syntax_a: {bread_1, milk_1}, problem_a: problem}
    end

    test "Syntax C: wildcard with bracket access produces same result as Syntax A", %{
      foods: foods
    } do
      problem_c =
        Problem.define model_parameters: %{
                         foods: foods,
                         food_names: [:bread, :milk],
                         nutrient_names: [:calories, :protein]
                       } do
          new(name: "Test C", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)

          # Syntax C: Wildcard with bracket access
          constraints(
            [nutrient <- [:calories, :protein]],
            sum(qty(:_) * foods[:_][nutrient]) >= 200,
            "Min"
          )
        end

      assert map_size(problem_c.constraints) == 2
      constraint_list = Map.values(problem_c.constraints)

      # Extract coefficients from first constraint
      c1 = Enum.at(constraint_list, 0)
      bread_c = c1.left_hand_side.simplified[["qty(bread)"]] || 0
      milk_c = c1.left_hand_side.simplified[["qty(milk)"]] || 0

      # Both should be non-zero
      assert bread_c != 0
      assert milk_c != 0

      # Should match one of the expected nutrient coefficient pairs
      # (100, 150) for calories or (3, 8) for protein
      assert {bread_c, milk_c} in [{100, 150}, {3, 8}]
    end

    test "Syntax D: wildcard with dot notation produces same result", %{foods: foods} do
      problem_d =
        Problem.define model_parameters: %{
                         foods: foods,
                         food_names: [:bread, :milk],
                         nutrient_names: [:calories, :protein]
                       } do
          new(name: "Test D", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)

          # Syntax D: Wildcard with dot notation
          constraints(
            [nutrient <- [:calories, :protein]],
            sum(qty(:_) * foods[:_].nutrient) >= 200,
            "Min"
          )
        end

      assert map_size(problem_d.constraints) == 2
      constraint_list = Map.values(problem_d.constraints)

      # Extract coefficients from first constraint
      c1 = Enum.at(constraint_list, 0)
      bread_d = c1.left_hand_side.simplified[["qty(bread)"]] || 0
      milk_d = c1.left_hand_side.simplified[["qty(milk)"]] || 0

      # Both should be non-zero
      assert bread_d != 0
      assert milk_d != 0

      # Should match one of the expected nutrient coefficient pairs
      assert {bread_d, milk_d} in [{100, 150}, {3, 8}]
    end
  end

  describe "Syntax equivalence: objectives" do
    setup do
      foods = %{
        bread: %{cost: 2.0},
        milk: %{cost: 1.0}
      }

      {:ok, foods: foods}
    end

    test "All four syntaxes produce same objective coefficients", %{foods: foods} do
      # Syntax A: Explicit for comprehension with bracket access
      problem_a =
        Problem.define model_parameters: %{foods: foods} do
          new(name: "A", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)

          objective(
            sum(for food <- [:bread, :milk], do: qty(food) * foods[food][:cost]),
            :minimize
          )
        end

      # Syntax B: Explicit for comprehension with dot notation
      problem_b =
        Problem.define model_parameters: %{foods: foods} do
          new(name: "B", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)
          objective(sum(for food <- [:bread, :milk], do: qty(food) * foods[food].cost), :minimize)
        end

      # Syntax C: Wildcard with bracket access
      problem_c =
        Problem.define model_parameters: %{foods: foods} do
          new(name: "C", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)
          objective(sum(qty(:_) * foods[:_][:cost]), :minimize)
        end

      # Syntax D: Wildcard with dot notation
      problem_d =
        Problem.define model_parameters: %{foods: foods} do
          new(name: "D", direction: :minimize)
          variables("qty", [food <- [:bread, :milk]], :continuous)
          objective(sum(qty(:_) * foods[:_].cost), :minimize)
        end

      # All should have identical coefficients
      bread_a = problem_a.objective.simplified[["qty(bread)"]]
      milk_a = problem_a.objective.simplified[["qty(milk)"]]

      bread_b = problem_b.objective.simplified[["qty(bread)"]]
      milk_b = problem_b.objective.simplified[["qty(milk)"]]

      bread_c = problem_c.objective.simplified[["qty(bread)"]]
      milk_c = problem_c.objective.simplified[["qty(milk)"]]

      bread_d = problem_d.objective.simplified[["qty(bread)"]]
      milk_d = problem_d.objective.simplified[["qty(milk)"]]

      # All should match
      assert {bread_a, milk_a} == {bread_b, milk_b}
      assert {bread_b, milk_b} == {bread_c, milk_c}
      assert {bread_c, milk_c} == {bread_d, milk_d}

      # Should be the expected cost values
      assert {bread_a, milk_a} == {2.0, 1.0}
    end
  end
end
