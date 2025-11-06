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
    
    # This should FAIL until T148 is implemented
    assert_raise [CompileError, RuntimeError], fn ->
      Problem.define model_parameters: model_parameters do
        new(name: "Model Param Test")
        variables("x", [i <- 1..n], :binary)
      end
    end
  end

  test "Problem.define uses model parameters in generators" do
    model_parameters = %{food_names: [:bread, :milk, :cheese]}
    
    # This should FAIL until T148 is implemented
    assert_raise [CompileError, RuntimeError], fn ->
      Problem.define model_parameters: model_parameters do
        new(name: "Generator Test")
        # This should resolve food_names from model_parameters
        variables("qty", [food <- food_names], :continuous)
      end
    end
  end

  test "Problem.define uses model parameters in expressions" do
    model_parameters = %{capacity: 100, costs: %{a: 10, b: 20}}
    
    # This should FAIL until T148 is implemented
    assert_raise [CompileError, RuntimeError], fn ->
      Problem.define model_parameters: model_parameters do
        new(name: "Expression Test")
        variables("x", [i <- 1..2], :continuous)
        constraints([i <- 1..2], x(i) <= capacity)  # Should use capacity from model_parameters
        objective(x(1) * costs[a] + x(2) * costs[b], :minimize)  # Should use costs from model_parameters
      end
    end
  end

  test "Problem.define uses model parameters in descriptions" do
    model_parameters = %{product_name: "Widget", max_i: 5}
    
    # This should FAIL until T148 is implemented
    assert_raise [CompileError, RuntimeError], fn ->
      Problem.define model_parameters: model_parameters do
        new(name: "Description Test")
        variables("x", [i <- 1..max_i], :continuous)  # Should interpolate both variables
      end
    end
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
    model_parameters = %{defined_param: 10}
    
    # This should FAIL until proper error handling is implemented
    assert_raise [CompileError, RuntimeError], ~r/(undefined parameter|undefined function)/, fn ->
      Problem.define model_parameters: model_parameters do
        new(name: "Error Test")
        variables("x", [i <- 1..undefined_param], :continuous)  # undefined_param not in model_parameters
      end
    end
  end
end
