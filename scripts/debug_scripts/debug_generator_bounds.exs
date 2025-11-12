defmodule DebugGeneratorBounds do
  import Dantzig.Problem

  def main do
    IO.puts("=== Debugging Generator Variable Bounds Flow ===")

    # Override the generator pattern to add debug logging
    original_variables = &variables/5

    # Create a wrapper that logs calls
    debug_variables = fn problem, name, generators, var_type, opts ->
      IO.puts("\n=== DEBUG: variables/5 called ===")
      IO.puts("name: #{inspect(name)}")
      IO.puts("generators: #{inspect(generators)}")
      IO.puts("var_type: #{inspect(var_type)}")
      IO.puts("opts: #{inspect(opts)}")
      
      result = original_variables.(problem, name, generators, var_type, opts)
      IO.puts("variables/5 result variable_defs keys: #{inspect(Map.keys(result.variable_defs))}")
      
      result
    end

    # Test generator variables with bounds using the debug wrapper
    problem =
      define do
        new(name: "Generator Bounds Test", description: "Test generator variables with bounds")

        variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity",
          min_bound: 0,
          max_bound: 100
        )
      end

    IO.puts("\n=== Final Problem ===")
    IO.inspect(problem.variable_defs, label: "variable_defs")
  end
end

DebugGeneratorBounds.main()