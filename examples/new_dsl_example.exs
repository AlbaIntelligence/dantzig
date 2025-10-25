# Example demonstrating the modern DSL syntax
# This shows the clean, modern approach to building optimization problems

require Dantzig.Problem, as: Problem

IO.puts("=== Modern DSL Example ===")

# Create a problem using the DSL
problem =
  Problem.define do
    new(
      name: "Simple Test",
      description: "Testing the modern DSL syntax",
      direction: :maximize
    )

    # Add variables using the modern DSL syntax
    variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variables")

    # Add constraints
    constraints([i <- 1..2], sum(x(i, :_)) == 1, "Row constraint")
    constraints([j <- 1..2], sum(x(:_, j)) == 1, "Column constraint")

    # Add objective
    objective(sum(x(:_, :_)), direction: :maximize)
  end

IO.puts("Created problem: #{problem.name}")
IO.puts("Description: #{problem.description}")

IO.puts("Added variables:")
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("Variable map keys: #{inspect(Map.keys(var_map))}")
IO.puts("Variables created: #{map_size(var_map)}")
IO.puts("Constraints created: #{map_size(problem.constraints)}")

IO.puts("\n=== Modern DSL structure working! ===")
IO.puts("DSL syntax fully implemented with variables, constraints, and objectives")
