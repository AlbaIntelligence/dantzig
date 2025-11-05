defmodule MacroApproach.NQueensIntegrationTest do
  use ExUnit.Case

  require Dantzig.Problem, as: Problem

  # Test complete N-Queens example with Problem.define syntax
  test "Complete N-Queens problem with DSL constraint generation" do
    # Create the N-Queens problem using the DSL
    problem =
      Problem.define do
        new(
          name: "N-Queens",
          description:
            "Place N queens on an N×N chessboard so that no two queens attack each other."
        )

        # Add binary variables for queen positions (4x4 board)
        variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

        # Add constraints: one queen per row
        constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row #{i}")

        # Add constraints: one queen per column
        constraints([j <- 1..4], sum(queen2d(:_, j)) == 1, "One queen per column #{j}")

        # Add constraints: one queen per diagonal (main diagonal)
        constraints([i <- 1..4], queen2d(i, i) == 1, "One queen per diagonal #{i}")

        # Add constraints: one queen per anti-diagonal
        constraints([i <- 1..4], queen2d(i, 5 - i) == 1, "One queen per anti-diagonal #{i}")

        # Set objective (maximize total queens)
        objective(sum(queen2d(:_, :_)), :maximize)
      end

    # Check that variables were added (4x4 = 16 variables)
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    assert map_size(queen2d_vars) == 16

    # Check that constraints were added
    # - 4 row constraints
    # - 4 column constraints
    # - 4 main diagonal constraints
    # - 4 anti-diagonal constraints
    # Total: 16 constraints
    assert map_size(problem.constraints) == 16

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # All names should be unique (with proper variable interpolation)
    unique_names = Enum.uniq(constraint_names)
    assert length(unique_names) == 16

    # Check that we have constraints for each type
    row_constraints = Enum.filter(constraint_names, &String.contains?(&1, "One queen per row"))

    column_constraints =
      Enum.filter(constraint_names, &String.contains?(&1, "One queen per column"))

    main_diag_constraints =
      Enum.filter(constraint_names, &String.contains?(&1, "One queen per diagonal"))

    anti_diag_constraints =
      Enum.filter(constraint_names, &String.contains?(&1, "One queen per anti-diagonal"))

    assert length(row_constraints) == 4
    assert length(column_constraints) == 4
    assert length(main_diag_constraints) == 4
    assert length(anti_diag_constraints) == 4

    # Check that objective was set
    assert problem.objective != nil
    assert problem.direction == :maximize
  end

  test "N-Queens problem with 3x3 board" do
    # Create a smaller 3x3 N-Queens problem
    problem =
      Problem.define do
        new(name: "3x3 N-Queens")

        # Add binary variables for queen positions (3x3 board)
        variables("queen2d", [i <- 1..3, j <- 1..3], :binary, "Queen position")

        # Add constraints: one queen per row
        constraints([i <- 1..3], sum(queen2d(i, :_)) == 1, "row_constraint_#{i}")

        # Add constraints: one queen per column
        constraints([j <- 1..3], sum(queen2d(:_, j)) == 1, "column_constraint_#{j}")
      end

    # Check that variables were added (3x3 = 9 variables)
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    assert map_size(queen2d_vars) == 9

    # Check that constraints were added (3 + 3 = 6 constraints)
    assert map_size(problem.constraints) == 6

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 6

    # Check that we have the right number of each type
    row_constraints = Enum.filter(constraint_names, &String.contains?(&1, "row_constraint"))

    column_constraints =
      Enum.filter(constraint_names, &String.contains?(&1, "column_constraint"))

    assert length(row_constraints) == 3
    assert length(column_constraints) == 3
  end

  test "N-Queens problem with sum expressions" do
    # Test N-Queens with sum expressions (more complex)
    problem =
      Problem.define do
        new(name: "N-Queens with Sum")

        # Add binary variables for queen positions (2x2 board for simplicity)
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")

        # Add constraints: one queen per row (using sum)
        constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "row_sum_constraint_#{i}")

        # Add constraints: one queen per column (using sum)
        constraints([j <- 1..2], sum(queen2d(:_, j)) == 1, "column_sum_constraint_#{j}")
      end

    # Check that variables were added (2x2 = 4 variables)
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    assert map_size(queen2d_vars) == 4

    # Check that constraints were added (2 + 2 = 4 constraints)
    assert map_size(problem.constraints) == 4

    # Check constraint names
    constraint_names =
      problem.constraints
      |> Map.values()
      |> Enum.map(& &1.name)

    # All names should be unique
    assert length(Enum.uniq(constraint_names)) == 4
  end
end
