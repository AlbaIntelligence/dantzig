#!/usr/bin/env elixir

# Facility Location Problem Example
# ==================================
#
# This example demonstrates the classic Facility Location Problem using the Dantzig DSL.
# Facility location problems are fundamental to strategic decision-making and optimization,
# with applications in supply chain design, retail location, and logistics network planning.
#
# BUSINESS CONTEXT:
# A company needs to decide which facilities to open and how to serve customers from
# those facilities to minimize total costs (fixed opening costs + transportation costs).
# Each facility has a fixed opening cost, and serving customers from distant facilities
# incurs higher transportation costs.
#
# Real-world applications:
# - Warehouse location optimization
# - Retail store placement strategies
# - Distribution center planning
# - Manufacturing facility siting
# - Service center location design
# - Emergency services placement
#
# MATHEMATICAL FORMULATION:
# Variables:
#   - x[i] = 1 if facility i is opened, 0 otherwise (binary)
#   - y[i,j] = 1 if customer j is served by facility i, 0 otherwise (binary)
# Parameters:
#   - fixed_cost[i] = fixed cost to open facility i
#   - transport_cost[i,j] = cost to serve customer j from facility i
#   - F = set of candidate facilities
#   - C = set of customers
#
# Constraints:
#   - Each customer served by exactly one facility: Σi y[i,j] = 1 for all customers j
#   - Customers can only be served by open facilities: y[i,j] <= x[i] for all i,j
#   - Binary variables: x[i] ∈ {0,1}, y[i,j] ∈ {0,1}
#
# Objective: Minimize total cost: minimize Σi fixed_cost[i] * x[i] + Σi Σj transport_cost[i,j] * y[i,j]
#
# This is a strategic optimization problem where binary decisions (open/not open)
# interact with assignment decisions (serve/not serve) through coupling constraints.
#
# DSL SYNTAX EXPLANATION:
# - Two sets of binary variables: facility opening and customer assignment
# - Coupling constraints: y(i, j) <= x(i) ensures customers only served by open facilities
# - Assignment constraints: sum(y(:_, j)) == 1 ensures each customer served exactly once
# - Complex objective combining fixed and variable costs
#
# COMMON GOTCHAS:
# 1. **Binary Variables**: Both facility opening and assignment decisions are binary
# 2. **Coupling Constraints**: Assignment variables limited by facility opening variables
# 3. **Fixed Costs**: Opening costs are paid regardless of customer assignment
# 4. **Complete Assignment**: Every customer must be served by exactly one facility
# 5. **Model Parameters**: Facility and customer data passed via model_parameters
# 6. **Scalability**: Problem size grows with facilities × customers
# 7. **Solution Quality**: Balance between fixed costs (fewer facilities) and transport costs (closer facilities)

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
facilities = ["Facility_A", "Facility_B", "Facility_C"]
customers = ["Customer_1", "Customer_2", "Customer_3", "Customer_4", "Customer_5"]

# Fixed costs to open each facility
fixed_costs = %{
  "Facility_A" => 1000,
  "Facility_B" => 800,
  "Facility_C" => 600
}

# Transportation costs from each facility to each customer
transport_costs = %{
  "Facility_A" => %{
    "Customer_1" => 50,
    "Customer_2" => 70,
    "Customer_3" => 40,
    "Customer_4" => 60,
    "Customer_5" => 55
  },
  "Facility_B" => %{
    "Customer_1" => 80,
    "Customer_2" => 45,
    "Customer_3" => 65,
    "Customer_4" => 35,
    "Customer_5" => 75
  },
  "Facility_C" => %{
    "Customer_1" => 60,
    "Customer_2" => 85,
    "Customer_3" => 50,
    "Customer_4" => 70,
    "Customer_5" => 40
  }
}

IO.puts("Facility Location Problem")
IO.puts("===========================")
IO.puts("Candidate facilities: #{Enum.join(facilities, ", ")}")
IO.puts("Customers: #{Enum.join(customers, ", ")}")
IO.puts("")

IO.puts("Fixed costs to open facilities:")

Enum.each(facilities, fn facility ->
  IO.puts("  #{facility}: $#{fixed_costs[facility]}")
end)

IO.puts("")
IO.puts("Transportation costs (facility → customer):")

Enum.each(facilities, fn facility ->
  costs =
    Enum.map(customers, fn customer ->
      "#{customer}:#{transport_costs[facility][customer]}"
    end)

  IO.puts("  #{facility}: #{Enum.join(costs, ", ")}")
end)

IO.puts("")

# Create the optimization problem
problem =
  Problem.define model_parameters: %{
                   facilities: facilities,
                   customers: customers,
                   fixed_costs: fixed_costs,
                   transport_costs: transport_costs
                 } do
    new(
      name: "Facility Location Problem",
      description: "Minimize total cost (fixed opening + transportation costs)"
    )

    # Binary variables: x[i] = 1 if facility i is opened
    variables(
      "x",
      [facility <- facilities],
      :binary,
      description: "Facility opened (1) or not opened (0)"
    )

    # Binary variables: y[i,j] = 1 if customer j is served by facility i
    variables(
      "y",
      [facility <- facilities, customer <- customers],
      :binary,
      description: "Customer served by facility"
    )

    # Constraint: Each customer served by exactly one facility
    constraints(
      [customer <- customers],
      sum(for facility <- facilities, do: y(facility, customer)) == 1,
      "Each customer served exactly once"
    )

    # Constraint: Customers can only be served by open facilities
    # This ensures y[i,j] <= x[i] for all i,j
    constraints(
      [facility <- facilities, customer <- customers],
      y(facility, customer) <= x(facility),
      "Only open facilities can serve customers"
    )

    # Objective: Minimize total cost (fixed + transportation)
    objective(
      sum(
        for facility <- facilities do
          x(facility) * fixed_costs[facility] +
            sum(
              for customer <- customers do
                y(facility, customer) * transport_costs[facility][customer]
              end
            )
        end
      ),
      direction: :minimize
    )
  end

