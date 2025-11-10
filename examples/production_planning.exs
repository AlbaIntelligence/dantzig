#!/usr/bin/env elixir

# Production Planning Problem Example
#
# BUSINESS CONTEXT:
# A manufacturing company needs to plan production over multiple time periods
# to meet varying customer demand while minimizing total costs. The company
# can produce different amounts each period and carry inventory forward to
# future periods. This balances production costs (which may vary by period)
# against inventory holding costs. This is a classic production planning and
# inventory management problem found in manufacturing, supply chain optimization,
# and operations research.
#
# Real-world applications:
# - Manufacturing production scheduling
# - Supply chain inventory management
# - Seasonal demand planning
# - Capacity planning with inventory buffers
# - Multi-period resource allocation
# - Just-in-time vs. inventory holding trade-offs
# - Warehouse and distribution center planning
#
# Key decisions:
# - How much to produce in each time period
# - How much inventory to carry forward to the next period
# - Trade-off between production costs and inventory holding costs
#
# MATHEMATICAL FORMULATION:
# Variables:
#   production[t] = units produced in period t (continuous, ≥ 0, ≤ max_production)
#   inventory[t] = units in inventory at end of period t (continuous, ≥ 0)
#
# Constraints:
#   Period 1: initial_inventory + production[1] - demand[1] = inventory[1]
#   Period t (t > 1): inventory[t-1] + production[t] - demand[t] = inventory[t]
#   production[t] ≤ max_production for all t (capacity constraint)
#   inventory[t] ≥ 0 for all t (non-negativity)
#
# Objective: Minimize Σ (production[t] × production_cost[t] + inventory[t] × holding_cost)
#
# DSL SYNTAX EXPLANATION:
# - Model parameters: Pass data via model_parameters: %{...} for clean separation
#   of problem data from problem structure. Parameters are accessible directly by
#   name (e.g., demand, production_cost) in expressions.
# - Pattern-based variables: variables("production", [t <- time_periods], :continuous, ...)
#   creates variables for each time period using generator syntax.
# - Variable bounds: min_bound: 0.0, max_bound: max_production enforces capacity
#   constraints directly on variables (more efficient than explicit constraints).
# - Infinity bounds: max_bound: :infinity allows unbounded inventory (no storage limit).
#   Note: :infinity is handled specially and cannot be converted to Polynomial constants.
# - Inventory balance constraints: Link inventory[t-1] + production[t] - demand[t] = inventory[t]
#   to ensure inventory flows correctly across periods.
# - Sum expressions: sum(for t <- time_periods, do: ...) aggregates costs across
#   all periods in the objective function.
# - Variable access: production(t), inventory(t) access variables in expressions.
# - Model parameter access: demand[t], production_cost[t] access constants from
#   model_parameters in expressions.
#
# COMMON GOTCHAS:
# 1. **Period 1 Constraint**: Period 1 is special - uses initial_inventory (given data)
#    instead of inventory[0] (which doesn't exist). The constraint is rearranged as:
#    production(1) - demand[1] == -initial_inventory + inventory(1).
# 2. **Parser Limitations**: Constraints for periods 2-4 are written individually because
#    the parser doesn't yet support arithmetic in generator ranges (e.g., [t <- [2..max_periods]])
#    or variable indexing with arithmetic (e.g., inventory(t-1)).
# 3. **Future Improvements**: TODO - Future parser improvements will support:
#    constraints([t <- [2..max_periods]], inventory(t-1) + production(t) - demand[t] == inventory(t)).
# 4. **Variable Naming**: Variable names are auto-generated: production_1, production_2, inventory_1, etc.
#    Access them in solution using these generated names.
# 5. **Model Parameter Access**: Model parameters are accessed directly by name (demand,
#    production_cost) not via params.demand syntax. String keys are automatically
#    converted to atom keys when accessing maps.
# 6. **Infinity Bounds**: Infinity bounds (:infinity) are handled specially and cannot
#    be converted to Polynomial constants. They must be passed directly to variable
#    bounds or constraint right-hand sides.
# 7. **Objective Syntax**: The objective uses a for comprehension inside sum() to iterate
#    over time periods. Each term multiplies variables by model parameters.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
time_periods = [1, 2, 3, 4]
max_periods = Enum.at(time_periods, -1)

# Demand for each time period
demand = %{
  # Period 1
  1 => 100,
  # Period 2
  2 => 150,
  # Period 3
  3 => 80,
  # Period 4
  4 => 200
}

# Production cost per unit for each period
production_cost = %{
  # Period 1
  1 => 10,
  # Period 2
  2 => 12,
  # Period 3
  3 => 11,
  # Period 4
  4 => 13
}

