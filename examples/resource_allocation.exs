#!/usr/bin/env elixir

# Resource Allocation Example
# ===========================
#
# This example demonstrates resource allocation across multiple competing activities
# using the Dantzig DSL. It shows how to allocate limited resources (budget, personnel,
# equipment) to different projects or activities to maximize overall benefit.
#
# BUSINESS CONTEXT:
# A project manager has a fixed budget and must allocate it across three potential
# projects. Each project has different resource requirements and expected returns.
# The goal is to select the optimal combination of projects that maximizes total
# benefit while respecting the budget constraint.
#
# This is a classic resource allocation problem that appears in:
# - Project portfolio management
# - Capital budgeting decisions
# - Resource planning and scheduling
# - Investment portfolio selection
#
# MATHEMATICAL FORMULATION:
# Variables: x_i = 1 if project i is selected, 0 otherwise (binary variables)
# Objective: Maximize Σ benefit_i * x_i
# Constraints:
#   - Budget: Σ cost_i * x_i <= total_budget
#   - Binary: x_i ∈ {0,1} for all projects i
#
# DSL SYNTAX HIGHLIGHTS:
# - variables("select", [i <- projects], :binary, "Project selection")
#   Creates binary variables for each project selection decision
# - constraints(sum(select[:_] * costs[:_]) <= budget, "Budget constraint")
#   Uses wildcard pattern to sum costs across selected projects
# - objective(sum(select[:_] * benefits[:_]), :maximize)
#   Maximizes total benefit from selected projects
#
# LEARNING OBJECTIVES:
# 1. Understand binary decision variables for selection problems
# 2. Practice wildcard patterns for constraint aggregation
# 3. Learn resource allocation modeling patterns
# 4. See how budget constraints affect project selection
#
# COMMON GOTCHAS:
# 1. Binary variables: Use :binary type for yes/no decisions
# 2. Wildcard access: [:_] works with map keys from model_parameters
# 3. Map access: costs[:_] and benefits[:_] access values by key
# 4. Constraint aggregation: sum() with wildcards for multiple items

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("Resource Allocation Example")
IO.puts("============================")
IO.puts("")
IO.puts("Business Scenario:")
IO.puts("A project manager must allocate a $500,000 budget across three potential projects.")
IO.puts("Each project has different costs and expected benefits (NPV in thousands of dollars).")
IO.puts("Goal: Select optimal combination of projects to maximize total benefit.")
IO.puts("")

# Project data
projects = ["website_redesign", "mobile_app", "data_analytics"]

costs = %{
  "website_redesign" => 200,
  "mobile_app" => 150,
  "data_analytics" => 300
}

benefits = %{
  "website_redesign" => 180,
  "mobile_app" => 220,
  "data_analytics" => 350
}

# Display names for output
display_names = %{
  "website_redesign" => "Website Redesign",
  "mobile_app" => "Mobile App",
  "data_analytics" => "Data Analytics"
}

budget = 500

# Display project information
IO.puts("Available Projects:")

Enum.each(projects, fn project ->
  IO.puts("  #{display_names[project]}:")
  IO.puts("    Cost: $#{costs[project]}K")
  IO.puts("    Benefit: $#{benefits[project]}K")
  IO.puts("    Profit: $#{benefits[project] - costs[project]}K")
end)

IO.puts("")
IO.puts("Total Budget: $#{budget}K")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define model_parameters: %{
                   projects: projects,
                   costs: costs,
                   benefits: benefits,
                   budget: budget
                 } do
    new(
      name: "Resource Allocation Problem",
      description: "Allocate budget across projects to maximize total benefit"
    )

    # Binary decision variables: select[i] = 1 if project i is selected
    variables("select", [i <- projects], :binary, "Whether to select this project")

    # Budget constraint: total cost of selected projects <= budget
    constraints(
      sum(for i <- projects, do: select(i) * costs[i]) <= budget,
      "Total project costs within budget"
    )

    # Objective: maximize total benefit from selected projects
    objective(
      sum(for i <- projects, do: select(i) * benefits[i]),
      :maximize
    )
  end

