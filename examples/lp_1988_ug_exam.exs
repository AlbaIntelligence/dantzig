#!/usr/bin/env elixir

# Linear Programming Example 1988 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem: Minimize 4a + 5b + 6c subject to:
#   a + b >= 11
#   a - b <= 5
#   c - a - b = 0
#   7a >= 35 - 12b
#   a,b,c >= 0
#
# Solution (from source):
# Using c = a + b substitution:
# Minimize 10a + 11b subject to:
#   a + b >= 11
#   a - b <= 5
#   7a + 12b >= 35
#   a,b >= 0
#
# Optimal: a = 8, b = 3, c = 11, objective = 113

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1988 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Minimization with equality constraint")
IO.puts("")

# Create the optimization problem
# Using the substitution c = a + b from the equality constraint
problem =
  Problem.define do
    new(name: "1988 UG Exam - Minimization")

    # Decision variables (c is substituted as a + b)
    variables("a", :continuous, min_bound: 0, description: "Variable a")
    variables("b", :continuous, min_bound: 0, description: "Variable b")

    # Constraints (using substitution c = a + b)
    constraints(a + b >= 11, "a + b >= 11")
    constraints(a - b <= 5, "a - b <= 5")
    constraints(7 * a + 12 * b >= 35, "7a + 12b >= 35")

    # Objective: minimize 4a + 5b + 6c = 4a + 5b + 6(a + b) = 10a + 11b
    objective(10 * a + 11 * b, direction: :minimize)
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

# Calculate c using the substitution
a_val = solution.variables["a"] || 0
b_val = solution.variables["b"] || 0
c_val = a_val + b_val

IO.puts("  c (a + b): #{Float.round(c_val, 4)}")

IO.puts("")
IO.puts("=== SOLUTION ANALYSIS (from OR-Notes) ===")
IO.puts("")
IO.puts("Original Problem:")
IO.puts("minimize 4a + 5b + 6c")
IO.puts("subject to:")
IO.puts("  a + b ≥ 11")
IO.puts("  a - b ≤ 5")
IO.puts("  c - a - b = 0")
IO.puts("  7a ≥ 35 - 12b")
IO.puts("  a,b,c ≥ 0")
IO.puts("")
IO.puts("Using equality constraint c = a + b:")
IO.puts("minimize 4a + 5b + 6(a + b) = 10a + 11b")
IO.puts("subject to:")
IO.puts("  a + b ≥ 11")
IO.puts("  a - b ≤ 5")
IO.puts("  7a + 12b ≥ 35")
IO.puts("  a,b ≥ 0")
IO.puts("")
IO.puts("Graphical Solution:")
IO.puts("  Feasible region bounded by:")
IO.puts("  - a + b ≥ 11")
IO.puts("  - a - b ≤ 5")
IO.puts("  - 7a - 12b ≤ -35  (7a + 12b ≥ 35)")
IO.puts("  - a ≥ 0, b ≥ 0")
IO.puts("")
IO.puts("  Optimal solution at intersection of:")
IO.puts("  - a - b = 5")
IO.puts("  - a + b = 11")
IO.puts("")
IO.puts("  Solving the system:")
IO.puts("  a - b = 5    (1)")
IO.puts("  a + b = 11   (2)")
IO.puts("  Add (1)+(2): 2a = 16 → a = 8")
IO.puts("  Substitute: 8 + b = 11 → b = 3")
IO.puts("  c = a + b = 8 + 3 = 11")
IO.puts("")
IO.puts("  Objective = 10×8 + 11×3 = 80 + 33 = 113")

IO.puts("")
IO.puts("Optimal Solution:")
IO.puts("  a = 8")
IO.puts("  b = 3")
IO.puts("  c = 11")
IO.puts("  Objective = 113")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
