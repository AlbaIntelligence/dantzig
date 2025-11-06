#!/usr/bin/env elixir

# Linear Programming Example 1987 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem: Maximize 5x1 + 6x2 subject to:
#   x1 + x2 <= 10
#   x1 - x2 >= 3
#   5x1 + 4x2 <= 35
#   x1, x2 >= 0
#
# Solution (from source):
# Optimal at intersection of 5x1 + 4x2 = 35 and x1 - x2 = 3
# x1 = 47/9 ≈ 5.222, x2 = 20/9 ≈ 2.222
# Objective = 355/9 ≈ 39.444

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1987 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Standard maximization problem")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1987 UG Exam - Maximization")

    # Decision variables
    variables("x1", :continuous, min_bound: 0, description: "Variable x1")
    variables("x2", :continuous, min_bound: 0, description: "Variable x2")

    # Constraints
    constraints(x1 + x2 <= 10, "x1 + x2 <= 10")
    constraints(x1 - x2 >= 3, "x1 - x2 >= 3")
    constraints(5 * x1 + 4 * x2 <= 35, "5x1 + 4x2 <= 35")

    # Objective: maximize 5x1 + 6x2
    objective(5 * x1 + 6 * x2, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Objective value: #{Float.round(objective_value, 4)}")
IO.puts("")

IO.puts("Variable values:")
solution.variables
|> Enum.sort_by(fn {k, _} -> k end)
|> Enum.each(fn {var_name, value} ->
  IO.puts("  #{var_name}: #{Float.round(value, 4)}")
end)

IO.puts("")
IO.puts("=== SOLUTION ANALYSIS (from OR-Notes) ===")
IO.puts("")
IO.puts("Mathematical Formulation:")
IO.puts("maximize 5x1 + 6x2")
IO.puts("subject to:")
IO.puts("  x1 + x2 ≤ 10")
IO.puts("  x1 - x2 ≥ 3")
IO.puts("  5x1 + 4x2 ≤ 35")
IO.puts("  x1, x2 ≥ 0")
IO.puts("")
IO.puts("Graphical Solution:")
IO.puts("  Feasible region bounded by:")
IO.puts("  - x1 + x2 ≤ 10")
IO.puts("  - x1 - x2 ≤ -3  (x1 - x2 ≥ 3)")
IO.puts("  - 5x1 + 4x2 ≤ 35")
IO.puts("  - x1 ≥ 0, x2 ≥ 0")
IO.puts("")
IO.puts("  Optimal solution at intersection of:")
IO.puts("  - 5x1 + 4x2 = 35")
IO.puts("  - x1 - x2 = -3  (x1 - x2 = 3)")
IO.puts("")
IO.puts("  Solving the system:")
IO.puts("  5x1 + 4x2 = 35  (1)")
IO.puts("  x1 - x2 = 3     (2)")
IO.puts("")
IO.puts("  From (2): x1 = x2 + 3")
IO.puts("  Substitute into (1): 5(x2 + 3) + 4x2 = 35")
IO.puts("  5x2 + 15 + 4x2 = 35")
IO.puts("  9x2 = 20")
IO.puts("  x2 = 20/9 ≈ 2.222")
IO.puts("  x1 = 2.222 + 3 = 5.222")
IO.puts("")
IO.puts("  Objective = 5×(20/9) + 6×(47/9) = (100 + 282)/9 = 382/9 ≈ 42.444")
IO.puts("  Wait, source shows 355/9 ≈ 39.444. Let me check...")
IO.puts("")
IO.puts("  Wait, source shows x1 = 47/9, x2 = 20/9")
IO.puts("  That would be x1 ≈ 5.222, x2 ≈ 2.222")
IO.puts("  Objective = 5×47/9 + 6×20/9 = (235 + 120)/9 = 355/9 ≈ 39.444")
IO.puts("")
IO.puts("  Yes, that's correct. I had the wrong objective calculation above.")

IO.puts("")
IO.puts("Optimal Solution:")
IO.puts("  x1 = 47/9 ≈ 5.222")
IO.puts("  x2 = 20/9 ≈ 2.222")
IO.puts("  Objective = 355/9 ≈ 39.444")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
