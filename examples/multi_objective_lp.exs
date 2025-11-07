#!/usr/bin/env elixir

# Multi-Objective Linear Programming Example
# ===========================================
#
# This example demonstrates Multi-Objective Optimization using the Dantzig DSL.
# Multi-objective optimization involves optimizing multiple conflicting objectives
# simultaneously, requiring trade-offs between different goals.
#
# BUSINESS CONTEXT:
# A manufacturing company needs to decide how much of each product to produce
# while balancing two conflicting objectives:
# 1. Maximize total profit
# 2. Minimize total environmental impact (carbon emissions)
#
# These objectives are typically in conflict: products with higher profit margins
# often have higher environmental impact, and vice versa. The company must find
# a solution that balances both concerns.
#
# Real-world applications:
# - Sustainable manufacturing and production planning
# - Supply chain optimization with cost and sustainability goals
# - Portfolio optimization (return vs. risk)
# - Resource allocation with efficiency and equity objectives
# - Project selection with ROI and strategic value
# - Facility location with cost and service quality
# - Workforce scheduling with cost and employee satisfaction
#
# MATHEMATICAL FORMULATION:
# Variables: x[i] = quantity of product i to produce
# Parameters:
#   - profit[i] = profit per unit of product i
#   - emissions[i] = carbon emissions per unit of product i
#   - resource[j][i] = amount of resource j needed per unit of product i
#   - capacity[j] = available capacity of resource j
#   - demand[i] = maximum demand for product i
#   - N = number of products
#   - M = number of resources
#
# Constraints:
#   - Resource constraints: Σi resource[j][i] * x[i] <= capacity[j] for all j
#   - Demand constraints: x[i] <= demand[i] for all i
#   - Non-negativity: x[i] >= 0 for all i
#
# Objectives (conflicting):
#   - Objective 1: Maximize profit = Σi profit[i] * x[i]
#   - Objective 2: Minimize emissions = Σi emissions[i] * x[i]
#
# Multi-Objective Approach:
# Since Dantzig DSL supports a single objective function, we use the weighted sum
# method to combine objectives:
#   minimize: -w1 * (profit) + w2 * (emissions)
#   where w1 and w2 are weights representing the relative importance
#   of profit vs. environmental impact
#
# By varying the weights, we can explore the Pareto frontier (set of
# non-dominated solutions) and find trade-offs between objectives.
#
# DSL SYNTAX EXPLANATION:
# - Single set of continuous variables representing production quantities
# - Multiple resource constraints using generator syntax
# - Demand constraints using generator syntax
# - Weighted objective combining both goals
# - Model parameters for profit, emissions, resources, capacities, demands
#
# COMMON GOTCHAS:
# 1. **Objective Direction**: Profit is maximized, emissions minimized
#    - Combined objective: minimize (-profit_weight * profit + emission_weight * emissions)
#    - Negative sign on profit because we're minimizing
# 2. **Weight Selection**: Weights determine trade-off between objectives
#    - Equal weights (0.5, 0.5) balance both objectives
#    - High profit weight (0.9, 0.1) prioritizes profit
#    - High emission weight (0.1, 0.9) prioritizes environmental impact
# 3. **Pareto Frontier**: Multiple solutions exist, each representing a different trade-off
#    - Run multiple times with different weights to explore the frontier
# 4. **Unit Consistency**: Ensure profit and emissions are in comparable units
#    - May need normalization or scaling
# 5. **Resource Constraints**: All resources must be satisfied simultaneously
# 6. **Demand Limits**: Cannot produce more than market demand
# 7. **Non-Dominance**: A solution is Pareto-optimal if no other solution is better
#    in both objectives simultaneously

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define products to manufacture
# Defined as a dictionary for easy parameter access
products = %{
  "Widget_A" => %{
    name: "Widget_A",
    profit: 45.0,
    emissions: 2.5,
    labour: 2.0,
    material: 1.2,
    machine_hours: 0.8,
    max_demand: 80.0
  },
  "Widget_B" => %{
    name: "Widget_B",
    profit: 52.0,
    emissions: 3.2,
    labour: 2.5,
    material: 1.5,
    machine_hours: 1.0,
    max_demand: 70.0
  },
  "Widget_C" => %{
    name: "Widget_C",
    profit: 38.0,
    emissions: 1.8,
    labour: 1.5,
    material: 0.9,
    machine_hours: 0.6,
    max_demand: 90.0
  },
  "Gadget_X" => %{
    name: "Gadget_X",
    profit: 68.0,
    emissions: 4.5,
    labour: 3.5,
    material: 2.1,
    machine_hours: 1.4,
    max_demand: 60.0
  },
  "Gadget_Y" => %{
    name: "Gadget_Y",
    profit: 75.0,
    emissions: 5.1,
    labour: 4.0,
    material: 2.4,
    machine_hours: 1.6,
    max_demand: 55.0
  },
  "Gadget_Z" => %{
    name: "Gadget_Z",
    profit: 58.0,
    emissions: 3.8,
    labour: 3.0,
    material: 1.8,
    machine_hours: 1.2,
    max_demand: 65.0
  },
  "Device_1" => %{
    name: "Device_1",
    profit: 85.0,
    emissions: 6.2,
    labour: 5.0,
    material: 3.2,
    machine_hours: 2.0,
    max_demand: 40.0
  },
  "Device_2" => %{
    name: "Device_2",
    profit: 92.0,
    emissions: 7.0,
    labour: 5.5,
    material: 3.6,
    machine_hours: 2.2,
    max_demand: 35.0
  },
  "Device_3" => %{
    name: "Device_3",
    profit: 78.0,
    emissions: 5.5,
    labour: 4.5,
    material: 2.8,
    machine_hours: 1.8,
    max_demand: 45.0
  },
  "Device_4" => %{
    name: "Device_4",
    profit: 65.0,
    emissions: 4.2,
    labour: 4.0,
    material: 2.2,
    machine_hours: 1.5,
    max_demand: 50.0
  }
}

