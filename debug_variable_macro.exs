#!/usr/bin/env elixir
IO.puts("=== Debugging Variable Macro AST ===")

# Debug script to see what AST is generated for generator variables with bounds
import Dantzig.Problem.DSL

# Test case from failing test
ast1 = quote do
  variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity", min_bound: 0, max_bound: 100)
end

IO.puts("\n--- AST for generator variables with bounds ---")
IO.inspect(ast1, structs: false)

# Test what the DSL macro would expand to
expanded_ast = Macro.expand(ast1, __ENV__)
IO.puts("\n--- Expanded AST ---")
IO.inspect(expanded_ast, structs: false)

# Check what Problem.variables/5 would receive
IO.puts("\n=== Testing Problem.variables/5 ===")
problem = Dantzig.Problem.new(name: "Test", description: "Test")

try do
  {new_problem, _} = Dantzig.Problem.variables(problem, "qty", [food <- ["bread", "milk"]], :continuous, [min_bound: 0, max_bound: 100])
  IO.puts("Problem.variables/5 succeeded!")
  IO.inspect(new_problem.variable_defs)
rescue
  e ->
    IO.puts("Problem.variables/5 failed: #{inspect(e)}")
end
