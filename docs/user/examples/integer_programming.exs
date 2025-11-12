#!/usr/bin/env elixir

# Integer Programming Example - Production Planning
# =================================================
#
# This example demonstrates Integer Programming using the Dantzig DSL.
# Integer programming is essential when decision variables must take whole-number
# values, such as counting items, assigning workers, or producing discrete units.
#
# BUSINESS CONTEXT:
# A manufacturing company needs to decide how many units of each product to produce
# to maximize profit while respecting resource constraints. Unlike continuous variables,
# we cannot produce fractional units (e.g., 2.5 cars or 3.7 bicycles). The solution
# must be in whole numbers.
#
# Real-world applications:
# - Production planning with discrete units
# - Workforce scheduling (integer number of workers)
# - Vehicle routing (integer number of vehicles)
# - Cutting stock problems (integer number of cuts)
# - Facility location with integer capacity decisions
# - Inventory management with discrete items
# - Project selection (integer number of projects)
#
# MATHEMATICAL FORMULATION:
# Variables:
#   - produce[p] = number of units of product p to produce (integer, >= 0)
# Parameters:
#   - profit[p] = profit per unit of product p
#   - resource_usage[p][r] = units of resource r needed per unit of product p
#   - resource_capacity[r] = available units of resource r
#   - P = set of products
#   - R = set of resources
#
# Constraints:
#   - Resource constraints: Σp produce[p] * resource_usage[p][r] <= resource_capacity[r] for all r
#   - Non-negativity: produce[p] >= 0 for all p
#   - Integer constraint: produce[p] ∈ ℤ (whole numbers only)
#
# Objective: Maximize total profit: maximize Σp profit[p] * produce[p]
#
# KEY DIFFERENCE FROM CONTINUOUS VARIABLES:
# - Continuous variables: Can take any real value (e.g., 2.5, 3.14159)
# - Integer variables: Must take whole number values (e.g., 2, 3, 4)
# - This constraint makes the problem harder to solve but more realistic for
#   many practical applications where fractional solutions don't make sense
#
# DSL SYNTAX EXPLANATION:
# - Integer variables: variables("produce", [product <- products], :integer, ...)
# - Same constraint syntax as continuous variables
# - Solver automatically handles integer constraints
# - Solution values will be integers (or very close due to numerical precision)
#
# KEY LEARNING POINTS:
# - Integer variables are essential for discrete decision problems
# - Integer programming is more computationally intensive than linear programming
# - The solution space is discrete, not continuous
# - Integer solutions may be suboptimal compared to relaxed continuous solutions
#
# COMMON GOTCHAS:
# - Integer variables cannot have fractional bounds (e.g., min_bound: 0.5)
# - Integer programming problems can take longer to solve than LP
# - Some solvers may return near-integer values (e.g., 2.0000001) due to numerical precision
# - Integer constraints make the feasible region non-convex
#
# ============================================================================

require Dantzig.Problem, as: Problem

# ============================================================================
# PROBLEM DATA
# ============================================================================

# Products with profit and resource requirements
products_data = %{
  "Widget_A" => %{
    profit: 25.0,
    resource_usage: %{"Labor" => 2, "Material" => 3, "Machine_Time" => 1},
    description: "High-margin product requiring skilled labor"
  },
  "Widget_B" => %{
    profit: 30.0,
    resource_usage: %{"Labor" => 1, "Material" => 4, "Machine_Time" => 2},
    description: "Material-intensive product"
  },
  "Widget_C" => %{
    profit: 20.0,
    resource_usage: %{"Labor" => 3, "Material" => 2, "Machine_Time" => 1},
    description: "Labor-intensive product"
  },
  "Widget_D" => %{
    profit: 35.0,
    resource_usage: %{"Labor" => 2, "Material" => 5, "Machine_Time" => 3},
    description: "Premium product with high resource requirements"
  },
  "Widget_E" => %{
    profit: 18.0,
    resource_usage: %{"Labor" => 1, "Material" => 1, "Machine_Time" => 1},
    description: "Simple product with low resource requirements"
  }
}

# Available resource capacities
resource_capacities = %{
  "Labor" => 40,
  "Material" => 50,
  "Machine_Time" => 30
}

product_names = Map.keys(products_data)
resource_names = Map.keys(resource_capacities)

