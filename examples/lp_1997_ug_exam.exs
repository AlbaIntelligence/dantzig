#!/usr/bin/env elixir

# Linear Programming Example 1997 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem Description:
# A company makes two products (X and Y) using two machines (A and B).
# Each unit of X requires 50 minutes on A and 30 minutes on B.
# Each unit of Y requires 24 minutes on A and 33 minutes on B.
#
# Initial stock: 30 units of X, 90 units of Y
# Available time: 40 hours on A, 35 hours on B
# Demand: 75 units of X, 95 units of Y
#
# Goal: Maximize the combined sum of units in stock at end of week
#
# Solution (from source):
# x = 45 (units of X to produce)
# y = 6.25 (units of Y to produce)
# Objective value: 1.25 (additional units in stock)

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1997 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Maximizing combined stock levels")
IO.puts("")

# Define problem data
initial_stock_x = 30
initial_stock_y = 90
demand_x = 75
demand_y = 95
time_a_hours = 40
time_b_hours = 35

# Convert to minutes
time_a_minutes = time_a_hours * 60
time_b_minutes = time_b_hours * 60

IO.puts("Problem Data:")
IO.puts("  Initial stock: #{initial_stock_x} units X, #{initial_stock_y} units Y")
IO.puts("  Demand: #{demand_x} units X, #{demand_y} units Y")
IO.puts("  Machine A: #{time_a_hours} hours (#{time_a_minutes} minutes)")
IO.puts("  Machine B: #{time_b_hours} hours (#{time_b_minutes} minutes)")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1997 UG Exam - Stock Maximization")

    # Decision variables
    variables("x", :continuous, min: 0, description: "Units of X to produce")
    variables("y", :continuous, min: 0, description: "Units of Y to produce")

    # Machine time constraints (minutes)
    constraints(50 * x + 24 * y <= time_a_minutes, "Machine A time limit")
    constraints(30 * x + 33 * y <= time_b_minutes, "Machine B time limit")

    # Demand satisfaction (must produce at least demand - initial stock)
    constraints(x >= demand_x - initial_stock_x, "Meet demand for X")
    constraints(y >= demand_y - initial_stock_y, "Meet demand for Y")

    # Objective: maximize (x + initial_stock_x - demand_x) + (y + initial_stock_y - demand_y)
    # = maximize (x + y - (demand_x + demand_y - initial_stock_x - initial_stock_y))
    # = maximize (x + y - 50)
    objective(x + y - 50, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Objective value: #{Float.round(objective_value, 4)}")
IO.puts("  (additional units in stock at end of week)")
IO.puts("")

IO.puts("Production Plan:")
solution.variables
|> Enum.sort_by(fn {k, _} -> k end)
|> Enum.each(fn {var_name, value} ->
  if value > 0.001 do
    IO.puts("  #{var_name}: #{Float.round(value, 4)} units")
  end
end)

IO.puts("")
IO.puts("Expected solution (from source):")
IO.puts("  x = 45.0 units of X")
IO.puts("  y = 6.25 units of Y")
IO.puts("  Objective = 1.25")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
