# Simple test to verify :infinity LP export fix
require Dantzig.Problem, as: Problem
require Dantzig.Constraint, as: Constraint
require Dantzig.ProblemVariable, as: ProblemVariable
require Dantzig.Polynomial

IO.puts("=== Testing :infinity LP Export Fix ===")

# Create a simple problem
problem = %Problem{
  name: "Test Problem",
  direction: :minimize,
  objective: Dantzig.Polynomial.const(1),
  variable_counter: 1,
  constraint_counter: 1,
  variable_defs: %{
    "x" => %ProblemVariable{
      name: "x",
      min: 0,
      max: :infinity,
      type: :continuous,
      description: "Variable with infinity bound"
    }
  },
  variables: %{
    "x" => %{{} => Dantzig.Polynomial.const(1)}
  },
  constraints: %{
    "c1" => %Constraint{
      name: "infinity constraint",
      operator: :<=,
      left_hand_side: Dantzig.Polynomial.const(1),
      right_hand_side: :infinity,
      description: "Constraint with infinity RHS"
    }
  },
  contraints_metadata: %{}
}

# Test private format_lp_value function directly through reflection
IO.puts("Testing format_lp_value function...")

# Try calling the function through the module
try do
  # Since format_lp_value is private, we'll test it through LP export
  result = Dantzig.Highs.to_lp_iodata(problem)
  iodata_str = IO.iodata_to_binary(result)

  IO.puts("LP Export Result:")
  IO.puts(iodata_str)

  # Check if our fix worked
  if String.contains?(iodata_str, "1e+30") do
    IO.puts("✅ SUCCESS: :infinity correctly converted to 1e+30")
  else
    IO.puts("❌ FAILED: :infinity not properly converted")
  end

  if not String.contains?(iodata_str, "infinity") do
    IO.puts("✅ SUCCESS: No raw 'infinity' string found")
  else
    IO.puts("❌ WARNING: Raw 'infinity' string found")
  end
rescue
  error ->
    IO.puts("❌ ERROR: #{inspect(error)}")
end
