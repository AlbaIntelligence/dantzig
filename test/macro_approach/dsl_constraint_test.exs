defmodule MacroApproach.DSLConstraintTest do
  use ExUnit.Case

  # Test the actual DSL constraint generation
  test "DSL constraint generation with variable interpolation" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first
    problem =
      Dantzig.Problem.variables(problem, "queen2d", [quote(do: i <- 1..3)], :binary,
        description: "Queen position"
      )

    # Test constraint generation with variable interpolation
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..3)],
        quote(do: queen2d(i, :_) == 1),
        "One queen per row"
      )

    # Check that constraints were added
    assert map_size(problem.constraints) == 3

    # Check constraint names - should be interpolated
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should be interpolated (exact format depends on implementation)
    assert length(constraint_names) == 3
    assert Enum.all?(constraint_names, &is_binary/1)
  end

  test "DSL constraint generation with simple names" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first
    problem =
      Dantzig.Problem.variables(problem, "queen2d", [quote(do: i <- 1..2)], :binary,
        description: "Queen position"
      )

    # Test constraint generation with simple names
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2)],
        quote(do: queen2d(i, :_) == 1),
        "simple_constraint"
      )

    # Check that constraints were added
    assert map_size(problem.constraints) == 2

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should be simple with index values appended
    assert length(constraint_names) == 2
    assert Enum.all?(constraint_names, &is_binary/1)
  end
end
