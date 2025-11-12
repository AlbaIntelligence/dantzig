#!/usr/bin/env elixir

# Working Example - Multiple Problem Types
# =========================================
#
# This example demonstrates the modern Dantzig DSL through three classic optimization
# problems: N-Queens, Traveling Salesman Problem (TSP), and Classroom Scheduling.
# Each example showcases different DSL features including binary variables, pattern-based
# constraints, and multi-dimensional variable generation.
#
# BUSINESS CONTEXT:
# This file contains three distinct optimization problems that demonstrate different
# aspects of the DSL:
#
# 1. **N-Queens Problem**: Place N queens on an N×N chessboard such that no two queens
#    attack each other. This is a classic constraint satisfaction problem used in
#    artificial intelligence, scheduling, and resource allocation.
#
# 2. **Traveling Salesman Problem (TSP)**: Find the shortest route that visits each
#    city exactly once and returns to the starting city. Fundamental to logistics,
#    route planning, and network optimization.
#
# 3. **Classroom Scheduling**: Assign courses to time slots and rooms such that each
#    course is scheduled exactly once and no room is double-booked. Common in
#    educational institutions and event planning.
#
# Real-world applications:
# - N-Queens: Resource allocation, scheduling conflicts, constraint satisfaction
# - TSP: Delivery routes, circuit board design, DNA sequencing
# - Classroom Scheduling: University timetabling, conference room booking, event planning
#
# MATHEMATICAL FORMULATION:
#
# **N-Queens Problem:**
# Variables: x[i,j] ∈ {0,1} where x[i,j] = 1 if queen is placed at position (i,j)
# Constraints:
#   - One queen per row: Σj x[i,j] = 1 for all rows i
#   - One queen per column: Σi x[i,j] = 1 for all columns j
#   - No diagonal attacks: (handled implicitly in full N-Queens, simplified here)
# Objective: Minimize total queens (should equal N)
#
# **Traveling Salesman Problem:**
# Variables: x[i,j] ∈ {0,1} where x[i,j] = 1 if edge from city i to city j is used
# Constraints:
#   - Outgoing edges: Σj x[i,j] = 1 for all cities i (exactly one outgoing edge)
#   - Incoming edges: Σi x[i,j] = 1 for all cities j (exactly one incoming edge)
#   - Subtour elimination: (simplified version shown, full TSP requires additional constraints)
# Objective: Minimize total travel distance (not shown in this example)
#
# **Classroom Scheduling:**
# Variables: x[c,t,r] ∈ {0,1} where x[c,t,r] = 1 if course c is scheduled at time t in room r
# Constraints:
#   - Each course scheduled once: Σt Σr x[c,t,r] = 1 for all courses c
#   - No room double-booking: Σc x[c,t,r] <= 1 for all times t and rooms r
# Objective: Minimize conflicts or maximize utilization (not shown in this example)
#
# DSL SYNTAX EXPLANATION:
# - Multi-dimensional variables: variables("x", [i <- 1..4, j <- 1..4], :binary, ...)
#   creates variables for all combinations using nested generators. Order matters.
# - Wildcard syntax in constraints: sum(x(i, :_)) sums over all values of the second
#   dimension, sum(x(:_, j)) sums over all values of the first dimension.
# - Double wildcards: sum(x(:_, :_)) sums over all dimensions (all variables).
# - Range generators: [i <- 1..4] creates variables for i = 1, 2, 3, 4.
# - Binary variables: :binary type restricts variables to 0 or 1.
# - Pattern-based constraints: constraints([i <- 1..4], ...) creates one constraint
#   per value of i using generator syntax.
# - Three-dimensional variables: [c <- courses, t <- times, r <- rooms] creates
#   variables for all combinations of courses, times, and rooms.
# - Triple wildcards: sum(x(c, :_, :_)) sums over times and rooms for a given course.
#
# COMMON GOTCHAS:
# 1. **Generator Order**: The order of generators in [i <- ..., j <- ...] matters.
#    The first generator is the outer loop, subsequent generators are nested.
# 2. **Wildcard Position**: sum(x(i, :_)) sums over the second dimension, while
#    sum(x(:_, j)) sums over the first dimension. Position corresponds to generator order.
# 3. **Binary Variables**: Binary variables are automatically constrained to {0,1}.
#    No need to add explicit bounds.
# 4. **Constraint Generators**: constraints([i <- 1..4], ...) creates multiple constraints,
#    one for each value of i. This is pattern-based constraint generation.
# 5. **Multi-dimensional Access**: Variables are accessed as x(i, j) or x(c, t, r) in
#    expressions. The number of arguments must match the number of generators.
# 6. **Range vs List**: [i <- 1..4] uses a range, [i <- cities] uses a list. Both work,
#    but ranges are more concise for consecutive integers.
# 7. **Simplified Examples**: These examples show basic constraint structures. Full
#    N-Queens requires diagonal constraints, full TSP requires subtour elimination.
# 8. **Variable Count**: The total number of variables equals the product of generator
#    sizes. For [i <- 1..4, j <- 1..4], there are 4 × 4 = 16 variables.
# 9. **Objective Syntax**: Use direction: :minimize or :maximize in objective() call,
#    or as a keyword argument in new() for the default direction.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Example 1: N-Queens Problem
# ============================
# This example demonstrates binary variables, multi-dimensional variable generation,
# and pattern-based constraints using wildcard syntax.
IO.puts("=== N-Queens Problem ===")

