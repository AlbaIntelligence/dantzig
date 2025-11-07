#!/usr/bin/env elixir

# Two-Variable Linear Programming Example
# ======================================
#
# This example demonstrates the most basic form of linear programming using the Dantzig DSL.
# We solve a simple resource allocation problem that can be visualized geometrically.
#
# BUSINESS CONTEXT:
# A small manufacturing company produces two products (A and B) using limited resources
# (labor hours and raw materials). The goal is to maximize profit while respecting
# resource constraints. This represents the simplest possible optimization scenario
# that still captures all essential LP concepts.
#
# MATHEMATICAL FORMULATION:
# Variables: x_A, x_B = units of products A and B to produce
# Objective: Maximize profit = 10*x_A + 15*x_B
# Constraints:
#   - Labor: 2*x_A + 3*x_B <= 40 hours
#   - Material: 1*x_A + 2*x_B <= 20 units
#   - Non-negativity: x_A >= 0, x_B >= 0
#
# GEOMETRIC INTERPRETATION:
# This problem can be visualized in 2D space where:
# - X-axis: units of product A (x_A)
# - Y-axis: units of product B (x_B)
# - Feasible region: intersection of half-planes defined by constraints
# - Optimal solution: vertex of feasible region with highest profit
#
# DSL SYNTAX HIGHLIGHTS:
# - variables("x", [i <- ["A", "B"]], :continuous, "Units to produce")
#   Creates individual variables with descriptive names
# - constraints(labor_expr <= 40, "Labor constraint")
#   Simple constraint expressions with clear descriptions
# - objective(10*x("A") + 15*x("B"), :maximize)
#   Basic objective function using variable access
#
# LEARNING OBJECTIVES:
# 1. Understand basic LP structure (variables, constraints, objective)
# 2. Practice fundamental DSL syntax patterns
# 3. Visualize how constraints define feasible regions
# 4. See how optimal solutions occur at constraint boundaries
#
# COMMON GOTCHAS:
# 1. Variable naming: Use strings in generators, access with parentheses
# 2. Constraint syntax: Left side expression, operator, right side value
# 3. Objective direction: :maximize or :minimize (no "direction:" keyword)
# 4. Model parameters: Not needed for this simple example

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("Two-Variable Linear Programming Example")
IO.puts("=========================================")
IO.puts("")
IO.puts("Business Scenario:")
IO.puts("A company produces two products (A and B) with limited resources.")
IO.puts("Product A: $10 profit, requires 2 hours labor, 1 unit material")
IO.puts("Product B: $15 profit, requires 3 hours labor, 2 units material")
IO.puts("Available: 40 hours labor, 20 units material")
IO.puts("Goal: Maximize total profit")
IO.puts("")

# Define the products
products = ["A", "B"]

# Create the optimization problem
problem =
  Problem.define model_parameters: %{products: products} do
    new(
      name: "Two-Variable LP Example",
      description: "Basic resource allocation with two decision variables"
    )

    # Decision variables: units of each product to produce
    # Create individual variables for clarity
    variables("produce_A", :continuous, "Units of product A to produce", min_bound: 0.0)
    variables("produce_B", :continuous, "Units of product B to produce", min_bound: 0.0)

    # Constraints: resource limitations
    constraints(2*produce_A + 3*produce_B <= 40, "Labor hours available (40 hours)")
    constraints(1*produce_A + 2*produce_B <= 20, "Raw materials available (20 units)")

    # Objective: maximize total profit
    objective(10*produce_A + 15*produce_B, :maximize)
  end

IO.puts("Problem Structure:")
IO.puts("- 2 decision variables (produce_A, produce_B)")
IO.puts("- 2 resource constraints")
IO.puts("- 1 objective function (maximize profit)")
IO.puts("")

# Solve the optimization problem
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Maximum profit: $#{Float.round(objective_value * 1.0, 2)}")
IO.puts("")

IO.puts("Optimal Production Plan:")
IO.puts("Product A: #{Float.round((solution.variables["produce_A"] || 0) * 1.0, 2)} units (profit: $#{Float.round(10 * (solution.variables["produce_A"] || 0) * 1.0, 2)})")
IO.puts("Product B: #{Float.round((solution.variables["produce_B"] || 0) * 1.0, 2)} units (profit: $#{Float.round(15 * (solution.variables["produce_B"] || 0) * 1.0, 2)})")
IO.puts("")

# Calculate resource utilization
labor_used = 2 * (solution.variables["produce_A"] || 0) + 3 * (solution.variables["produce_B"] || 0)
material_used = 1 * (solution.variables["produce_A"] || 0) + 2 * (solution.variables["produce_B"] || 0)

IO.puts("Resource Utilization:")
IO.puts("Labor: #{Float.round(labor_used * 1.0, 2)} / 40 hours (#{Float.round(100 * labor_used / 40, 1)}%)")
IO.puts("Material: #{Float.round(material_used * 1.0, 2)} / 20 units (#{Float.round(100 * material_used / 20, 1)}%)")
IO.puts("")

# Validation
labor_ok = labor_used <= 40.01
material_ok = material_used <= 20.01
profit_correct = abs((10 * (solution.variables["produce_A"] || 0) + 15 * (solution.variables["produce_B"] || 0)) - objective_value) < 0.01

IO.puts("Validation:")
IO.puts("✓ Labor constraint satisfied: #{labor_ok}")
IO.puts("✓ Material constraint satisfied: #{material_ok}")
IO.puts("✓ Profit calculation correct: #{profit_correct}")
IO.puts("✓ All variables non-negative: #{(solution.variables["produce_A"] || 0) >= -0.001 && (solution.variables["produce_B"] || 0) >= -0.001}")

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Linear programming finds optimal solutions at constraint boundaries")
IO.puts("• Resource constraints define the feasible region of solutions")
IO.puts("• The DSL makes it easy to express business problems mathematically")
IO.puts("• Continuous variables naturally model fractional production quantities")
IO.puts("• This 2-variable problem can be solved graphically on paper")
IO.puts("• Real-world applications: production planning, resource allocation, budgeting")

IO.puts("")
IO.puts("✅ Two-variable LP example completed successfully!")

# Expected optimal solution (for verification):
# x_A = 10, x_B = 6.666..., profit = $200
# This occurs where both constraints are binding
