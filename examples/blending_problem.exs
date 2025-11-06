#!/usr/bin/env elixir

# Blending Problem Example
#
# BUSINESS CONTEXT:
# A food manufacturer needs to create a blended product (e.g., animal feed, fertilizer, or food mix)
# by combining multiple raw materials. Each material has different costs and quality properties.
# The goal is to minimize total cost while ensuring the final blend meets quality specifications
# and usage limits for each material.
#
# This is a classic blending optimization problem commonly found in agriculture, chemical processing,
# and manufacturing industries.
#
# MATHEMATICAL FORMULATION:
# Variables: fraction_m = fraction of material m in the final blend (0.1 ≤ fraction_m ≤ 0.8)
# Constraints:
#   Σ fraction_m = 1 (blend composition)
#   Σ (fraction_m × quality1_m) ≥ 0.75 (minimum quality1 requirement)
#   Σ (fraction_m × quality2_m) ≤ 0.25 (maximum quality2 requirement)
# Objective: Minimize Σ (fraction_m × cost_m)
#
# DSL SYNTAX HIGHLIGHTS:
# - Variable creation with bounds: variables(name, generators, type, min_bound: val, max_bound: val)
# - Sum expressions in constraints: sum(for m <- materials, do: expr)
# - Weighted sum constraints for quality requirements
# - Case expressions for conditional data access (until model parameters are implemented)
#
# GOTCHAS:
# - Variable names are auto-generated as "fraction_Material1", "fraction_Material2", etc.
# - Complex expressions require case statements when model parameters aren't available
# - Sum expressions require explicit comprehension: sum(for m <- materials, do: ...)
# - Bounds are enforced per variable, not globally
# - Model parameters feature is planned but not yet implemented

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
materials = ["Material1", "Material2", "Material3"]

# Cost per unit of each material
cost_per_unit = %{
  "Material1" => 5.0,
  "Material2" => 8.0,
  "Material3" => 6.0
}

# Quality properties of each material
# Quality1: Some property (e.g., protein content)
# Quality2: Another property (e.g., fat content)
quality_properties = %{
  "Material1" => %{quality1: 0.8, quality2: 0.2},
  "Material2" => %{quality1: 0.6, quality2: 0.4},
  "Material3" => %{quality1: 0.9, quality2: 0.1}
}

# Quality requirements for the final blend
# We need quality1 >= 0.75 and quality2 <= 0.25
min_quality1 = 0.75
max_quality2 = 0.25

# Minimum and maximum usage for each material (as percentages)
# 10% minimum
# 80% maximum

IO.puts("Blending Problem")
IO.puts("================")
IO.puts("Materials: #{Enum.join(materials, ", ")}")
IO.puts("")
IO.puts("Cost per unit:")

Enum.each(materials, fn material ->
  IO.puts("  #{material}: $#{cost_per_unit[material]}")
end)

IO.puts("")
IO.puts("Quality properties:")

Enum.each(materials, fn material ->
  props = quality_properties[material]
  IO.puts("  #{material}: Quality1=#{props.quality1}, Quality2=#{props.quality2}")
end)

IO.puts("")
IO.puts("Quality requirements:")
IO.puts("  Quality1 >= #{min_quality1}")
IO.puts("  Quality2 <= #{max_quality2}")
IO.puts("  Usage limits: 10.0% - 80.0% per material")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(
      name: "Blending Problem",
      description: "Minimize cost while meeting quality specifications and usage limits"
    )

    # Decision variables: fraction_m = fraction of material m in the blend
    variables("fraction_Material1", :continuous, "Fraction of Material1 in blend", min_bound: 0.1, max_bound: 0.8)
    variables("fraction_Material2", :continuous, "Fraction of Material2 in blend", min_bound: 0.1, max_bound: 0.8)
    variables("fraction_Material3", :continuous, "Fraction of Material3 in blend", min_bound: 0.1, max_bound: 0.8)

    # Constraint: fractions must sum to 1 (100% of blend)
    constraints(
      fraction_Material1 + fraction_Material2 + fraction_Material3 == 1,
      "Blend composition constraint"
    )

    # Quality constraints (hardcoded for now - model parameters not yet implemented)
    constraints(
    fraction_Material1 * 0.8 + fraction_Material2 * 0.6 + fraction_Material3 * 0.9 >= min_quality1,
    "Minimum quality1 requirement"
    )

    constraints(
    fraction_Material1 * 0.2 + fraction_Material2 * 0.4 + fraction_Material3 * 0.1 <= max_quality2,
    "Maximum quality2 requirement"
    )

    # Objective: minimize total cost
    objective(
    fraction_Material1 * 5.0 + fraction_Material2 * 8.0 + fraction_Material3 * 6.0,
    direction: :minimize
    )
  end

