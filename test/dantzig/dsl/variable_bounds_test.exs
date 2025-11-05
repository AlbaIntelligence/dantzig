defmodule Dantzig.DSL.VariableBoundsTest do
  @moduledoc """
  Test variable bounds functionality according to DSL specification.

  Tests the EPIC for variable bounds support including:
  - min_bound/max_bound syntax in variable declarations
  - Type validation (binary variables cannot have bounds)
  - Integer variable type validation (no floating point bounds)
  - Continuous variable bounds support
  - Mixed syntax patterns
  """
  use ExUnit.Case

  import Dantzig.Problem

  # Helper function to convert tuple key back to variable name
  defp tuple_key_to_var_name(var_name, tuple_key) do
    index_vals = Tuple.to_list(tuple_key)
    create_var_name(var_name, index_vals)
  end

  # Import the helper from VariableManager for generating variable names
  defp create_var_name(var_name, index_vals) do
    # Simplified for test purposes
    sanitized_base = var_name

    case index_vals do
      [] ->
        sanitized_base

      [_ | _] ->
        sanitized_indices =
          index_vals
          |> Enum.map(&to_string/1)
          |> Enum.join(",")

        "#{sanitized_base}(#{sanitized_indices})"
    end
  end

  describe "Variable Bounds - Basic Syntax" do
    test "continuous variables with bounds" do
      problem =
        define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("x", :continuous, "X variable", min_bound: 0, max_bound: 100)
        end

      assert problem.variable_defs["x"] != nil
      variable = problem.variable_defs["x"]
      assert variable.type == :continuous
      assert variable.min == 0
      assert variable.max == 100
    end

    test "integer variables with integer bounds" do
      problem =
        define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("y", :integer, "Y variable", min_bound: 0, max_bound: 10)
        end

      assert problem.variable_defs["y"] != nil
      variable = problem.variable_defs["y"]
      assert variable.type == :integer
      assert variable.min == 0
      assert variable.max == 10
    end

    test "variables with only min bound" do
      problem =
        define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("z", :continuous, "Z variable", min_bound: 5)
        end

      assert problem.variable_defs["z"] != nil
      variable = problem.variable_defs["z"]
      assert variable.min == 5
      assert variable.max == nil
    end

    test "variables with only max bound" do
      problem =
        define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("w", :continuous, "W variable", max_bound: 50)
        end

      assert problem.variable_defs["w"] != nil
      variable = problem.variable_defs["w"]
      assert variable.min == nil
      assert variable.max == 50
    end

    test "variables with infinity bounds" do
      problem =
        define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("v", :continuous, "V variable", min_bound: 0, max_bound: :infinity)
        end

      assert problem.variable_defs["v"] != nil
      variable = problem.variable_defs["v"]
      assert variable.min == 0
      assert variable.max == :infinity
    end
  end

  describe "Variable Bounds - Generator Variables" do
    test "generator variables with bounds" do
      problem =
        define do
          new(name: "Generator Bounds Test", description: "Test generator variables with bounds")

          variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity",
            min_bound: 0,
            max_bound: 100
          )
        end

      # Should create two variables with bounds
      assert Map.has_key?(problem.variables, "qty")
      qty_vars = problem.variables["qty"]
      assert map_size(qty_vars) == 2

      # Check that both variables have the correct bounds
      Enum.each(qty_vars, fn {key, _poly} ->
        # Variable name will be qty(bread) and qty(milk)
        # Convert tuple key to variable name for variable_defs lookup
        var_name = tuple_key_to_var_name("qty", key)
        var_def = problem.variable_defs[var_name]
        assert var_def != nil, "Expected variable_defs[#{var_name}] to exist"
        assert var_def.type == :continuous
        # Bounds should be applied to all generated variables
        assert var_def.min == 0
        assert var_def.max == 100
      end)
    end

    test "multi-dimensional generator variables with bounds" do
      problem =
        define do
          new(
            name: "Multi-dimensional Bounds Test",
            description: "Test multi-dimensional variables with bounds"
          )

          variables("transport", [i <- 1..2, j <- 1..2], :continuous, "Transport",
            min_bound: 0,
            max_bound: :infinity
          )
        end

      assert Map.has_key?(problem.variables, "transport")
      transport_vars = problem.variables["transport"]
      assert map_size(transport_vars) == 4

      # All variables should have bounds
      Enum.each(transport_vars, fn {key, _poly} ->
        # Convert tuple key to variable name for variable_defs lookup
        var_name = tuple_key_to_var_name("transport", key)
        var_def = problem.variable_defs[var_name]
        assert var_def != nil, "Expected variable_defs[#{var_name}] to exist"
        assert var_def.type == :continuous
        assert var_def.min == 0
        assert var_def.max == :infinity
      end)
    end
  end

  describe "Variable Bounds - Type Validation" do
    test "binary variables cannot have bounds" do
      assert_raise ArgumentError, "Binary variables cannot have bounds", fn ->
        define do
          new(name: "Binary Bounds Error", description: "Test binary bounds error")
          variables("binary_var", :binary, "Binary variable", min_bound: 0, max_bound: 1)
        end
      end
    end

    test "binary variables cannot have min bound only" do
      assert_raise ArgumentError, "Binary variables cannot have bounds", fn ->
        define do
          new(name: "Binary Min Bound Error", description: "Test binary min bound error")
          variables("binary_var", :binary, "Binary variable", min_bound: 0)
        end
      end
    end

    test "binary variables cannot have max bound only" do
      assert_raise ArgumentError, "Binary variables cannot have bounds", fn ->
        define do
          new(name: "Binary Max Bound Error", description: "Test binary max bound error")
          variables("binary_var", :binary, "Binary variable", max_bound: 1)
        end
      end
    end

    test "integer variables cannot have float bounds - min" do
      assert_raise ArgumentError, "Integer variables cannot have floating point bounds", fn ->
        define do
          new(name: "Integer Float Min Error", description: "Test integer float min bound error")
          variables("int_var", :integer, "Integer variable", min_bound: 0.5)
        end
      end
    end

    test "integer variables cannot have float bounds - max" do
      assert_raise ArgumentError, "Integer variables cannot have floating point bounds", fn ->
        define do
          new(name: "Integer Float Max Error", description: "Test integer float max bound error")
          variables("int_var", :integer, "Integer variable", max_bound: 10.7)
        end
      end
    end

    test "integer variables cannot have float bounds - both" do
      assert_raise ArgumentError, "Integer variables cannot have floating point bounds", fn ->
        define do
          new(
            name: "Integer Float Both Error",
            description: "Test integer float both bounds error"
          )

          variables("int_var", :integer, "Integer variable", min_bound: 0.1, max_bound: 10.9)
        end
      end
    end

    test "continuous variables accept float bounds" do
      problem =
        define do
          new(
            name: "Continuous Float Bounds",
            description: "Test continuous variables with float bounds"
          )

          variables("cont_var", :continuous, "Continuous variable",
            min_bound: 0.1,
            max_bound: 99.9
          )
        end

      assert problem.variable_defs["cont_var"] != nil
      variable = problem.variable_defs["cont_var"]
      assert variable.type == :continuous
      assert variable.min == 0.1
      assert variable.max == 99.9
    end
  end

  describe "Variable Bounds - Problem.modify" do
    test "adding variables with bounds in modify" do
      problem =
        define do
          new(name: "Modify Test", description: "Test modify with bounds")
        end

      modified_problem =
        modify problem do
          variables("x", :continuous, "X variable", min_bound: 0, max_bound: 100)
          variables("y", [i <- 1..2], :integer, "Y variable", min_bound: 1, max_bound: 5)
        end

      assert modified_problem.variable_defs["x"] != nil
      x_var = modified_problem.variable_defs["x"]
      assert x_var.min == 0
      assert x_var.max == 100

      assert Map.has_key?(modified_problem.variables, "y")
      y_vars = modified_problem.variables["y"]
      assert map_size(y_vars) == 2

      Enum.each(y_vars, fn {key, _poly} ->
        # Convert tuple key to variable name for variable_defs lookup
        var_name = tuple_key_to_var_name("y", key)
        var_def = modified_problem.variable_defs[var_name]
        assert var_def != nil, "Expected variable_defs[#{var_name}] to exist"
        assert var_def.min == 1
        assert var_def.max == 5
      end)
    end
  end

  describe "Variable Bounds - Imperative API" do
    test "add_variable with bounds" do
      problem =
        define do
          new(name: "Imperative Test", description: "Test imperative API")
        end

      {modified_problem, _} =
        {problem, _} = new_variable(problem, "x", type: :continuous, min: 10, max: 90)

      assert modified_problem.variable_defs["x"] != nil
      x_var = modified_problem.variable_defs["x"]
      assert x_var.min == 10
      assert x_var.max == 90
    end

    test "add_variables with bounds and generators" do
      problem =
        define do
          new(name: "Imperative Generator Test", description: "Test imperative generator API")
        end

      # Use a for-comprehension to add variables with bounds
      food_names = ["bread", "milk"]

      modified_problem =
        Enum.reduce(food_names, problem, fn food, acc ->
          {new_problem, _} =
            new_variable(acc, "qty(#{food})",
              type: :continuous,
              min: 0,
              max: 100,
              description: "Quantity of #{food}"
            )

          new_problem
        end)

      # Check that variables were created with proper names and bounds
      assert modified_problem.variable_defs["qty(bread)"] != nil
      assert modified_problem.variable_defs["qty(milk)"] != nil

      bread_var = modified_problem.variable_defs["qty(bread)"]
      milk_var = modified_problem.variable_defs["qty(milk)"]

      assert bread_var.min == 0
      assert bread_var.max == 100
      assert milk_var.min == 0
      assert milk_var.max == 100
    end
  end

  describe "Variable Bounds - Error Handling" do
    test "invalid variable type with bounds" do
      assert_raise ArgumentError, "Unknown variable type", fn ->
        define do
          new(name: "Invalid Type Test", description: "Test invalid variable type")

          variables("invalid_var", :unknown_type, "Invalid type variable",
            min_bound: 0,
            max_bound: 100
          )
        end
      end
    end
  end
end
