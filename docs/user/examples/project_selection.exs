#!/usr/bin/env elixir

# Project Selection Example
# =========================
#
# This example demonstrates binary decision-making for project selection with
# dependencies using the Dantzig DSL. It shows how to model complex decision
# problems where projects have costs, benefits, and interdependencies.
#
# BUSINESS CONTEXT:
# A company has a portfolio of potential projects with different costs, benefits,
# and dependencies. Some projects can only be undertaken if other projects are
# completed first. The goal is to select the optimal set of projects that
# maximizes total benefit while respecting budget constraints and dependencies.
#
# This is a classic project portfolio management problem that appears in:
# - Capital budgeting and project prioritization
# - Software development project planning
# - Research and development portfolio management
# - Infrastructure development planning
# - Strategic initiative selection
#
# MATHEMATICAL FORMULATION:
# Variables: x_i = 1 if project i is selected, 0 otherwise (binary variables)
# Parameters:
#   - cost[i] = cost of project i
#   - benefit[i] = benefit from project i
#   - dependencies[i] = list of projects that must be completed before project i
#   - budget = total available budget
#
# Constraints:
#   - Budget: Σ cost[i] * x[i] <= budget
#   - Dependencies: x[i] <= x[j] for all j in dependencies[i] (if i selected, dependencies must be selected)
#   - Binary: x[i] ∈ {0,1} for all projects i
#
# Objective: Maximize total benefit: maximize Σ benefit[i] * x[i]
#
# DSL SYNTAX HIGHLIGHTS:
# - variables("select", [project <- projects], :binary, "Project selection")
#   Creates binary variables for each project selection decision
# - constraints([dependency <- dependencies], select(project) <= select(dependency), "Dependency constraint")
#   Ensures dependencies are satisfied when a project is selected
# - sum(for project <- projects, do: select(project) * costs[project]) <= budget
#   Budget constraint using explicit comprehensions
# - objective(sum(for project <- projects, do: select(project) * benefits[project]), :maximize)
#   Maximizes total benefit from selected projects
#
# COMMON GOTCHAS:
# 1. **Binary Variables**: Use :binary type for yes/no decisions
# 2. **Dependency Modeling**: x[i] <= x[j] ensures if i is selected, j must also be selected
# 3. **Budget Constraints**: Sum of selected project costs cannot exceed budget
# 4. **Cyclic Dependencies**: Ensure no circular dependencies in project relationships
# 5. **Display Names**: Use display names for user-friendly output while using internal IDs for variables

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("Project Selection Example")
IO.puts("============================")
IO.puts("")
IO.puts("Business Scenario:")
IO.puts("A company must select which projects to undertake from a portfolio of options.")
IO.puts("Each project has costs, benefits, and may depend on other projects being completed.")

IO.puts(
  "Goal: Select projects to maximize total benefit while respecting budget and dependencies."
)

IO.puts("")

# Project data with dependencies
projects_data = %{
  "website" => %{
    name: "website",
    cost: 150,
    benefit: 180,
    dependencies: []
  },
  "mobile_app" => %{
    name: "mobile_app",
    cost: 200,
    benefit: 280,
    dependencies: ["website"]
  },
  "api" => %{
    name: "api",
    cost: 100,
    benefit: 120,
    dependencies: ["website"]
  },
  "database_upgrade" => %{
    name: "database_upgrade",
    cost: 80,
    benefit: 90,
    dependencies: []
  },
  "data_analytics" => %{
    name: "data_analytics",
    cost: 250,
    benefit: 400,
    dependencies: ["database_upgrade", "api"]
  },
  "ml_insights" => %{
    name: "ml_insights",
    cost: 300,
    benefit: 500,
    dependencies: ["data_analytics"]
  }
}

# Extract project information
projects = Map.keys(projects_data)
num_projects = length(projects)

# Display project information
IO.puts("Available Projects:")

