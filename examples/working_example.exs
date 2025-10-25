# Working example demonstrating the modern Dantzig DSL
# This shows the clean syntax for creating variables and constraints

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Example 1: N-Queens Problem
IO.puts("=== N-Queens Problem ===")

# Create a new problem using the DSL
problem =
  Problem.define do
    new(name: "N-Queens", description: "N-Queens problem using DSL", direction: :minimize)

    # Create variables: x[i,j] = 1 if queen is placed at position (i,j)
    variables("x", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Constraint: exactly one queen per row
    constraints([i <- 1..4], sum(x(i, :_)) == 1, "One queen per row")

    # Constraint: exactly one queen per column
    constraints([j <- 1..4], sum(x(:_, j)) == 1, "One queen per column")

    # Objective: minimize total number of queens (should be 4)
    objective(sum(x(:_, :_)), direction: :minimize)
  end

# Check that we have 16 variables (4 * 4)
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("Created #{map_size(var_map)} variables")

# Check that all combinations are present
expected_keys = for i <- 1..4, j <- 1..4, do: {i, j}
actual_keys = Map.keys(var_map) |> Enum.sort()
IO.puts("Expected keys: #{inspect(expected_keys)}")
IO.puts("Actual keys: #{inspect(actual_keys)}")
IO.puts("Keys match: #{expected_keys == actual_keys}")

# Check that we have 8 constraints total (4 rows + 4 columns)
IO.puts("Total constraints: #{map_size(problem.constraints)}")

IO.puts("\n=== Traveling Salesman Problem ===")

# Example 2: TSP using DSL
cities = 1..3

problem2 =
  Problem.define do
    new(name: "TSP", description: "Traveling Salesman Problem", direction: :minimize)

    variables("x", [i <- cities, j <- cities], :binary, "Edge used")

    constraints([i <- cities], sum(x(i, :_)) == 1, "Outgoing edges")
    constraints([i <- cities], sum(x(:_, i)) == 1, "Incoming edges")
  end

var_map2 = Problem.get_variables_nd(problem2, "x")
IO.puts("Created #{map_size(var_map2)} variables for TSP")
IO.puts("Created #{map_size(problem2.constraints)} constraints for TSP")

IO.puts("\n=== Classroom Scheduling ===")

# Example 3: Classroom Scheduling using DSL
courses = 1..2
times = 1..3
rooms = 1..2

problem3 =
  Problem.define do
    new(
      name: "Classroom Scheduling",
      description: "Course scheduling problem",
      direction: :minimize
    )

    variables("x", [c <- courses, t <- times, r <- rooms], :binary, "Course schedule")

    # Constraint: each course scheduled exactly once
    constraints([c <- courses], sum(x(c, :_, :_)) == 1, "Course scheduled once")

    # Constraint: no room double-booking
    constraints([t <- times, r <- rooms], sum(x(:_, t, r)) <= 1, "No room double-booking")
  end

# Check that we have 12 variables (2 * 3 * 2)
var_map3 = Problem.get_variables_nd(problem3, "x")
IO.puts("Created #{map_size(var_map3)} variables for scheduling")
IO.puts("Created #{map_size(problem3.constraints)} constraints for scheduling")

IO.puts("\n=== All examples completed successfully! ===")