IO.puts("Solving the facility location problem...")
result = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

case result do
  {solution, objective_value} ->
    IO.puts("\nSolution:")
    IO.puts("=========")
    IO.puts("Minimum total cost: $#{Float.round(objective_value * 1.0, 2)}")
    IO.puts("")

    IO.puts("Facilities to Open:")
    total_fixed_cost =
      Enum.reduce(facilities, 0, fn facility, acc ->
        var_name = "x(#{facility})"
        opened = solution.variables[var_name] || 0

        if opened > 0.5 do
          fixed_cost = fixed_costs[facility]
          IO.puts("  ✅ #{facility}: Open (fixed cost: $#{fixed_cost})")
          acc + fixed_cost
        else
          IO.puts("  ❌ #{facility}: Closed")
          acc
        end
      end)

    IO.puts("")
    IO.puts("Customer Assignments:")
    total_transport_cost =
      Enum.reduce(customers, 0, fn customer, acc ->
        IO.puts("  #{customer}:")

        customer_cost =
          Enum.reduce(facilities, 0, fn facility, facility_acc ->
            var_name = "y(#{facility},#{customer})"
            assigned = solution.variables[var_name] || 0

            if assigned > 0.5 do
              transport_cost = transport_costs[facility][customer]
              IO.puts("    → Served by #{facility} (transport cost: $#{transport_cost})")
              facility_acc + transport_cost
            else
              facility_acc
            end
          end)

        acc + customer_cost
      end)

    IO.puts("")
    IO.puts("Cost Breakdown:")
    IO.puts("  Fixed facility costs: $#{Float.round(total_fixed_cost * 1.0, 2)}")
    IO.puts("  Transportation costs: $#{Float.round(total_transport_cost * 1.0, 2)}")
    IO.puts("  Total cost: $#{Float.round((total_fixed_cost + total_transport_cost) * 1.0, 2)}")
    IO.puts("  Reported objective: $#{Float.round(objective_value * 1.0, 2)}")

    IO.puts(
      "  Cost matches objective: #{abs(total_fixed_cost + total_transport_cost - objective_value) < 0.001}"
    )

    # Validation
    if abs(total_fixed_cost + total_transport_cost - objective_value) > 0.001 do
      IO.puts("ERROR: Cost calculation mismatch!")
      System.halt(1)
    end

    # Validate each customer is served exactly once
    IO.puts("")
    IO.puts("Assignment Validation:")

    customer_assignments =
      Enum.map(customers, fn customer ->
        assignments =
          Enum.map(facilities, fn facility ->
            var_name = "y(#{facility},#{customer})"
            solution.variables[var_name] || 0
          end)

        {customer, Enum.sum(assignments)}
      end)

    all_served_once =
      Enum.all?(customer_assignments, fn {customer, count} ->
        if abs(count - 1.0) < 0.001 do
          IO.puts("  ✅ #{customer}: Served exactly once")
          true
        else
          IO.puts("  ❌ #{customer}: Served #{count} times (should be 1)")
          false
        end
      end)

    # Validate only open facilities serve customers
    IO.puts("")
    IO.puts("Facility Utilization Check:")

    Enum.each(facilities, fn facility ->
      var_name = "x(#{facility})"
      opened = solution.variables[var_name] || 0

      if opened > 0.5 do
        # Check if this facility serves any customers
        served_customers =
          Enum.count(customers, fn customer ->
            var_name = "y(#{facility},#{customer})"
            (solution.variables[var_name] || 0) > 0.5
          end)

        IO.puts("  ✅ #{facility}: Open and serves #{served_customers} customers")
      else
        # Check that this facility serves no customers
        served_customers =
          Enum.count(customers, fn customer ->
            var_name = "y(#{facility},#{customer})"
            (solution.variables[var_name] || 0) > 0.5
          end)

        if served_customers == 0 do
          IO.puts("  ✅ #{facility}: Closed and serves no customers")
        else
          IO.puts("  ❌ #{facility}: Closed but serves #{served_customers} customers")
        end
      end
    end)

    IO.puts("")
    IO.puts("LEARNING INSIGHTS:")
    IO.puts("==================")
    IO.puts("• Facility location problems optimize strategic placement under cost constraints")
    IO.puts("• Binary variables naturally model discrete decisions (open/not open)")
    IO.puts("• Coupling constraints ensure assignment variables respect facility status")
    IO.puts("• Balance between fixed costs (economy of scale) and transport costs (proximity)")
    IO.puts("• Real-world applications: supply chain design, retail placement, service location")

    IO.puts(
      "• The DSL demonstrates complex optimization with multiple variable types and constraints"
    )

    IO.puts("")
    IO.puts("✅ Facility location problem solved successfully!")

  :error ->
    IO.puts("ERROR: Facility location problem could not be solved.")
    IO.puts("This may be due to infeasible constraints or formulation issues.")
    IO.puts("Check that all customers can be served by at least one open facility.")
    System.halt(1)
end
