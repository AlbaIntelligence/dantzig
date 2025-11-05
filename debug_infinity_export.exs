# Final comprehensive test for :infinity LP export fix

require Dantzig.Problem, as: Problem
require Dantzig.Constraint, as: Constraint
require Dantzig.ProblemVariable, as: ProblemVariable
require Dantzig.Polynomial

IO.puts("=== Final Test: :infinity LP Export Fix ===")

# Create a simple problem with :infinity directly
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

IO.puts("\nProblem created successfully:")
IO.inspect(problem)

# Test the full LP export - this should work now with our fix
IO.puts("\n=== Testing Full LP Export ===")

try do
  lp_output = Dantzig.Highs.to_lp_iodata(problem) |> IO.iodata_to_binary()
  IO.puts("LP Export Output:")
  IO.puts(lp_output)

  # Verify the fix worked
  success_checks = [
    {"1e+30 found", String.contains?(lp_output, "1e+30")},
    {"No ':infinity' atom", not String.contains?(lp_output, ":infinity")},
    {"Contains variable bounds", String.contains?(lp_output, "Bounds")},
    {"Contains constraints", String.contains?(lp_output, "Subject To")}
  ]

  IO.puts("\n=== Success Checks ===")

  all_passed =
    Enum.all?(success_checks, fn {desc, result} ->
      status = if result, do: "✅ PASS", else: "❌ FAIL"
      IO.puts("#{status}: #{desc}")
      result
    end)

  if all_passed do
    IO.puts("\n🎉 ALL TESTS PASSED! :infinity LP export fix is working correctly!")
  else
    IO.puts("\n❌ Some tests failed. Check the output above.")
  end

rescue
  error ->
    IO.puts("❌ FAILED: LP export error: #{inspect(error)}")
    IO.puts("This means the :infinity fix is not working properly.")
end
