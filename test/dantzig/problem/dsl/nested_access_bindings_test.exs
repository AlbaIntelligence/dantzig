defmodule Dantzig.Problem.DSL.NestedAccessBindingsTest do
  @moduledoc """
  Tests for nested Access.get expressions with generator bindings in sum expressions.

  These tests verify that generator variables (like 'food' from 'for food <- food_names')
  are correctly available when evaluating nested constant access expressions like
  'foods_dict[food][nutrient_to_atom[limit]]'.

  Based on debug scripts created to diagnose the binding propagation issue.
  """

  use ExUnit.Case
  require Dantzig.Problem, as: Problem
  alias Dantzig.Problem.DSL.ExpressionParser

  describe "enumerate_for_bindings" do
    test "creates bindings for single generator" do
      bindings = %{food_names: ["hamburger", "chicken"]}

      generator =
        quote do
          food <- food_names
        end

      # Use public function
      result = ExpressionParser.enumerate_for_bindings([generator], bindings)

      assert length(result) == 2
      assert Enum.at(result, 0) == Map.put(bindings, :food, "hamburger")
      assert Enum.at(result, 1) == Map.put(bindings, :food, "chicken")
    end

    test "creates bindings for nested generators" do
      bindings = %{
        limits_names: ["calories", "protein"],
        food_names: ["hamburger", "chicken"]
      }

      constraint_gen =
        quote do
          limit <- limits_names
        end

      sum_gen =
        quote do
          food <- food_names
        end

      # First level (constraint generator)
      constraint_bindings = ExpressionParser.enumerate_for_bindings([constraint_gen], bindings)
      assert length(constraint_bindings) == 2

      # Second level (sum generator within constraint iteration)
      for constraint_binding <- constraint_bindings do
        sum_bindings = ExpressionParser.enumerate_for_bindings([sum_gen], constraint_binding)
        assert length(sum_bindings) == 2

        for sum_binding <- sum_bindings do
          assert Map.has_key?(sum_binding, :limit)
          assert Map.has_key?(sum_binding, :food)
          assert Map.has_key?(sum_binding, :food_names)
        end
      end
    end

    test "merges bindings correctly" do
      outer_bindings = %{
        limit: "calories",
        foods_dict: %{"hamburger" => %{calories: 410}},
        nutrient_to_atom: %{"calories" => :calories},
        food_names: ["hamburger"]
      }

      generator =
        quote do
          food <- food_names
        end

      result = ExpressionParser.enumerate_for_bindings([generator], outer_bindings)

      assert length(result) == 1
      merged = hd(result)
      assert merged[:food] == "hamburger"
      assert merged[:limit] == "calories"
      assert merged[:foods_dict] == outer_bindings[:foods_dict]
      assert merged[:nutrient_to_atom] == outer_bindings[:nutrient_to_atom]
    end
  end

  describe "parse_sum_expression with nested Access.get" do
    test "parses sum with nested Access.get using generator bindings" do
      foods = [
        %{name: "hamburger", calories: 410},
        %{name: "chicken", calories: 420}
      ]

      food_names = Enum.map(foods, & &1.name)
      foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}
      nutrient_to_atom = %{"calories" => :calories}

      # Test via actual problem definition - this should work now
      problem =
        Problem.define model_parameters: %{
                         foods_dict: foods_dict,
                         nutrient_to_atom: nutrient_to_atom,
                         food_names: food_names
                       } do
          new(name: "Test Problem")
          variables("qty", [food <- food_names], :continuous, min_bound: 0.0, max_bound: :infinity)

          # This constraint should parse successfully
          # Use struct field access syntax
          constraints(
            sum(for food <- food_names, do: foods_dict[food].calories) <= 1000,
            "Test constraint"
          )
        end

      # Should create constraint without error
      assert map_size(problem.constraints) == 1
    end
  end

  describe "diet problem scenario" do
    test "parses constraint with nested Access.get in sum expression" do
      foods = [
        %{name: "hamburger", cost: 2.49, calories: 410, protein: 24, fat: 26, sodium: 730},
        %{name: "chicken", cost: 2.89, calories: 420, protein: 32, fat: 10, sodium: 1190}
      ]

      food_names = Enum.map(foods, & &1.name)
      foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

      limits = [
        %{nutrient: "calories", min_bound: 1800, max_bound: 2200},
        %{nutrient: "protein", min_bound: 91, max_bound: :infinity}
      ]

      limits_names = Enum.map(limits, & &1.nutrient)
      limits_dict = for limit_entry <- limits, into: %{}, do: {limit_entry.nutrient, limit_entry}
      nutrient_to_atom = %{"calories" => :calories, "protein" => :protein}

      problem =
        Problem.define model_parameters: %{
                         foods_dict: foods_dict,
                         limits_dict: limits_dict,
                         food_names: food_names,
                         limits_names: limits_names,
                         nutrient_to_atom: nutrient_to_atom
                       } do
          new(name: "Diet Problem")
          variables("qty", [food <- food_names], :continuous, min_bound: 0.0, max_bound: :infinity)
        end

      # This is the exact constraint that was failing
      constraint_expr =
        quote do
          sum(for food <- food_names, do: qty(food) * foods_dict[food][nutrient_to_atom[limit]]) <=
            limits_dict[limit].max
        end

      # Parse with limit="calories" binding
      outer_bindings = %{
        limit: "calories",
        foods_dict: foods_dict,
        limits_dict: limits_dict,
        food_names: food_names,
        limits_names: limits_names,
        nutrient_to_atom: nutrient_to_atom
      }

      # Should NOT raise "Cannot evaluate variable 'food'" error
      assert Problem.DSL.ConstraintManager.parse_constraint_expression(
               constraint_expr,
               outer_bindings,
               problem
             ) != nil
    end

    test "creates full diet problem successfully" do
      foods = [
        %{name: "hamburger", cost: 2.49, calories: 410, protein: 24, fat: 26, sodium: 730},
        %{name: "chicken", cost: 2.89, calories: 420, protein: 32, fat: 10, sodium: 1190}
      ]

      food_names = Enum.map(foods, & &1.name)
      foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

      limits = [
        %{nutrient: "calories", min_bound: 1800, max_bound: 2200},
        %{nutrient: "protein", min_bound: 91, max_bound: :infinity}
      ]

      limits_names = Enum.map(limits, & &1.nutrient)
      limits_dict = for limit_entry <- limits, into: %{}, do: {limit_entry.nutrient, limit_entry}
      nutrient_to_atom = %{"calories" => :calories, "protein" => :protein}

      # This should create the problem without errors
      problem =
        Problem.define model_parameters: %{
                         foods_dict: foods_dict,
                         limits_dict: limits_dict,
                         food_names: food_names,
                         limits_names: limits_names,
                         nutrient_to_atom: nutrient_to_atom
                       } do
          new(name: "Diet Problem")

          variables("qty", [food <- food_names], :continuous, min_bound: 0.0, max_bound: :infinity)

          constraints(
            [limit <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][nutrient_to_atom[limit]]) <=
              2200,
            "Min and max #{limit}"
          )

          objective(
            sum(for food <- food_names, do: qty(food) * foods_dict[food].cost),
            direction: :minimize
          )
        end

      assert problem != nil
      # One for each limit
      assert Map.size(problem.constraints) == 2
      assert problem.objective != nil
    end
  end

  describe "binding propagation through parse_sum_expression" do
    test "bindings from enumerate_for_bindings are available in body parsing" do
      foods = [
        %{name: "hamburger", calories: 410}
      ]

      food_names = Enum.map(foods, & &1.name)
      foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

      # Test via actual problem definition
      problem =
        Problem.define model_parameters: %{
                         foods_dict: foods_dict,
                         food_names: food_names
                       } do
          new(name: "Test Problem")
          variables("qty", [food <- food_names], :continuous, min_bound: 0.0, max_bound: :infinity)

          # Sum expression where body uses 'food' from generator
          constraints(
            sum(for food <- food_names, do: foods_dict[food].calories) <= 1000,
            "Test constraint"
          )
        end

      # Should create constraint without error
      assert map_size(problem.constraints) == 1
    end
  end
end
