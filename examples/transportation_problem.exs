#!/usr/bin/env elixir

# Transportation Problem Example
# ==============================
#
# This example demonstrates the classic Transportation Problem using the Dantzig DSL.
# Transportation problems are fundamental to supply chain optimization and logistics,
# with applications in distribution, resource allocation, and network flow.
#
# BUSINESS CONTEXT:
# A logistics company needs to ship goods from multiple suppliers to multiple customers
# while minimizing total transportation costs. Each supplier has limited capacity,
# and each customer has specific demand that must be met exactly.
#
# Real-world applications:
# - Distribution center optimization
# - Supply chain management
# - Network flow problems
# - Resource allocation across locations
# - Delivery route optimization
# - Inventory management across warehouses
#
# MATHEMATICAL FORMULATION:
# Variables: x[s,c] = amount shipped from supplier s to customer c
# Parameters:
#   - supply[s] = available supply at supplier s
#   - demand[c] = required demand at customer c
#   - cost[s,c] = cost per unit to ship from s to c
#   - S = set of suppliers
#   - C = set of customers
#
# Constraints:
#   - Supply limits: Σc x[s,c] <= supply[s] for all suppliers s
#   - Demand requirements: Σs x[s,c] = demand[c] for all customers c
#   - Non-negativity: x[s,c] >= 0 for all s,c
#
# Objective: Minimize total shipping cost: minimize Σs Σc cost[s,c] * x[s,c]
#
# This is a special case of the minimum cost flow problem where all
# supplies and demands are concentrated at specific nodes.
#
# DSL SYNTAX EXPLANATION:
# - Model parameters: Pass data via model_parameters: %{...} for clean separation
#   of problem data from problem structure. Parameters are accessible directly by
#   name (e.g., supply, demand, cost_matrix) in expressions.
# - Pattern-based variables: variables("ship", [s <- suppliers, c <- customers], :continuous, ...)
#   creates variables for all supplier-customer pairs using nested generator syntax.
# - Variable bounds: min_bound: 0.0, max_bound: :infinity enforces non-negativity
#   (no negative shipments) and allows unlimited shipments.
# - Pattern-based constraints: sum(ship(s, :_)) uses wildcard syntax to sum over
#   all customers for a given supplier, enforcing supply capacity constraints.
# - Pattern-based demand constraints: sum(ship(:_, c)) uses wildcard syntax to sum
#   over all suppliers for a given customer, enforcing exact demand satisfaction.
# - Objective with nested comprehensions: sum(for s <- suppliers, c <- customers, do: ...)
#   aggregates shipping costs across all supplier-customer pairs.
# - Variable access: ship(s, c) accesses variables in expressions.
# - Model parameter access: supply[s], demand[c], cost_matrix[s][c] access constants
#   from model_parameters in expressions.
#
# COMMON GOTCHAS:
# 1. **Supply-Demand Balance**: Total supply must equal total demand for a balanced
#    transportation problem. Unbalanced problems require dummy suppliers/customers
#    or constraint modifications.
# 2. **Variable Bounds**: Use min_bound: 0.0 for non-negativity (no negative shipments).
#    Use max_bound: :infinity to allow unlimited shipments (or set specific capacity
#    limits if needed).
# 3. **Cost Matrix Structure**: Ensure cost_matrix has entries for all supplier-customer
#    pairs. Nested map structure: cost_matrix[supplier][customer] accesses shipping costs.
# 4. **Model Parameters**: Model parameters are now supported and should be used for
#    clean data separation. Access via direct name (supply, demand) not params.supply.
# 5. **Demand Requirements**: Use == for exact demand satisfaction, not <=. Each customer
#    must receive exactly their required demand.
# 6. **Supply Constraints**: Use <= for capacity limits, not == (to allow unused capacity).
#    Suppliers can ship less than their capacity if it's optimal.
# 7. **Wildcard Syntax**: Use ship(s, :_) to sum over all customers for supplier s, and
#    ship(:_, c) to sum over all suppliers for customer c. This is more elegant than
#    explicit for comprehensions in constraints.
# 8. **Variable Naming**: Variable names are auto-generated as ship(Supplier1,Customer1),
#    ship(Supplier1,Customer2), etc. Access them in solution using parentheses format:
#    solution.variables["ship(#{supplier},#{customer})"].
# 9. **Nested Generators**: When creating variables with [s <- suppliers, c <- customers],
#    all combinations are created. Order matters: first generator is outer loop.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
suppliers = ["Supplier1", "Supplier2", "Supplier3"]
customers = ["Customer1", "Customer2", "Customer3", "Customer4"]

