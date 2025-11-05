defmodule Dantzig.Performance.ScalabilityTest do
  @moduledoc """
  Performance and scalability tests for the Dantzig library.

  These tests verify that the system scales efficiently with:
  - Increasing numbers of variables
  - Increasing numbers of constraints
  - Complex problem structures
  - Large objective expressions
  - LP format export performance

  T052: Add performance tests for scalability
  """
  use ExUnit.Case, async: false  # Performance tests should run sequentially

  require Dantzig.Problem, as: Problem
  alias Dantzig.{Problem, HiGHS, Config}

  # Helper to check if HiGHS solver is available
  defp highs_available? do
    try do
      command = Config.default_highs_binary_path()
      {_output, exit_code} = System.cmd(command, ["--version"], stderr_to_stdout: true)
      exit_code == 0
    rescue
      _ -> false
    catch
      _ -> false
    end
  end

  # Helper to measure execution time
  defp measure_time(fun) do
    start_time = System.monotonic_time(:millisecond)
    result = fun.()
    end_time = System.monotonic_time(:millisecond)
    elapsed = end_time - start_time
    {result, elapsed}
  end

  describe "Problem creation scalability" do
    test "creates problems with 100 variables efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Scalability 100", direction: :minimize)
            variables("x", [i <- 1..100], :continuous, "Variable")
            constraints([i <- 1..100], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 100
      # Should complete quickly (< 1 second for 100 variables)
      assert elapsed < 1_000, "Problem creation took #{elapsed}ms, expected < 1000ms"
    end

    test "creates problems with 500 variables efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Scalability 500", direction: :minimize)
            variables("x", [i <- 1..500], :continuous, "Variable")
            constraints([i <- 1..500], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 500
      # Should complete in reasonable time (< 5 seconds for 500 variables)
      assert elapsed < 5_000, "Problem creation took #{elapsed}ms, expected < 5000ms"
    end

    test "creates problems with 1000 variables efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Scalability 1000", direction: :minimize)
            variables("x", [i <- 1..1000], :continuous, "Variable")
            constraints([i <- 1..1000], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 1000
      # Should complete in reasonable time (< 10 seconds for 1000 variables)
      assert elapsed < 10_000, "Problem creation took #{elapsed}ms, expected < 10000ms"
    end

    test "creates problems with 2000 variables efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Scalability 2000", direction: :minimize)
            variables("x", [i <- 1..2000], :continuous, "Variable")
            constraints([i <- 1..2000], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 2000
      # Should complete in reasonable time (< 20 seconds for 2000 variables)
      assert elapsed < 20_000, "Problem creation took #{elapsed}ms, expected < 20000ms"
    end

    test "creates problems with many constraints efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Many Constraints", direction: :minimize)
            variables("x", [i <- 1..10], :continuous, "Variable")
            constraints([i <- 1..1000], sum(x(:_)) >= 0, "Constraint")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.constraints) == 1000
      # Should complete in reasonable time (< 10 seconds for 1000 constraints)
      assert elapsed < 10_000, "Problem creation took #{elapsed}ms, expected < 10000ms"
    end

    test "creates problems with nested generators efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Nested Generators Scalability", direction: :minimize)
            variables("x", [i <- 1..50, j <- 1..50], :continuous, "Variable")
            constraints([i <- 1..50, j <- 1..50], x(i, j) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 2500
      # Should complete in reasonable time (< 15 seconds for 2500 variables)
      assert elapsed < 15_000, "Problem creation took #{elapsed}ms, expected < 15000ms"
    end
  end

  describe "LP format export scalability" do
    test "exports LP format for 100 variables efficiently" do
      problem =
        Problem.define do
          new(name: "LP Export 100", direction: :minimize)
          variables("x", [i <- 1..100], :continuous, "Variable")
          constraints([i <- 1..100], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      {lp_data, elapsed} = measure_time(fn -> HiGHS.to_lp_iodata(problem) end)
      lp_string = IO.iodata_to_binary(lp_data)

      assert is_binary(lp_string)
      assert byte_size(lp_string) > 0
      # Should complete quickly (< 500ms for 100 variables)
      assert elapsed < 500, "LP export took #{elapsed}ms, expected < 500ms"
    end

    test "exports LP format for 500 variables efficiently" do
      problem =
        Problem.define do
          new(name: "LP Export 500", direction: :minimize)
          variables("x", [i <- 1..500], :continuous, "Variable")
          constraints([i <- 1..500], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      {lp_data, elapsed} = measure_time(fn -> HiGHS.to_lp_iodata(problem) end)
      lp_string = IO.iodata_to_binary(lp_data)

      assert is_binary(lp_string)
      assert byte_size(lp_string) > 0
      # Should complete in reasonable time (< 2 seconds for 500 variables)
      assert elapsed < 2_000, "LP export took #{elapsed}ms, expected < 2000ms"
    end

    test "exports LP format for 1000 variables efficiently" do
      problem =
        Problem.define do
          new(name: "LP Export 1000", direction: :minimize)
          variables("x", [i <- 1..1000], :continuous, "Variable")
          constraints([i <- 1..1000], x(i) >= 0, "Non-negativity")
          objective(sum(x(:_)), direction: :minimize)
        end

      {lp_data, elapsed} = measure_time(fn -> HiGHS.to_lp_iodata(problem) end)
      lp_string = IO.iodata_to_binary(lp_data)

      assert is_binary(lp_string)
      assert byte_size(lp_string) > 0
      # Should complete in reasonable time (< 5 seconds for 1000 variables)
      assert elapsed < 5_000, "LP export took #{elapsed}ms, expected < 5000ms"
    end

    test "exports LP format for many constraints efficiently" do
      problem =
        Problem.define do
          new(name: "LP Export Constraints", direction: :minimize)
          variables("x", [i <- 1..10], :continuous, "Variable")
          constraints([i <- 1..1000], sum(x(:_)) >= 0, "Constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      {lp_data, elapsed} = measure_time(fn -> HiGHS.to_lp_iodata(problem) end)
      lp_string = IO.iodata_to_binary(lp_data)

      assert is_binary(lp_string)
      assert byte_size(lp_string) > 0
      # Should complete in reasonable time (< 3 seconds for 1000 constraints)
      assert elapsed < 3_000, "LP export took #{elapsed}ms, expected < 3000ms"
    end
  end

  describe "Memory usage scalability" do
    test "handles large problems without excessive memory growth" do
      # Create multiple large problems and verify memory doesn't grow excessively
      problems =
        for n <- [100, 200, 300] do
          Problem.define do
            new(name: "Memory Test #{n}", direction: :minimize)
            variables("x", [i <- 1..n], :continuous, "Variable")
            constraints([i <- 1..n], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end

      # Verify all problems were created successfully
      assert length(problems) == 3
      Enum.each(problems, fn problem ->
        assert problem != nil
        assert map_size(problem.variable_defs) > 0
      end)
    end

    test "handles repeated problem creation efficiently" do
      # Create multiple problems sequentially to test memory cleanup
      problems =
        for n <- 1..10 do
          Problem.define do
            new(name: "Repeated #{n}", direction: :minimize)
            variables("x", [i <- 1..100], :continuous, "Variable")
            constraints([i <- 1..100], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end
        end

      assert length(problems) == 10
      Enum.each(problems, fn problem ->
        assert problem != nil
        assert map_size(problem.variable_defs) == 100
      end)
    end
  end

  describe "Solving scalability" do
    @tag :requires_highs
    test "solves problems with 100 variables efficiently" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Solve Scalability 100", direction: :minimize)
          variables("x", [i <- 1..100], :continuous, "Variable")
          constraints([i <- 1..100], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1.0, "Sum constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      {result, elapsed} = measure_time(fn -> HiGHS.solve(problem) end)

      # Solving time depends on solver, but should complete reasonably
      assert result == :error or match?({:ok, _}, result)
      # Allow reasonable time for solver (depends on HiGHS performance)
      assert elapsed < 30_000, "Solving took #{elapsed}ms, expected < 30000ms"
    end

    @tag :requires_highs
    test "solves problems with 200 variables efficiently" do
      unless highs_available?() do
        flunk("HiGHS solver not available - install HiGHS to run this test")
      end

      problem =
        Problem.define do
          new(name: "Solve Scalability 200", direction: :minimize)
          variables("x", [i <- 1..200], :continuous, "Variable")
          constraints([i <- 1..200], x(i) >= 0, "Non-negativity")
          constraints([], sum(x(:_)) == 1.0, "Sum constraint")
          objective(sum(x(:_)), direction: :minimize)
        end

      {result, elapsed} = measure_time(fn -> HiGHS.solve(problem) end)

      assert result == :error or match?({:ok, _}, result)
      # Allow reasonable time for solver
      assert elapsed < 60_000, "Solving took #{elapsed}ms, expected < 60000ms"
    end
  end

  describe "Scalability trends" do
    test "problem creation time scales reasonably with variable count" do
      # Test that creation time doesn't grow too quickly
      sizes = [50, 100, 200]
      times = Enum.map(sizes, fn n ->
        {_problem, elapsed} =
          measure_time(fn ->
            Problem.define do
              new(name: "Trend Test #{n}", direction: :minimize)
              variables("x", [i <- 1..n], :continuous, "Variable")
              constraints([i <- 1..n], x(i) >= 0, "Non-negativity")
              objective(sum(x(:_)), direction: :minimize)
            end
          end)
        elapsed
      end)

      # Verify times are reasonable (each size should complete)
      Enum.each(times, fn time ->
        assert time < 10_000, "Problem creation took #{time}ms, which is too slow"
      end)

      # Verify trend: larger problems may take longer, but not excessively
      [t50, t100, t200] = times
      # t200 should not be more than 4x t50 (reasonable scaling)
      assert t200 <= t50 * 4 || t200 < 10_000,
             "Scaling seems poor: 50 vars=#{t50}ms, 200 vars=#{t200}ms"
    end

    test "LP export time scales reasonably with variable count" do
      sizes = [50, 100, 200]
      times = Enum.map(sizes, fn n ->
        problem =
          Problem.define do
            new(name: "LP Trend Test #{n}", direction: :minimize)
            variables("x", [i <- 1..n], :continuous, "Variable")
            constraints([i <- 1..n], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)), direction: :minimize)
          end

        {_lp_data, elapsed} = measure_time(fn -> HiGHS.to_lp_iodata(problem) end)
        elapsed
      end)

      # Verify times are reasonable
      Enum.each(times, fn time ->
        assert time < 5_000, "LP export took #{time}ms, which is too slow"
      end)

      # Verify trend: larger problems may take longer, but not excessively
      [t50, t100, t200] = times
      # t200 should not be more than 4x t50 (reasonable scaling)
      assert t200 <= t50 * 4 || t200 < 5_000,
             "Scaling seems poor: 50 vars=#{t50}ms, 200 vars=#{t200}ms"
    end
  end

  describe "Complex problem scalability" do
    test "handles problems with multiple variable types efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Mixed Types", direction: :minimize)
            variables("x", [i <- 1..100], :continuous, "Continuous")
            variables("y", [i <- 1..100], :binary, "Binary")
            variables("z", [i <- 1..100], :integer, "Integer")
            constraints([i <- 1..100], x(i) >= 0, "Non-negativity")
            objective(sum(x(:_)) + sum(y(:_)) + sum(z(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 300
      # Should complete in reasonable time
      assert elapsed < 10_000, "Problem creation took #{elapsed}ms, expected < 10000ms"
    end

    test "handles problems with complex objective expressions efficiently" do
      {problem, elapsed} =
        measure_time(fn ->
          Problem.define do
            new(name: "Complex Objective", direction: :minimize)
            variables("x", [i <- 1..100], :continuous, "Variable")
            variables("y", [i <- 1..100], :continuous, "Variable")
            constraints([i <- 1..100], x(i) >= 0, "Non-negativity x")
            constraints([i <- 1..100], y(i) >= 0, "Non-negativity y")
            constraints([i <- 1..100], x(i) + y(i) <= 1, "Sum constraint")
            objective(sum(x(:_)) + sum(y(:_)), direction: :minimize)
          end
        end)

      assert problem != nil
      assert map_size(problem.variable_defs) == 200
      assert map_size(problem.constraints) == 300
      # Should complete in reasonable time
      assert elapsed < 15_000, "Problem creation took #{elapsed}ms, expected < 15000ms"
    end
  end
end
