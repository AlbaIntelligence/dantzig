#!/usr/bin/env elixir

# Minimax Scheduling Problem Example
# =================================
#
# This example demonstrates the Minimax Scheduling Problem using the Dantzig DSL.
# Minimax scheduling is a classic optimization problem where we minimize the maximum
# completion time (makespan) across multiple jobs or tasks.
#
# BUSINESS CONTEXT:
# A manufacturing facility needs to schedule multiple jobs on machines to minimize
# the time until all jobs are complete. This is critical for meeting deadlines,
# optimizing resource utilization, and ensuring timely delivery to customers.
#
# Real-world applications:
# - Job shop scheduling (minimize makespan)
# - Project management (minimize project duration)
# - Resource allocation with fairness (minimize worst-case completion time)
# - Production line balancing
# - Task scheduling in distributed systems
# - Cloud computing workload distribution
#
# MATHEMATICAL FORMULATION:
# Variables:
#   - start[j] = start time of job j (continuous, >= 0)
#   - makespan = maximum completion time across all jobs (continuous, >= 0)
# Parameters:
#   - processing_time[j] = time required to complete job j
#   - J = set of jobs
#
# Constraints:
#   - Completion time: completion[j] = start[j] + processing_time[j] for all jobs j
#   - Makespan definition: makespan >= completion[j] for all jobs j
#   - Non-negativity: start[j] >= 0 for all jobs j
#
# Objective: Minimize makespan
#
# This problem demonstrates the automatic linearization of the max() function:
# - The constraint "makespan >= completion[j] for all j" ensures makespan is at least
#   the maximum of all completion times
# - Minimizing makespan then finds the minimum possible maximum completion time
#
# DSL SYNTAX EXPLANATION:
# - Continuous variables for start times and makespan
# - Generator-based constraints to define makespan >= each completion time
# - max() function in objective: minimize max(completion[j] for all j)
# - Automatic linearization: max() creates auxiliary variable + constraints
#
# KEY LEARNING POINTS:
# - max() function automatically linearized by DSL
# - Minimax optimization (minimize the maximum) is a common pattern
# - Makespan minimization is fundamental to scheduling theory
#
# COMMON GOTCHAS:
# - Remember that max() creates an auxiliary variable automatically
# - The makespan variable must be >= all completion times
# - Minimizing makespan naturally finds the minimum maximum value
#
# ============================================================================

require Dantzig.Problem, as: Problem

# ============================================================================
# PROBLEM DATA
# ============================================================================

# Jobs with their processing times (in hours)
jobs_data = %{
  "Job_A" => %{processing_time: 8.0, description: "Assembly task"},
  "Job_B" => %{processing_time: 6.0, description: "Quality inspection"},
  "Job_C" => %{processing_time: 10.0, description: "Packaging"},
  "Job_D" => %{processing_time: 7.0, description: "Shipping prep"},
  "Job_E" => %{processing_time: 9.0, description: "Documentation"}
}

job_names = Map.keys(jobs_data)

IO.puts("=" <> String.duplicate("=", 78))
IO.puts("MINIMAX SCHEDULING PROBLEM")
IO.puts("=" <> String.duplicate("=", 78))
IO.puts("")
IO.puts("Problem: Schedule #{length(job_names)} jobs to minimize maximum completion time")
IO.puts("")
IO.puts("Job Processing Times:")
Enum.each(jobs_data, fn {job, data} ->
  IO.puts("  • #{job}: #{data.processing_time} hours (#{data.description})")
end)
IO.puts("")
IO.puts("Objective: Minimize makespan = max(completion_time[j] for all jobs j)")
IO.puts("")
IO.puts("This demonstrates the max() function with automatic linearization.")
IO.puts("")

# ============================================================================
# PROBLEM DEFINITION
# ============================================================================

problem =
  Problem.define model_parameters: %{
                   jobs: jobs_data,
                   job_names: job_names
                 } do
    new(name: "Minimax Scheduling", direction: :minimize)

    # Decision variables: start time for each job
    variables(
      "start",
      [job <- job_names],
      :continuous,
      min_bound: 0.0,
      description: "Start time of each job"
    )

    # Makespan variable: maximum completion time across all jobs
    # This will be automatically created by the max() function in the objective
    # But we can also define it explicitly for clarity
    variables("makespan", :continuous, "Maximum completion time (makespan)", min_bound: 0.0)

    # Constraints: Makespan must be >= completion time of each job
    # Completion time = start time + processing time
    # Note: We use jobs[job].processing_time (dot notation) for cleaner access
    constraints(
      [job <- job_names],
      makespan >= start(job) + jobs[job].processing_time,
      "Makespan must be at least completion time of #{job}"
    )

    # Objective: Minimize the maximum completion time (makespan)
    # This is equivalent to: minimize max(start(j) + processing_time[j] for all j)
    # The DSL automatically linearizes max() by creating the makespan variable
    # and the constraints above ensure makespan >= each completion time
    objective(makespan, :minimize)
  end

