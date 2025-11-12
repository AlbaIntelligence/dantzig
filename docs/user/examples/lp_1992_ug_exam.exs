#!/usr/bin/env elixir

# Linear Programming Example 1992 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem Description:
# Production of two products (A and B) with profit maximization.
# Assembly time constraint and technological constraint.
#
# Profits: £3 per unit A, £5 per unit B
# Assembly time: 12 min per A, 25 min per B
# Available: 30 hours assembly time
# Technological: for every 5 units of A, at least 2 units of B
#
# Solution (from source):
# xA = 81.8 units of A
# xB = 32.7 units of B
# Profit = £408.90
#
# Additional analysis: Machine hire worth £408.90/week

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1992 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Production with technological constraints")
IO.puts("")

# Problem data
profit_a = 3
profit_b = 5
# minutes per unit A
time_a = 12
# minutes per unit B
time_b = 25
available_hours = 30
available_minutes = available_hours * 60

IO.puts("Production Data:")
IO.puts("  Product A: £#{profit_a} profit, #{time_a} minutes assembly")
IO.puts("  Product B: £#{profit_b} profit, #{time_b} minutes assembly")
IO.puts("  Assembly time available: #{available_hours} hours (#{available_minutes} minutes)")
IO.puts("  Technological constraint: 5A ≥ 2B (for every 5 units A, at least 2 units B)")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1992 UG Exam - Technological Constraints")

    # Decision variables
    variables("xA", :continuous, min_bound: 0, description: "Units of product A to produce")
    variables("xB", :continuous, min_bound: 0, description: "Units of product B to produce")

    # Assembly time constraint
    constraints(time_a * xA + time_b * xB <= available_minutes, "Assembly time limit")

    # Technological constraint: 5*xA >= 2*xB  (equivalent to 2*xB <= 5*xA)
    constraints(2 * xB <= 5 * xA, "Technological constraint (2B ≤ 5A)")

    # Objective: maximize profit
    objective(profit_a * xA + profit_b * xB, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Profit: £#{Float.round(objective_value, 2)}")
IO.puts("")

IO.puts("Production Plan:")

solution.variables
|> Enum.sort_by(fn {k, _} -> k end)
|> Enum.each(fn {var_name, value} ->
  IO.puts("  #{var_name}: #{Float.round(value, 2)} units")
end)

IO.puts("")
IO.puts("=== SOLUTION ANALYSIS (from OR-Notes) ===")
IO.puts("")
IO.puts("Mathematical Formulation:")
IO.puts("Variables: xA, xB ≥ 0")
IO.puts("Constraints:")
IO.puts("  12xA + 25xB ≤ 1800  (30h × 60min assembly time)")
IO.puts("  5xB ≥ 2xA           (technological constraint)")
IO.puts("                       (equivalent to xB ≥ (2/5)xA)")
IO.puts("")
IO.puts("Objective: maximize 3xA + 5xB")
IO.puts("")
IO.puts("Graphical Solution:")
IO.puts("  Feasible region bounded by:")
IO.puts("  - 12xA + 25xB ≤ 1800")
IO.puts("  - 5xB ≥ 2xA  (below line xB = 0.4xA)")
IO.puts("  - xA ≥ 0, xB ≥ 0")
IO.puts("")
IO.puts("  Optimal solution at intersection of:")
IO.puts("  - 12xA + 25xB = 1800 (assembly time binding)")
IO.puts("  - xB = 0.4xA (technological constraint binding)")
IO.puts("")
IO.puts("  Substituting xB = 0.4xA into first equation:")
IO.puts("  12xA + 25(0.4xA) = 1800")
IO.puts("  12xA + 10xA = 1800")
IO.puts("  22xA = 1800")
IO.puts("  xA = 1800/22 ≈ 81.82")
IO.puts("  xB = 0.4 × 81.82 ≈ 32.73")
IO.puts("")
IO.puts("  Objective = 3×81.82 + 5×32.73 ≈ 408.90")

IO.puts("")
IO.puts("Optimal Solution:")
IO.puts("  xA = 81.82 units of Product A")
IO.puts("  xB = 32.73 units of Product B")
IO.puts("  Profit = £408.90")

IO.puts("")
IO.puts("=== MACHINE HIRE ANALYSIS ===")
IO.puts("If assembly time constraint is doubled: 12xA + 25xB ≤ 3600")
IO.puts("")
IO.puts("New optimal at intersection of:")
IO.puts("  12xA + 25xB = 3600")
IO.puts("  xB = 0.4xA")
IO.puts("")
IO.puts("  12xA + 25(0.4xA) = 3600")
IO.puts("  12xA + 10xA = 3600")
IO.puts("  22xA = 3600")
IO.puts("  xA = 3600/22 ≈ 163.64")
IO.puts("  xB = 0.4 × 163.64 ≈ 65.45")
IO.puts("")
IO.puts("  New profit = 3×163.64 + 5×65.45 ≈ 817.80")
IO.puts("  Additional profit = £817.80 - £408.90 = £408.90")
IO.puts("")
IO.puts("Maximum willing to pay for machine hire: £408.90 per week")
IO.puts("(Any more would reduce profit below current optimal)")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
