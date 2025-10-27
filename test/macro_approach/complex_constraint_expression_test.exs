defmodule MacroApproach.ComplexConstraintExpressionTest do
  use ExUnit.Case

  # Test complex constraint expressions with the actual DSL
  test "DSL constraint generation with inequality constraints" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first
    problem =
      Dantzig.Problem.variables(problem, "x", [quote(do: i <- 1..3)], :integer,
        description: "Variable x"
      )

    # Test constraint generation with <= inequality
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..3)],
        quote(do: x(i) <= 10),
        "bound_constraint"
      )

    # Check that constraints were added
    assert map_size(problem.constraints) == 3

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have index values
    assert length(constraint_names) == 3
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 3
  end

  test "DSL constraint generation with >= inequality constraints" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first
    problem =
      Dantzig.Problem.variables(problem, "y", [quote(do: i <- 1..2)], :integer,
        description: "Variable y"
      )

    # Test constraint generation with >= inequality
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2)],
        quote(do: y(i) >= 5),
        "min_constraint"
      )

    # Check that constraints were added
    assert map_size(problem.constraints) == 2

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have index values
    assert length(constraint_names) == 2
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 2
  end

  test "DSL constraint generation with complex expressions" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first (2D variables)
    problem =
      Dantzig.Problem.variables(
        problem,
        "z",
        [quote(do: i <- 1..2), quote(do: j <- 1..2)],
        :integer,
        description: "Variable z"
      )

    # Test constraint generation with complex expression: z(i,j) + z(i,j) == 2*z(i,j)
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2), quote(do: j <- 1..2)],
        quote(do: z(i, j) + z(i, j) == 2 * z(i, j)),
        "complex_constraint"
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

  test "DSL constraint generation with different constraint types mixed" do
    # Create a simple problem
    problem = Dantzig.Problem.new(name: "Test Problem")

    # Add some variables first
    problem =
      Dantzig.Problem.variables(problem, "w", [quote(do: i <- 1..2)], :integer,
        description: "Variable w"
      )

    # Test constraint generation with equality
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2)],
        quote(do: w(i) == 1),
        "eq_constraint"
      )

    # Test constraint generation with <= inequality
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2)],
        quote(do: w(i) <= 10),
        "le_constraint"
      )

    # Test constraint generation with >= inequality
    problem =
      Dantzig.Problem.constraints(
        problem,
        [quote(do: i <- 1..2)],
        quote(do: w(i) >= 0),
        "ge_constraint"
      )

    # Check that constraints were added (2 + 2 + 2 = 6 total)
    assert map_size(problem.constraints) == 6

    # Check constraint names
    constraint_names = Enum.map(problem.constraints, fn {_id, constraint} -> constraint.name end)

    # Debug: print actual names
    IO.puts("Actual constraint names: #{inspect(constraint_names)}")

    # The names should have index values
    assert length(constraint_names) == 6
    assert Enum.all?(constraint_names, &is_binary/1)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 6
  end
end
