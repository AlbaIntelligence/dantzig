defmodule DebugGeneratorVariables do
  import Dantzig.Problem

  def main do
    IO.puts("=== Debugging Generator Variable Creation ===")

    # Test generator variables with bounds
    problem =
      define do
        new(name: "Generator Bounds Test", description: "Test generator variables with bounds")

        variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity",
          min_bound: 0,
          max_bound: 100
        )
      end

    IO.inspect(problem, label: "Problem structure")

    IO.puts("\n=== Variable Defs ===")
    IO.inspect(problem.variable_defs, label: "variable_defs")

    IO.puts("\n=== Variables ===")
    IO.inspect(problem.variables, label: "variables")

    # Check what keys are available
    if Map.has_key?(problem.variables, "qty") do
      qty_vars = problem.variables["qty"]
      IO.inspect(qty_vars, label: "qty variables")

      IO.puts("\n=== Individual variable checks ===")

      Enum.each(qty_vars, fn {key, _poly} ->
        IO.puts("Checking variable_defs for key: #{inspect(key)}")
        var_def = problem.variable_defs[key]
        IO.inspect(var_def, label: "variable_defs[#{inspect(key)}]")
      end)
    end
  end
end

DebugGeneratorVariables.main()
