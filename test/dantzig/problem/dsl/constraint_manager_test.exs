defmodule Dantzig.Problem.DSL.ConstraintManagerTest do
  use ExUnit.Case
  alias Dantzig.Problem.DSL.ConstraintManager

  # T141g: Tests for interpolate_variables_in_description/2
  # Note: interpolate_variables_in_description/2 is private, so we test it via create_constraint_name/3
  # These tests verify the interpolation functionality

  describe "interpolate_variables_in_description/2 (via create_constraint_name/3)" do
    test "interpolates single variable in description string" do
      # Test that "Variable i" gets interpolated correctly when i is in bindings
      description = "Variable i"
      bindings = %{i: 1}
      index_vals = [1]

      # Test via create_constraint_name which uses interpolate_variables_in_description
      result = ConstraintManager.create_constraint_name(description, bindings, index_vals)

      # Should interpolate i to 1
      assert result == "Variable 1"
    end

    test "interpolates multiple variables in description string" do
      # Test that "Position (i, j)" gets interpolated correctly
      description = "Position (i, j)"
      bindings = %{i: 2, j: 3}
      index_vals = [2, 3]

      result = ConstraintManager.create_constraint_name(description, bindings, index_vals)

      # Should interpolate both variables
      assert result == "Position (2, 3)"
    end

    test "handles description without interpolation" do
      # Test that plain descriptions are preserved
      description = "Plain description"
      bindings = %{}
      index_vals = []

      result = ConstraintManager.create_constraint_name(description, bindings, index_vals)

      # Should remain unchanged
      assert result == description
    end

    test "handles description with AST interpolation" do
      # Test that AST interpolation {:<<>>, ...} gets evaluated
      description_ast = quote do: "Variable #{i}"
      bindings = %{i: 1}
      index_vals = [1]

      result = ConstraintManager.create_constraint_name(description_ast, bindings, index_vals)

      # Should resolve to "Variable 1"
      assert result == "Variable 1"
    end

    test "handles description with multiple AST interpolations" do
      # Test that multiple variables in AST get interpolated
      description_ast = quote do: "Position (#{i}, #{j})"
      bindings = %{i: 2, j: 3}
      index_vals = [2, 3]

      result = ConstraintManager.create_constraint_name(description_ast, bindings, index_vals)

      # Should resolve to "Position (2, 3)"
      assert result == "Position (2, 3)"
    end

    test "handles nil description" do
      # Test that nil descriptions are handled gracefully
      description = nil
      bindings = %{}
      index_vals = []

      # Should not raise an error
      result = ConstraintManager.create_constraint_name(description, bindings, index_vals)

      # Should return a default constraint name
      assert is_binary(result)
    end

    test "handles description with expression interpolation" do
      # Test that expressions like i + j get interpolated
      description_ast = quote do: "Sum #{i + j}"
      bindings = %{i: 2, j: 3}
      index_vals = [2, 3]

      result = ConstraintManager.create_constraint_name(description_ast, bindings, index_vals)

      # Should resolve to "Sum 5"
      assert result == "Sum 5"
    end

    test "handles description with transformed AST from transform_description_to_ast" do
      # Test that AST transformed by transform_description_to_ast works correctly
      alias Dantzig.Problem.AST
      original_desc = quote do: "Variable #{i}"
      transformed_desc = AST.transform_description_to_ast(original_desc)
      bindings = %{i: 1}
      index_vals = [1]

      result = ConstraintManager.create_constraint_name(transformed_desc, bindings, index_vals)

      # Should resolve to "Variable 1"
      assert result == "Variable 1"
    end
  end
end
