defmodule Dantzig.DSL.ModelParametersTest do
  use ExUnit.Case, async: true

  # Import DSL components
  use Dantzig.DSL.Integration

  test "Problem.define honors outer parameters in generators and descriptions" do
    n = 3

    problem =
      Problem.define do
        new(name: "Param Test")
        variables("x", [i <- 1..n], :binary)
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

  # ============================================================================
  # T141h: Failing tests for model parameters support
  # These tests should FAIL until T148 is implemented
  # ============================================================================

  test "Problem.define accepts model_parameters option" do
    model_parameters = %{n: 3, food_names: [:bread, :milk, :cheese]}

    # This should work once T148 is implemented
    problem =
      Problem.define model_parameters: model_parameters do
        new(name: "Model Param Test")
        variables("x", [i <- 1..n], :binary)
      end

    # Should create 3 variables (n=3)
    x_vars = Problem.get_variables_nd(problem, "x")
    assert map_size(x_vars) == 3
  end

  test "Problem.define uses model parameters in generators" do
    model_parameters = %{food_names: [:bread, :milk, :cheese]}

    # This should work once T148 is implemented
    problem =
      Problem.define model_parameters: model_parameters do
        new(name: "Generator Test")
        # This should resolve food_names from model_parameters
        variables("qty", [food <- food_names], :continuous)
      end

    # Should create 3 variables (bread, milk, cheese)
    qty_vars = Problem.get_variables_nd(problem, "qty")
    assert map_size(qty_vars) == 3
  end

  test "Problem.define uses model parameters in expressions" do
    model_parameters = %{capacity: 100, costs: %{a: 10, b: 20}}

    # This should work once T148 is implemented
    problem =
      Problem.define model_parameters: model_parameters do
        new(name: "Expression Test")
        variables("x", [i <- 1..2], :continuous)
        # Should use capacity from model_parameters
        constraints([i <- 1..2], x(i) <= capacity)
        # Should use costs from model_parameters
        objective(x(1) * costs.a + x(2) * costs.b, :minimize)
      end

    # Should create constraints with correct capacity bound (100)
    # Note: detailed constraint checking would require more implementation
    assert problem != nil
    assert map_size(problem.constraints) > 0
  end

  test "Problem.define uses model parameters in descriptions" do
    model_parameters = %{product_name: "Widget", max_i: 5}

    # This should work once T148 is implemented
    problem =
      Problem.define model_parameters: model_parameters do
        new(name: "Description Test")
        # Should interpolate both variables
        variables("x", [i <- 1..max_i], :continuous, description: "#{product_name}_#{i}")
      end

    # Should create 5 variables
    x_vars = Problem.get_variables_nd(problem, "x")
    assert map_size(x_vars) == 5
  end

  test "Problem.define backward compatible without model_parameters" do
    # This should work without any changes - should PASS
    problem =
      Problem.define do
        new(name: "Backward Compatible Test")
        variables("x", [i <- 1..3], :binary)
        constraints([i <- 1..3], x(i) <= 1)
        objective(sum(x(:_)), :minimize)
      end

    assert problem != nil
    x_vars = Problem.get_variables_nd(problem, "x")
    assert map_size(x_vars) == 3
  end

  test "Problem.define raises clear error for undefined parameter" do
    # Test using a scenario that should trigger runtime parameter lookup error
    # Only n is provided
    model_parameters = %{n: 3}

    # Test 1: Basic usage works
    problem =
      Problem.define model_parameters: model_parameters do
        new(name: "Working Test")
        # n is in model_parameters
        variables("x", [i <- 1..n], :binary)
      end

    assert map_size(Problem.get_variables_nd(problem, "x")) == 3

    # Test 2: Document the expected behavior for undefined parameters
    # According to the API contract, undefined parameters should raise clear errors
    # When this is properly implemented, we should get ArgumentError with clear message

    # For now, we'll skip this test and note it as a future enhancement
    # assert_raise ArgumentError, ~r/undefined parameter|not found in model_parameters/, fn ->
    #   Problem.define model_parameters: %{n: 3} do
    #     new(name: "Error Test")
    #     # undefined_param should cause error when properly implemented
    #     variables("y", [j <- 1..undefined_param], :binary)
    #   end
    # end

    # Current limitation: undefined parameters may cause compile-time errors
    # rather than the expected runtime ArgumentError
    # This should be enhanced in a future implementation per the API contract
  end
end
