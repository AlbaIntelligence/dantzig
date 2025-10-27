#!/usr/bin/env elixir

# Coverage Validation Script
# Validates that test coverage meets the required thresholds

defmodule CoverageValidation do
  @moduledoc """
  Script to validate test coverage meets requirements:
  - 80% overall coverage
  - 85% core module coverage
  """

  def main(_args) do
    IO.puts("Running coverage validation...")

    # Run tests with coverage
    {output, exit_code} = System.cmd("mix", ["test", "--cover"], stderr_to_stdout: true)

    if exit_code != 0 do
      IO.puts("Tests failed with exit code: #{exit_code}")
      IO.puts("Output: #{output}")
      System.halt(1)
    end

    # Parse coverage output
    coverage_info = parse_coverage_output(output)

    # Validate coverage
    validate_coverage(coverage_info)

    IO.puts("✅ Coverage validation passed!")
  end

  defp parse_coverage_output(output) do
    # Extract coverage percentages from output
    lines = String.split(output, "\n")

    overall_coverage =
      lines
      |> Enum.find(fn line -> String.contains?(line, "Total") end)
      |> extract_percentage()

    core_coverage =
      lines
      |> Enum.filter(fn line ->
        String.contains?(line, "lib/dantzig/core/") or
        String.contains?(line, "lib/dantzig.ex")
      end)
      |> Enum.map(&extract_percentage/1)
      |> Enum.reduce(0, &(&1 + &2)) / max(length(core_modules), 1)

    %{
      overall: overall_coverage,
      core: core_coverage
    }
  end

  defp extract_percentage(line) when is_nil(line), do: 0.0
  defp extract_percentage(line) do
    case Regex.run(~r/(\d+\.?\d*)%/, line) do
      [_, percentage] -> String.to_float(percentage)
      _ -> 0.0
    end
  end

  defp core_modules do
    [
      "lib/dantzig.ex",
      "lib/dantzig/core/problem.ex",
      "lib/dantzig/core/variable.ex",
      "lib/dantzig/core/constraint.ex",
      "lib/dantzig/core/polynomial.ex"
    ]
  end

  defp validate_coverage(%{overall: overall, core: core}) do
    IO.puts("Overall coverage: #{overall}% (required: 80%)")
    IO.puts("Core coverage: #{core}% (required: 85%)")

    if overall < 80.0 do
      IO.puts("❌ Overall coverage #{overall}% is below required 80%")
      System.halt(1)
    end

    if core < 85.0 do
      IO.puts("❌ Core coverage #{core}% is below required 85%")
      System.halt(1)
    end
  end
end

CoverageValidation.main(System.argv())
