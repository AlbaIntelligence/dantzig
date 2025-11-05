defmodule Dantzig.DSL.ParenthesesVariableNamesTest do
  @moduledoc """
  Test for new parentheses-based variable naming system

  Tests that the DSL properly creates variables with parentheses format
  instead of the old underscore format, with correct sanitization.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.Problem

  describe "parentheses-based variable naming" do
    test "basic single index" do
      problem =
        Problem.define do
          new(name: "Single Index Test")
          variables("x", [i <- 1..3], :continuous, "Test variables")
        end

      assert problem.variables["x"] != nil
      variables = problem.variables["x"]

      # Should have parentheses format
      assert Map.has_key?(variables, {1})
      assert Map.has_key?(variables, {2})
      assert Map.has_key?(variables, {3})

      # Check that variable names use parentheses format
      Enum.each(variables, fn {_key, polynomial} ->
        poly_str = inspect(polynomial)

        assert String.contains?(poly_str, "("),
               "Variable should use parentheses format: #{poly_str}"

        refute String.contains?(poly_str, "_1") and not String.contains?(poly_str, "("),
               "Should not use underscore format: #{poly_str}"
      end)
    end

    test "multi-dimensional indices" do
      problem =
        Problem.define do
          new(name: "Multi-dimensional Test")
          variables("transport", [i <- 1..2, j <- 1..3], :continuous, "Transportation")
        end

      assert problem.variables["transport"] != nil
      variables = problem.variables["transport"]

      # Should have correct tuple keys
      assert Map.has_key?(variables, {1, 1})
      assert Map.has_key?(variables, {1, 2})
      assert Map.has_key?(variables, {1, 3})
      assert Map.has_key?(variables, {2, 1})

      # Check variable names use parentheses
      Enum.each(variables, fn {_key, polynomial} ->
        poly_str = inspect(polynomial)
        assert String.contains?(poly_str, "("), "Variable should use parentheses format"
      end)
    end

    test "string indices (like food names)" do
      food_names = ["hot_dog", "ice_cream", "pizza"]

      problem =
        Problem.define model_parameters: %{foods: food_names} do
          new(name: "String Indices Test")
          variables("qty", [food <- foods], :continuous, "Food quantities")
        end

      assert problem.variables["qty"] != nil
      variables = problem.variables["qty"]

      # Should have string indices
      assert Map.has_key?(variables, {"hot_dog"})
      assert Map.has_key?(variables, {"ice_cream"})
      assert Map.has_key?(variables, {"pizza"})

      # Check sanitization works correctly
      Enum.each(variables, fn {_key, polynomial} ->
        poly_str = inspect(polynomial)
        # Should contain parentheses but preserve underscores in string indices
        assert String.contains?(poly_str, "("), "Variable should use parentheses format"
        # Should preserve the exact food names
        assert String.contains?(poly_str, "hot_dog") or String.contains?(poly_str, "ice_cream") or
                 String.contains?(poly_str, "pizza")
      end)
    end

    test "LP format sanitization for problematic indices" do
      # Test that indices starting with 'e'/'E' get var_ prefix for LP solver compatibility
      problem =
        Problem.define do
          new(name: "LP Format Test")

          variables(
            "cost",
            [i <- ["e123", "E456", "normal", "email@example"]],
            :continuous,
            "Costs"
          )
        end

      assert problem.variables["cost"] != nil
      variables = problem.variables["cost"]

      # Map keys use original values, but variable names inside polynomials are sanitized
      assert Map.has_key?(variables, {"e123"})
      assert Map.has_key?(variables, {"E456"})
      assert Map.has_key?(variables, {"email@example"})
      assert Map.has_key?(variables, {"normal"})

      # Check that only problematic indices are prefixed
      Enum.each(variables, fn {_key, polynomial} ->
        poly_str = inspect(polynomial)

        if String.contains?(poly_str, "var_") do
          assert String.contains?(poly_str, "var_e123") or String.contains?(poly_str, "var_E456") or
                   String.contains?(poly_str, "var_email")
        end
      end)
    end

    test "mixed data types in indices" do
      problem =
        Problem.define do
          new(name: "Mixed Types Test")
          variables("matrix", [i <- ["A", 1, "x_1"], j <- ["B", 2]], :binary, "Mixed indices")
        end

      assert problem.variables["matrix"] != nil
      variables = problem.variables["matrix"]

      # Should have correct mixed type keys
      assert Map.has_key?(variables, {"A", "B"})
      assert Map.has_key?(variables, {"A", 2})
      assert Map.has_key?(variables, {1, "B"})
      assert Map.has_key?(variables, {1, 2})
      assert Map.has_key?(variables, {"x_1", "B"})
      assert Map.has_key?(variables, {"x_1", 2})

      # Check parentheses format is used
      Enum.each(variables, fn {_key, polynomial} ->
        poly_str = inspect(polynomial)
        assert String.contains?(poly_str, "("), "Variable should use parentheses format"
      end)
    end

    test "old underscore patterns are not created" do
      problem =
        Problem.define do
          new(name: "No Underscores Test")
          variables("test", [i <- 1..2], :continuous, "Test")
        end

      variables = problem.variables["test"]

      # Extract variable names from polynomial terms
      actual_var_names =
        Map.values(variables)
        |> Enum.map(fn polynomial ->
          poly_str = inspect(polynomial)

          case Regex.run(~r/(\w+\([^)]+\))/, poly_str) do
            [var_name] -> var_name
            _ -> "unknown"
          end
        end)

      # Should not contain underscore patterns (except in legitimate contexts like "x_1")
      has_underscore_patterns =
        Enum.any?(actual_var_names, fn name ->
          String.contains?(name, "_") and not String.contains?(name, "(")
        end)

      refute has_underscore_patterns,
             "Should not create underscore pattern variables: #{inspect(actual_var_names)}"
    end
  end
end