# Product names (needed for variable generation)
product_names = Map.keys(products)
num_products = length(product_names)

# Resource names (needed for constraint generation)
# Resource capacities (using atoms to match resource_names)
resource_capacities = %{
  labour: 500.0,
  material: 400.0,
  machine_hours: 300.0
}

resource_names = Map.keys(resource_capacities)
num_resources = length(resource_names)

# Multi-objective weights
# profit_weight: importance of maximizing profit (0.0 to 1.0)
# emission_weight: importance of minimizing emissions (0.0 to 1.0)
# Note: These should sum to 1.0 for proper normalization
profit_weight = 0.3
emission_weight = 1.0 - profit_weight

# Emission cost per kg CO2 (to make emissions comparable to profit in dollars)
# This represents the cost/penalty of emissions in monetary terms
emission_cost_per_kg = 10.0

IO.puts("=" <> String.duplicate("=", 79))
IO.puts("Multi-Objective Production Planning Problem")
IO.puts("=" <> String.duplicate("=", 79))
IO.puts("\nObjectives:")
IO.puts("  1. Maximize Profit (weight: #{profit_weight})")
IO.puts("  2. Minimize Environmental Impact (weight: #{emission_weight})")
IO.puts("\nProducts: #{num_products}")
IO.puts("Resources: #{num_resources}")
IO.puts("\n" <> String.duplicate("-", 79))

# Define the optimization problem
problem =
  Problem.define model_parameters: %{
                   products: products,
                   product_names: product_names,
                   resource_names: resource_names,
                   resource_capacities: resource_capacities,
                   profit_weight: profit_weight,
                   emission_weight: emission_weight,
                   emission_cost_per_kg: emission_cost_per_kg
                 } do
    new(name: "Multi-Objective Production Planning", direction: :minimize)

    # Decision variables: quantity of each product to produce
    variables(
      "production",
      [product <- product_names],
      :continuous,
      min_bound: 0.0,
      description: "Production quantity for each product"
    )

    # Resource capacity constraints
    constraints(
      [resource <- resource_names],
      sum(
        for product <- product_names do
          production(product) * products[product][resource]
        end
      ) <= resource_capacities[resource],
      "Resource capacity constraint for #{resource}"
    )

    # Demand constraints
    constraints(
      [product <- product_names],
      production(product) <= products[product].max_demand,
      "Maximum demand constraint for #{product}"
    )

    # Multi-objective function: weighted sum
    # minimize: -profit_weight * profit + emission_weight * (emissions * cost_per_kg)
    # Note: Negative sign on profit because we're minimizing (to maximize profit)
    objective(
      profit_weight *
        sum(
          for product <- product_names do
            production(product) * products[product].profit
          end
        ) -
        emission_weight *
          sum(
            for product <- product_names do
              production(product) * products[product].emissions * emission_cost_per_kg
            end
          ),
      :minimize
    )
  end

