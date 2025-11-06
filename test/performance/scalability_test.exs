defmodule Dantzig.Performance.ScalabilityTest do
  @moduledoc """
  Performance benchmarks testing scalability with increasing problem sizes.

  Tests performance requirements from 001-robustify specification (FR-012):
  - Problems up to 1000 variables must complete within 30 seconds
  - Memory usage must stay under 100MB for typical problems
  - Performance must scale reasonably with problem size
  """

  use ExUnit.Case, async: false

  alias Dantzig.Performance.BenchmarkFramework
  alias Dantzig.Performance.BenchmarkFramework.ProblemGenerators

  setup_all do
    # Ensure random seed is consistent for reproducible benchmarks
    :rand.seed(:exs1024, {1, 2, 3})
    :ok
  end

  describe "knapsack problem scalability" do
    @tag :performance
    test "knapsack problems scale within performance requirements" do
      # Test increasing problem sizes
      sizes = [50, 100, 200, 500, 1000]

      test_fn =
        BenchmarkFramework.create_problem_benchmark_test(
          :knapsack,
          sizes,
          &ProblemGenerators.knapsack_problem/1
        )

      test_fn.()
    end

    @tag :performance
    test "small knapsack problems perform well" do
      problem = ProblemGenerators.knapsack_problem(50)

      metrics = BenchmarkFramework.benchmark_problem(problem)

      assert metrics.within_time_limit, "Small knapsack should complete within 30 seconds"
      assert metrics.within_memory_limit, "Small knapsack should use less than 100MB"
      assert metrics.variables_count == 50
    end
  end

  describe "facility location problem scalability" do
    @tag :performance
    test "facility location problems scale within performance requirements" do
      # Test problem sizes: {num_facilities, num_customers}
      sizes = [{3, 10}, {5, 20}, {10, 50}, {15, 100}]

      test_fn =
        BenchmarkFramework.create_problem_benchmark_test(
          :facility_location,
          sizes,
          fn {facilities, customers} ->
            ProblemGenerators.facility_location_problem(facilities, customers)
          end
        )

      test_fn.()
    end
  end

  describe "large problem performance validation" do
    @tag :performance
    test "problems with 1000 variables complete within time limit" do
      problem = ProblemGenerators.knapsack_problem(1000)

      metrics = BenchmarkFramework.benchmark_problem(problem)

      assert metrics.variables_count == 1000, "Should create exactly 1000 variables"
      assert metrics.within_time_limit, "1000 variable problem should complete within 30 seconds"
      assert metrics.within_memory_limit, "Should use less than 100MB memory"
    end

    @tag :performance
    test "memory usage scales reasonably with problem size" do
      sizes = [100, 300, 500, 1000]

      results =
        BenchmarkFramework.run_scalability_benchmarks(
          sizes,
          &ProblemGenerators.knapsack_problem/1
        )

      # Validate that memory usage doesn't grow excessively
      max_memory = Enum.max_by(results, & &1.memory_usage_mb) |> Map.get(:memory_usage_mb)
      assert max_memory < 200, "Memory usage should not exceed 200MB even for large problems"

      # Verify that not all benchmarks failed
      passed = Enum.count(results, &(&1.within_time_limit and &1.within_memory_limit))
      assert passed > 0, "At least some benchmarks should pass"
    end
  end

  describe "performance reporting" do
    @tag :performance
    test "benchmark framework generates meaningful reports" do
      problems = [100, 300, 500] |> Enum.map(&ProblemGenerators.knapsack_problem/1)

      results = Enum.map(problems, &BenchmarkFramework.benchmark_problem/1)

      # This should not raise an exception
      report = BenchmarkFramework.generate_performance_report(results)
      assert is_binary(report) or is_list(report), "Should generate a report"

      # Should be able to validate results
      validation_result = BenchmarkFramework.validate_performance_requirements(results)
      assert validation_result in [{:ok, results}, {:error, _}], "Should return validation result"
    end
  end
end
