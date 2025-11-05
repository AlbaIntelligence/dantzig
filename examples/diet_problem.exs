# Diet Problem Example using DSL
# Minimize cost of food while meeting nutritional requirements

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== Diet Problem DSL Example ===")

# Food data
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

# Convert food names to use underscores for valid variable names
food_names = Enum.map(foods, & &1.name)
foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

# Nutritional limits
limits = [
  %{nutrient: "calories", min: 1800, max: 2200},
  %{nutrient: "protein", min: 91, max: :infinity},
  %{nutrient: "fat", min: 0, max: 65},
  %{nutrient: "sodium", min: 0, max: 1779}
]

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
      min: 0.0,
      max: :infinity,
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

{solution, objective} = Problem.solve(problem_diet)

IO.puts("\nProblem summary:")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\n=== Diet problem created with DSL! ===")
IO.puts("Note: This example demonstrates the DSL structure.")
IO.puts("Full constraint parsing with patterns is still being implemented.")