# Solve the problem
IO.puts("\nSolving optimization problem...")
{solution, _objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

# Display results
IO.puts("\n" <> String.duplicate("=", 79))
IO.puts("SOLUTION SUMMARY")
IO.puts(String.duplicate("=", 79))

if solution.model_status == "Optimal" do
  IO.puts("\n✅ Optimal solution found!\n")

  # Calculate actual objective values
  total_profit =
    Enum.reduce(products, 0.0, fn p, acc ->
      acc + solution.variables["production(#{p})"] * products[p].profit
    end)

  total_emissions =
    Enum.reduce(products, 0.0, fn p, acc ->
      acc + solution.variables["production(#{p})"] * products[p].emissions
    end)

  IO.puts("Objective Values:")
  IO.puts("  Total Profit: $#{:erlang.float_to_binary(total_profit, decimals: 2)}")
  IO.puts("  Total Emissions: #{:erlang.float_to_binary(total_emissions, decimals: 2)} kg CO2")

  IO.puts(
    "  Combined Objective: #{:erlang.float_to_binary(solution.objective_value, decimals: 6)}"
  )

  IO.puts("\nProduction Plan:")
  IO.puts(String.duplicate("-", 79))
  IO.puts("Product          | Quantity | Profit    | Emissions")
  IO.puts(String.duplicate("-", 79))

  Enum.each(product_names, fn product ->
    qty = solution.variables["production(#{product})"]

    if qty > 0.001 do
      profit = qty * products[product].profit
      emissions = qty * products[product].emissions

      IO.puts(
        String.pad_trailing(product, 15) <>
          " | " <>
          String.pad_leading(:erlang.float_to_binary(qty, decimals: 2), 8) <>
          " | " <>
          String.pad_leading("$#{:erlang.float_to_binary(profit, decimals: 2)}", 9) <>
          " | " <>
          String.pad_leading(:erlang.float_to_binary(emissions, decimals: 2), 9) <> " kg"
      )
    end
  end)

  IO.puts(String.duplicate("-", 79))

  IO.puts(
    String.pad_trailing("TOTAL", 15) <>
      " | " <>
      String.pad_leading("", 8) <>
      " | " <>
      String.pad_leading("$#{:erlang.float_to_binary(total_profit, decimals: 2)}", 9) <>
      " | " <>
      String.pad_leading(:erlang.float_to_binary(total_emissions, decimals: 2), 9) <>
      " kg"
  )

  IO.puts("\nResource Utilization:")
  IO.puts(String.duplicate("-", 79))

  Enum.each(resource_names, fn resource ->
    used =
      Enum.reduce(products, 0.0, fn p, acc ->
        acc + solution.variables["production(#{p})"] * products[p][resource]
      end)

    capacity = resource_capacities[resource]
    utilization = used / capacity * 100.0

    IO.puts(
      String.pad_trailing(resource, 20) <>
        ": " <>
        String.pad_leading(:erlang.float_to_binary(used, decimals: 2), 8) <>
        " / " <>
        String.pad_leading(:erlang.float_to_binary(capacity, decimals: 2), 8) <>
        " " <>
        "(#{:erlang.float_to_binary(utilization, decimals: 1)}%)"
    )
  end)

  IO.puts("\n" <> String.duplicate("=", 79))
  IO.puts("MULTI-OBJECTIVE ANALYSIS")
  IO.puts(String.duplicate("=", 79))
  IO.puts("\nThis solution represents a trade-off between profit and environmental impact.")
  IO.puts("To explore the Pareto frontier, run this example with different weights:")
  IO.puts("  - Profit-focused: profit_weight=0.9, emission_weight=0.1")
  IO.puts("  - Balanced: profit_weight=0.5, emission_weight=0.5")
  IO.puts("  - Environment-focused: profit_weight=0.1, emission_weight=0.9")
  IO.puts("\nEach weight combination will produce a different solution on the Pareto frontier.")
else
  IO.puts("\n❌ Solution status: #{solution.model_status}")

  case solution.model_status do
    "Infeasible" ->
      IO.puts("The problem is infeasible. Check constraints and parameters.")

    "Unbounded" ->
      IO.puts("The problem is unbounded. Check objective function and constraints.")
      IO.puts("This may indicate the objective normalization needs adjustment.")

    _ ->
      IO.puts("Unexpected solution status: #{solution.model_status}")
  end
end

IO.puts("\n")