# Supply capacity for each supplier
supply = %{
  "Supplier1" => 20,
  "Supplier2" => 25,
  "Supplier3" => 15
}

# Demand requirements for each customer
demand = %{
  "Customer1" => 15,
  "Customer2" => 20,
  "Customer3" => 15,
  "Customer4" => 10
}

# Shipping cost per unit from each supplier to each customer
cost_matrix = %{
  "Supplier1" => %{"Customer1" => 2, "Customer2" => 3, "Customer3" => 1, "Customer4" => 4},
  "Supplier2" => %{"Customer1" => 3, "Customer2" => 2, "Customer3" => 4, "Customer4" => 1},
  "Supplier3" => %{"Customer1" => 1, "Customer2" => 4, "Customer3" => 3, "Customer4" => 2}
}

IO.puts("Transportation Problem")
IO.puts("======================")
IO.puts("Suppliers: #{Enum.join(suppliers, ", ")}")
IO.puts("Customers: #{Enum.join(customers, ", ")}")
IO.puts("")
IO.puts("Supply Capacity:")

Enum.each(suppliers, fn supplier ->
  IO.puts("  #{supplier}: #{supply[supplier]} units")
end)

IO.puts("")
IO.puts("Demand Requirements:")

Enum.each(customers, fn customer ->
  IO.puts("  #{customer}: #{demand[customer]} units")
end)

IO.puts("")
IO.puts("Cost Matrix (per unit):")

Enum.each(suppliers, fn supplier ->
  costs = Enum.map(customers, fn customer -> "#{customer}:#{cost_matrix[supplier][customer]}" end)
  IO.puts("  #{supplier}: #{Enum.join(costs, ", ")}")
end)

# Verify supply equals demand
total_supply = Enum.sum(Map.values(supply))
total_demand = Enum.sum(Map.values(demand))
IO.puts("")
IO.puts("Total Supply: #{total_supply}, Total Demand: #{total_demand}")

if total_supply != total_demand do
  IO.puts("WARNING: Supply (#{total_supply}) != Demand (#{total_demand})")
  IO.puts("This is an unbalanced transportation problem!")
end

# Create the optimization problem
problem =
  Problem.define model_parameters: %{
                   supply: supply,
                   demand: demand,
                   suppliers: suppliers,
                   customers: customers,
                   cost_matrix: cost_matrix
                 } do
    new(
      name: "Transportation Problem",
      description: "Minimize shipping costs from suppliers to customers"
    )

    # Continuous variables: ship[s,c] = units shipped from supplier s to customer c
    # Note: Nested generators [s <- suppliers, c <- customers] create variables for
    # all combinations of suppliers and customers. The order matters: s is the outer
    # loop, c is the inner loop.
    variables(
      "ship",
      [s <- suppliers, c <- customers],
      :continuous,
      min_bound: 0.0,
      max_bound: :infinity,
      description: "Units shipped from supplier to customer"
    )

    # Constraint: supply limits - each supplier cannot ship more than their capacity
    # Note: sum(ship(s, :_)) uses wildcard syntax to sum over all customers for
    # supplier s. This is more elegant than explicit for comprehensions.
    constraints(
      [s <- suppliers],
      sum(ship(s, :_)) <= supply[s],
      "Supplier capacity #{s}"
    )

    # Constraint: demand requirements - each customer must receive exactly their demand
    # Note: sum(ship(:_, c)) uses wildcard syntax to sum over all suppliers for
    # customer c. Use == for exact demand satisfaction (not <=).
    constraints(
      [c <- customers],
      sum(ship(:_, c)) == demand[c],
      "Customer demand #{c}"
    )

    # Objective: minimize total shipping cost
    # Note: Uses nested for comprehension to iterate over all supplier-customer pairs.
    # Each term: ship(s, c) * cost_matrix[s][c] multiplies the shipment quantity by
    # the per-unit shipping cost. The sum aggregates costs across all pairs.
    objective(
      sum(for s <- suppliers, c <- customers, do: ship(s, c) * cost_matrix[s][c]),
      :minimize
    )
  end

# Debug: Show problem structure
IO.puts("")
IO.puts("Problem structure:")
IO.puts("Variables: #{map_size(problem.variables)}")
IO.puts("Constraints: #{map_size(problem.constraints)}")

# Debug: Show constraints
IO.puts("")
IO.puts("Constraints:")

