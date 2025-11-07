#!/usr/bin/env elixir

# Knapsack Problem Example
#
# BUSINESS CONTEXT:
# A hiker needs to pack a knapsack with limited capacity (weight limit) to maximize
# the total value of items carried. Each item has both weight and value, and can be
# taken at most once. This is a classic resource allocation problem found in logistics,
# supply chain optimization, and decision making under constraints.
#
# MATHEMATICAL FORMULATION:
# Variables: x_i = 1 if item i is selected, 0 otherwise (binary variables)
# Constraints:
#   Σ (x_i × weight_i) ≤ capacity (weight limit)
#   x_i ∈ {0,1} for all i (binary constraint)
# Objective: Maximize Σ (x_i × value_i)
#
# DSL SYNTAX HIGHLIGHTS:
# - Binary variables for selection decisions: variables(name, generators, :binary)
# - Sum expressions for weighted constraints: sum(for i <- items, do: x(i) * weight_i)
# - Model parameters for data separation (when implemented)
# - Binary constraints are automatically enforced by solver
#
# GOTCHAS:
# - Binary variables automatically constrain to 0 or 1
# - Sum expressions require explicit comprehensions
# - Variable names are auto-generated with underscores: select_laptop, select_book, etc.
# - Model parameters feature is planned but not yet implemented

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
items = %{
  "laptop" => %{name: "laptop", weight: 3, value: 10},
  "book" => %{name: "book", weight: 1, value: 3},
  "camera" => %{name: "camera", weight: 2, value: 6},
  "phone" => %{name: "phone", weight: 1, value: 4},
  "headphones" => %{name: "headphones", weight: 1, value: 2}
}

item_names = Map.keys(items)

capacity = 5

IO.puts("Knapsack Problem")
IO.puts("================")
IO.puts("Items:")

Enum.each(items, fn {_name, item} ->
  IO.puts("  #{item.name}: weight=#{item.weight}, value=#{item.value}")
end)

IO.puts("Knapsack capacity: #{capacity}")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define model_parameters: %{items: items, item_names: item_names} do
    new(
      name: "Knapsack Problem",
      description: "Select items to maximize value while respecting weight constraint"
    )

    # Binary variables: x[i] = 1 if item i is selected, 0 otherwise
    variables("select", [i <- item_names], :binary, "Whether to select a given item")

    # Constraint: total weight must not exceed capacity
    constraints(
      sum(for i <- item_names, do: select(i) * items[i].weight) <= capacity,
      "Weight constraint"
    )

    # Objective: maximize total value
    objective(
      sum(for i <- item_names, do: select(i) * items[i].value),
      direction: :maximize
    )
  end

IO.puts("Solving the knapsack problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value (total value): #{objective_value}")
IO.puts("")

IO.puts("Selected items:")

{total_weight, total_value} =
  Enum.reduce(items, {0, 0}, fn {_name, item}, {acc_weight, acc_value} ->
    var_name = "select(#{item.name})"
    selected = solution.variables[var_name] || 0

    if selected > 0.5 do
      IO.puts("  ✓ #{item.name} (weight: #{item.weight}, value: #{item.value})")
      {acc_weight + item.weight, acc_value + item.value}
    else
      IO.puts("  ✗ #{item.name} (weight: #{item.weight}, value: #{item.value})")
      {acc_weight, acc_value}
    end
  end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total weight: #{total_weight}/#{capacity}")
IO.puts("  Total value: #{total_value}")
IO.puts("  Weight constraint satisfied: #{total_weight <= capacity}")
IO.puts("  Optimal solution: #{total_value == objective_value}")

# Validation
if total_weight > capacity do
  IO.puts("ERROR: Weight constraint violated!")
  System.halt(1)
end

if abs(total_value - objective_value) > 0.001 do
  IO.puts("ERROR: Objective value mismatch!")
  System.halt(1)
end

# Enhanced validation
IO.puts("")
IO.puts("Solution Analysis:")
# Should be selected: 3+1+1=5w, 10+3+4=17v
optimal_items = ["laptop", "book", "phone"]

selected_items =
  for {_name, item} <- items, solution.variables["select(#{item.name})"] > 0.5, do: item.name

optimal_selected = Enum.sort(selected_items) == Enum.sort(optimal_items)

IO.puts("  Selected items: #{Enum.join(selected_items, ", ")}")
IO.puts("  Expected optimal: laptop, book, phone (value=17)")
IO.puts("  Optimal solution found: #{if optimal_selected, do: "✅", else: "❌"}")

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Knapsack problems model discrete choice under resource constraints")
IO.puts("• Binary variables naturally represent yes/no decisions")
IO.puts("• Linear programming solvers handle binary constraints efficiently")
IO.puts("• Weighted sums create flexible constraint formulations")
IO.puts("• Real-world applications: project selection, budget allocation, feature prioritization")
IO.puts("• NP-hard in general, but small instances solve quickly")

IO.puts("")
IO.puts("✅ Knapsack problem solved successfully!")
