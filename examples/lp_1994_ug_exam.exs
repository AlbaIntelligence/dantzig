#!/usr/bin/env elixir

# Linear Programming Example 1994 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem Description:
# Production of two items (X and Y) with machine and craftsman time constraints.
# Contract requirement for minimum X production.
# Costs for machine and craftsman time.
#
# Processing times (minutes):
# Item X: 13 machine, 20 craftsman
# Item Y: 19 machine, 29 craftsman
#
# Available time: 40 hours machine, 35 hours craftsman
# Costs: £10/hour machine, £2/hour craftsman
# Revenue: £20/item X, £30/item Y
# Contract: minimum 10 items of X per week
#
# Solution (from source):
# x = 10 (items of X)
# y = 65.52 (items of Y)
# Objective value: £1866.50

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1994 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Production planning with cost optimization")
IO.puts("")

# Problem data
machine_time_x = 13      # minutes per unit X
machine_time_y = 19      # minutes per unit Y
craftsman_time_x = 20    # minutes per unit X
craftsman_time_y = 29    # minutes per unit Y

machine_hours = 40
craftsman_hours = 35
machine_minutes = machine_hours * 60
craftsman_minutes = craftsman_hours * 60

machine_cost_per_hour = 10
craftsman_cost_per_hour = 2
revenue_x = 20
revenue_y = 30

contract_x = 10  # minimum X production

IO.puts("Processing Requirements (minutes per unit):")
IO.puts("  Item X: #{machine_time_x} machine, #{craftsman_time_x} craftsman")
IO.puts("  Item Y: #{machine_time_y} machine, #{craftsman_time_y} craftsman")
IO.puts("")
IO.puts("Available Time: #{machine_hours} hours machine, #{craftsman_hours} hours craftsman")
IO.puts("Costs: £#{machine_cost_per_hour}/hour machine, £#{craftsman_cost_per_hour}/hour craftsman")
IO.puts("Revenue: £#{revenue_x}/item X, £#{revenue_y}/item Y")
IO.puts("Contract: minimum #{contract_x} items of X")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1994 UG Exam - Cost Optimization")

    # Decision variables
    variables("x", :continuous, min: contract_x, description: "Number of items X to produce")
    variables("y", :continuous, min: 0, description: "Number of items Y to produce")

    # Time constraints
    constraints(machine_time_x * x + machine_time_y * y <= machine_minutes, "Machine time limit")
    constraints(craftsman_time_x * x + craftsman_time_y * y <= craftsman_minutes, "Craftsman time limit")

    # Contract constraint (already handled by x >= contract_x in variable definition)

    # Objective: maximize profit
    # Revenue - costs for actual time used
    # Time costs: machine_cost_per_hour * (machine_time_used/60)
    #            craftsman_cost_per_hour * (craftsman_time_used/60)
    #
    # Objective = revenue_x * x + revenue_y * y
    #           - machine_cost_per_hour * (machine_time_x * x + machine_time_y * y) / 60
    #           - craftsman_cost_per_hour * (craftsman_time_x * x + craftsman_time_y * y) / 60
    #
    # Which simplifies to the coefficients given in the source

    objective(17.1667 * x + 25.8667 * y, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

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
IO.puts("Expected solution (from source):")
IO.puts("  x = 10.0 units of X")
IO.puts("  y = 65.52 units of Y")
IO.puts("  Profit = £1866.50")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