Enum.each(projects, fn project ->
  data = projects_data[project]

  dep_str =
    if Enum.empty?(data.dependencies), do: "None", else: Enum.join(data.dependencies, ", ")

  IO.puts("  #{data.name}:")
  IO.puts("    Cost: $#{data.cost}K")
  IO.puts("    Benefit: $#{data.benefit}K")
  IO.puts("    ROI: #{Float.round((data.benefit - data.cost) * 100.0 / data.cost, 1)}%")
  IO.puts("    Dependencies: #{dep_str}")
end)

IO.puts("")

# Total potential investment
total_cost =
  Enum.reduce(projects, 0, fn project, acc ->
    acc + projects_data[project].cost
  end)

total_benefit =
  Enum.reduce(projects, 0, fn project, acc ->
    acc + projects_data[project].benefit
  end)

IO.puts("Portfolio Summary:")
IO.puts("  Total projects: #{num_projects}")
IO.puts("  Total cost if all projects: $#{total_cost}K")
IO.puts("  Total benefit if all projects: $#{total_benefit}K")
IO.puts("  Total potential net benefit: $#{total_benefit - total_cost}K")
IO.puts("")

# Test a specific budget scenario
budget = 600

IO.puts("=" <> String.duplicate("=", 60))
IO.puts("SOLVING FOR BUDGET: $#{budget}K")
IO.puts("=" <> String.duplicate("=", 60))

problem =
  Problem.define model_parameters: %{
                   projects: projects,
                   projects_data: projects_data,
                   budget: budget
                 } do
    new(
      name: "Project Selection Problem",
      description: "Select projects to maximize benefit within budget and dependencies"
    )

    # Binary decision variables: select[i] = 1 if project i is selected
    variables("select", [project <- projects], :binary, "Whether to select this project")

    # Budget constraint: total cost of selected projects <= budget
    constraints(
      sum(for project <- projects, do: select(project) * projects_data[project].cost) <= budget,
      "Total project costs within budget"
    )

    # Explicit dependency constraints
    # mobile_app requires website
    constraints(
      select("mobile_app") <= select("website"),
      "mobile_app requires website"
    )

    # api requires website
    constraints(
      select("api") <= select("website"),
      "api requires website"
    )

    # data_analytics requires database_upgrade and api
    constraints(
      select("data_analytics") <= select("database_upgrade"),
      "data_analytics requires database_upgrade"
    )

    constraints(
      select("data_analytics") <= select("api"),
      "data_analytics requires api"
    )

    # ml_insights requires data_analytics
    constraints(
      select("ml_insights") <= select("data_analytics"),
      "ml_insights requires data_analytics"
    )

    # Objective: maximize total benefit from selected projects
    objective(
      sum(for project <- projects, do: select(project) * projects_data[project].benefit),
      :maximize
    )
  end

