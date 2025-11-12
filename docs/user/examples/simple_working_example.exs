#!/usr/bin/env elixir

# Simple Working Example: Demonstrating the Modern Dantzig DSL
# ==============================================================
#
# This example demonstrates the clean, pattern-based syntax of the Dantzig DSL
# through three classic optimization problems:
# 1. N-Queens Problem (constraint satisfaction)
# 2. Traveling Salesman Problem (TSP) - routing optimization
# 3. Classroom Scheduling Problem (resource allocation)
#
# Each example shows how to:
# - Define variables using pattern-based generators
# - Create constraints with mathematical expressions
# - Use wildcards (:_) for aggregations
# - Access variables using indexed notation
#
# Business Context
# ----------------
# These problems represent common optimization challenges:
#
# - **N-Queens**: Place N queens on an N×N chessboard so no two queens threaten each other.
#   Applications: Resource placement, scheduling conflicts, constraint satisfaction.
#
# - **Traveling Salesman Problem**: Find the shortest route visiting all cities exactly once.
#   Applications: Logistics, route optimization, circuit design, DNA sequencing.
#
# - **Classroom Scheduling**: Assign courses to time slots and rooms without conflicts.
#   Applications: University timetabling, meeting room booking, resource allocation.
#
# Mathematical Formulation
# ------------------------
#
# **N-Queens Problem:**
# - Variables: x[i,j] ∈ {0,1} where x[i,j] = 1 if queen at position (i,j)
# - Constraints:
#   - Row: Σⱼ x[i,j] = 1 for all i (exactly one queen per row)
#   - Column: Σᵢ x[i,j] = 1 for all j (exactly one queen per column)
#   - Diagonal: Σᵢ x[i,i] ≤ 1 (at most one queen per main diagonal)
#   - Anti-diagonal: Σᵢ x[i,5-i] ≤ 1 (at most one queen per anti-diagonal)
#
# **Traveling Salesman Problem:**
# - Variables: x[i,j] ∈ {0,1} where x[i,j] = 1 if edge (i,j) is in tour
# - Constraints:
#   - Outgoing: Σⱼ x[i,j] = 1 for all i (each city has exactly one outgoing edge)
#   - Incoming: Σᵢ x[i,j] = 1 for all j (each city has exactly one incoming edge)
#   - Note: This is a simplified version; full TSP requires subtour elimination
#
# **Classroom Scheduling:**
# - Variables: x[c,t,r] ∈ {0,1} where x[c,t,r] = 1 if course c at time t in room r
# - Constraints:
#   - Course scheduling: Σₜ,ᵣ x[c,t,r] = 1 for all c (each course scheduled once)
#   - No double-booking: Σc x[c,t,r] ≤ 1 for all t,r (at most one course per room-time)
#
# DSL Syntax Explanation
# ----------------------
#
# **Problem Definition:**
#   Problem.define do
#     new(name: "Problem", direction: :minimize)
#     # ... variables and constraints ...
#   end
#
# **Variables:**
#   variables("x", [i <- 1..n], :binary, "Description")
#   - First argument: variable name (string)
#   - Second argument: generator pattern (comprehension syntax)
#   - Third argument: variable type (:binary, :continuous, :integer)
#   - Fourth argument: description (optional)
#
# **Constraints:**
#   constraints([i <- 1..n], expression == value, "Description")
#   - First argument: generator pattern for constraint indices
#   - Second argument: mathematical expression (using ==, <=, >=)
#   - Third argument: constraint description
#
# **Variable Access:**
#   x(i)        - Single index variable
#   x(i, j)     - Multi-index variable
#   x(i, :_)    - Sum over all values of second index
#   x(:_, j)    - Sum over all values of first index
#   x(:_, :_)   - Sum over all indices
#
# **Aggregations:**
#   sum(x(i, :_)) - Sum of x[i,j] over all j
#   max(x(i))     - Maximum value of x[i]
#   min(x(i))     - Minimum value of x[i]
#
# Common Gotchas
# --------------
#
# 1. **Wildcard Position Matters:**
#    - x(i, :_) sums over the second index
#    - x(:_, j) sums over the first index
#    - Order matters when using multiple wildcards
#
# 2. **Generator Patterns:**
#    - Use [i <- 1..n] for ranges
#    - Use [i <- list] for explicit lists
#    - Variables in generators are available in expressions
#
# 3. **Constraint Descriptions:**
#    - Always provide meaningful descriptions for debugging
#    - Descriptions help identify which constraint failed
#
# 4. **Variable Types:**
#    - :binary: 0 or 1 (for yes/no decisions)
#    - :continuous: any real number (for continuous optimization)
#    - :integer: whole numbers (for discrete optimization)
#
# 5. **Indexing:**
#    - Variable indices match generator order
#    - x(c, t, r) means course c, time t, room r
#    - Access order must match definition order
#
# 6. **Equality vs Inequality:**
#    - Use == for exact constraints (exactly one, exactly equal)
#    - Use <= or >= for bounds (at most, at least)
#
# 7. **Problem Size:**
#    - Large problems may be slow to solve
#    - Binary variables can make problems NP-hard
#    - Consider problem size when designing constraints

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# ============================================================================
# Example 1: N-Queens Problem
# ============================================================================
#
# Problem: Place 4 queens on a 4×4 chessboard so that no two queens
# threaten each other (no two queens share a row, column, or diagonal).
#
# Business Context: This is a classic constraint satisfaction problem
# used in resource allocation, scheduling, and combinatorial optimization.
#
# Variables: x[i,j] = 1 if a queen is placed at position (i,j), 0 otherwise
# Constraints:
#   - Exactly one queen per row (constraint satisfaction)
#   - Exactly one queen per column (no column conflicts)
#   - At most one queen per diagonal (no diagonal conflicts)
#
IO.puts("=== N-Queens Problem ===")

