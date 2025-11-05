#!/usr/bin/env elixir

# Script to test all example files
# Checks syntax alignment with DSL specs and tests execution

examples = [
  "examples/simple_working_example.exs",
  "examples/assignment_problem.exs",
  "examples/working_example.exs",
  "examples/new_dsl_example.exs",
  "examples/nqueens_dsl.exs",
  "examples/knapsack_problem.exs",
  "examples/transportation_problem.exs",
  "examples/blending_problem.exs",
  "examples/production_planning.exs",
  "examples/network_flow.exs",
  "examples/test_basic_dsl.exs",
  "examples/variadic_operations_example.exs",
  "examples/pattern_based_operations_example.exs",
  "examples/tutorial_examples.exs",
  "examples/school_timetabling.exs",
  "examples/generate_timetable_svg.exs"
]

IO.puts("=" |> String.duplicate(80))
IO.puts("EXAMPLE VALIDATION REPORT")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

results = Enum.map(examples, fn example_file ->
  IO.puts("Testing: #{example_file}")
  IO.puts("-" |> String.duplicate(80))
  
  # Check if file exists
  if not File.exists?(example_file) do
    IO.puts("❌ FILE NOT FOUND")
    IO.puts("")
    %{file: example_file, status: :not_found, errors: ["File does not exist"]}
  else
    # Read file content for syntax checking
    content = File.read!(example_file)
    
    # Basic syntax checks
    syntax_errors = []
    
    # Check for deprecated Problem.new() usage
    if String.contains?(content, "Problem.new(") do
      syntax_errors = syntax_errors ++ ["Uses deprecated Problem.new() - should use Problem.define"]
    end
    
    # Check for invalid syntax patterns
    if String.contains?(content, "objective([],") do
      syntax_errors = syntax_errors ++ ["Invalid objective syntax: objective([], ...) - empty list not allowed"]
    end
    
    # Check for undefined variable references
    if String.contains?(content, "problem1.") and not String.contains?(content, "problem1 =") do
      syntax_errors = syntax_errors ++ ["References undefined variable 'problem1'"]
    end
    
    # Check for invalid expressions
    if Regex.match?(~r/that\(are\)/, content) do
      syntax_errors = syntax_errors ++ ["Contains invalid syntax: that(are)"]
    end
    
    # Try to compile/run the example
    {exec_status, exec_output} = try do
      System.cmd("mix", ["run", example_file], 
        stderr_to_stdout: true
      )
    rescue
      error -> {1, "Execution error: #{inspect(error)}"}
    catch
      :exit, {:timeout, _} -> {1, "Execution timeout"}
    end
    
    exec_result = cond do
      exec_status == 0 -> :success
      String.contains?(exec_output, "Compilation error") -> :compilation_error
      String.contains?(exec_output, "syntax error") -> :syntax_error
      String.contains?(exec_output, "undefined function") -> :undefined_function
      String.contains?(exec_output, "undefined variable") -> :undefined_variable
      true -> :execution_error
    end
    
    # Print results
    if syntax_errors != [] do
      IO.puts("⚠️  SYNTAX ISSUES:")
      Enum.each(syntax_errors, fn err -> IO.puts("  - #{err}") end)
    end
    
    case exec_result do
      :success ->
        IO.puts("✅ EXECUTION: SUCCESS")
        IO.puts("")
        %{file: example_file, status: :success, syntax_errors: syntax_errors, execution: :success}
      
      :compilation_error ->
        IO.puts("❌ EXECUTION: COMPILATION ERROR")
        error_lines = exec_output 
          |> String.split("\n") 
          |> Enum.filter(&String.contains?(&1, "error")) 
          |> Enum.take(3)
        Enum.each(error_lines, fn line -> IO.puts("  #{line}") end)
        IO.puts("")
        %{file: example_file, status: :failed, syntax_errors: syntax_errors, execution: :compilation_error, error_details: error_lines}
      
      :syntax_error ->
        IO.puts("❌ EXECUTION: SYNTAX ERROR")
        error_lines = exec_output 
          |> String.split("\n") 
          |> Enum.filter(&String.contains?(&1, "error")) 
          |> Enum.take(3)
        Enum.each(error_lines, fn line -> IO.puts("  #{line}") end)
        IO.puts("")
        %{file: example_file, status: :failed, syntax_errors: syntax_errors, execution: :syntax_error, error_details: error_lines}
      
      :undefined_function ->
        IO.puts("❌ EXECUTION: UNDEFINED FUNCTION")
        error_lines = exec_output 
          |> String.split("\n") 
          |> Enum.filter(&String.contains?(&1, "undefined")) 
          |> Enum.take(3)
        Enum.each(error_lines, fn line -> IO.puts("  #{line}") end)
        IO.puts("")
        %{file: example_file, status: :failed, syntax_errors: syntax_errors, execution: :undefined_function, error_details: error_lines}
      
      :undefined_variable ->
        IO.puts("❌ EXECUTION: UNDEFINED VARIABLE")
        error_lines = exec_output 
          |> String.split("\n") 
          |> Enum.filter(&String.contains?(&1, "undefined")) 
          |> Enum.take(3)
        Enum.each(error_lines, fn line -> IO.puts("  #{line}") end)
        IO.puts("")
        %{file: example_file, status: :failed, syntax_errors: syntax_errors, execution: :undefined_variable, error_details: error_lines}
      
      :execution_error ->
        IO.puts("❌ EXECUTION: ERROR")
        error_lines = exec_output 
          |> String.split("\n") 
          |> Enum.filter(&String.contains?(&1, "error") or String.contains?(&1, "Error")) 
          |> Enum.take(5)
        Enum.each(error_lines, fn line -> IO.puts("  #{line}") end)
        IO.puts("")
        %{file: example_file, status: :failed, syntax_errors: syntax_errors, execution: :execution_error, error_details: error_lines}
    end
  end
end)

# Summary
IO.puts("=" |> String.duplicate(80))
IO.puts("SUMMARY")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

total = length(results)
successful = Enum.count(results, &(&1.status == :success))
failed = Enum.count(results, &(&1.status == :failed))
not_found = Enum.count(results, &(&1.status == :not_found))

IO.puts("Total examples: #{total}")
IO.puts("✅ Successful: #{successful}")
IO.puts("❌ Failed: #{failed}")
IO.puts("⚠️  Not found: #{not_found}")
IO.puts("")

# List failed examples
if failed > 0 do
  IO.puts("FAILED EXAMPLES:")
  Enum.each(results, fn result ->
    if result.status == :failed do
      IO.puts("  - #{result.file}")
      if Map.has_key?(result, :syntax_errors) and result.syntax_errors != [] do
        Enum.each(result.syntax_errors, fn err -> IO.puts("      Syntax: #{err}") end)
      end
      if Map.has_key?(result, :execution) do
        IO.puts("      Execution: #{result.execution}")
      end
    end
  end)
  IO.puts("")
end

# List examples with syntax issues but successful execution
syntax_issues = Enum.filter(results, fn result ->
  Map.has_key?(result, :syntax_errors) and result.syntax_errors != [] and result.status == :success
end)

if syntax_issues != [] do
  IO.puts("EXAMPLES WITH SYNTAX ISSUES (but successful execution):")
  Enum.each(syntax_issues, fn result ->
    IO.puts("  - #{result.file}")
    Enum.each(result.syntax_errors, fn err -> IO.puts("      #{err}") end)
  end)
  IO.puts("")
end

# Exit with appropriate code
if failed > 0 or not_found > 0 do
  System.halt(1)
else
  System.halt(0)
end
