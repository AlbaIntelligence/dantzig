# Diet Problem Example
# =====================
#
# This example demonstrates the classic Diet Problem using the Dantzig DSL.
# The diet problem is fundamental to resource allocation and nutritional optimization,
# with applications in meal planning, food production, and cost optimization.
#
# BUSINESS CONTEXT:
# A nutritionist needs to create a meal plan that meets daily nutritional
# requirements while minimizing cost. This is a classic linear programming
# problem that demonstrates constraint modeling and cost optimization.
#
# Real-world applications:
# - Hospital meal planning with dietary restrictions
# - Military rations optimization
# - Sports nutrition planning
# - Budget-conscious meal planning
# - Food aid distribution
#
# MATHEMATICAL FORMULATION:
# Variables: x[f] = amount of food f to include in diet
# Parameters:
#   - cost[f] = cost per unit of food f
#   - nutrient[f,n] = amount of nutrient n in food f
#   - min_req[n] = minimum required amount of nutrient n
#   - max_req[n] = maximum allowed amount of nutrient n
#
# Constraints:
#   - Nutritional minimum: Σf nutrient[f,n] * x[f] >= min_req[n] for all nutrients n
#   - Nutritional maximum: Σf nutrient[f,n] * x[f] <= max_req[n] for all nutrients n
#   - Non-negativity: x[f] >= 0 for all foods f
#
# Objective: Minimize total cost: minimize Σf cost[f] * x[f]
#
# DSL SYNTAX EXPLANATION:
# - variables("qty", [food <- food_names], :continuous, min_bound: 0.0, max_bound: :infinity)
#   Creates continuous variables for each food with non-negativity constraints
# - constraints([limit <- limits_names], sum(...) <= limits_dict[limit].max)
#   Uses pattern-based constraints to enforce nutritional limits
# - sum(for food <- food_names, do: qty(food) * foods_dict[food][limit])
#   Weighted sum expressions to calculate total nutrients
#
# COMMON GOTCHAS:
# 1. **Food Names**: Convert food names to use underscores for valid variable names
# 2. **Dictionary Access**: Use foods_dict[food][limit] for nested map access
# 3. **Nutritional Limits**: Handle :infinity for unbounded nutrients (like protein minimum)
# 4. **Variable Bounds**: :continuous variables default to non-negative (min_bound: 0.0)
# 5. **Model Parameters**: Data must be passed via model_parameters for DSL access
# 6. **Weighted Sums**: Multiplication of variables by constants in sum expressions
# 7. **Dictionary Lookup**: Ensure all foods have entries for all nutritional limits

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Diet Problem DSL Example ===")
IO.puts("Creating a cost-optimal meal plan that meets nutritional requirements")
IO.puts("")

# Display problem setup
IO.puts("Problem Setup:")
IO.puts("==============")

# Food data with nutritional information and costs
foods = [
  %{name: "hamburger", cost: 2.49, calories: 410, protein: 24, fat: 26, sodium: 730},
  %{name: "chicken", cost: 2.89, calories: 420, protein: 32, fat: 10, sodium: 1190},
  %{name: "hot dog", cost: 1.50, calories: 560, protein: 20, fat: 32, sodium: 1800},
  %{name: "fries", cost: 1.89, calories: 380, protein: 4, fat: 19, sodium: 270},
  %{name: "macaroni", cost: 2.09, calories: 320, protein: 12, fat: 10, sodium: 930},
  %{name: "pizza", cost: 1.99, calories: 320, protein: 15, fat: 12, sodium: 820},
  %{name: "salad", cost: 2.49, calories: 320, protein: 31, fat: 12, sodium: 1230},
  %{name: "milk", cost: 0.89, calories: 100, protein: 8, fat: 2.5, sodium: 125},
  %{name: "ice cream", cost: 1.59, calories: 330, protein: 8, fat: 10, sodium: 180}
]

# Display food information
IO.puts("Available Foods:")

Enum.each(foods, fn food ->
  IO.puts("  #{food.name}: $#{food.cost}/unit")

  IO.puts(
    "    Nutrition: #{food.calories} cal, #{food.protein}g protein, #{food.fat}g fat, #{food.sodium}mg sodium"
  )
end)

# Convert food names to use underscores for valid variable names
food_names = Enum.map(foods, & &1.name)
foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

# Nutritional requirements
limits = [
  %{nutrient: "calories", min_bound: 1800, max_bound: 2200},
  %{nutrient: "protein", min_bound: 91, max_bound: :infinity},
  %{nutrient: "fat", min_bound: 0, max_bound: 65},
  %{nutrient: "sodium", min_bound: 0, max_bound: 1779}
]

# Display nutritional requirements
IO.puts("")
IO.puts("Daily Nutritional Requirements:")

