# N-Queens problem using the new DSL
require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== N-Queens DSL No-index Example ===")

# Create the problem
problem2d_simple =
  Problem.define do
    new(
      name: "2-Queens",
      description: "Place queens on an 2x2 chessboard so that no two queens attack each other."
    )

    # Add binary variables for queen positions (2x2 board)
    variables("queen2d_1_1", :binary, "Queen position")
    variables("queen2d_1_2", :binary, "Queen position")
    variables("queen2d_2_1", :binary, "Queen position")
    variables("queen2d_2_2", :binary, "Queen position")

    # Add constraints: one queen per row
    constraints(queen2d_1_1 + queen2d_1_2 == 1, "One queen per row")
    constraints(queen2d_2_1 + queen2d_2_2 == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints(queen2d_1_1 + queen2d_2_1 == 1, "One queen per column")
    constraints(queen2d_1_2 + queen2d_2_2 == 1, "One queen per column")

    # Set objective (squeeze as many queens as possible)
    objective(queen2d_1_1 + queen2d_1_2 + queen2d_2_1 + queen2d_2_2, direction: :maximize)
  end

{solution, objective} = Problem.solve(problem2d_simple, print_optimizer_input: true)

IO.puts("Created problem: #{problem2d_simple.name}")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem2d_simple.variables)}")
IO.puts("Constraints: #{map_size(problem2d_simple.constraints)}")
IO.puts("Objective: #{inspect(problem2d_simple.objective)}")
IO.puts("Direction: #{inspect(problem2d_simple.direction)}")

IO.puts("")
IO.puts("")
IO.puts("")
IO.puts("=== N-Queens DSL Example ===")

# Create the problem
problem2d =
  Problem.define do
    new(
      name: "N-Queens",
      description: "Place N queens on an N×N chessboard so that no two queens attack each other."
    )

    # Add binary variables for queen positions (4x4 board)
    variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Add constraints: one queen per row
    constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints([j <- 1..4], sum(queen2d(:_, j)) == 1, "One queen per column")

    # Set objective (squeeze as many queens as possible)
    objective(sum(queen2d(:_, :_)), direction: :maximize)
  end

{solution, objective} = Problem.solve(problem2d, print_optimizer_input: true)

IO.puts("Created problem: #{problem2d.name}")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem2d.variables)}")
IO.puts("Constraints: #{map_size(problem2d.constraints)}")
IO.puts("Objective: #{inspect(problem2d.objective)}")
IO.puts("Direction: #{inspect(problem2d.direction)}")

IO.puts("")
IO.puts("")
IO.puts("")
IO.puts("=== N-Queens DSL Example 2 ===")

# Create the problem
problem3d =
  Problem.define do
    new(
      name: "N-Queens",
      description:
        "Place N queens on an N×N×N chessboard so that no two queens attack each other."
    )

    tap(&IO.puts("Created problem: #{&1.name}"))

    # Add binary variables for queen positions (4x4 board)
    variables("queen3d", [i <- 1..4, j <- 1..4, k <- 1..4], :binary, "Queen position")
    tap(&IO.puts("Variables: #{map_size(&1.variables)}"))

    # Add constraints: one queen per row
    constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints([j <- 1..4, k <- 1..4], sum(queen3d(:_, j, k)) == 1, "One queen per column")

    # Add constraints: one queen per vertical
    constraints([i <- 1..4, j <- 1..4], sum(queen3d(i, j, :_)) == 1, "One queen per vertical")
    tap(&IO.puts("Constraints: #{map_size(&1.constraints)}"))

    # Set objective (squeeze as many queens as possible)
    objective(sum(queen3d(:_, :_, :_)), direction: :maximize)
  end

{solution, objective} = Problem.solve(problem3d)

IO.puts("\nProblem summary:")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\n=== N-Queens problem created with DSL! ===")
IO.puts("Note: This example demonstrates the DSL structure.")
IO.puts("Full constraint parsing with patterns is still being implemented.")
