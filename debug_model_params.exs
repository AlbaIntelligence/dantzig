# Debug script to test model parameters functionality

require Dantzig.Problem, as: Problem
use Dantzig.DSL.Integration

# Test 1: Basic model parameters functionality (should work)
IO.puts("=== Test 1: Basic Model Parameters ===")
model_parameters = %{n: 3, food_names: [:bread, :milk, :cheese]}

problem =
  Problem.define model_parameters: model_parameters do
    new(name: "Model Param Test")
    variables("x", [i <- 1..n], :binary)
  end

x_vars = Problem.get_variables_nd(problem, "x")
IO.puts("Variables created: #{map_size(x_vars)}")

# Test 2: Parameters in expressions (should work)
IO.puts("\n=== Test 2: Parameters in Expressions ===")
model_parameters2 = %{capacity: 100, costs: %{a: 10, b: 20}}

problem2 =
  Problem.define model_parameters: model_parameters2 do
    new(name: "Expression Test")
    variables("x", [i <- 1..2], :continuous)
    constraints([i <- 1..2], x(i) <= capacity)
  end

IO.puts(
  "Problem with capacity constraints created: #{map_size(problem2.constraints)} constraints"
)

# Test 3: Backward compatibility (should work)
IO.puts("\n=== Test 3: Backward Compatibility ===")

problem3 =
  Problem.define do
    new(name: "Backward Compatible Test")
    variables("x", [i <- 1..3], :binary)
  end

IO.puts(
  "Backward compatible problem created: #{map_size(Problem.get_variables_nd(problem3, "x"))} variables"
)

# Test 4: Problem.modify functionality (should work)
IO.puts("\n=== Test 4: Problem.modify ===")

base =
  Problem.define do
    new(name: "Base Problem")
    variables("x", [i <- 1..3], :continuous)
  end

modified =
  Problem.modify base do
    variables("y", [i <- 1..2], :binary)
  end

x_vars = Problem.get_variables_nd(modified, "x")
y_vars = Problem.get_variables_nd(modified, "y")
IO.puts("Modified problem - x variables: #{map_size(x_vars)}, y variables: #{map_size(y_vars)}")

IO.puts("\n=== All basic functionality tests completed ===")
