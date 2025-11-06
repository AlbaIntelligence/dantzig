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
    variables("a", :continuous, min: 0, description: "Variable a")
    variables("b", :continuous, min: 0, description: "Variable b")

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
IO.puts("Expected solution (from source):")
IO.puts("  a = 8.0")
IO.puts("  b = 3.0")
IO.puts("  c = 11.0")
IO.puts("  Objective = 113.0")

IO.puts("")
IO.puts("✓ Problem solved successfully!")
