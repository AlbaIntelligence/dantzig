#!/usr/bin/env elixir

# Toy Example 4: Check if process dictionary is set during constraint parsing
# This will help us understand the timing of when the process dict is available

require Dantzig.Problem, as: Problem

outer_list = ["A", "B"]
inner_list = ["X", "Y"]

IO.puts("=== Toy Example 4: Checking Process Dictionary Timing ===")
IO.puts("")

# Let's hook into the constraint parsing to check the process dict
# We'll modify the code temporarily to add debug output

problem = Problem.define do
  new(name: "Toy4")
  
  variables("x", [o <- outer_list, i <- inner_list], :binary)
  
  # Check process dict before constraint
  # (We can't do this directly, but we can check in the constraint manager)
  constraints(
    [o <- outer_list],
    sum(for i <- inner_list, do: x(o, i)) <= 1,
    "Test"
  )
end

IO.puts("After Problem.define, process dict: #{inspect(Process.get(:dantzig_eval_env) != nil)}")
