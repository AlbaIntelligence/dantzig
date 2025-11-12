# N-Queens Problem Example
#
# BUSINESS CONTEXT:
# The N-Queens problem is a classic combinatorial optimization challenge that originated
# as a chess puzzle: place N queens on an N×N chessboard so that no two queens
# threaten each other. This problem demonstrates constraint satisfaction and
# combinatorial optimization techniques used in scheduling, resource allocation,
# and puzzle solving.
#
# MATHEMATICAL FORMULATION:
# Variables: x_{i,j} = 1 if queen placed at row i, column j, 0 otherwise (binary)
# Constraints:
#   Σ_j x_{i,j} = 1 for each row i (one queen per row)
#   Σ_i x_{i,j} = 1 for each column j (one queen per column)
#   Additional constraints for diagonals (not implemented in this basic version)
# Objective: Maximize Σ_{i,j} x_{i,j} (place as many queens as possible)
#
# DSL SYNTAX HIGHLIGHTS:
# - Generator variables: variables(name, [i <- range, j <- range], :binary)
# - Pattern sums: sum(queen2d(i, :_)) sums over all j for fixed i
# - Wildcard patterns: queen2d(:_, :_) for all variables
# - Constraint generators: constraints([i <- range], expr, description)
# - Binary variables for combinatorial problems
#
# GOTCHAS:
# - Binary variables automatically constrain to 0 or 1
# - Generator indices create variable names like queen2d_1_2
# - Pattern matching uses :_ for "all values of this index"
# - Diagonal constraints are omitted in this basic version
# - N-Queens is NP-complete, so large N may be slow

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

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• N-Queens demonstrates combinatorial constraint satisfaction")
IO.puts("• Binary variables model yes/no placement decisions")
IO.puts("• Generator syntax creates variables and constraints systematically")
IO.puts("• Pattern sums aggregate over wildcard dimensions")
IO.puts("• Real-world applications: scheduling, resource placement, puzzle solving")
IO.puts("• This basic version omits diagonal constraints for simplicity")

IO.puts("")
IO.puts("✅ N-Queens problem examples completed!")
