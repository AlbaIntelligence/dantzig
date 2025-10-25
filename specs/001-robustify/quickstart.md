# Quickstart: Robustify Elixir Linear Programming Package

**Feature**: 001-robustify
**Date**: 2024-12-19
**Purpose**: Quick start guide for robustifying the Dantzig package

## Overview

This quickstart guide provides step-by-step instructions for robustifying the Dantzig Elixir Linear Programming package. The robustification effort focuses on three main areas:

1. **Fix Compilation Issues** - Resolve all test compilation errors
2. **Achieve Comprehensive Test Coverage** - Reach 80%+ overall, 85%+ core modules
3. **Enhance Documentation** - Add well-documented examples covering 5+ optimization types

## Prerequisites

- Elixir 1.15+ and OTP 26+
- Mix build tool
- Git for version control
- Basic understanding of linear programming concepts

## Phase 1: Fix Compilation Issues

### Step 1: Identify Compilation Errors

```bash
# Run tests to identify compilation issues
mix test

# Check for specific error patterns
mix compile --warnings-as-errors
```

### Step 2: Fix Test Compilation Errors

**Common Issues and Solutions**:

1. **Undefined Variables in Tests**
   ```elixir
   # Problem: undefined variable "i" in test
   # Solution: Fix variable scope in test generators
   test "chained constraints work correctly" do
     problem = Problem.new()
     |> Problem.constraints([i <- 1..3], x(i) == 1, "row_#{i}")
   end
   ```

2. **Missing Imports**
   ```elixir
   # Problem: undefined function x/1
   # Solution: Add proper imports
   use Dantzig.DSL.Integration
   import Dantzig.DSL.Integration, only: [enable_variable_access: 1]
   ```

3. **Unused Variables**
   ```elixir
   # Problem: variable "description" is unused
   # Solution: Use variable or prefix with underscore
   def constraint(problem, _constraint_expr, _description \\ nil) do
     # Implementation
   end
   ```

### Step 3: Validate Fixes

```bash
# Ensure all tests compile
mix test --compile

# Run specific test categories
mix test test/dantzig/dsl/
mix test test/dantzig/core/
```

## Phase 2: Achieve Test Coverage

### Step 1: Install Coverage Tools

```elixir
# Add to mix.exs
defp deps do
  [
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

### Step 2: Configure Coverage

```elixir
# Add to mix.exs
def project do
  [
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  ]
end
```

### Step 3: Run Coverage Analysis

```bash
# Generate coverage report
mix coveralls

# Generate HTML coverage report
mix coveralls.html

# Check specific module coverage
mix coveralls --module Dantzig.Problem
```

### Step 4: Add Missing Tests

**Target Coverage Requirements**:
- Overall: 80%+
- Core modules: 85%+
  - `Dantzig.Problem`
  - `Dantzig.DSL`
  - `Dantzig.AST`
  - `Dantzig.Solver`

**Test Categories to Add**:

1. **Unit Tests**
   ```elixir
   # test/dantzig/problem_test.exs
   describe "Problem creation" do
     test "creates new problem with direction" do
       problem = Problem.new(direction: :maximize)
       assert problem.direction == :maximize
     end
   end
   ```

2. **Integration Tests**
   ```elixir
   # test/dantzig/dsl/integration_test.exs
   describe "DSL integration" do
     test "creates variables with generators" do
       problem = Problem.new()
       |> Problem.variables("x", [i <- 1..3], :binary)

       assert map_size(problem.variables) > 0
     end
   end
   ```

3. **Edge Case Tests**
   ```elixir
   # test/dantzig/edge_cases_test.exs
   describe "Edge cases" do
     test "handles infeasible problems" do
       problem = create_infeasible_problem()
       {:ok, solution} = Dantzig.solve(problem)
       assert solution.status == :infeasible
     end
   end
   ```

## Phase 3: Enhance Documentation

### Step 1: Document Existing Examples

**Documentation Requirements**:
- Business context explanation
- Mathematical formulation
- DSL syntax explanation
- Common gotchas and pitfalls

**Example Structure**:
```elixir
# examples/diet_problem.exs

# =============================================================================
# DIET PROBLEM - Nutritional Optimization
# =============================================================================
#
# BUSINESS CONTEXT:
# A nutritionist needs to create a meal plan that meets daily nutritional
# requirements while minimizing cost. This is a classic linear programming
# problem that demonstrates constraint modeling and cost optimization.
#
# MATHEMATICAL FORMULATION:
# Minimize: Σ(cost[i] * x[i]) for all foods i
# Subject to:
#   - Σ(nutrients[i,j] * x[i]) >= min_requirements[j] for all nutrients j
#   - Σ(nutrients[i,j] * x[i]) <= max_requirements[j] for all nutrients j
#   - x[i] >= 0 for all foods i
#
# DSL SYNTAX EXPLANATION:
# - variables("food", [food <- foods], :continuous) creates continuous variables
# - constraints([nutrient <- nutrients], sum(...) >= min_req[nutrient]) creates constraints
# - objective(sum(...), direction: :minimize) sets the objective function
#
# COMMON GOTCHAS:
# - Remember to use :continuous for fractional quantities
# - Constraint syntax: sum(food(nutrient)) not sum(food) for nutrient constraints
# - Objective must be linear (no products of variables)
#
# =============================================================================

