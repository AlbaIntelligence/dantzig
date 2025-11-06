defmodule DebugPatternMatching do
  import Dantzig.Problem

  def main do
    IO.puts("=== Debugging Generator Pattern Matching ===")

    # Test a simpler generator variable without bounds first
    IO.puts("\n--- Testing generator variables WITHOUT bounds ---")

    problem1 =
      define do
        new(name: "No Bounds Test")
        variables("x", [i <- 1..2], :continuous, "X variable")
      end

    IO.inspect(problem1.variable_defs, label: "No bounds variable_defs")

    # Test generator variables with bounds
    IO.puts("\n--- Testing generator variables WITH bounds ---")

    problem2 =
      define do
        new(name: "With Bounds Test")
        variables("y", [i <- 1..2], :continuous, "Y variable", min_bound: 0, max_bound: 10)
      end

    IO.inspect(problem2.variable_defs, label: "With bounds variable_defs")
  end
end

DebugPatternMatching.main()