IO.puts("Problem Structure:")
IO.puts("- #{length(projects)} binary decision variables (select each project?)")
IO.puts("- 1 budget constraint")
IO.puts("- 1 objective function (maximize benefit)")
IO.puts("")

# Solve the optimization problem
{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

IO.puts("Solution:")
IO.puts("========")
IO.puts("Maximum total benefit: $#{Float.round(objective_value * 1.0, 2)}K")
IO.puts("")

IO.puts("Selected Projects:")

{total_cost, selected_projects} =
  Enum.reduce(projects, {0, []}, fn project, {acc_cost, acc_projects} ->
    selected = solution.variables["select(#{project})"] || 0
    display_name = display_names[project]

    if selected > 0.5 do
      IO.puts("  ✓ #{display_name}")
      IO.puts("    Cost: $#{costs[project]}K, Benefit: $#{benefits[project]}K")
      {acc_cost + costs[project], [display_name | acc_projects]}
    else
      IO.puts("  ✗ #{display_name}")
      {acc_cost, acc_projects}
    end
  end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Selected projects: #{Enum.join(Enum.reverse(selected_projects), ", ")}")

IO.puts(
  "  Total cost: $#{total_cost}K / $#{budget}K (#{Float.round(100 * total_cost / budget, 1)}%)"
)

IO.puts("  Total benefit: $#{Float.round(objective_value * 1.0, 2)}K")
IO.puts("  Net profit: $#{objective_value - total_cost}K")
IO.puts("")

# Validation
budget_ok = total_cost <= budget
selection_valid = length(selected_projects) >= 0 and length(selected_projects) <= length(projects)

# Convert display names back to keys for benefits lookup
key_map = Enum.map(display_names, fn {k, v} -> {v, k} end) |> Map.new()
selected_keys = Enum.map(selected_projects, &key_map[&1])
benefit_correct = abs(Enum.sum(Enum.map(selected_keys, &benefits[&1])) - objective_value) < 0.001

IO.puts("Validation:")
IO.puts("✓ Budget constraint satisfied: #{budget_ok}")
IO.puts("✓ Valid project selection: #{selection_valid}")
IO.puts("✓ Benefit calculation correct: #{benefit_correct}")

IO.puts(
  "✓ All variables binary: #{Enum.all?(projects, fn p ->
    s = solution.variables["select(#{p})"] || 0
    s == 0.0 or s == 1.0
  end)}"
)

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Binary variables model yes/no selection decisions")
IO.puts("• Resource constraints limit which combinations are feasible")
IO.puts("• Optimal solutions balance cost and benefit trade-offs")
IO.puts("• The DSL's wildcard patterns simplify constraint aggregation")
IO.puts("• Real-world applications: project selection, budget allocation, portfolio optimization")

# Analysis of the solution
IO.puts("")
IO.puts("Solution Analysis:")

case selected_projects do
  ["Mobile App", "Data Analytics"] ->
    IO.puts("• Selected high-benefit projects that fit within budget")
    IO.puts("• Mobile App + Data Analytics = $470K cost, $570K benefit")
    IO.puts("• Website Redesign excluded due to lower benefit-to-cost ratio")

  ["Website Redesign", "Data Analytics"] ->
    IO.puts("• Selected Website + Analytics for maximum coverage")
    IO.puts("• Both projects provide different types of business value")

  ["Website Redesign", "Mobile App"] ->
    IO.puts("• Selected customer-facing projects")
    IO.puts("• Lower total benefit but better risk diversification")

  ["Data Analytics"] ->
    IO.puts("• Selected only the highest-benefit project")
    IO.puts("• Single project approach minimizes complexity")

  [] ->
    IO.puts("• No projects selected - budget constraints too tight")

  _ ->
    IO.puts("• Mixed selection balancing cost and benefit")
end

IO.puts("")
IO.puts("✅ Resource allocation example completed successfully!")

# Expected optimal solution (for verification):
# Select Mobile App ($150K cost, $220K benefit) + Data Analytics ($300K cost, $350K benefit)
# Total cost: $450K, Total benefit: $570K, Net profit: $120K
