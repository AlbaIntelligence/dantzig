#!/usr/bin/env elixir

# Linear Programming Example 1986 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem Description:
# A carpenter makes tables and chairs with profit maximization.
#
# Profits: £30 per table, £10 per chair
# Time: 6 hours per table, 3 hours per chair, max 40 hours/week
# Demand: at least 3 times as many chairs as tables
# Storage: tables take 4 times space of chairs, max 4 tables
#
# Solution (from source):
# Optimal at intersection of storage and time constraints
# xT = 4/3 ≈ 1.333 tables, xC = 10.667 chairs
# Profit = £146.667

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1986 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Carpenter production planning")
IO.puts("")

# Problem data
profit_table = 30
profit_chair = 10
time_table = 6    # hours per table
time_chair = 3    # hours per chair
max_hours = 40

# Demand constraint: chairs >= 3 * tables
demand_ratio = 3

# Storage constraint: table space = 4 * chair space, max 4 tables
max_tables = 4

IO.puts("Production Data:")
IO.puts("  Table: £#{profit_table} profit, #{time_table} hours, #{4} chair-space units")
IO.puts("  Chair: £#{profit_chair} profit, #{time_chair} hours, #{1} chair-space units")
IO.puts("  Total time available: #{max_hours} hours")
IO.puts("  Demand: at least #{demand_ratio} chairs per table")
IO.puts("  Storage: maximum #{max_tables} tables worth of space")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1986 UG Exam - Carpenter Production")

    # Decision variables
    variables("xT", :continuous, min: 0, max: max_tables, description: "Number of tables to make")
    variables("xC", :continuous, min: 0, description: "Number of chairs to make")

    # Time constraint
    constraints(time_table * xT + time_chair * xC <= max_hours, "Total working hours <= #{max_hours}")

    # Demand constraint: chairs >= 3 * tables
    constraints(xC >= demand_ratio * xT, "At least #{demand_ratio} chairs per table")

    # Storage constraint: table space + chair space <= max table space
    # Table takes 4 units, chair takes 1 unit, max 4 tables = 16 units
    # So: 4*xT + 1*xC <= 4*4 = 16, or simplified: xT + 0.25*xC <= 4
    constraints(xT + 0.25 * xC <= 4, "Storage space limit")

    # Objective: maximize profit
    objective(profit_table * xT + profit_chair * xC, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Profit: £#{Float.round(objective_value, 3)}")
IO.puts("")

IO.puts("Production Plan:")
solution.variables
|> Enum.sort_by(fn {k, _} -> k end)
|> Enum.each(fn {var_name, value} ->
  IO.puts("  #{var_name}: #{Float.round(value, 3)} units")
end)

IO.puts("")
IO.puts("Expected solution (from source):")
IO.puts("  xT = 1.333 tables")
IO.puts("  xC = 10.667 chairs")
IO.puts("  Profit = £146.667")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
