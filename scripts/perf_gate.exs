#!/usr/bin/env elixir

# Performance Gate Script for CI/CD Pipeline
# ==========================================
#
# This script validates that all performance benchmarks meet the requirements
# from the 001-robustify specification (FR-012):
# - Problems up to 1000 variables must complete within 30 seconds
# - Memory usage must stay under 100MB for typical problems
# - Performance must scale reasonably with problem size
#
# Usage:
#   elixir scripts/perf_gate.exs
#   elixir scripts/perf_gate.exs --verbose
#   elixir scripts/perf_gate.exs --threshold-scale 0.8  # 80% of requirements
#
# Exit codes:
#   0 - All benchmarks pass
#   1 - Performance requirements violated
#   2 - Benchmark execution failed

defmodule Dantzig.Performance.Gate do
  @moduledoc """
  Performance gate for CI/CD pipeline validation.

  Validates that the Dantzig library meets performance requirements
  for production readiness.
  """

  alias Dantzig.Performance.BenchmarkFramework
  alias Dantzig.Performance.BenchmarkFramework.ProblemGenerators

  # Performance requirements from FR-012
  @max_execution_time_ms 30_000  # 30 seconds
  @max_memory_usage_mb 100       # 100MB
  @default_threshold_scale 1.0   # 100% of requirements

  def main do
    {opts, _args} = OptionParser.parse(System.argv(), switches: [verbose: :boolean, threshold_scale: :float])

    threshold_scale = Keyword.get(opts, @threshold_scale, @default_threshold_scale)
    verbose? = Keyword.get(opts, :verbose, false)

    if verbose? do
      IO.puts("=== Dantzig Performance Gate ===")
      IO.puts("Threshold scale: #{Float.round(threshold_scale, 2)}")
      IO.puts("")
    end

    # Set random seed for reproducible benchmarks
    :rand.seed(:exs1024, {42, 43, 44})

    # Define benchmark scenarios
    scenarios = [
      %{
        name: "Small Knapsack",
        size: 50,
        creator: &ProblemGenerators.knapsack_problem/1,
        requirements: %{
          max_time: 2_000,     # 2 seconds for small problems
          max_memory: 10.0     # 10MB for small problems
        }
      },
      %{
        name: "Medium Knapsack",
        size: 200,
        creator: &ProblemGenerators.knapsack_problem/1,
        requirements: %{
          max_time: 8_000,     # 8 seconds for medium problems
          max_memory: 25.0     # 25MB for medium problems
        }
      },
      %{
        name: "Large Knapsack",
        size: 1000,
        creator: &ProblemGenerators.knapsack_problem/1,
        requirements: %{
          max_time: @max_execution_time_ms * threshold_scale,
          max_memory: @max_memory_usage_mb * threshold_scale
        }
      },
      %{
        name: "Facility Location Medium",
        size: {5, 20},
        creator: &ProblemGenerators.facility_location_problem/2,
        requirements: %{
          max_time: 15_000,    # 15 seconds for facility location
          max_memory: 50.0     # 50MB for facility location
        }
      }
    ]

    # Run all benchmark scenarios
    results = Enum.map(scenarios, fn scenario ->
      if verbose? do
        IO.puts("Running #{scenario.name} benchmark...")
      end

      problem = scenario.creator.(scenario.size)
      metrics = BenchmarkFramework.benchmark_problem(problem)

      time_ok = metrics.execution_time_ms <= scenario.requirements.max_time
      memory_ok = metrics.memory_usage_mb <= scenario.requirements.max_memory
      overall_ok = time_ok and memory_ok

      result = %{
        scenario: scenario.name,
        size: scenario.size,
        variables: metrics.variables_count,
        constraints: metrics.constraints_count,
        execution_time_ms: metrics.execution_time_ms,
        memory_usage_mb: metrics.memory_usage_mb,
        time_ok: time_ok,
        memory_ok: memory_ok,
        overall_ok: overall_ok,
        requirements: scenario.requirements
      }

      if verbose? do
        status = if overall_ok, do: "✅ PASS", else: "❌ FAIL"
        IO.puts("  #{status}: #{metrics.variables_count} vars, " <>
                "#{Float.round(metrics.execution_time_ms, 1)}ms, " <>
                "#{Float.round(metrics.memory_usage_mb, 1)}MB")
      end

      result
    end)

    # Generate summary report
    if verbose? do
      IO.puts("\n=== Performance Gate Results ===")
    end

    total_scenarios = length(results)
    passed_scenarios = Enum.count(results, & &.overall_ok)
    failed_scenarios = total_scenarios - passed_scenarios

    if verbose? do
      IO.puts("Total scenarios: #{total_scenarios}")
      IO.puts("Passed: #{passed_scenarios}")
      IO.puts("Failed: #{failed_scenarios}")
      IO.puts("Success rate: #{Float.round(passed_scenarios / total_scenarios * 100, 1)}%")
      IO.puts("")
    end

    # Report failures if any
    failures = Enum.filter(results, & not &.overall_ok)

    if not Enum.empty?(failures) do
      IO.puts("❌ PERFORMANCE GATE FAILED")
      IO.puts("")

      Enum.each(failures, fn failure ->
        IO.puts("Scenario: #{failure.scenario}")
        IO.puts("  Variables: #{failure.variables}")
        IO.puts("  Execution time: #{Float.round(failure.execution_time_ms, 1)}ms (limit: #{Float.round(failure.requirements.max_time, 1)}ms)")
        IO.puts("  Memory usage: #{Float.round(failure.memory_usage_mb, 1)}MB (limit: #{Float.round(failure.requirements.max_memory, 1)}MB)")
        IO.puts("")
      end)

      IO.puts("Performance requirements from FR-012:")
      IO.puts("- Problems up to 1000 variables: <= #{@max_execution_time_ms}ms")
      IO.puts("- Memory usage for typical problems: <= #{@max_memory_usage_mb}MB")
      IO.puts("")
      System.halt(1)
    else
      if verbose? do
        IO.puts("✅ ALL PERFORMANCE BENCHMARKS PASSED")
        IO.puts("")
        IO.puts("Performance requirements from FR-012 satisfied:")
        IO.puts("- Problems up to 1000 variables complete within #{@max_execution_time_ms}ms")
        IO.puts("- Memory usage stays under #{@max_memory_usage_mb}MB")
      end

      System.halt(0)
    end
  rescue
    error ->
      IO.puts("❌ BENCHMARK EXECUTION FAILED")
      IO.puts("Error: #{inspect(error)}")
      IO.puts("")
      System.halt(2)
  end
end

# Run the performance gate
Dantzig.Performance.Gate.main()
