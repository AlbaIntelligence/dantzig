# DSL Syntax Reference

**GOLDEN REFERENCE - DO NOT MODIFY WITHOUT EXPLICIT APPROVAL**

This document serves as the **canonical, unbreakable reference** for Dantzig DSL syntax. All implementations must support the syntax patterns documented here exactly as specified.

## Source of Truth

This reference is based on:

1. **`test/dantzig/dsl/experimental/simple_generator_test.exs`** - Marked as golden syntax
2. **`examples/nqueens_dsl.exs`** - Marked as golden syntax

## Core DSL Syntax

### Problem Definition

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")
  # ... variables, constraints, objectives
end
```

### Variable Creation

#### Basic Variables (No Generators)

```elixir
problem = Problem.define do
  # new(...)
  variables("var_name", :binary, "Description")
  variables("var_name", :continuous, "Description")
end
```

#### Generator Variables (Single Dimension)

```elixir
problem = Problem.define do
  # new(...)
  # Using literal lists
  variables("qty", [food <- ["bread", "milk"]], :continuous, "Amount of food")
end
```

```elixir
food_names = ["bread", "milk"]

problem = Problem.define do
  # new(...)
  # Using variables from outer scope
  variables("qty", [food <- food_names], :continuous, "Amount of food")
end
```

#### Generator Variables (Multiple Dimensions)

```elixir
# 2D variables
problem = Problem.define do
  new(name: "2D Example", description: "2D variables example")
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
end
```

```elixir
# 3D variables
problem = Problem.define do
  new(name: "3D Example", description: "3D variables example")
  variables("queen3d", [i <- 1..4, j <- 1..4, k <- 1..4], :binary, "Queen position")
end
```

#### Variables - Adding variables to a problem

When adding one or several variables outside a `Problem.define` block to an existing problem, we use `add_variables()` instead of `variables()`.

The following 2 examples should behave the same way and should produce the same result.

```elixir
# Defining variables within the problem definition
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
  variables("x", [i <- 1..4], :binary, "X variables")
  variables("y", [i <- 1..4], :binary, "Y variables")
end
```

```elixir
# 2D variables
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
  variables("x", [i <- 1..4], :binary, "X variables")
end

problem = Problem.add_variables(problem, "y", [i <- 1..4], :binary, "Y variables")
```

Note that we internally transform the former syntax to the latter syntax when adding variables to a problem.

### Constraint Creation

#### Simple Constraints (No Generators)

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  constraints(queen2d_1_1 + queen2d_1_2 == 1, "One queen per row")
end
```

#### Generator Constraints

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Single generator
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")

  # Multiple generators
  constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen per row")
end
```

#### Generator Constraints with naming constraints using indices

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Single generator
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen on row #{i}")

  # Multiple generators
  constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen on first axis #{i} and 3rd axis #{k}")
end
```

#### Constraints - Adding constraints to a problem

When adding one or several constraints outside a `Problem.define` block to an existing problem, we use `add_constraints()` instead of `constraints()`.
The following 2 examples should behave the same way and should produce the same result.

```elixir
# Defining constraints within the problem definition
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Single generator
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")

  # Multiple generators
  constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen on first axis #{i} and 3rd axis #{k}")
end
```

```elixir
problem = Problem.define do

  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Single generator
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")
end

problem = Problem.add_constraints(
  problem,
  [i <- 1..4, k <- 1..4],
  sum(queen3d(i, :_, k)) == 1,
  "One queen on first axis #{i} and 3rd axis #{k}"
)
```

### Objective Functions

#### Simple Objectives

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  objective(queen2d_1_1 + queen2d_1_2 + queen2d_2_1 + queen2d_2_2, direction: :maximize)
end
```

#### Generator Objectives

##### Single Generator

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Using sum with patterns
  objective(sum(queen2d(:_, :_)), direction: :maximize)
end
```

Note that a define block can only contain one objective function.

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Using sum with patterns
  objective(sum(queen2d(:_, :_)), direction: :maximize)

  # Add another objective
  objective(sum(queen2d(:_, :_)), direction: :maximize) # <-- This triggers an error even if the objective is identical.>
end
```

But an objective can always be set outside a `Problem.define` block with `Problem.set_objective()`. If there was a previously existing objective, only a warning is triggered, not an error.

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
end

# First definition of an objective (none specified in the `Problem.define()` block)
problem = Problem.set_objective(
  problem,
  sum(queen2d(:_, :_)),
  direction: :maximize
)

# Specify a replacement objective (there is an existing one)
problem = Problem.set_objective(
  problem,
  sum(queen2d(:_, :_)),
  direction: :maximize
) # <-- This triggers a warning about redefining the problem objective

```

