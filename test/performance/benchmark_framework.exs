defmodule Dantzig.Performance.BenchmarkFramework do
  @moduledoc """
  Performance benchmarking framework for the Dantzig optimization library.

  This module provides utilities for measuring execution time, memory usage,
  and scalability characteristics of optimization problems.

  According to the 001-robustify specification (FR-012):
  - Problems up to 1000 variables must complete within 30 seconds
  - Memory usage must stay under 100MB for typical problems
  - Performance must scale reasonably with problem size
  """

  alias Dantzig.Problem
  require Logger

  @max_execution_time_ms 30_000  # 30 seconds
  @max_memory_usage_mb 100       # 100MB
  @warmup_iterations 2           # Warmup runs before measurement
  @measurement_iterations 5      # Number of runs for average measurement

  @doc """
  Measure the execution time and memory usage of solving an optimization problem.

  Returns a map with performance metrics:
  - `:execution_time_ms` - Time to solve in milliseconds
  - `:memory_usage_mb` - Memory usage in megabytes
  - `:variables_count` - Number of variables in the problem
  - `:constraints_count` - Number of constraints in the problem
  - `:within_time_limit` - Boolean indicating if within 30s limit
  - `:within_memory_limit` - Boolean indicating if within 100MB limit
  """
  @spec benchmark_problem(Problem.t(), keyword()) :: map()
  def benchmark_problem(problem, opts \\ []) do
    variables_count = count_variables(problem)
    constraints_count = map_size(problem.constraints)

    # Warmup runs
    for _ <- 1..@warmup_iterations do
      try do
        Problem.solve(problem, print_optimizer_input: false)
      rescue
        _ -> :ok  # Ignore warmup failures
      end
    end

    # Measure memory before
    initial_memory = :erlang.memory(:total)

    # Measure execution time
    {execution_time_us, result} = :timer.tc(fn ->
      Problem.solve(problem, print_optimizer_input: false)
    end)

    # Measure memory after
    final_memory = :erlang.memory(:total)
    memory_usage_mb = (final_memory - initial_memory) / (1024 * 1024)

    execution_time_ms = execution_time_us / 1000

    # Evaluate results
    within_time_limit = execution_time_ms <= @max_execution_time_ms
    within_memory_limit = memory_usage_mb <= @max_memory_usage_mb

    metrics = %{
      execution_time_ms: execution_time_ms,
      memory_usage_mb: memory_usage_mb,
      variables_count: variables_count,
      constraints_count: constraints_count,
      within_time_limit: within_time_limit,
      within_memory_limit: within_memory_limit,
      result: result,
      timestamp: DateTime.utc_now()
    }

    # Log performance metrics
    Logger.info("Performance benchmark: #{variables_count} variables, " <>
                "#{constraints_count} constraints, " <>
                "#{Float.round(execution_time_ms, 2)}ms, " <>
                "#{Float.round(memory_usage_mb, 2)}MB")

    metrics
  end

  @doc """
  Run multiple benchmarks with increasing problem sizes to test scalability.

  Creates problems of different sizes and measures their performance characteristics.
  """
  @spec run_scalability_benchmarks([integer()], fun(), keyword()) :: [map()]
  def run_scalability_benchmarks(sizes, problem_creator, opts \\ []) do
    Logger.info("Running scalability benchmarks for sizes: #{inspect(sizes)}")

    Enum.map(sizes, fn size ->
      Logger.info("Benchmarking size #{size}...")

      problem = problem_creator.(size)

      metrics = benchmark_problem(problem, opts)
      Map.put(metrics, :problem_size, size)
    end)
  end

  @doc """
  Validate that all benchmarks meet performance requirements.

  Checks that all metrics are within the specified limits:
  - Execution time <= 30 seconds
  - Memory usage <= 100MB
  """
  @spec validate_performance_requirements([map()]) :: {:ok, [map()]} | {:error, [map()]}
  def validate_performance_requirements(benchmark_results) do
    violations = Enum.filter(benchmark_results, fn result ->
      not result.within_time_limit or not result.within_memory_limit
    end)

    if Enum.empty?(violations) do
      {:ok, benchmark_results}
    else
      Logger.error("Performance violations found: #{length(violations)}")
      Enum.each(violations, fn violation ->
        Logger.error("Violation: #{violation.variables_count} variables, " <>
                    "#{violation.execution_time_ms}ms, " <>
                    "#{violation.memory_usage_mb}MB")
      end)
      {:error, violations}
    end
  end

  @doc """
  Generate a performance report summarizing all benchmark results.
  """
  @spec generate_performance_report([map()]) :: iodata()
  def generate_performance_report(benchmark_results) do
    IO.puts("\n=== Performance Benchmark Report ===")

    total_benchmarks = length(benchmark_results)
    passed_benchmarks = Enum.count(benchmark_results, &(&1.within_time_limit and &1.within_memory_limit))

    IO.puts("Total benchmarks: #{total_benchmarks}")
    IO.puts("Passed: #{passed_benchmarks}")
    IO.puts("Failed: #{total_benchmarks - passed_benchmarks}")
    IO.puts("Success rate: #{Float.round(passed_benchmarks / total_benchmarks * 100, 1)}%")

    IO.puts("\nDetailed Results:")
    IO.puts("Size\t\tVars\tConst\tTime(ms)\tMemory(MB)\tStatus")

    Enum.each(benchmark_results, fn result ->
      vars = result.variables_count
      const = result.constraints_count
      time = Float.round(result.execution_time_ms, 2)
      memory = Float.round(result.memory_usage_mb, 2)
      status = if result.within_time_limit and result.within_memory_limit, do: "✅", else: "❌"

      IO.puts("#{vars}\t\t#{const}\t#{time}\t#{memory}\t#{status}")
    end)

    IO.puts("\nRequirements:")
    IO.puts("- Max execution time: #{@max_execution_time_ms / 1000}s")
    IO.puts("- Max memory usage: #{@max_memory_usage_mb}MB")
  end

  @doc """
  Count the total number of variables in a problem.
  """
  @spec count_variables(Problem.t()) :: integer()
  def count_variables(problem) do
    problem.variables
    |> Map.values()
    |> Enum.reduce(0, fn var_set, acc ->
      acc + map_size(var_set)
    end)
  end

  @doc """
  Create a performance test for a specific problem type with scalable sizes.
  """
  @spec create_problem_benchmark_test(atom(), [integer()], fun()) :: function()
  def create_problem_benchmark_test(problem_type, sizes, problem_creator) do
    fn ->
      results = run_scalability_benchmarks(sizes, problem_creator)
      generate_performance_report(results)

      case validate_performance_requirements(results) do
        {:ok, _} -> :ok
        {:error, violations} -> flunk("Performance requirements violated: #{inspect(violations)}")
      end
    end
  end

  @doc """
  Generate example problems for benchmarking different optimization types.
  """
  defmodule ProblemGenerators do
    @doc """
    Generate a knapsack problem with given number of items.
    """
    @spec knapsack_problem(integer()) :: Problem.t()
    def knapsack_problem(num_items) do
      weights = Enum.map(1..num_items, fn _ -> :rand.uniform(50) + 10 end)
      values = Enum.map(1..num_items, fn _ -> :rand.uniform(100) + 20 end)
      max_weight = Enum.sum(weights) |> div(2)

      Problem.define do
        new(name: "Knapsack Problem #{num_items} items")
        variables("x", [i <- 1..num_items], :binary)
        constraints([], sum(x(i) * weights[i] for i <- 1..num_items) <= max_weight, "Weight constraint")
        objective(sum(x(i) * values[i] for i <- 1..num_items), direction: :maximize)
      end
    end

    @doc """
    Generate a facility location problem with given number of facilities and customers.
    """
    @spec facility_location_problem(integer(), integer()) :: Problem.t()
    def facility_location_problem(num_facilities, num_customers) do
      facilities = Enum.map(1..num_facilities, &"Facility_#{&1}")
      customers = Enum.map(1..num_customers, &"Customer_#{&1}")

      fixed_costs = Enum.into(facilities, %{}, &{&1, :rand.uniform(1000) + 500})
      transport_costs = Enum.into(facilities, %{}, fn facility ->
        {facility, Enum.into(customers, %{}, &{&1, :rand.uniform(50) + 10})}
      end)

      Problem.define do
        new(name: "Facility Location #{num_facilities}x#{num_customers}")

        variables("x", [facility <- facilities], :binary)
        variables("y", [facility <- facilities, customer <- customers], :binary)

        constraints([customer <- customers], sum(y(facility, customer) for facility <- facilities) == 1)
        constraints([facility <- facilities, customer <- customers], y(facility, customer) <= x(facility))

        objective(
          sum(x(facility) * fixed_costs[facility] +
              y(facility, customer) * transport_costs[facility][customer]
              for facility <- facilities, customer <- customers),
          direction: :minimize
        )
      end
    end
  end
end
