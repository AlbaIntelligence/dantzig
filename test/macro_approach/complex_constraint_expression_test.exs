defmodule MacroApproach.ComplexConstraintExpressionTest do
  use ExUnit.Case

  require Dantzig.Problem, as: Problem

  # Test complex constraint expressions with the actual DSL
  test "DSL constraint generation with inequality constraints" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first
        variables("x", [i <- 1..3], :continuous, "Variable x")

        # Test constraint generation with <= inequality
        constraints([i <- 1..3], x(i) <= 10, "bound_constraint_#{i}")
      end

    # Check that constraints were added
    assert map_size(problem.constraints) == 3

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have index values
    assert length(constraint_names) == 3
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 3
  end

  test "DSL constraint generation with >= inequality constraints" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first
        variables("y", [i <- 1..2], :continuous, "Variable y")

        # Test constraint generation with >= inequality
        constraints([i <- 1..2], y(i) >= 5, "min_constraint_#{i}")
      end

    # Check that constraints were added
    assert map_size(problem.constraints) == 2

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have index values
    assert length(constraint_names) == 2
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 2
  end

  test "DSL constraint generation with complex expressions" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first (2D variables)
        variables("z", [i <- 1..2, j <- 1..2], :continuous, "Variable z")

        # Test constraint generation with complex expression: z(i,j) + z(i,j) == 2*z(i,j)
        constraints(
          [i <- 1..2, j <- 1..2],
          z(i, j) + z(i, j) == 2 * z(i, j),
          "complex_constraint_#{i}_#{j}"
        )
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

  test "DSL constraint generation with different constraint types mixed" do
    # Create a simple problem
    problem =
      Problem.define do
        new(name: "Test Problem")

        # Add some variables first
        variables("w", [i <- 1..2], :continuous, "Variable w")

        # Test constraint generation with equality
        constraints([i <- 1..2], w(i) == 1, "eq_constraint_#{i}")

        # Test constraint generation with <= inequality
        constraints([i <- 1..2], w(i) <= 10, "le_constraint_#{i}")

        # Test constraint generation with >= inequality
        constraints([i <- 1..2], w(i) >= 0, "ge_constraint_#{i}")
      end

    # Check that constraints were added (2 + 2 + 2 = 6 total)
    assert map_size(problem.constraints) == 6

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # The names should have index values
    assert length(constraint_names) == 6
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 6
  end
end