require Dantzig.Problem, as: Problem

# Food data with nutritional information
foods = [
  %{name: "hamburger", cost: 2.49, calories: 410, protein: 24, fat: 26, sodium: 730},
  %{name: "chicken", cost: 2.89, calories: 420, protein: 32, fat: 10, sodium: 1190},
  # ... more foods
]

# Nutritional requirements
requirements = [
  %{nutrient: "calories", min: 1800, max: 2200},
  %{nutrient: "protein", min: 91, max: :infinity},
  # ... more requirements
]

# Create the optimization problem
problem = Problem.define do
  new(direction: :minimize)

  # Create variables for each food (amount to buy)
  variables("food", [food <- foods], :continuous, min: 0,
    description: "Amount of each food to buy"
  )

  # Nutritional constraints
  constraints([nutrient <- requirements],
    sum(food(nutrient)) >= requirements[nutrient].min,
    "Minimum #{nutrient} requirement"
  )

  # Cost objective
  objective(sum(food * cost), direction: :minimize)
end

# Solve the problem
{:ok, solution} = Dantzig.solve(problem)

# Interpret results
IO.puts("Optimal daily cost: $#{solution.objective_value}")
IO.puts("Food quantities:")
for {food, quantity} <- solution.variables do
  IO.puts("  #{food}: #{quantity} servings")
end
```

### Step 2: Add Classical Examples

**Required Problem Types** (5+ domains):

1. **Diet Problem** - Nutritional optimization
2. **Transportation Problem** - Network flow optimization
3. **Assignment Problem** - Resource allocation
4. **Production Planning** - Manufacturing optimization
5. **Facility Location** - Strategic optimization

**Example Template**:
```elixir
# examples/[problem_name].exs

# =============================================================================
# [PROBLEM NAME] - [Business Domain]
# =============================================================================
#
# BUSINESS CONTEXT: [Real-world application]
# MATHEMATICAL FORMULATION: [Optimization model]
# DSL SYNTAX EXPLANATION: [Syntax and patterns]
# COMMON GOTCHAS: [Pitfalls and solutions]
#
# =============================================================================

# [Implementation with comprehensive documentation]
```

### Step 3: Validate Examples

```bash
# Test all examples execute successfully
for example in examples/*.exs; do
  echo "Testing $example"
  mix run "$example"
done

# Check documentation quality
mix run scripts/validate_examples.exs
```

## Phase 4: Performance Validation

### Step 1: Create Performance Benchmarks

```elixir
# test/performance_benchmark_test.exs
defmodule PerformanceBenchmarkTest do
  use ExUnit.Case

  test "scalability with problem size" do
    for size <- [100, 500, 1000] do
      {time, _result} = :timer.tc(fn ->
        create_and_solve_problem(size)
      end)

      assert time < 30_000_000  # 30 seconds max
      IO.puts("Size #{size}: #{time / 1_000}ms")
    end
  end
end
```

### Step 2: Monitor Memory Usage

```elixir
test "memory usage stays within limits" do
  initial_memory = :erlang.memory(:total)

  problem = create_large_problem(1000)
  {:ok, solution} = Dantzig.solve(problem)

  final_memory = :erlang.memory(:total)
  memory_used = final_memory - initial_memory

  assert memory_used < 100_000_000  # 100MB max
end
```

## Validation Checklist

### Compilation Issues ✅
- [ ] All tests compile without errors
- [ ] No compilation warnings
- [ ] All imports resolved correctly

### Test Coverage ✅
- [ ] Overall coverage >= 80%
- [ ] Core module coverage >= 85%
- [ ] All test categories included (unit, integration, performance)

### Documentation Quality ✅
- [ ] All examples execute successfully
- [ ] Business context explained for each example
- [ ] Mathematical formulation documented
- [ ] DSL syntax explained with gotchas
- [ ] 5+ optimization problem types covered

### Performance ✅
- [ ] Problems up to 1000 variables complete within 30 seconds
- [ ] Memory usage < 100MB for typical problems
- [ ] Scalability benchmarks demonstrate reasonable growth

## Next Steps

After completing the robustification:

1. **Run Full Test Suite**: `mix test --cover`
2. **Validate Examples**: Test all examples execute successfully
3. **Performance Testing**: Run benchmarks with various problem sizes
4. **Documentation Review**: Ensure all examples are well-documented
5. **Release Preparation**: Update version and changelog

## Troubleshooting

### Common Issues

**Compilation Errors**:
- Check variable scope in test generators
- Verify all imports are present
- Fix unused variable warnings

**Coverage Issues**:
- Add tests for uncovered functions
- Include edge case testing
- Test error conditions

**Documentation Issues**:
- Ensure business context is clear
- Explain mathematical concepts
- Document common pitfalls

**Performance Issues**:
- Optimize constraint generation
- Consider problem size limits
- Monitor memory usage patterns

## Resources

- [ExUnit Documentation](https://hexdocs.pm/ex_unit/)
- [ExCoveralls Documentation](https://hexdocs.pm/excoveralls/)
- [Linear Programming Concepts](https://en.wikipedia.org/wiki/Linear_programming)
- [Dantzig Package Documentation](https://hexdocs.pm/dantzig/)
