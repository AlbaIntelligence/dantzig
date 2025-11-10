#!/usr/bin/env elixir

# Toy Example 1: Reproducing the sum(for ...) issue with nested generators
# This demonstrates the problem: inner generators can't access outer scope variables

require Dantzig.Problem, as: Problem

# Define data in outer scope
outer_list = ["A", "B"]
inner_list = ["X", "Y"]

IO.puts("=== Toy Example 1: Reproducing the Issue ===")
IO.puts("Outer list: #{inspect(outer_list)}")
IO.puts("Inner list: #{inspect(inner_list)}")
IO.puts("")

problem = Problem.define do
  new(name: "Toy1")
  
  # Create variables with both outer and inner indices
  variables("x", [o <- outer_list, i <- inner_list], :binary)
  
  # Constraint with nested generators:
  # Outer: o <- outer_list
  # Inner: sum(for i <- inner_list, do: x(o, i))
  # Problem: inner_list is not accessible when parsing the constraint
  constraints(
    [o <- outer_list],
    sum(for i <- inner_list, do: x(o, i)) <= 1,
    "Sum constraint"
  )
end

# Check the constraint
constraint = problem.constraints |> Map.values() |> List.first()
IO.puts("Constraint left_hand_side: #{inspect(constraint.left_hand_side)}")
IO.puts("Expected: Should contain x(A,X) + x(A,Y) for o=A")
IO.puts("Actual: #{inspect(constraint.left_hand_side)}")
IO.puts("")

# Check if polynomial has terms
poly = constraint.left_hand_side
terms = Map.get(poly, :simplified, %{})
term_count = map_size(terms)

if term_count == 0 do
  IO.puts("❌ ISSUE REPRODUCED: Constraint shows 0 instead of variables")
else
  poly_str = Dantzig.Polynomial.to_iodata(poly) |> to_string()
  IO.puts("✅ Constraint parsed correctly with #{term_count} terms: #{poly_str}")
end