# Create a new problem using the DSL
problem =
  Problem.define do
    new(name: "N-Queens", description: "N-Queens problem using DSL", direction: :minimize)

    # Create variables: x[i,j] = 1 if queen is placed at position (i,j)
    # Note: [i <- 1..4, j <- 1..4] creates 16 binary variables (4×4 grid)
    # The order matters: i is the row, j is the column
    variables("x", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Constraint: exactly one queen per row
    # Note: sum(x(i, :_)) uses wildcard to sum over all columns j for row i
    # This creates 4 constraints, one for each row
    constraints([i <- 1..4], sum(x(i, :_)) == 1, "One queen per row")

    # Constraint: exactly one queen per column
    # Note: sum(x(:_, j)) uses wildcard to sum over all rows i for column j
    # This creates 4 constraints, one for each column
    constraints([j <- 1..4], sum(x(:_, j)) == 1, "One queen per column")

    # Objective: minimize total number of queens (should be 4)
    # Note: sum(x(:_, :_)) uses double wildcard to sum over all variables
    # In a valid solution, this should equal 4 (one queen per row/column)
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
# =========================================
# This example demonstrates three-dimensional variables and complex constraint patterns
# for scheduling problems with multiple resource dimensions.
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

    # Variables: x[c,t,r] = 1 if course c is scheduled at time t in room r
    # Note: Three nested generators create 2 × 3 × 2 = 12 variables
    # Order: course (c), time (t), room (r)
    variables("x", [c <- courses, t <- times, r <- rooms], :binary, "Course schedule")

    # Constraint: each course scheduled exactly once
    # Note: sum(x(c, :_, :_)) uses double wildcard to sum over times and rooms
    # for a given course c. This ensures each course has exactly one time-slot-room assignment.
    constraints([c <- courses], sum(x(c, :_, :_)) == 1, "Course scheduled once")

    # Constraint: no room double-booking
    # Note: sum(x(:_, t, r)) sums over all courses for a given time t and room r.
    # Using <= 1 ensures at most one course can use a room at a given time.
    # The generator [t <- times, r <- rooms] creates one constraint per time-room pair.
    constraints([t <- times, r <- rooms], sum(x(:_, t, r)) <= 1, "No room double-booking")
  end

# Check that we have 12 variables (2 * 3 * 2)
var_map3 = Problem.get_variables_nd(problem3, "x")
IO.puts("Created #{map_size(var_map3)} variables for scheduling")
IO.puts("Created #{map_size(problem3.constraints)} constraints for scheduling")

IO.puts("\n=== All examples completed successfully! ===")
