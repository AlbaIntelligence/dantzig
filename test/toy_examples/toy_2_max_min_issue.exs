#!/usr/bin/env elixir

# Toy Example 2: Testing if max()/min() would have the same issue
# Note: max()/min() may not be implemented yet, but if they use for-comprehensions
# with nested generators, they would have the same problem

require Dantzig.Problem, as: Problem

outer_list = ["A", "B"]
inner_list = ["X", "Y"]

IO.puts("=== Toy Example 2: Testing max()/min() (if implemented) ===")
IO.puts("Note: This test checks if max()/min() would have the same nested generator issue")
IO.puts("")

# For now, let's just document that if max()/min() support for-comprehensions,
# they would need the same fix
IO.puts("If max()/min() support syntax like:")
IO.puts("  max(for i <- inner_list, do: x(o, i))")
IO.puts("Then they would have the same issue: inner_list not accessible")
IO.puts("")
IO.puts("The fix for sum(for ...) should also apply to max()/min()")
