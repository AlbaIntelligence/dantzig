# Performance Benchmarking Framework
# This module provides utilities for benchmarking optimization problems

defmodule Dantzig.Performance.BenchmarkFramework do
  @moduledoc """
  Performance benchmarking framework for the Dantzig package.

  Provides functions to:
  - Benchmark optimization problems of varying sizes
  - Monitor execution time and memory usage
  - Generate scalability reports
  - Detect performance regressions
  """

  # 30 seconds
  @max_execution_time_ms 30_000
  # 100MB
  @max_memory_mb 100

  @doc """
  Benchmarks a problem with the given size and configuration.

  Returns benchmark results including execution time, memory usage, and status.
  """
  def benchmark_problem(problem_fun, size, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @max_execution_time_ms)

    # Monitor memory before execution
    initial_memory = :erlang.memory(:total)

    # Execute with timing
    {execution_time, result} =
      :timer.tc(fn ->
        problem_fun.(size)
      end)

    # Monitor memory after execution
    final_memory = :erlang.memory(:total)
    memory_used = final_memory - initial_memory

    # Determine status
    status =
      cond do
        execution_time > timeout -> :timeout
        memory_used > @max_memory_mb * 1024 * 1024 -> :memory_exceeded
        true -> :success
      end

    %{
      problem_size: size,
      execution_time_ms: execution_time / 1000,
      memory_used_mb: memory_used / (1024 * 1024),
      status: status,
      result: result,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Runs scalability benchmarks for a range of problem sizes.

  Returns scalability analysis with performance metrics.
  """
  def benchmark_scalability(problem_fun, sizes, opts \\ []) do
    results =
      Enum.map(sizes, fn size ->
        benchmark_problem(problem_fun, size, opts)
      end)

    # Analyze scalability
    scalability_analysis = analyze_scalability(results)

    %{
      results: results,
      scalability_analysis: scalability_analysis,
      performance_summary: generate_performance_summary(results)
    }
  end

  @doc """
  Analyzes scalability trends from benchmark results.
  """
  def analyze_scalability(results) do
    # Calculate time complexity trend
    time_trend = calculate_trend(results, :execution_time_ms)
    memory_trend = calculate_trend(results, :memory_used_mb)

    # Determine complexity class
    time_complexity = classify_complexity(time_trend)
    memory_complexity = classify_complexity(memory_trend)

    %{
      time_complexity: time_complexity,
      memory_complexity: memory_complexity,
      time_trend: time_trend,
      memory_trend: memory_trend,
      recommendations: generate_recommendations(results, time_complexity, memory_complexity)
    }
  end

  @doc """
  Detects performance regressions by comparing current results with baseline.
  """
  def detect_regression(current_results, baseline_results, threshold \\ 0.1) do
    regressions =
      Enum.filter(current_results, fn current ->
        baseline = Enum.find(baseline_results, &(&1.problem_size == current.problem_size))

        if baseline do
          time_regression =
            (current.execution_time_ms - baseline.execution_time_ms) / baseline.execution_time_ms

          memory_regression =
            (current.memory_used_mb - baseline.memory_used_mb) / baseline.memory_used_mb

          time_regression > threshold or memory_regression > threshold
        else
          false
        end
      end)

    %{
      regressions: regressions,
      regression_count: length(regressions),
      threshold: threshold
    }
  end

  # Private helper functions

  defp calculate_trend(results, metric) do
    # Simple linear regression to determine trend
    sizes = Enum.map(results, & &1.problem_size)
    values = Enum.map(results, &Map.get(&1, metric))

    # Calculate correlation coefficient
    correlation = calculate_correlation(sizes, values)

    %{
      correlation: correlation,
      trend_direction: if(correlation > 0, do: :increasing, else: :decreasing),
      strength: abs(correlation)
    }
  end

  defp calculate_correlation(xs, ys) do
    n = length(xs)
    sum_x = Enum.sum(xs)
    sum_y = Enum.sum(ys)
    sum_xy = Enum.zip_with(xs, ys, &(&1 * &2)) |> Enum.sum()
    sum_x2 = Enum.map(xs, &(&1 * &1)) |> Enum.sum()
    sum_y2 = Enum.map(ys, &(&1 * &1)) |> Enum.sum()

    numerator = n * sum_xy - sum_x * sum_y
    denominator = :math.sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y))

    if denominator == 0, do: 0, else: numerator / denominator
  end

  defp classify_complexity(trend) do
    case trend.strength do
      strength when strength < 0.3 -> "O(1)"
      strength when strength < 0.7 -> "O(log n)"
      strength when strength < 0.9 -> "O(n)"
      _ -> "O(n^2) or higher"
    end
  end

  defp generate_recommendations(results, time_complexity, memory_complexity) do
    recommendations = []

    # Check for performance issues
    max_time = Enum.max_by(results, & &1.execution_time_ms).execution_time_ms
    max_memory = Enum.max_by(results, & &1.memory_used_mb).memory_used_mb

    recommendations =
      if max_time > @max_execution_time_ms do
        ["Consider optimizing algorithm for large problems" | recommendations]
      else
        recommendations
      end

    recommendations =
      if max_memory > @max_memory_mb do
        ["Consider memory optimization for large problems" | recommendations]
      else
        recommendations
      end

    # Add complexity-based recommendations
    recommendations =
      if time_complexity == "O(n^2) or higher" do
        ["Consider algorithm optimization to reduce time complexity" | recommendations]
      else
        recommendations
      end

    recommendations
  end

  defp generate_performance_summary(results) do
    %{
      total_problems: length(results),
      successful_problems: Enum.count(results, &(&1.status == :success)),
      failed_problems: Enum.count(results, &(&1.status != :success)),
      average_execution_time: calculate_average(results, :execution_time_ms),
      average_memory_usage: calculate_average(results, :memory_used_mb),
      max_execution_time: Enum.max_by(results, & &1.execution_time_ms).execution_time_ms,
      max_memory_usage: Enum.max_by(results, & &1.memory_used_mb).memory_used_mb
    }
  end

  defp calculate_average(results, metric) do
    values = Enum.map(results, &Map.get(&1, metric))
    Enum.sum(values) / length(values)
  end
end