# Solve the optimization problem
{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

# Process and display results
if solution.model_status == "Optimal" do
  IO.puts("\n✅ Optimal solution found!")
  IO.puts("Maximum total benefit: $#{Float.round(objective_value * 1.0, 2)}K")
  IO.puts("")

  # Calculate actual costs and benefits
  {total_actual_cost, selected_projects} =
    Enum.reduce(projects, {0, []}, fn project, {acc_cost, acc_projects} ->
      selected = solution.variables["select(#{project})"] || 0
      data = projects_data[project]

      if selected > 0.5 do
        {acc_cost + data.cost, [project | acc_projects]}
      else
        {acc_cost, acc_projects}
      end
    end)

  actual_benefit = objective_value * 1.0
  net_benefit = actual_benefit - total_actual_cost

  IO.puts("Selected Projects:")

  Enum.each(selected_projects, fn project ->
    data = projects_data[project]
    IO.puts("  ✓ #{data.name}: $#{data.cost}K cost, $#{data.benefit}K benefit")
  end)

  IO.puts("")
  IO.puts("Financial Summary:")
  IO.puts("  Total cost: $#{total_actual_cost}K / $#{budget}K")
  IO.puts("  Total benefit: $#{Float.round(actual_benefit, 2)}K")
  IO.puts("  Net benefit: $#{Float.round(net_benefit, 2)}K")
  IO.puts("  Budget utilization: #{Float.round(100.0 * total_actual_cost / budget, 1)}%")

  # Validation
  budget_ok = total_actual_cost <= budget

  # Simple dependency check inline
  dependencies_satisfied =
    Enum.all?(selected_projects, fn project ->
      project_data = projects_data[project]
      Enum.all?(project_data.dependencies, fn dep -> dep in selected_projects end)
    end)

  binary_variables_ok =
    Enum.all?(projects, fn p ->
      s = solution.variables["select(#{p})"] || 0
      s == 0.0 or s == 1.0
    end)

  IO.puts("")
  IO.puts("Validation:")
  IO.puts("  ✓ Budget constraint satisfied: #{budget_ok}")
  IO.puts("  ✓ All dependencies satisfied: #{dependencies_satisfied}")
  IO.puts("  ✓ All variables binary: #{binary_variables_ok}")

  # Analysis
  if length(selected_projects) > 0 do
    IO.puts("")
    IO.puts("Analysis:")

    cond do
      "ml_insights" in selected_projects ->
        IO.puts("  • Full data science stack selected")
        IO.puts("  • This represents a complete digital transformation initiative")
        IO.puts("  • High investment with long-term strategic value")

      "data_analytics" in selected_projects ->
        IO.puts("  • Analytics capabilities selected (often including foundational components)")
        IO.puts("  • Balanced approach between cost and analytical capability")

      length(selected_projects) <= 2 ->
        IO.puts("  • Conservative selection focusing on highest-ROI projects")
        IO.puts("  • Lower risk approach with immediate benefits")

      true ->
        IO.puts("  • Diversified project portfolio")
        IO.puts("  • Balanced investment across different capability areas")
    end
  else
    IO.puts("")
    IO.puts("Analysis:")
    IO.puts("  • No projects selected - budget too constrained for any viable combination")
    IO.puts("  • Consider increasing budget or reducing project costs")
  end
else
  IO.puts("\n❌ Solution status: #{solution.model_status}")

  case solution.model_status do
    "Infeasible" ->
      IO.puts("The problem is infeasible. This may indicate:")
      IO.puts("  - Budget too low for any feasible project combination")
      IO.puts("  - Cyclic dependencies creating impossible constraints")
      IO.puts("  - Parameter inconsistencies")

    "Unbounded" ->
      IO.puts("The problem is unbounded. This should not happen with binary variables.")

    _ ->
      IO.puts("Unexpected solution status: #{solution.model_status}")
  end
end

IO.puts("")
IO.puts("=" <> String.duplicate("=", 60))
IO.puts("SUMMARY: PROJECT SELECTION INSIGHTS")
IO.puts("=" <> String.duplicate("=", 60))
IO.puts("")
IO.puts("Key Learnings:")
IO.puts("• Binary variables effectively model yes/no project selection decisions")
IO.puts("• Dependency constraints ensure logical project ordering")
IO.puts("• Budget constraints force trade-offs between project alternatives")
IO.puts("• Portfolio optimization reveals optimal combinations of projects")
IO.puts("• Complex dependencies require careful constraint modeling")
IO.puts("")
IO.puts("Practical Applications:")
IO.puts("• Strategic planning and capital budgeting")
IO.puts("• Technology roadmap planning")
IO.puts("• R&D portfolio management")
IO.puts("• Infrastructure investment decisions")
IO.puts("• Software development project prioritization")
IO.puts("")
IO.puts("Real-World Considerations:")
IO.puts("• Projects may have time dependencies (phased implementation)")
IO.puts("• Benefits may be realized at different time horizons")
IO.puts("• Risk assessment and project failure probabilities")
IO.puts("• Resource constraints beyond just budget (personnel, equipment)")
IO.puts("• Strategic vs. tactical project selection criteria")
IO.puts("")

IO.puts("✅ Project selection example completed successfully!")

# Expected optimal solution for $600K budget:
# Should select: website, database_upgrade, api, data_analytics
# Total cost: $580K, Total benefit: $790K, Net benefit: $210K
