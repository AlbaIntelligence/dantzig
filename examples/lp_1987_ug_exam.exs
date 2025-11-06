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
    variables("x1", :continuous, min: 0, description: "Variable x1")
    variables("x2", :continuous, min: 0, description: "Variable x2")

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
IO.puts("Expected solution (from source):")
IO.puts("  x1 = 5.222 (47/9)")
IO.puts("  x2 = 2.222 (20/9)")
IO.puts("  Objective = 39.444 (355/9)")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
