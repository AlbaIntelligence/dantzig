# Test file for basic DSL functionality
# This file tests the new Problem.variables/constraints/objective functions
# Using the modern clean DSL syntax

require Dantzig.Problem, as: Problem

IO.puts("=== Testing Basic DSL Functions ===")

problem =
  Problem.define do
    # Test 1: Simple variable creation using modern DSL syntax
    new(name: "Test Problem")
  end

problem =
  Problem.modify problem do
    # Use the modern clean DSL syntax
    variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variables")
  end

IO.puts("Created problem: #{problem.name}")
IO.puts("Variables: #{map_size(problem.variables)}")

# Test 2: Simple constraints using modern DSL syntax
problem =
  Problem.modify problem do
    constraints([i <- 1..2], x(i, :_) == 1, "Test constraint")
  end

IO.puts("Constraints: #{map_size(problem.constraints)}")

# Test 3: Simple objective using modern DSL syntax
problem =
  Problem.modify problem do
    objective(sum(x(:_, :_)), direction: :minimize)
  end

IO.puts("Objective set successfully")
IO.puts("Direction: #{problem.direction}")

IO.puts("\n=== Basic DSL Test Completed Successfully! ===")
