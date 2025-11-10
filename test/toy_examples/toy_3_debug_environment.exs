#!/usr/bin/env elixir

# Toy Example 3: Debugging environment access
# This will help us understand why subjects/rooms aren't being found

require Dantzig.Problem, as: Problem

outer_list = ["A", "B"]
inner_list = ["X", "Y"]

IO.puts("=== Toy Example 3: Debugging Environment Access ===")
IO.puts("")

# Let's manually check if the environment is accessible
problem = Problem.define do
  new(name: "Toy3")
  
  # Check if inner_list is accessible in a simple constraint first
  variables("x", [o <- outer_list, i <- inner_list], :binary)
  
  # Simple test: can we access inner_list directly?
  # This should work if environment is set correctly
  constraints(
    [o <- outer_list],
    sum(for i <- inner_list, do: x(o, i)) <= 1,
    "Test"
  )
end

# Check what happened
constraint = problem.constraints |> Map.values() |> List.first()
IO.puts("Constraint left_hand_side: #{inspect(constraint.left_hand_side)}")
IO.puts("")

# Check if process dictionary is set (for debugging)
env = Process.get(:dantzig_eval_env)
IO.puts("Process dictionary :dantzig_eval_env: #{if env, do: "SET (#{length(env)} items)", else: "NOT SET"}")
if env do
  IO.puts("Environment contains inner_list: #{Keyword.has_key?(env, :inner_list)}")
  IO.puts("Environment contains outer_list: #{Keyword.has_key?(env, :outer_list)}")
end