IO.puts("Solving the blending problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value (total cost): $#{Float.round(objective_value * 1.0, 2)}")
IO.puts("")

IO.puts("Optimal Blend Composition:")

# Display the blend composition
Enum.each(materials, fn material ->
var_name = "fraction_#{material}"
fraction = solution.variables[var_name]

material_cost = fraction * cost_per_unit[material]

IO.puts(
"  #{material}: #{Float.round(fraction * 100.0, 2)}% (cost contribution: $#{Float.round(material_cost, 2)})"
)
end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total cost: $#{Float.round(objective_value * 1.0, 2)}")
IO.puts("  Blend composition: 100% (all fractions sum to 1.0)")
IO.puts("  All quality and usage constraints satisfied")

# Validate that all constraints are satisfied
IO.puts("")
IO.puts("Constraint Validation:")

# Check blend composition (sum = 1)
total_fraction = solution.variables["fraction_Material1"] + solution.variables["fraction_Material2"] + solution.variables["fraction_Material3"]
blend_ok = abs(total_fraction - 1.0) < 0.001
IO.puts("  Blend composition (sum = 1.0): #{Float.round(total_fraction, 4)} #{if blend_ok, do: "✅", else: "❌"}")

# Check quality constraints
quality1_achieved = solution.variables["fraction_Material1"] * 0.8 + solution.variables["fraction_Material2"] * 0.6 + solution.variables["fraction_Material3"] * 0.9
quality2_achieved = solution.variables["fraction_Material1"] * 0.2 + solution.variables["fraction_Material2"] * 0.4 + solution.variables["fraction_Material3"] * 0.1

quality1_ok = quality1_achieved >= min_quality1 - 0.001
quality2_ok = quality2_achieved <= max_quality2 + 0.001

IO.puts("  Quality1 (≥ #{min_quality1}): #{Float.round(quality1_achieved, 4)} #{if quality1_ok, do: "✅", else: "❌"}")
IO.puts("  Quality2 (≤ #{max_quality2}): #{Float.round(quality2_achieved, 4)} #{if quality2_ok, do: "✅", else: "❌"}")

# Check fraction bounds (10% - 80%)
bounds_ok =
solution.variables["fraction_Material1"] >= 0.1 - 0.001 and solution.variables["fraction_Material1"] <= 0.8 + 0.001 and
solution.variables["fraction_Material2"] >= 0.1 - 0.001 and solution.variables["fraction_Material2"] <= 0.8 + 0.001 and
solution.variables["fraction_Material3"] >= 0.1 - 0.001 and solution.variables["fraction_Material3"] <= 0.8 + 0.001

IO.puts("  Fraction bounds (10%-80%): #{if bounds_ok, do: "✅ All OK", else: "❌ VIOLATED"}")

all_ok = blend_ok and quality1_ok and quality2_ok and bounds_ok

if not all_ok do
  IO.puts("ERROR: Some constraints violated!")
  System.halt(1)
end

# Display detailed quality breakdown
IO.puts("")
IO.puts("Quality Contribution by Material:")

Enum.each(materials, fn material ->
var_name = "fraction_#{material}"
fraction = solution.variables[var_name]
props = quality_properties[material]

quality1_contrib = fraction * props.quality1
quality2_contrib = fraction * props.quality2

IO.puts(
"  #{material}: Q1=#{Float.round(quality1_contrib * 1.0, 4)}, Q2=#{Float.round(quality2_contrib * 1.0, 4)}"
)
end)

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Blending problems optimize resource allocation with quality constraints")
IO.puts("• Linear programming handles weighted sums efficiently for quality calculations")
IO.puts("• Model parameters enable clean separation of data from optimization logic")
IO.puts("• Variable bounds prevent unrealistic solutions (e.g., 0% or 100% usage)")
IO.puts("• Sum comprehensions create complex constraints from simple expressions")
IO.puts("• Real-world applications: feed mixing, chemical blending, portfolio optimization")

IO.puts("")
IO.puts("✅ Blending problem solved successfully!")
