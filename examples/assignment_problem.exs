#!/usr/bin/env elixir

# Assignment Problem Example
#
# Problem: Assign workers to tasks optimally. We have 3 workers and 3 tasks
# with a cost matrix showing the cost of assigning each worker to each task.
# Each worker must be assigned to exactly one task, and each task must be
# assigned to exactly one worker. The goal is to minimize total assignment cost.
#
# This is a classic assignment problem that can be solved using binary variables
# and constraints to ensure proper assignment.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
# Cost matrix: cost[worker][task] = cost of assigning worker to task
cost_matrix = %{
  "Alice" => %{"Task1" => 2, "Task2" => 3, "Task3" => 1},
  "Bob" => %{"Task1" => 4, "Task2" => 2, "Task3" => 3},
  "Charlie" => %{"Task1" => 3, "Task2" => 1, "Task3" => 4}
}

workers = Enum.keys(cost_matrix)
# Tasks is the set of all possible tasks across all workers
tasks =
  MapSet.new(cost_matrix, fn {k, v} -> Enum.key(v) end)

IO.puts("==================")
IO.puts("Workers: #{Enum.join(workers, ", ")}")
IO.puts("Tasks: #{Enum.join(tasks, ", ")}")
IO.puts("")
IO.puts("Cost Matrix:")

Enum.each(workers, fn worker ->
  costs = Enum.map(tasks, fn task -> "#{task}:#{cost_matrix[worker][task]}" end)
  IO.puts("  #{worker}: #{Enum.join(costs, ", ")}")
end)

IO.puts("")

# Create the optimization problem with simplified costs (1 unit per task)
problem =
  Problem.define model_parameters: [workers, tasks, cost_matrix] do
    new(
      name: "Assignment Problem",
      description: "Assign workers to tasks to minimize total cost"
    )

    # Binary variables: assign[w,t] = 1 if worker w is assigned to task t, 0 otherwise
    variables(
      "assign",
      [w <- workers, t <- tasks],
      :binary,
      "Whether worker is assigned to task"
    )

    # Constraint: each worker is assigned to exactly one task
    constraints(
      [w <- workers],
      sum(assign(w, :_)) == 1,
      "Each worker assigned to exactly one task"
    )

    # Constraint: each task is assigned to exactly one worker
    constraints(
      [t <- tasks],
      sum(assign(:_, t)) == 1,
      "Each task assigned to exactly one worker"
    )

    # Objective: minimize total assignment cost (simplified for now)
    # We'll calculate the actual cost from the solution
    objective(
      # Just maximize number of assignments for now
      sum(assign(:_, :_)),
      direction: :minimize
    )
  end

# Helper function to calculate the overall cost:
calculate_total_cost = fn solution, workers, tasks, cost_matrix ->
  {total_cost, _} =
    Enum.reduce(workers, {0, []}, fn worker, {acc_cost, _} ->
      worker_assignments =
        Enum.reduce(tasks, {[], 0}, fn task, {task_list, task_cost} ->
          var_name = "assign_#{worker}_#{task}"
          assigned = solution.variables[var_name]

          if assigned > 0.5 do
            cost = cost_matrix[worker][task]
            {[{worker, task, cost} | task_list], task_cost + cost}
          else
            {task_list, task_cost}
          end
        end)

      # Display assignments for this worker
      Enum.each(elem(worker_assignments, 0), fn {w, t, c} ->
        IO.puts("  #{w} → #{t} (cost: #{c})")
      end)

      {acc_cost + elem(worker_assignments, 1), []}
    end)

  total_cost
end

IO.puts("Solving the simplified assignment problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value (1 unit per assignment): #{objective_value}")
IO.puts("")
IO.puts("Assignments:")
IO.puts("")

total_cost = calculate_total_cost.(solution, workers, tasks, cost_matrix)
IO.puts("Summary:")
IO.puts("  Total cost: #{total_cost}")
IO.puts("  Reported objective: #{objective_value}")
IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")

#
# Modify the optimization problem with actual costs
#
problem =
  problem
  |> Problem.modify model_parameters: [workers, tasks, cost_matrix] do
    # Update objective to minimize total assignment cost
    objective(
      sum(
        [w <- workers, t <- tasks],
        assign(w, t) * cost_matrix[w][t]
      ),
      direction: :minimize
    )
  end

IO.puts("Solving the full assignment problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value (1 unit per assignment): #{objective_value}")
IO.puts("")

total_cost = calculate_total_cost.(solution, workers, tasks, cost_matrix)
IO.puts("Assignments:")
IO.puts("")
IO.puts("Summary:")
IO.puts("  Total cost: #{total_cost}")
IO.puts("  Reported objective: #{objective_value}")
IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")