IO.puts("=" <> String.duplicate("=", 78))
IO.puts("INTEGER PROGRAMMING - PRODUCTION PLANNING")
IO.puts("=" <> String.duplicate("=", 78))
IO.puts("")
IO.puts("Problem: Determine optimal production quantities (whole units only)")
IO.puts("Objective: Maximize total profit")
IO.puts("")
IO.puts("Products:")
Enum.each(products_data, fn {product, data} ->
  IO.puts("  • #{product}: $#{data.profit} profit per unit")
  IO.puts("    #{data.description}")
end)
IO.puts("")
IO.puts("Resource Capacities:")
Enum.each(resource_capacities, fn {resource, capacity} ->
  IO.puts("  • #{resource}: #{capacity} units")
end)
IO.puts("")
IO.puts("Key Constraint: Production quantities must be whole numbers (integers)")
IO.puts("This distinguishes integer programming from continuous linear programming.")
IO.puts("")

# ============================================================================
# PROBLEM DEFINITION
# ============================================================================

problem =
  Problem.define model_parameters: %{
                   products: products_data,
                   product_names: product_names,
                   resource_names: resource_names,
                   resource_capacities: resource_capacities
                 } do
    new(name: "Integer Production Planning", direction: :maximize)

    # Decision variables: number of units to produce (INTEGER - whole numbers only)
    variables(
      "produce",
      [product <- product_names],
      :integer,
      min_bound: 0,
      description: "Number of units of each product to produce (must be whole numbers)"
    )

    # Resource capacity constraints
    constraints(
      [resource <- resource_names],
      sum(
        for product <- product_names do
          produce(product) * products[product].resource_usage[resource]
        end
      ) <= resource_capacities[resource],
      "Resource capacity constraint for #{resource}"
    )

    # Objective: Maximize total profit
    objective(
      sum(
        for product <- product_names do
          produce(product) * products[product].profit
        end
      ),
      :maximize
    )
  end

# ============================================================================
# SOLVE THE PROBLEM
# ============================================================================

IO.puts("Solving the integer programming problem...")
IO.puts("")
IO.puts("Note: Integer programming problems may take longer to solve than")
IO.puts("continuous linear programming problems due to the discrete solution space.")
IO.puts("")