##### Multiple Generators

The following 3 examples should be supported and should produce the same result:

```elixir
problem = Problem.define do
  # new(...)
  variables("qty", [food <- food_names], :continuous, "Amount of food")

  # Using sum with patterns
  objective(sum(qty(food)), direction: :minimize)
end
```

```elixir
problem = Problem.define do
  # new(...)
  variables("qty", [food <- food_names], :continuous, "Amount of food")

  # Using for comprehensions
  objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
end
```

```elixir
problem = Problem.define do
  # new(...)
  variables("qty", [food <- food_names], :continuous, "Amount of food")
end

# Using for comprehensions
problem = Problem.set_objective(
  problem,
  sum(for food <- food_names, do: qty(food)),
  direction: :minimize
)
```

##### Generator redefinition

In the following example, the second definition of "queen2d" should trigger an error and should not be allowed. An error message should be generated indicating that that redefining a variable is not allowed and the problem should not be created.

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position") # <--- THIS TRIGGERS AN ARROR>
end
```

Note that the following would bo OK as the final generated variable names have different indices (and actual name in the problem definition).

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  variables("queen2d", [i <- 5..8, j <- 5..8], :binary, "Queen position") # <--- THIS DOES NOT TRIGGER AN ERROR
  variables("queen2d", [i <- 1..4, j <- 5..8], :binary, "Queen position") # <--- THIS DOES NOT TRIGGER AN ERROR
  variables("queen2d", [i <- 5..8, j <- 1..4], :binary, "Queen position") # <--- THIS DOES NOT TRIGGER AN ERROR
```

## Complete Working Examples

### Example 1: Simple Generator (Golden Reference)

```elixir
defmodule Dantzig.DSL.SimpleGeneratorTest do
  @moduledoc """
  The syntax in this module is _golden_.
  It should be considered the canonical way to write generator syntax.
  """

  test "Simple generator syntax" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end

  test "Generator with objective" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
```

### Example 2: N-Queens Problem

```elixir
# N-Queens problem using the new DSL
require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

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
```

## Key Syntax Rules

### 1. Generator Syntax

- **Format**: `[variable <- list]`
- **Multiple dimensions**: `[i <- 1..4, j <- 1..4]`
- **Outer scope variables**: Must be supported (e.g., `[food <- food_names]`)
- **Literal lists**: Must be supported (e.g., `[food <- ["bread", "milk"]]`)

### 2. Variable Access

- **Pattern matching**: `queen2d(i, :_)` for row sums
- **Pattern matching**: `queen2d(:_, j)` for column sums
- **All variables**: `queen2d(:_, :_)` for total sum

### 3. Sum Functions

- **Pattern sums**: `sum(queen2d(i, :_))`
- **For comprehensions**: `sum(for food <- food_names, do: qty(food))`
- **All variables**: `sum(queen2d(:_, :_))`

### 4. Constraint Descriptions

- **Static**: `"One queen per row"`
- **Dynamic**: Must support variable interpolation in constraint names

## Implementation Requirements

The DSL implementation MUST support:

1. **Outer scope variables** in generators: `[food <- food_names]`
2. **Literal lists** in generators: `[food <- ["bread", "milk"]]`
3. **Range syntax**: `[i <- 1..4, j <- 1..4]`
4. **Pattern matching** in variable access: `queen2d(i, :_)`
5. **Sum functions** with patterns: `sum(queen2d(i, :_))`
6. **For comprehensions** in objectives: `sum(for food <- food_names, do: qty(food))`

## Error Cases

The following are NOT currently supported or should be clearly documented as limitations:

1. **Nested generators** beyond the documented patterns
2. **Complex expressions** in generator lists that cannot be evaluated at compile time
3. **Dynamic constraint names** that cannot be resolved at compile time

## Testing Requirements

All syntax patterns in this reference must:

1. **Compile without errors**
2. **Execute successfully**
3. **Produce expected results**
4. **Be covered by tests**

## Troubleshooting

### Common DSL Errors

*Content to be added as we encounter issues during implementation*

### Debugging DSL Issues

*Content to be added as we encounter issues during implementation*

### Migration from Old Syntax

*Content to be added as we encounter issues during implementation*

### Best Practices

*Content to be added as we encounter issues during implementation*

## Version History

- **v1.0** - Initial reference based on golden test file and nqueens example
- **Future changes** - Must be explicitly approved and documented

---

**REMINDER: This is the GOLDEN REFERENCE. Do not modify without explicit approval.**
