# Example Validation Framework
# This module provides utilities for validating example files

defmodule Dantzig.Examples.Validation do
  @moduledoc """
  Example validation framework for the Dantzig package.

  Provides functions to:
  - Validate example file execution
  - Check documentation quality
  - Verify problem type coverage
  - Generate validation reports
  """

  @required_problem_types [
    :diet,
    :transportation,
    :assignment,
    :production,
    :facility_location
  ]

  @doc """
  Validates all example files in the examples/ directory.

  Returns a validation report with execution status and documentation quality.
  """
  def validate_all_examples(opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60)
    include_documentation_check = Keyword.get(opts, :include_documentation_check, true)

    example_files = get_example_files()

    results =
      Enum.map(example_files, fn file_path ->
        validate_example_file(file_path, timeout, include_documentation_check)
      end)

    %{
      total_examples: length(results),
      successful_executions: Enum.count(results, &(&1.execution_status == :success)),
      failed_executions: Enum.count(results, &(&1.execution_status != :success)),
      documentation_quality: analyze_documentation_quality(results),
      problem_types_covered: extract_problem_types(results),
      execution_times: extract_execution_times(results),
      status: determine_overall_status(results)
    }
  end

  @doc """
  Validates a specific example file.

  Returns validation results including execution status and documentation quality.
  """
  def validate_example_file(file_path, timeout \\ 60, check_documentation \\ true) do
    # Check if file exists
    if not File.exists?(file_path) do
      return(%{
        file_path: file_path,
        execution_status: :file_not_found,
        execution_time_ms: 0,
        documentation_quality: :not_checked,
        problem_type: :unknown,
        business_context_present: false,
        mathematical_formulation_present: false,
        dsl_syntax_explanation_present: false,
        gotchas_documented: false,
        status: :failed
      })
    end

    # Execute example with timeout
    {execution_status, execution_time_ms, output} = execute_example(file_path, timeout)

    # Check documentation quality if requested
    documentation_analysis =
      if check_documentation do
        analyze_documentation(file_path)
      else
        %{quality: :not_checked}
      end

    %{
      file_path: file_path,
      execution_status: execution_status,
      execution_time_ms: execution_time_ms,
      output: output,
      documentation_quality: documentation_analysis.quality,
      problem_type: extract_problem_type(file_path),
      business_context_present: documentation_analysis.business_context_present || false,
      mathematical_formulation_present:
        documentation_analysis.mathematical_formulation_present || false,
      dsl_syntax_explanation_present:
        documentation_analysis.dsl_syntax_explanation_present || false,
      gotchas_documented: documentation_analysis.gotchas_documented || false,
      status: determine_file_status(execution_status, documentation_analysis)
    }
  end

  @doc """
  Analyzes documentation quality for an example file.
  """
  def analyze_documentation(file_path) do
    content = File.read!(file_path)

    %{
      quality: determine_documentation_quality(content),
      business_context_present: contains_business_context?(content),
      mathematical_formulation_present: contains_mathematical_formulation?(content),
      dsl_syntax_explanation_present: contains_dsl_syntax_explanation?(content),
      gotchas_documented: contains_gotchas?(content)
    }
  end

  @doc """
  Validates that examples cover required problem types.
  """
  def validate_problem_type_coverage(required_types \\ @required_problem_types) do
    example_files = get_example_files()
    covered_types = Enum.map(example_files, &extract_problem_type/1) |> Enum.uniq()
    missing_types = required_types -- covered_types

    %{
      required_types: required_types,
      covered_types: covered_types,
      missing_types: missing_types,
      coverage_percentage: length(covered_types) / length(required_types) * 100,
      status: if(length(missing_types) == 0, do: :complete, else: :incomplete)
    }
  end

  # Private helper functions

  defp get_example_files do
    "examples/"
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.map(&Path.join("examples", &1))
  end

  defp execute_example(file_path, timeout) do
    try do
      # Capture output and measure time
      {execution_time, {status, output}} =
        :timer.tc(fn ->
          # Use System.cmd to run the example with timeout
          {output, exit_status} =
            System.cmd("elixir", [file_path],
              stderr_to_stdout: true,
              timeout: timeout * 1000
            )

          {if(exit_status == 0, do: :success, else: :failed), output}
        end)

      {status, execution_time, output}
    rescue
      error ->
        {:error, 0, "Execution failed: #{inspect(error)}"}
    end
  end

  defp analyze_documentation_quality(results) do
    qualities = Enum.map(results, & &1.documentation_quality)

    %{
      comprehensive: Enum.count(qualities, &(&1 == :comprehensive)),
      adequate: Enum.count(qualities, &(&1 == :adequate)),
      needs_improvement: Enum.count(qualities, &(&1 == :needs_improvement)),
      not_checked: Enum.count(qualities, &(&1 == :not_checked))
    }
  end

  defp extract_problem_types(results) do
    results
    |> Enum.map(& &1.problem_type)
    |> Enum.uniq()
  end

  defp extract_execution_times(results) do
    results
    |> Enum.map(&{&1.file_path, &1.execution_time_ms})
    |> Enum.into(%{})
  end

  defp determine_overall_status(results) do
    failed_count = Enum.count(results, &(&1.status == :failed))
    if failed_count == 0, do: :all_passed, else: :some_failed
  end

  defp extract_problem_type(file_path) do
    filename = Path.basename(file_path, ".exs")

    cond do
      String.contains?(filename, "diet") -> :diet
      String.contains?(filename, "transportation") -> :transportation
      String.contains?(filename, "assignment") -> :assignment
      String.contains?(filename, "production") -> :production
      String.contains?(filename, "facility") -> :facility_location
      String.contains?(filename, "knapsack") -> :knapsack
      String.contains?(filename, "nqueens") -> :nqueens
      String.contains?(filename, "blending") -> :blending
      String.contains?(filename, "network") -> :network_flow
      true -> :other
    end
  end

  defp determine_file_status(execution_status, documentation_analysis) do
    if execution_status == :success and
         documentation_analysis.quality in [:comprehensive, :adequate] do
      :passed
    else
      :failed
    end
  end

  defp determine_documentation_quality(content) do
    has_business = contains_business_context?(content)
    has_math = contains_mathematical_formulation?(content)
    has_syntax = contains_dsl_syntax_explanation?(content)
    has_gotchas = contains_gotchas?(content)

    score = [has_business, has_math, has_syntax, has_gotchas] |> Enum.count(& &1)

    cond do
      score >= 4 -> :comprehensive
      score >= 3 -> :adequate
      score >= 1 -> :needs_improvement
      true -> :inadequate
    end
  end

  defp contains_business_context?(content) do
    String.contains?(content, "BUSINESS CONTEXT") or
      String.contains?(content, "business context") or
      String.contains?(content, "real-world") or
      String.contains?(content, "practical")
  end

  defp contains_mathematical_formulation?(content) do
    String.contains?(content, "MATHEMATICAL FORMULATION") or
      String.contains?(content, "mathematical formulation") or
      String.contains?(content, "optimization model") or
      String.contains?(content, "constraint")
  end

  defp contains_dsl_syntax_explanation?(content) do
    String.contains?(content, "DSL SYNTAX") or
      String.contains?(content, "DSL syntax") or
      String.contains?(content, "syntax explanation") or
      String.contains?(content, "variable creation")
  end

  defp contains_gotchas?(content) do
    String.contains?(content, "GOTCHAS") or
      String.contains?(content, "gotchas") or
      String.contains?(content, "common mistakes") or
      String.contains?(content, "pitfalls")
  end
end