# ============================================================================
# SOLVE THE PROBLEM
# ============================================================================

IO.puts("Solving the minimax scheduling problem...")
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
    IO.puts("Minimum Makespan: #{Float.round(objective_value * 1.0, 2)} hours")
    IO.puts("")

    # Display schedule
    IO.puts("Job Schedule:")
    IO.puts(String.duplicate("-", 79))

    schedule_data =
      Enum.map(job_names, fn job ->
        start_time = solution.variables["start(#{job})"] || 0.0
        processing_time = jobs_data[job].processing_time
        completion_time = start_time + processing_time

        %{
          job: job,
          start: start_time,
          processing: processing_time,
          completion: completion_time
        }
      end)
      |> Enum.sort_by(& &1.start)

    Enum.each(schedule_data, fn %{job: job, start: start, processing: processing, completion: completion} ->
      IO.puts(
        "  #{String.pad_trailing(job, 12)} | Start: #{String.pad_leading(Float.to_string(Float.round(start * 1.0, 2)), 6)}h | " <>
          "Duration: #{String.pad_leading(Float.to_string(Float.round(processing * 1.0, 2)), 5)}h | " <>
          "Completion: #{String.pad_leading(Float.to_string(Float.round(completion * 1.0, 2)), 6)}h"
      )
    end)

    IO.puts("")
    IO.puts(String.duplicate("-", 79))

    # Verify makespan
    max_completion =
      Enum.reduce(schedule_data, 0.0, fn %{completion: completion}, acc ->
        max(acc, completion)
      end)

    makespan_value = solution.variables["makespan"] || 0.0

    IO.puts("")
    IO.puts("Makespan Verification:")
    IO.puts("  • Maximum completion time: #{Float.round(max_completion * 1.0, 2)} hours")
    IO.puts("  • Makespan variable value: #{Float.round(makespan_value * 1.0, 2)} hours")
    IO.puts("  • Objective value: #{Float.round(objective_value * 1.0, 2)} hours")
    IO.puts("  • Values match: #{abs(max_completion - objective_value) < 0.01}")

    # Gantt chart visualization (text-based)
    IO.puts("")
    IO.puts("Schedule Visualization (Gantt Chart):")
    IO.puts(String.duplicate("=", 79))

    max_time = max_completion
    scale = 60.0 / max_time # Scale to 60 characters

    Enum.each(schedule_data, fn %{job: job, start: start, processing: processing} ->
      start_pos = round(start * scale)
      duration_pos = round(processing * scale)

      bar = String.duplicate("█", max(1, duration_pos))
      padding = String.duplicate(" ", start_pos)

      IO.puts("#{String.pad_trailing(job, 12)} |#{padding}#{bar}")
    end)

    IO.puts(String.duplicate("=", 79))
    IO.puts("Time scale: 0" <> String.duplicate(" ", 58) <> "#{Float.round(max_time * 1.0, 1)}h")
    IO.puts("")

    # Validation
    IO.puts("Validation:")
    IO.puts(String.duplicate("-", 79))

    validations = [
      {"All jobs scheduled", Enum.all?(schedule_data, &(&1.start >= 0))},
      {"Makespan >= all completions",
       Enum.all?(schedule_data, fn %{completion: completion} ->
         makespan_value >= completion - 0.01
       end)},
      {"Makespan equals max completion", abs(max_completion - makespan_value) < 0.01},
      {"Objective equals makespan", abs(objective_value - makespan_value) < 0.01}
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
    IO.puts("• Minimax optimization minimizes the maximum value across a set")
    IO.puts("• The max() function is automatically linearized by the DSL:")
    IO.puts("  - Creates auxiliary variable (makespan)")
    IO.puts("  - Adds constraints: makespan >= each completion time")
    IO.puts("  - Minimizing makespan finds the minimum maximum")
    IO.puts("• Makespan minimization is fundamental to scheduling theory")
    IO.puts("• This pattern applies to many optimization problems:")
    IO.puts("  - Load balancing (minimize max server load)")
    IO.puts("  - Facility location (minimize max distance)")
    IO.puts("  - Resource allocation (minimize max utilization)")
    IO.puts("  - Fairness optimization (minimize max disadvantage)")
    IO.puts("")

    IO.puts("✅ Minimax scheduling problem solved successfully!")
    IO.puts("")

  {:error, reason} ->
    IO.puts("❌ Error solving problem: #{inspect(reason)}")
    System.halt(1)

  other ->
    IO.puts("❌ Unexpected result: #{inspect(other)}")
    System.halt(1)
end