problem.constraints
|> Map.values()
|> Enum.each(fn c ->
  IO.puts("  #{c.name}: #{inspect(c.left_hand_side)} #{c.operator} #{inspect(c.right_hand_side)}")
end)

# Debug: Show variable names
IO.puts("")
IO.puts("Variable names created:")
var_names = Map.keys(problem.variables["ship"])
IO.inspect(var_names, label: "Ship variables")

IO.puts("Solving the transportation problem...")
{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value: #{objective_value}")
IO.puts("")

IO.puts("Shipping Plan:")
# Display the shipping plan and calculate total cost
{total_cost, _} =
  Enum.reduce(suppliers, {0, solution.variables}, fn supplier, {acc_cost, vars} ->
    IO.puts("#{supplier}:")

    Enum.reduce(customers, {acc_cost, vars}, fn customer, {inner_acc, inner_vars} ->
      var_name = "ship(#{supplier},#{customer})"
      units_shipped = Map.get(inner_vars, var_name, 0)

      # Only show non-zero shipments
      if units_shipped > 0.001 do
        unit_cost = cost_matrix[supplier][customer]
        shipment_cost = units_shipped * unit_cost
        new_acc = inner_acc + shipment_cost

        IO.puts(
          "  → #{customer}: #{Float.round(units_shipped * 1.0, 2)} units (cost: $#{Float.round(shipment_cost * 1.0, 2)})"
        )

        {new_acc, inner_vars}
      else
        {inner_acc, inner_vars}
      end
    end)
  end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total shipping cost: $#{Float.round(total_cost * 1.0, 2)}")
IO.puts("  Reported objective: #{objective_value}")
IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")

# Validation
if abs(total_cost - objective_value) > 0.001 do
  IO.puts("ERROR: Objective value mismatch!")
  System.halt(1)
end

# Check that each supplier's shipments don't exceed capacity
supplier_validation =
  Enum.map(suppliers, fn supplier ->
    total_shipped =
      Enum.reduce(customers, 0, fn customer, acc ->
        var_name = "ship(#{supplier},#{customer})"
        acc + Map.get(solution.variables, var_name, 0)
      end)

    {supplier, total_shipped, supply[supplier]}
  end)

IO.puts("")
IO.puts("Supplier Capacity Check:")

Enum.each(supplier_validation, fn {supplier, shipped, capacity} ->
  status =
    if shipped <= capacity + 0.001 do
      "✅ OK"
    else
      "❌ VIOLATED"
    end

  shipped_float = if is_integer(shipped), do: :erlang.float(shipped), else: shipped
  capacity_float = if is_integer(capacity), do: :erlang.float(capacity), else: capacity
  IO.puts("  #{supplier}: #{Float.round(shipped_float, 2)}/#{capacity_float} units #{status}")
end)

# Check that each customer's demand is met exactly
customer_validation =
  Enum.map(customers, fn customer ->
    total_received =
      Enum.reduce(suppliers, 0, fn supplier, acc ->
        var_name = "ship(#{supplier},#{customer})"
        acc + Map.get(solution.variables, var_name, 0)
      end)

    {customer, total_received, demand[customer]}
  end)

IO.puts("")
IO.puts("Customer Demand Check:")

Enum.each(customer_validation, fn {customer, received, required} ->
  status =
    if abs(received - required) < 0.001 do
      "✅ OK"
    else
      "❌ VIOLATED"
    end

  received_float = if is_integer(received), do: :erlang.float(received), else: received
  required_float = if is_integer(required), do: :erlang.float(required), else: required
  IO.puts("  #{customer}: #{Float.round(received_float, 2)}/#{required_float} units #{status}")
end)

# Check for any validation errors
validation_errors =
  Enum.filter(supplier_validation ++ customer_validation, fn {_, actual, expected} ->
    case {actual, expected} do
      {a, e} when is_number(e) -> abs(a - e) >= 0.001
      _ -> false
    end
  end)

if validation_errors != [] do
  IO.puts("ERROR: Validation failed!")
  System.halt(1)
end

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Transportation problems optimize distribution across supply-demand networks")
IO.puts("• Linear programming naturally handles capacity and demand constraints")
IO.puts("• Model parameters enable clean separation of data from optimization logic")
IO.puts("• Continuous variables naturally model fractional shipment quantities")
IO.puts("• Network flow problems demonstrate balanced supply-demand relationships")
IO.puts("• Real-world applications: logistics, supply chain, distribution networks")
IO.puts("• The DSL shows pattern-based constraint generation for multiple suppliers/customers")

IO.puts("")
IO.puts("✅ Transportation problem solved successfully!")