# Create a new problem using the DSL
# The 'new' statement initializes the problem with a name and optimization direction
problem =
  Problem.define do
    new(name: "N-Queens", description: "N-Queens problem using DSL", direction: :minimize)

    # Create binary variables: x[i,j] = 1 if queen is placed at position (i,j)
    # Pattern: [i <- 1..4, j <- 1..4] creates variables for all combinations
    # Type: :binary means each variable can only be 0 or 1
    variables("x", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Constraint: exactly one queen per row
    # For each row i, the sum of x[i,j] over all columns j must equal 1
    # The wildcard :_ means "sum over all values of this index"
    constraints([i <- 1..4], sum(x(i, :_)) == 1, "One queen per row")

    # Constraint: exactly one queen per column
    # For each column j, the sum of x[i,j] over all rows i must equal 1
    constraints([j <- 1..4], sum(x(:_, j)) == 1, "One queen per column")

    # Constraint: at most one queen per diagonal (main diagonal)
    # For the main diagonal, sum x[i,i] over all i must be at most 1
    # Note: This is a simplified diagonal constraint for demonstration
    constraints([i <- 1..4], sum(x(i, i)) <= 1, "At most one queen per main diagonal")

    # Constraint: at most one queen per anti-diagonal
    # For the anti-diagonal, sum x[i,5-i] over all i must be at most 1
    constraints([i <- 1..4], sum(x(i, 5 - i)) <= 1, "At most one queen per anti-diagonal")
  end

# Verify problem structure
# Check that we have 16 variables (4 rows × 4 columns)
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("Created #{map_size(var_map)} variables")

# Check that all combinations are present
expected_keys = for i <- 1..4, j <- 1..4, do: {i, j}
actual_keys = Map.keys(var_map) |> Enum.sort()
IO.puts("Expected keys: #{inspect(expected_keys)}")
IO.puts("Actual keys: #{inspect(actual_keys)}")
IO.puts("Keys match: #{expected_keys == actual_keys}")

# Check that we have constraints
IO.puts("Created #{map_size(problem.constraints)} constraints")

# ============================================================================
# Example 2: Traveling Salesman Problem (TSP)
# ============================================================================
#
# Problem: Find the shortest route that visits each city exactly once
# and returns to the starting city.
#
# Business Context: TSP is fundamental to logistics, route optimization,
# and many other real-world problems involving path finding.
#
# Variables: x[i,j] = 1 if edge (i,j) is used in the tour, 0 otherwise
# Constraints:
#   - Each city has exactly one outgoing edge (must leave each city once)
#   - Each city has exactly one incoming edge (must arrive at each city once)
#
# Note: This is a simplified TSP formulation. A complete solution would
# require subtour elimination constraints to prevent disconnected cycles.
#
IO.puts("\n=== Traveling Salesman Problem ===")

# Define cities as a list (could be city names, IDs, etc.)
cities = [1, 2, 3]

problem2 =
  Problem.define do
    new(name: "TSP", description: "Traveling Salesman Problem", direction: :minimize)

    # Variables: x[i,j] = 1 if edge (i,j) is used in the tour
    # Pattern: [i <- cities, j <- cities] creates variables for all city pairs
    # Note: In a full TSP, you might want to exclude self-loops (i != j)
    variables("x", [i <- cities, j <- cities], :binary, "Edge used")

    # Constraint: each city has exactly 2 edges (incoming and outgoing)
    # Outgoing: sum of x[i,j] over all j must equal 1 for each city i
    constraints([i <- cities], sum(x(i, :_)) == 1, "Outgoing edges")

    # Incoming: sum of x[i,j] over all i must equal 1 for each city j
    constraints([i <- cities], sum(x(:_, i)) == 1, "Incoming edges")
  end

# Verify problem structure
# Check that we have 9 variables (3 cities × 3 cities)
var_map2 = Problem.get_variables_nd(problem2, "x")
IO.puts("Created #{map_size(var_map2)} variables for TSP")

# Check that we have constraints
IO.puts("Created #{map_size(problem2.constraints)} constraints for TSP")

# ============================================================================
# Example 3: Classroom Scheduling Problem
# ============================================================================
#
# Problem: Assign courses to time slots and rooms such that:
# - Each course is scheduled exactly once
# - No room is double-booked (at most one course per room-time slot)
#
# Business Context: Resource allocation problems like scheduling are common
# in universities, event planning, and resource management systems.
#
# Variables: x[c,t,r] = 1 if course c is scheduled at time t in room r
# Constraints:
#   - Course scheduling: each course must be scheduled exactly once
#   - No double-booking: at most one course per room-time combination
#
IO.puts("\n=== Classroom Scheduling ===")

# Define problem dimensions
courses = [1, 2]      # Course IDs
times = [1, 2, 3]     # Time slot IDs
rooms = [1, 2]        # Room IDs

problem3 =
  Problem.define do
    new(name: "Scheduling", description: "Classroom Scheduling Problem", direction: :minimize)

    # Variables: x[c,t,r] = 1 if course c is scheduled at time t in room r
    # Pattern: [c <- courses, t <- times, r <- rooms] creates 3D variable array
    # Total variables: 2 courses × 3 times × 2 rooms = 12 variables
    variables("x", [c <- courses, t <- times, r <- rooms], :binary, "Course schedule")

    # Constraint: each course scheduled exactly once
    # For each course c, sum over all times t and rooms r must equal 1
    # The double wildcard :_ means "sum over all values of these indices"
    constraints([c <- courses], sum(x(c, :_, :_)) == 1, "Course scheduled once")

    # Constraint: no room double-booking
    # For each time t and room r, at most one course can be scheduled
    # Sum over all courses c must be at most 1
    constraints([t <- times, r <- rooms], sum(x(:_, t, r)) <= 1, "No room double-booking")
  end

# Verify problem structure
# Check that we have 12 variables (2 courses × 3 times × 2 rooms)
var_map3 = Problem.get_variables_nd(problem3, "x")
IO.puts("Created #{map_size(var_map3)} variables for scheduling")

# Check that we have constraints
IO.puts("Created #{map_size(problem3.constraints)} constraints for scheduling")

IO.puts("\n=== All examples completed successfully! ===")