# Inventory holding cost per unit per period
holding_cost = 2

# Maximum production capacity per period
max_production = 250

# Initial inventory at start of period 1
initial_inventory = 50

IO.puts("Production Planning Problem")
IO.puts("===========================")
IO.puts("Time periods: #{Enum.join(time_periods, ", ")}")
IO.puts("")
IO.puts("Demand by period:")

Enum.each(time_periods, fn period ->
  IO.puts("  Period #{period}: #{demand[period]} units")
end)

IO.puts("")
IO.puts("Production cost per unit:")

Enum.each(time_periods, fn period ->
  IO.puts("  Period #{period}: $#{production_cost[period]}")
end)

IO.puts("")
IO.puts("Holding cost per unit per period: $#{holding_cost}")
IO.puts("Maximum production per period: #{max_production}")
IO.puts("Initial inventory: #{initial_inventory}")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define model_parameters: %{
                   demand: demand,
                   production_cost: production_cost,
                   holding_cost: holding_cost,
                   max_production: max_production,
                   initial_inventory: initial_inventory,
                   time_periods: time_periods,
                   max_periods: max_periods
                 } do
    new(
      name: "Production Planning Problem",
      description: "Minimize production and inventory costs over 4 periods"
    )

    # Production variables: production[t] = units produced in period t
    # Note: max_bound uses model parameter max_production directly
    # The capacity constraint is enforced via variable bounds (more efficient than
    # explicit constraints)
    variables(
      "production",
      [t <- time_periods],
      :continuous,
      min_bound: 0.0,
      max_bound: 250.0,
      description: "Units produced in period"
    )

    # Inventory variables: inventory[t] = units in inventory at end of period t
    # Note: max_bound: :infinity allows unlimited inventory (no storage capacity limit)
    # Non-negativity is enforced via min_bound: 0.0
    variables(
      "inventory",
      [t <- time_periods],
      :continuous,
      min_bound: 0.0,
      max_bound: :infinity,
      description: "Units in inventory at end of period"
    )

    # Inventory balance constraints: ensure inventory flows correctly across periods
    #
    # Period 1 is special: uses initial_inventory (given data) instead of
    # inventory[0] (which doesn't exist). The balance equation is:
    #   initial_inventory + production(1) - demand[1] == inventory(1)
    # Rearranged: production(1) - demand[1] + initial_inventory == inventory(1)
    constraints(
      [t <- [1]],
      production(t) - demand[1] + 50 == inventory(t),
      "Inventory balance for period 1"
    )

    # For periods 2-4: inventory[t-1] + produce[t] - demand[t] = inventory[t]
    # Note: Currently written individually because parser doesn't yet support:
    #   - Arithmetic in generator ranges: [t <- [2..max_periods]]
    #   - Variable indexing with arithmetic: inventory(t-1)
    #   - Model parameter access in constraints: demand[t] (though this works in objectives)
    #
    # TODO: Future parser improvements will allow:
    #   constraints(
    #     [t <- [2..max_periods]],
    #     inventory(t-1) + production(t) - demand[t] == inventory(t),
    #     "Inventory balance for period #{t}"
    #   )
    #
    # For now, we write each period explicitly and use hardcoded demand values:
    constraints(
      inventory(1) + production(2) - 150 == inventory(2),
      "Inventory balance for period 2"
    )

    constraints(
      inventory(2) + production(3) - 80 == inventory(3),
      "Inventory balance for period 3"
    )

    constraints(
      inventory(3) + production(4) - 200 == inventory(4),
      "Inventory balance for period 4"
    )

    # Production capacity constraints (already handled by variable bounds)
    # Inventory cannot be negative (already handled by variable bounds)

    # Objective: minimize total production + holding costs
    # Note: Uses sum() with a for comprehension to iterate over all time periods
    # Each term: production(t) * production_cost[t] + inventory(t) * holding_cost
    #   - production(t): variable access (units produced in period t)
    #   - production_cost[t]: model parameter access (cost per unit in period t)
    #   - inventory(t): variable access (ending inventory in period t)
    #   - holding_cost: model parameter (constant holding cost per unit per period)
    # The sum aggregates costs across all periods to get total cost
    objective(
      sum(
        for t <- time_periods, do: production(t) * production_cost[t] + inventory(t) * holding_cost
      ),
      direction: :minimize
    )
  end

IO.puts("Solving the production planning problem...")
result = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

