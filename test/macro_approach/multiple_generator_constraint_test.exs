defmodule MacroApproach.MultipleGeneratorConstraintTest do
  use ExUnit.Case

  require Dantzig.Problem, as: Problem

  # Test multiple generator constraint generation with the actual DSL
  test "DSL constraint generation with two generators" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first (2D variables)
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")

        # Test constraint generation with two generators
        constraints([i <- 1..2, j <- 1..2], queen2d(i, j) <= 1, "constraint_#{i}_#{j}")
      end

    # Check that constraints were added (2x2 = 4 combinations)
    assert map_size(problem.constraints) == 4

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have both index values
    assert length(constraint_names) == 4
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 4
  end

  test "DSL constraint generation with three generators" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first (3D variables)
        variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..2], :binary, "Queen position")

        # Test constraint generation with three generators
        constraints(
          [i <- 1..2, j <- 1..2, k <- 1..2],
          queen3d(i, j, k) <= 1,
          "constraint_#{i}_#{j}_#{k}"
        )
      end

    # Check that constraints were added (2x2x2 = 8 combinations)
    assert map_size(problem.constraints) == 8

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have all three index values
    assert length(constraint_names) == 8
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 8
  end

  test "DSL constraint generation with mixed range sizes" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first (mixed range sizes)
        variables("mixed", [i <- 1..3, j <- 1..2], :binary, "Mixed range")

        # Test constraint generation with mixed range sizes
        constraints([i <- 1..3, j <- 1..2], mixed(i, j) <= 1, "constraint_#{i}_#{j}")
      end

    # Check that constraints were added (3x2 = 6 combinations)
    assert map_size(problem.constraints) == 6

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have both index values
    assert length(constraint_names) == 6
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 6
  end
end
