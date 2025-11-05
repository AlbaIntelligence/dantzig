# Simple test for DSL functionality
require Dantzig.Problem, as: Problem

IO.puts("Testing DSL functionality...")

# Test basic problem creation
try do
  problem =
    Problem.define do
      new(name: "Simple Test")
      variables("x", [], :continuous, "Variable x")
      constraints(x <= 10, "Upper bound")
      objective(x, :maximize)
    end

  IO.puts("✅ Problem creation successful")
  IO.puts("Variables: #{map_size(problem.variables)}")
  IO.puts("Constraints: #{map_size(problem.constraints)}")
rescue
  error ->
    IO.puts("❌ Problem creation failed: #{inspect(error)}")
end