case result do
  {solution, objective_value} ->
    IO.puts("Solution:")
    IO.puts("=========")
    IO.puts("Objective value: #{objective_value}")
    IO.puts("")

    IO.puts("Production Plan:")
    {total_production_cost, total_holding_cost} =
      Enum.reduce(time_periods, {0.0, 0.0}, fn period, {acc_prod, acc_hold} ->
        production_var = "production(#{period})"
        inventory_var = "inventory(#{period})"

        produced = solution.variables[production_var] || 0.0
        inventory = solution.variables[inventory_var] || 0.0

        production_cost = produced * production_cost[period]
        holding_cost_period = inventory * holding_cost

        IO.puts("Period #{period}:")
        IO.puts(
          "  Production: #{Float.round(produced * 1.0, 2)} units (cost: $#{Float.round(production_cost * 1.0, 2)})"
        )
        IO.puts(
          "  Ending Inventory: #{Float.round(inventory * 1.0, 2)} units (holding cost: $#{Float.round(holding_cost_period * 1.0, 2)})"
        )
        IO.puts("  Demand: #{demand[period]} units")
        IO.puts("")

        {acc_prod + production_cost, acc_hold + holding_cost_period}
      end)

    total_cost = total_production_cost + total_holding_cost

    IO.puts("Summary:")
    IO.puts("  Total production cost: $#{Float.round(total_production_cost * 1.0, 2)}")
    IO.puts("  Total holding cost: $#{Float.round(total_holding_cost * 1.0, 2)}")
    IO.puts("  Total cost: $#{Float.round(total_cost * 1.0, 2)}")
    IO.puts("  Reported objective: #{objective_value}")
    IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")

    # Validation
    if abs(total_cost - objective_value) > 0.001 do
      IO.puts("ERROR: Objective value mismatch!")
      System.halt(1)
    end

    # Validate inventory balance for each period
    IO.puts("")
    IO.puts("Inventory Balance Validation:")

    # Period 1: initial + produced - demand should equal ending inventory
    period1_balance = initial_inventory + solution.variables["production(1)"] - demand[1]
    period1_valid = abs(period1_balance - solution.variables["inventory(1)"]) < 0.001

    IO.puts(
      "  Period 1: #{initial_inventory} + #{Float.round((solution.variables["production(1)"] || 0.0) * 1.0, 2)} - #{demand[1]} = #{Float.round(period1_balance * 1.0, 2)} (inventory: #{Float.round((solution.variables["inventory(1)"] || 0.0) * 1.0, 2)}) #{if period1_valid, do: "✅ OK", else: "❌ VIOLATED"}"
    )

    # Periods 2-4: previous inventory + produced - demand should equal ending inventory
    Enum.each(2..4, fn period ->
      prev_inventory = (solution.variables["inventory(#{period - 1})"] || 0.0) * 1.0
      produced = (solution.variables["production(#{period})"] || 0.0) * 1.0
      balance = prev_inventory + produced - demand[period]
      current_inventory = (solution.variables["inventory(#{period})"] || 0.0) * 1.0
      valid = abs(balance - current_inventory) < 0.001

      IO.puts(
        "  Period #{period}: #{Float.round(prev_inventory, 2)} + #{Float.round(produced, 2)} - #{demand[period]} = #{Float.round(balance, 2)} (inventory: #{Float.round(current_inventory, 2)}) #{if valid, do: "✅ OK", else: "❌ VIOLATED"}"
      )
    end)

    # Check that all production is within capacity
    production_validation =
      Enum.map(time_periods, fn period ->
        produced = (solution.variables["production(#{period})"] || 0.0) * 1.0
        {period, produced, max_production}
      end)

    IO.puts("")
    IO.puts("Production Capacity Check:")

    Enum.each(production_validation, fn {period, produced, capacity} ->
      status =
        if produced <= capacity + 0.001 do
          "✅ OK"
        else
          "❌ VIOLATED"
        end

      IO.puts("  Period #{period}: #{Float.round(produced, 2)}/#{capacity} units #{status}")
    end)

    # Check for any validation errors
    validation_errors =
      Enum.filter(
        [period1_valid] ++
          Enum.map(2..4, fn t ->
            abs(
              solution.variables["inventory(#{t - 1})"] + solution.variables["production(#{t})"] -
                demand[t] - solution.variables["inventory(#{t})"]
            ) < 0.001
          end),
        fn valid -> not valid end
      )

    if validation_errors != [] do
      IO.puts("ERROR: Inventory balance validation failed!")
      System.halt(1)
    end

    IO.puts("")
    IO.puts("✅ Production planning problem solved successfully!")

  :error ->
    IO.puts("ERROR: Problem could not be solved. This may be due to:")
    IO.puts("  1. Infeasible constraints (no feasible solution exists)")
    IO.puts("  2. Unbounded objective (solution can be arbitrarily large)")
    IO.puts("  3. Invalid constraint formulation")
    IO.puts("")
    IO.puts("Please check the problem formulation and try again.")
    System.halt(1)
end