Enum.each(limits, fn limit ->
  max_str = if limit.max == :infinity, do: "unlimited", else: "#{limit.max}"
  IO.puts("  #{limit.nutrient}: #{limit.min} - #{max_str}")
end)

limits_names = Enum.map(limits, & &1.nutrient)
limits_dict = for limit_entry <- limits, into: %{}, do: {limit_entry.nutrient, limit_entry}

# Create the problem
problem_diet =
  Problem.define model_parameters: %{
                   foods_dict: foods_dict,
                   limits_dict: limits_dict,
                   food_names: food_names,
                   limits_names: limits_names
                 } do
    new(
      name: "Diet Problem",
      description: "Minimize cost of food while meeting nutritional requirements"
    )

    variables(
      "qty",
      [food <- food_names],
      :continuous,
      min_bound: 0.0,
      max_bound: :infinity,
      description: "Amount of food to buy"
    )

    # Nutritional constraints
    constraints(
      [limit <- limits_names],
      sum(for food <- food_names, do: qty(food) * foods_dict[food][limit]) <=
        limits_dict[limit].max,
      "Max #{limit}"
    )

    objective(
      sum(for food <- food_names, do: qty(food) * foods_dict[food].cost),
      direction: :minimize
    )
  end

# Solve the optimization problem
IO.puts("\nSolving the diet optimization problem...")
result = Problem.solve(problem_diet, print_optimizer_input: false)

case result do
  {solution, objective_value} ->
    IO.puts("\nSolution:")
    IO.puts("=========")

    objective_value =
      if is_integer(objective_value), do: objective_value * 1.0, else: objective_value

    IO.puts("Minimum daily cost: $#{Float.round(objective_value, 2)}")
    IO.puts("")

    IO.puts("Optimal Food Selection:")
    total_cost = 0

    total_nutrients = %{
      calories: 0,
      protein: 0,
      fat: 0,
      sodium: 0
    }

    Enum.each(foods, fn food ->
      # Try multiple possible variable name formats
      var_name1 = "qty_#{food.name}"
      var_name2 = "qty(#{food.name})"
      quantity = solution.variables[var_name1] || solution.variables[var_name2] || 0

      if quantity > 0.001 do
        food_cost = quantity * food.cost
        total_cost = total_cost + food_cost

        # Accumulate nutritional totals
        total_nutrients =
          Map.update!(total_nutrients, :calories, &(&1 + quantity * food.calories))

        total_nutrients = Map.update!(total_nutrients, :protein, &(&1 + quantity * food.protein))
        total_nutrients = Map.update!(total_nutrients, :fat, &(&1 + quantity * food.fat))
        total_nutrients = Map.update!(total_nutrients, :sodium, &(&1 + quantity * food.sodium))

        IO.puts(
          "  #{food.name}: #{Float.round(quantity, 2)} units (cost: $#{Float.round(food_cost, 2)})"
        )
      end
    end)

    IO.puts("")
    IO.puts("Nutritional Analysis:")
    IO.puts("  Total calories: #{Float.round(total_nutrients.calories, 0)}")
    IO.puts("  Total protein: #{Float.round(total_nutrients.protein, 1)}g")
    IO.puts("  Total fat: #{Float.round(total_nutrients.fat, 1)}g")
    IO.puts("  Total sodium: #{Float.round(total_nutrients.sodium, 0)}mg")

    IO.puts("")
    IO.puts("Validation:")

    all_constraints_satisfied =
      Enum.all?(limits, fn limit ->
        current_amount = total_nutrients[String.to_atom(limit.nutrient)]

        case limit.max do
          :infinity -> current_amount >= limit.min
          max -> current_amount >= limit.min and current_amount <= max
        end
      end)

    if all_constraints_satisfied do
      IO.puts("  ✅ All nutritional requirements satisfied")
    else
      IO.puts("  ❌ Some nutritional requirements violated")
    end

    IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")

    IO.puts("")
    IO.puts("LEARNING INSIGHTS:")
    IO.puts("==================")
    IO.puts("• Diet problems optimize resource allocation under nutritional constraints")
    IO.puts("• Linear programming naturally handles weighted sum constraints for nutrition")
    IO.puts("• Model parameters enable clean separation of data from optimization logic")
    IO.puts("• Continuous variables naturally model fractional food quantities")
    IO.puts("• Real-world applications: meal planning, food aid, dietary optimization")
    IO.puts("• The DSL demonstrates pattern-based constraint generation for multiple nutrients")

    IO.puts("")
    IO.puts("✅ Diet problem solved successfully!")

  :error ->
    IO.puts("ERROR: Diet problem could not be solved.")
    IO.puts("This may be due to infeasible nutritional requirements.")
    IO.puts("Try adjusting the nutritional limits to ensure they can be satisfied.")
end
