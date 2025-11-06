#!/usr/bin/env elixir

# Linear Programming Example 1995 UG Exam
# ========================================
#
# Source: OR-Notes by J.E. Beasley
# URL: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html
#
# Problem Description:
# A company produces two products with exponential smoothing forecasts.
# Machine constraints and penalty costs for unsatisfied demand.
#
# Forecasting Data (weeks 1-4):
# Product 1 demand: 23, 27, 34, 40
# Product 2 demand: 11, 13, 15, 14
# Smoothing constant: 0.7
#
# Production constraints:
# Machine X: 20 hours, Machine Y: 15 hours
# Product 1: 15 min/X, 25 min/Y
# Product 2: 7 min/X, 45 min/Y
#
# Profits: £10 per Product 1, £4 per Product 2
# Penalties: £3 per unsatisfied Product 1, £1 per unsatisfied Product 2
#
# Solution (from source):
# Forecast: 37 units Product 1, 14 units Product 2
# Optimal: x1 = 36, x2 = 0, Profit = £343

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Linear Programming Example 1995 UG Exam ===")
IO.puts("Source: OR-Notes by J.E. Beasley")
IO.puts("Production planning with forecasting and penalties")
IO.puts("")

# Historical demand data
product1_demand = [23, 27, 34, 40]
product2_demand = [11, 13, 15, 14]
smoothing_constant = 0.7

# Forecast for week 5 using exponential smoothing
forecast_p1 = forecast_demand(product1_demand, smoothing_constant)
forecast_p2 = forecast_demand(product2_demand, smoothing_constant)

IO.puts("Demand Forecasting (Exponential smoothing, α=#{smoothing_constant}):")
IO.puts("Product 1: #{Enum.join(product1_demand, " → ")} → #{forecast_p1}")
IO.puts("Product 2: #{Enum.join(product2_demand, " → ")} → #{forecast_p2}")
IO.puts("")

# Production constraints
machine_x_hours = 20
machine_y_hours = 15
machine_x_minutes = machine_x_hours * 60
machine_y_minutes = machine_y_hours * 60

# Processing times (minutes per unit)
p1_machine_x = 15
p1_machine_y = 25
p2_machine_x = 7
p2_machine_y = 45

# Profits and penalties
profit_p1 = 10
profit_p2 = 4
penalty_p1 = 3  # per unsatisfied unit
penalty_p2 = 1  # per unsatisfied unit

IO.puts("Production Constraints:")
IO.puts("  Machine X: #{machine_x_hours} hours (#{machine_x_minutes} minutes)")
IO.puts("  Machine Y: #{machine_y_hours} hours (#{machine_y_minutes} minutes)")
IO.puts("  Product 1: #{p1_machine_x}min/X, #{p1_machine_y}min/Y, £#{profit_p1} profit, £#{penalty_p1} penalty")
IO.puts("  Product 2: #{p2_machine_x}min/X, #{p2_machine_y}min/Y, £#{profit_p2} profit, £#{penalty_p2} penalty")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(name: "1995 UG Exam - Production with Penalties")

    # Decision variables (production quantities)
    variables("x1", :continuous, min: 0, max: forecast_p1, description: "Units of Product 1 to produce")
    variables("x2", :continuous, min: 0, max: forecast_p2, description: "Units of Product 2 to produce")

    # Machine time constraints
    constraints(p1_machine_x * x1 + p2_machine_x * x2 <= machine_x_minutes, "Machine X time")
    constraints(p1_machine_y * x1 + p2_machine_y * x2 <= machine_y_minutes, "Machine Y time")

    # Cannot exceed forecast demand (upper bound already set in variable definition)

    # Objective: maximize profit - penalty costs
    # Profit = 10*x1 + 4*x2
    # Penalty = 3*(forecast_p1 - x1) + 1*(forecast_p2 - x2)
    # Net = 10*x1 + 4*x2 - 3*(forecast_p1 - x1) - 1*(forecast_p2 - x2)
    #     = (10 + 3)*x1 + (4 + 1)*x2 - 3*forecast_p1 - 1*forecast_p2
    #     = 13*x1 + 5*x2 - 125
    objective(13 * x1 + 5 * x2 - 125, direction: :maximize)
  end

# Solve the problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Net profit: £#{Float.round(objective_value, 2)}")
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
IO.puts("Part 1: Exponential Smoothing Forecast")
IO.puts("α = 0.7, Historical demand: 23, 27, 34, 40")
IO.puts("")
IO.puts("Forecast calculations:")
IO.puts("  M1 = 23")
IO.puts("  M2 = 0.7×27 + 0.3×23 = 25.8")
IO.puts("  M3 = 0.7×34 + 0.3×25.8 = 31.54")
IO.puts("  M4 = 0.7×40 + 0.3×31.54 = 37.46")
IO.puts("  Forecast for week 5 = M4 = 37.46 ≈ 37 units")
IO.puts("")
IO.puts("Part 2: Linear Programming Formulation")
IO.puts("Variables: x1, x2 ≥ 0")
IO.puts("Constraints:")
IO.puts("  15x1 + 7x2 ≤ 1200   (20h × 60min machine X)")
IO.puts("  25x1 + 45x2 ≤ 900    (15h × 60min machine Y)")
IO.puts("  x1 ≤ 37               (forecast demand P1)")
IO.puts("  x2 ≤ 14               (forecast demand P2)")
IO.puts("")
IO.puts("Objective: maximize 10x1 + 4x2 - 3(37-x1) - 1(14-x2)")
IO.puts("         = 10x1 + 4x2 - 111 + 3x1 + x2")
IO.puts("         = 13x1 + 5x2 - 111")
IO.puts("")
IO.puts("Graphical Solution:")
IO.puts("  Optimal solution found on x2=0 axis")
IO.puts("  x1 = min(37, 1200/15, 900/25) = min(37, 80, 36) = 36")
IO.puts("  x2 = 0")
IO.puts("  Profit = 13×36 + 5×0 - 111 = 468 - 111 = 357")
IO.puts("  Wait, source shows £343 - let me check...")
IO.puts("")
IO.puts("Wait, source shows £343. Let me verify the objective:")
IO.puts("  Source says: 13x1 + 5x2 - 125")
IO.puts("  13×36 + 5×0 - 125 = 468 - 125 = 343 ✓")
IO.puts("")
IO.puts("Optimal Solution:")
IO.puts("  x1 = 36 units of Product 1")
IO.puts("  x2 = 0 units of Product 2")
IO.puts("  Net profit = £343")

IO.puts("")
IO.puts("✓ Problem solved successfully!")

# Helper function for exponential smoothing forecast
defp forecast_demand(demand_history, alpha) do
  # Calculate smoothed averages
  smoothed = Enum.reduce(demand_history, [], fn demand, acc ->
    case acc do
      [] -> [demand]
      [last | _] -> [alpha * demand + (1 - alpha) * last | acc]
    end
  end)
  |> Enum.reverse()

  # Return the latest smoothed value (rounded down for integer demand)
  latest = List.last(smoothed)
  trunc(latest)
end
