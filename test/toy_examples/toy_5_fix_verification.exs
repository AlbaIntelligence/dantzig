#!/usr/bin/env elixir

# Toy Example 5: Verification that the fix works for school_timetabling pattern
# This demonstrates that sum(for ...) with nested generators now works correctly

require Dantzig.Problem, as: Problem

teachers = ["T1", "T2"]
subjects = ["Math", "Science"]
rooms = ["R1", "R2"]
time_slots = ["Slot1"]

IO.puts("=== Toy Example 5: Fix Verification ===")
IO.puts("Testing the same pattern as school_timetabling.exs")
IO.puts("")

problem = Problem.define do
  new(name: "Toy5")
  
  variables("schedule", [t <- teachers, s <- subjects, r <- rooms, m <- time_slots], :binary)
  
  # Constraint 1: Each teacher can only teach one class at a time (same as school_timetabling)
  constraints(
    [t <- teachers, m <- time_slots],
    sum(for s <- subjects, r <- rooms, do: schedule(t, s, r, m)) <= 1,
    "Teacher time conflict"
  )
  
  # Constraint 2: Each room can only host one class at a time
  constraints(
    [r <- rooms, m <- time_slots],
    sum(for t <- teachers, s <- subjects, do: schedule(t, s, r, m)) <= 1,
    "Room time conflict"
  )
  
  # Constraint 3: Each subject must be taught exactly once per time slot
  constraints(
    [s <- subjects, m <- time_slots],
    sum(for t <- teachers, r <- rooms, do: schedule(t, s, r, m)) == 1,
    "Subject coverage"
  )
end

# Check all constraints have proper variables
all_good = problem.constraints
|> Map.values()
|> Enum.all?(fn constraint ->
  case constraint.left_hand_side do
    %Dantzig.Polynomial{simplified: terms} when map_size(terms) > 0 -> true
    _ -> false
  end
end)

if all_good do
  IO.puts("✅ All constraints have proper variables!")
  IO.puts("   Total constraints: #{map_size(problem.constraints)}")
  
  # Show first constraint as example
  first_constraint = problem.constraints |> Map.values() |> List.first()
  poly_str = Dantzig.Polynomial.to_iodata(first_constraint.left_hand_side) |> to_string()
  IO.puts("   Example constraint: #{poly_str} #{first_constraint.operator} #{first_constraint.right_hand_side}")
else
  IO.puts("❌ Some constraints still show 0")
end
