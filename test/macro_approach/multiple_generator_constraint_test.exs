defmodule MacroApproach.MultipleGeneratorConstraintTest do
  use ExUnit.Case

  # Test multiple generator constraint generation with the actual DSL
  test "DSL constraint generation with two generators" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first (2D variables)
    problem =
      Dantzig.Problem.variables(
        problem,
        "queen2d",
        [quote(do: i <- 1..2), quote(do: j <- 1..2)],
        :binary,
        description: "Queen position"
      )

    # Test constraint generation with two generators
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2), quote(do: j <- 1..2)],
        quote(do: queen2d(i, j) == 1),
        "constraint"
      )

    # Check that constraints were added (2x2 = 4 combinations)
    assert map_size(problem.constraints) == 4

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have both index values
    assert length(constraint_names) == 4
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 4
  end

  test "DSL constraint generation with three generators" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first (3D variables)
    problem =
      Dantzig.Problem.variables(
        problem,
        "queen3d",
        [quote(do: i <- 1..2), quote(do: j <- 1..2), quote(do: k <- 1..2)],
        :binary,
        description: "Queen position"
      )

    # Test constraint generation with three generators
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2), quote(do: j <- 1..2), quote(do: k <- 1..2)],
        quote(do: queen3d(i, j, k) == 1),
        "constraint"
      )

    # Check that constraints were added (2x2x2 = 8 combinations)
    assert map_size(problem.constraints) == 8

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have all three index values
    assert length(constraint_names) == 8
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 8
  end

  test "DSL constraint generation with mixed range sizes" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first (mixed range sizes)
    problem =
      Dantzig.Problem.variables(
        problem,
        "mixed",
        [quote(do: i <- 1..3), quote(do: j <- 1..2)],
        :binary,
        description: "Mixed range"
      )

    # Test constraint generation with mixed range sizes
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..3), quote(do: j <- 1..2)],
        quote(do: mixed(i, j) == 1),
        "constraint"
      )

    # Check that constraints were added (3x2 = 6 combinations)
    assert map_size(problem.constraints) == 6

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have both index values
    assert length(constraint_names) == 6
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 6
  end
end