{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

case {solution, objective_value} do
  {%Dantzig.Solution{} = solution_map, obj_val} ->
    solution = solution_map
    objective_value = obj_val

    IO.puts("\n" <> String.duplicate("-", 79))
    IO.puts("SOLUTION")
    IO.puts(String.duplicate("-", 79))
    IO.puts("")
    IO.puts("Maximum Total Profit: $#{Float.round(objective_value * 1.0, 2)}")
    IO.puts("")

    # Display production plan
    IO.puts("Production Plan:")
    IO.puts(String.duplicate("-", 79))

    production_plan =
      Enum.map(product_names, fn product ->
        quantity = solution.variables["produce(#{product})"] || 0.0
        # Round to nearest integer (handle numerical precision issues)
        quantity_int = round(quantity)
        profit_per_unit = products_data[product].profit
        total_profit = quantity_int * profit_per_unit

        %{
          product: product,
          quantity: quantity_int,
          profit_per_unit: profit_per_unit,
          total_profit: total_profit
        }
      end)
      |> Enum.filter(fn %{quantity: q} -> q > 0 end)
      |> Enum.sort_by(& &1.total_profit, :desc)

    if Enum.empty?(production_plan) do
      IO.puts("  No products selected for production")
    else
      Enum.each(production_plan, fn %{product: product, quantity: q, profit_per_unit: ppu, total_profit: tp} ->
        IO.puts(
          "  #{String.pad_trailing(product, 15)} | Quantity: #{String.pad_leading(Integer.to_string(q), 3)} units | " <>
            "Profit/unit: $#{String.pad_leading(Float.to_string(Float.round(ppu * 1.0, 2)), 6)} | " <>
            "Total: $#{String.pad_leading(Float.to_string(Float.round(tp * 1.0, 2)), 7)}"
        )
      end)
    end

    IO.puts("")
    IO.puts(String.duplicate("-", 79))

    # Verify integer values
    IO.puts("")
    IO.puts("Integer Constraint Verification:")
    IO.puts(String.duplicate("-", 79))

    all_integers =
      Enum.all?(product_names, fn product ->
        value = solution.variables["produce(#{product})"] || 0.0
        # Check if value is close to an integer (within numerical precision)
        abs(value - round(value)) < 0.001
      end)

    Enum.each(product_names, fn product ->
      value = solution.variables["produce(#{product})"] || 0.0
      rounded = round(value)
      is_integer = abs(value - rounded) < 0.001

      status = if is_integer, do: "✅", else: "⚠️"
      IO.puts(
        "  #{status} #{String.pad_trailing(product, 15)} | Value: #{Float.to_string(Float.round(value * 1.0, 6))} | " <>
          "Rounded: #{Integer.to_string(rounded)} | Integer: #{is_integer}"
      )
    end)

    IO.puts("")
    IO.puts("  Overall: #{if all_integers, do: "✅ All values are integers", else: "⚠️ Some values may not be integers (check numerical precision)"}")
    IO.puts("")

    # Resource utilization
    IO.puts("Resource Utilization:")
    IO.puts(String.duplicate("-", 79))

    Enum.each(resource_names, fn resource ->
      used =
        Enum.reduce(product_names, 0.0, fn product, acc ->
          quantity = solution.variables["produce(#{product})"] || 0.0
          quantity_int = round(quantity)
          usage_per_unit = products_data[product].resource_usage[resource] || 0
          acc + quantity_int * usage_per_unit
        end)

      capacity = resource_capacities[resource]
      utilization = if capacity > 0, do: (used / capacity) * 100.0, else: 0.0

      IO.puts(
        "  #{String.pad_trailing(resource, 15)} | Used: #{String.pad_leading(Float.to_string(Float.round(used * 1.0, 2)), 6)} / " <>
          "#{String.pad_leading(Integer.to_string(capacity), 6)} | " <>
          "Utilization: #{String.pad_leading(Float.to_string(Float.round(utilization * 1.0, 1)), 5)}%"
      )
    end)

    IO.puts("")

    # Validation
    IO.puts("Validation:")
    IO.puts(String.duplicate("-", 79))

    # Check resource constraints
    resource_constraints_ok =
      Enum.all?(resource_names, fn resource ->
        used =
          Enum.reduce(product_names, 0.0, fn product, acc ->
            quantity = solution.variables["produce(#{product})"] || 0.0
            quantity_int = round(quantity)
            usage_per_unit = products_data[product].resource_usage[resource] || 0
            acc + quantity_int * usage_per_unit
          end)

        capacity = resource_capacities[resource]
        used <= capacity + 0.01 # Allow small numerical tolerance
      end)

    # Check non-negativity
    non_negative =
      Enum.all?(product_names, fn product ->
        value = solution.variables["produce(#{product})"] || 0.0
        value >= -0.01 # Allow small numerical tolerance
      end)

    validations = [
      {"All production quantities are non-negative", non_negative},
      {"All resource constraints satisfied", resource_constraints_ok},
      {"All values are integers (within numerical precision)", all_integers}
    ]

    Enum.each(validations, fn {check, result} ->
      status = if result, do: "✅", else: "❌"
      IO.puts("  #{status} #{check}")
    end)

    IO.puts("")

    # Learning insights
    IO.puts("LEARNING INSIGHTS:")
    IO.puts(String.duplicate("=", 79))
    IO.puts("")
    IO.puts("• Integer programming requires variables to take whole-number values")
    IO.puts("• This is essential for problems where fractional solutions don't make sense:")
    IO.puts("  - Production quantities (can't produce 2.5 cars)")
    IO.puts("  - Workforce scheduling (can't have 3.7 workers)")
    IO.puts("  - Vehicle routing (can't use 1.3 trucks)")
    IO.puts("  - Cutting stock (can't make 4.2 cuts)")
    IO.puts("• Integer programming is more computationally intensive than LP")
    IO.puts("• The solution space is discrete, making optimization harder")
    IO.puts("• Integer solutions may be suboptimal compared to relaxed continuous solutions")
    IO.puts("• Solver automatically handles integer constraints - no special syntax needed")
    IO.puts("• Numerical precision: Values may be very close to integers (e.g., 2.0000001)")
    IO.puts("")

    IO.puts("✅ Integer programming problem solved successfully!")
    IO.puts("")

  {:error, reason} ->
    IO.puts("❌ Error solving problem: #{inspect(reason)}")
    System.halt(1)

  other ->
    IO.puts("❌ Unexpected result: #{inspect(other)}")
    System.halt(1)
end
