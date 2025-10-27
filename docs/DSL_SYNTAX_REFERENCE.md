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

### Problem change

Once a problem has been defined, it can be amended with new variables, constraints, and objectives.

```elixir
problem = Problem.modify(problem) do
  # .new variables, constraints, objectives
end
```

### Variable Creation

#### Basic Variables (No Generators)

##### Definition in a single block

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")

  # variables/3 takes a variable name, a type and a description
  variables("var_name", :binary, "Description")
  variables("var_name", :continuous, "Description")
end
```

##### Definition in a separate block

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")
end

problem = Problem.modify(problem) do
  variables("var_name", :binary, "Description")
  variables("var_name", :continuous, "Description")
end
```

#### Generator Variables (Single Dimension)

##### Definition in a single block

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")

  # Using literal lists
  # variables/4 takes a variable name, a list of generators, a type and a description
  # It would generate a list of variables/3 for each combination of the generators
  # For example, if food_names = ["bread", "milk"], it would generate:
  # variables("qty_bread", :continuous, "Amount of bread")
  # variables("qty_milk", :continuous, "Amount of milk")
  variables("qty", [food <- ["bread", "milk"]], :continuous, "Amount of food")
end
```

##### Definition in a separate block

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")
end

problem = Problem.modify(problem) do
  # variables/4 takes a variable name, a list of generators, a type and a description
  variables("qty", [food <- ["bread", "milk"]], :continuous, "Amount of food")
end

```

##### Definition of a model providing parameters as a map

```elixir
modelParameters = %{food_names: ["bread", "milk"]}

problem = Problem.define(model_parameters: model_parameters) do
  new(name: "Problem Name", description: "Problem description")
  variables("qty", [food <- food_names], :continuous, "Amount of food")
end
```

or, equivalently in mutiple blocks:

```elixir
problem = Problem.define do
  new(name: "Problem Name", description: "Problem description")
end

modelParameters = %{food_names: ["bread", "milk"]}
problem = Problem.modify(problem, model_parameters: model_parameters) do
  variables("qty", [food <- food_names], :continuous, "Amount of food")
end
```

#### Generator Variables (Multiple Dimensions)

```elixir
# 2D variables
problem = Problem.define do
  new(name: "2D Example", description: "2D variables example")
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  # It would generate 16 variables/3 like:
  # variables("queen2d_1_1", :binary, "Queen position 1,1")
  # variables("queen2d_1_2", :binary, "Queen position 1,2")
  # ...
  # variables("queen2d_4_4", :binary, "Queen position 4,4")
end
```

```elixir
# 3D variables
problem = Problem.define do
  new(name: "3D Example", description: "3D variables example")
  variables("queen3d", [i <- 1..4, j <- 1..4, k <- 1..4], :binary, "Queen position")
end
```

##### Definition using a model parameters map

```elixir
modelParameters = %{max_i: 4, max_j: 4, max_k: 4}

problem = Problem.define(model_parameters: model_parameters) do
  new(name: "3D Example", description: "3D variables example")
  variables("queen3d", [i <- 1..max_i, j <- 1..max_j, k <- 1..max_k], :binary, "Queen position")
  # It would generate max_i x max_j x max_k variables/3 statements like:
  # variables("queen3d_1_1_1", :binary, "Queen position 1,1,1")
  # variables("queen3d_1_1_2", :binary, "Queen position 1,1,2")
  # ...
  # variables("queen3d_1_1_#{max_k}", :binary, "Queen position 1,1,#{max_k}")
  # variables("queen3d_1_2_1", :binary, "Queen position 1,2,1")
  # ...
  # variables("queen3d_1_2_#{max_k}", :binary, "Queen position 1,2,#{max_k}")
  # variables("queen3d_1_3_1", :binary, "Queen position 1,3,1")
  # ...
  # variables("queen3d_1_#{max_j}_#{max_k}", :binary, "Queen position 1,#{max_j},#{max_k}")
  # ...
  # variables("queen3d_#{max_i}_#{max_j}_#{max_k}", :binary, "Queen position #{max_i},#{max_j},#{max_k}")
end
```

#### Variables - Adding variables to a problem

When adding one or several variables outside a `Problem.define` block to an existing problem, we use 2 approaches:

- use a `Problem.modify` block with `variables()` as above.
- use `Problem.add_variable()` one by one outside of a block. In this case, there cannot be any generators

The following 2 examples should behave the same way and should produce the same result.

##### Approach 1: Using a `Problem.modify` block

```elixir
# Defining variables within the problem definition
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
end

problem = Problem.modify(problem) do
  variables("x", [i <- 1..4], :binary, "X variables")
  variables("y", [i <- 1..4], :binary, "Y variables")
end
```

##### Approach 2: Using `Problem.add_variable()` one by one

```elixir
# 2D variables
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
  variables("x", [i <- 1..4], :binary, "X variables")
end

problem = Problem.add_variable(problem, "y_1", :binary, "Y variables 1")
problem = Problem.add_variable(problem, "y_2", :binary, "Y variables 2")
problem = Problem.add_variable(problem, "y_3", :binary, "Y variables 3")
problem = Problem.add_variable(problem, "y_4", :binary, "Y variables 4")
```

Note that we internally transform the former syntax to the latter syntax when adding variables to a problem.

### Constraint Creation

#### Simple Constraints (No Generators)

```elixir
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")

  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # constraints/2 takes a constraint and a description
  constraints(queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4 == 1, "One queen per row 1")
  constraints(queen2d_2_1 + queen2d_2_2 + queen2d_2_3 + queen2d_2_4 == 1, "One queen per row 2")
  constraints(queen2d_3_1 + queen2d_3_2 + queen2d_3_3 + queen2d_3_4 == 1, "One queen per row 3")
  constraints(queen2d_4_1 + queen2d_4_2 + queen2d_4_3 + queen2d_4_4 == 1, "One queen per row 4")
end
```

#### Constraint with automatic indexing

With numerical ranges:

```elixir
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")

  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # constraints/2 takes a constraint and a description
  # :_ is a wildcard for any value of anindex
  # In this case,
  #   sum(queen2d(:_, :_)) means something like:
  #   1) create a list of all possible indices:
  #      listIndices = list of tuples (i, j) where i and j are integers between 1 and 4
  #   2) create a list of all possible queen2d variables:
  #      listVariables = list of queen2d(i, j) where i and j are integers between 1 and 4
  #   3) sum all the queen2d variables.

  # The constraints/2 has no iterators like constraints/3 (see below). This statement
  # creates a SINGLE constraint summing ALL the queen2d variables.
  constraints(sum(queen2d(:_, :_)) == 4, "4 queens in total")
  # It would generate a single constraint/2 statement like:
  # constraints(
  #     queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4 +
  #     queen2d_2_1 + queen2d_2_2 + queen2d_2_3 + queen2d_2_4 +
  #     queen2d_3_1 + queen2d_3_2 + queen2d_3_3 + queen2d_3_4 +
  #     queen2d_4_1 + queen2d_4_2 + queen2d_4_3 + queen2d_4_4 == 4, "4 queens in total")
end
```

With user supplied iterators:

```elixir
iterators = %{var_1: iterator_1, var_2: iterator_2}

problem = Problem.define(modelParameters: iterators) do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")

  variables("val", [var_1 <- iterator_1, var_2 <- iterator_2], :binary, "Variable description")

  constraints(sum(val(:_, :_)) == 4, "sum of all vals across all var_1 and var_2 possibilities")
end
```

#### Generator Constraints

```elixir
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")

  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # constraints/3 takes a list of generators, a constraint and a description
  # Here the generator will create one constraints/2 for each combination of the generators
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")
  # This will generate 4 constraints/2 like:
  # constraints(sum(queen2d(1, :_)) == 1, "One queen per row 1")
  # constraints(sum(queen2d(2, :_)) == 1, "One queen per row 2")
  # constraints(sum(queen2d(3, :_)) == 1, "One queen per row 3")
  # constraints(sum(queen2d(4, :_)) == 1, "One queen per row 4")

  # In turn, the constraints/2 will generate:
  # constraints(queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4 == 1, "One queen per row 1")
  # constraints(queen2d_2_1 + queen2d_2_2 + queen2d_2_3 + queen2d_2_4 == 1, "One queen per row 2")
  # constraints(queen2d_3_1 + queen2d_3_2 + queen2d_3_3 + queen2d_3_4 == 1, "One queen per row 3")
  # constraints(queen2d_4_1 + queen2d_4_2 + queen2d_4_3 + queen2d_4_4 == 1, "One queen per row 4")
end
```

#### Multiple generators

```elixir
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
  variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..3], :binary, "Queen position")

  # Multiple generators
  # In the following statement, we have 2 generators: i <- 1..2 and k <- 1..3.
  constraints([i <- 1..2, k <- 1..3], sum(queen3d(i, :_, k)) == 1, "One queen on first axis #{i} and 3rd axis #{k}")
  # The statement will create 6 constraints/2 like:
  # constraints(sum(queen3d(1, :_, 1)) == 1, "One queen on first axis 1 and 3rd axis 1")
  # constraints(sum(queen3d(1, :_, 2)) == 1, "One queen on first axis 1 and 3rd axis 2")
  # constraints(sum(queen3d(1, :_, 3)) == 1, "One queen on first axis 1 and 3rd axis 3")
  # constraints(sum(queen3d(2, :_, 1)) == 1, "One queen on first axis 2 and 3rd axis 1")
  # constraints(sum(queen3d(2, :_, 2)) == 1, "One queen on first axis 2 and 3rd axis 2")
  # constraints(sum(queen3d(2, :_, 3)) == 1, "One queen on first axis 2 and 3rd axis 3")
  #
  # In turn, the 6 constraints/2 will respectively generate:
  # constraints(queen3d_1_1_1 + queen3d_1_2_1 == 1, "One queen on first axis 1 and 3rd axis 1")
  # constraints(queen3d_1_1_2 + queen3d_1_2_2 == 1, "One queen on first axis 1 and 3rd axis 2")
  # constraints(queen3d_1_1_3 + queen3d_1_2_3 == 1, "One queen on first axis 1 and 3rd axis 3")
  # constraints(queen3d_2_1_1 + queen3d_2_2_1 == 1, "One queen on first axis 2 and 3rd axis 1")
  # constraints(queen3d_2_1_2 + queen3d_2_2_2 == 1, "One queen on first axis 2 and 3rd axis 2")
  # constraints(queen3d_2_1_3 + queen3d_2_2_3 == 1, "One queen on first axis 2 and 3rd axis 3")

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

problem = Problem.modify(problem) do
  constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen on first axis #{i} and 3rd axis #{k}")
end
```

### Objective Functions

#### Simple Objectives

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  objective(queen2d_1_1 + queen2d_1_2 + queen2d_2_1 + queen2d_2_2, :maximize)
end
```

#### Generator Objectives

##### Single Generator

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Using sum with patterns
  objective(sum(queen2d(:_, :_)), :maximize)
  # It would generate a single objective/2 statement like:
  objective(
    queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4 +
    queen2d_2_1 + queen2d_2_2 + queen2d_2_3 + queen2d_2_4 +
    queen2d_3_1 + queen2d_3_2 + queen2d_3_3 + queen2d_3_4 +
    queen2d_4_1 + queen2d_4_2 + queen2d_4_3 + queen2d_4_4,
    :maximize)
end
```

Note that a define block can only contain one objective function.

```elixir
problem = Problem.define do
  # new(...)
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # Using sum with patterns
  objective(sum(queen2d(:_, :_)), :maximize)

  # Add another objective
  objective(sum(queen2d(:_, :_)), :maximize) # <-- This triggers an error even if the objective is identical.>
end
```

But an objective can always be set outside a `Problem.define` block with `Problem.set_objective()`. If there was a previously existing objective, only a warning is triggered, not an error.

```elixir
problem = Problem.define do
  new(name: "Adding variables to a problem", description: "Adding variables to a problem")
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
end

# First definition of an objective (none specified in the `Problem.define()` block)
problem = Problem.set_objective(
  problem,
  queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4 +
  queen2d_2_1 + queen2d_2_2 + queen2d_2_3 + queen2d_2_4 +
  queen2d_3_1 + queen2d_3_2 + queen2d_3_3 + queen2d_3_4 +
  queen2d_4_1 + queen2d_4_2 + queen2d_4_3 + queen2d_4_4,
  :maximize
) # <-- This triggers a warning about redefining the problem objective

problem = Problem.set_objective(
  problem,
  sum(queen2d(:_, :_)), # <-- ERROR: Not allowed because iterators are not allowed outside of Problem.define or Problem.modify
  :maximize
)

```

##### Multiple Generators

The following 3 examples should be supported and should produce the same result:

```elixir
problem = Problem.define do
  # new(...)
  variables("qty", [food <- food_names], :continuous, "Amount of food")

  # Using sum with patterns
  objective(sum(qty(:_)), :minimize)
end
```

```elixir
problem = Problem.define do
  # new(...)
  variables("qty", [food <- food_names], :continuous, "Amount of food")

  # Using for comprehensions
  objective(sum(for food <- food_names, do: qty(food)), :minimize)
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
  :minimize
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
    params = %{food_names: ["bread", "milk"]}

    problem =
      Problem.define(model_parameters: params) do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end

  test "Generator with objective" do
    params = %{food_names: ["bread", "milk"]}

    problem =
      Problem.define(model_parameters: params) do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food)), :minimize)
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
    objective(sum(queen2d(:_, :_)), :maximize)
  end
```

## Key Syntax Rules

### 1. Generator Syntax

- **Format**: `[variable <- list]` or `[variable <- generator]`
- **Multiple dimensions**: `[i <- 1..4, j <- 1..4]` or `[var_1 <- generator_1, var_2 <- generator_2]`
- **Provided model parameters**: Must be supported (e.g., `[food <- food_names]`) - food_names should be identified as an unknown symbol and looked up in the model parameters
- **Literal lists**: Must be supported (e.g., `[food <- ["bread", "milk"]]`)

### 2. Variable Access

`:_` is a special symbol that means "_iterate through all values_".

If a symbol is used instead of `:_`, it means "_for each value of the symbol generate a statement_".

- **Pattern matching**: `queen2d(i, :_)` means "_for each value of i generate a statement where all the values of the second iterator (j) are used_".
- **Pattern matching**: `queen2d(:_, j)` means "_for each value of the second iterator (j) generate a statement where all the values of the first iterator (i) are used_".
- **All variables**: `queen2d(:_, :_)` means "_generate a single statement where all the values of the first iterator (i) and the second iterator (j) are used_".

### 3. Sum Functions

- **Pattern sums**: `sum(queen2d(i, :_))` means "_create a sum statement for each value of the first iterator (i) where all the values of the second iterator (j) are summed_".
- **For comprehensions**: `sum(for food <- food_names, do: qty(food))` means "_create a sum statement for each value of the food iterator (food) where the value of the `qty`'s varuiales are summed_".
- **All variables**: `sum(queen2d(:_, :_))` means "_create a single sum statement where all the values of the `queen2d`'s variables (every cross product of the first iterator (i) and the second iterator (j)) are summed_".

### 4. Pattern Functions

The DSL supports several pattern functions that expand expressions with wildcards:

#### Sum Function

- **Pattern sums**: `sum(queen2d(i, :_))` expands to `queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4` for each value of `i`
- **All variables**: `sum(queen2d(:_, :_))` expands to a single sum of all queen2d variables
- **Generator sums**: `sum(qty(food) for food <- food_names)` expands to `qty_bread + qty_milk`

#### Max Function (Future Extension)

- **Pattern max**: `max(queen2d(i, :_))` expands to `max(queen2d_1_1, queen2d_1_2, queen2d_1_3, queen2d_1_4)` for each value of `i`
- **All variables**: `max(queen2d(:_, :_))` expands to `max(queen2d_1_1, queen2d_1_2, ..., queen2d_4_4)`

#### Min Function (Future Extension)

- **Pattern min**: `min(queen2d(i, :_))` expands to `min(queen2d_1_1, queen2d_1_2, queen2d_1_3, queen2d_1_4)` for each value of `i`
- **All variables**: `min(queen2d(:_, :_))` expands to `min(queen2d_1_1, queen2d_1_2, ..., queen2d_4_4)`

#### Count Function (Future Extension)

- **Pattern count**: `count(queen2d(i, :_))` expands to `queen2d_1_1 + queen2d_1_2 + queen2d_1_3 + queen2d_1_4` for each value of `i` (same as sum for binary variables)
- **All variables**: `count(queen2d(:_, :_))` expands to sum of all queen2d variables

Note: `max()` and `min()` functions require linearization techniques for optimization solvers.

### 5. Constraint Descriptions

- **Static**: `"One queen per row"`
- **Dynamic with interpolation**: `"One queen per row #{i}"` expands to:
  - `"One queen per row 1"` for i=1
  - `"One queen per row 2"` for i=2
  - `"One queen per row 3"` for i=3
  - `"One queen per row 4"` for i=4
- **Multiple variable interpolation**: `"One queen on axis #{i} and #{k}"` expands to:
  - `"One queen on axis 1 and 1"` for i=1, k=1
  - `"One queen on axis 1 and 2"` for i=1, k=2
  - etc.

## Implementation Requirements

The DSL implementation MUST support:

1. **Model parameter lookup** in generators: `[food <- food_names]` - food_names should be identified as an unknown symbol and looked up in the model parameters. If a symbol is not found in the model parameters, an error should be raised.
2. **Literal lists** in generators: `[food <- ["bread", "milk"]]`
3. **Literal dictionaries** in generators: `[k, v <- [{"bread", 1}, {"milk", 2}]]`
4. **Range syntax**: `[i <- 1..4, j <- 1..4]`
5. **Pattern matching** in variable access: `queen2d(i, :_)`
6. **Pattern functions** with wildcards: `sum(queen2d(i, :_))`, `max(queen2d(i, :_))`, `min(queen2d(i, :_))`, `count(queen2d(i, :_))`
7. **For comprehensions** in objectives: `sum(for food <- food_names, do: qty(food))`
8. **Variable interpolation** in constraint descriptions: `"One queen per row #{i}"`
9. **Constraint deduplication** and naming clash warnings
10. **Variable range validation** for constraints

## Error Cases

The following are NOT currently supported or should be clearly documented as limitations:

1. **Nested generators** beyond the documented patterns
2. **Complex expressions** in generator lists that cannot be evaluated at compile time
3. **Dynamic constraint names** that cannot be resolved at compile time

## Error Handling

### Constraint Redefinition

If a constraint with the same name is added multiple times, an error is issued:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row") # Error: duplicate constraint
end
```

### Variable Range Mismatch

If constraint ranges don't match variable ranges, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: constraint range (1..5) doesn't match variable range (1..4)
  constraints([i <- 1..5], sum(queen2d(i, :_)) == 1, "One queen per row")
end
```

### Unknown Variables in Constraints

If a variable referenced in a constraint hasn't been declared, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: queen3d variable not declared
  constraints([i <- 1..4], sum(queen3d(i, :_)) == 1, "One queen per row")
end
```

## Testing Requirements

All syntax patterns in this reference must:

1. **Compile without errors**
2. **Execute successfully**
3. **Produce expected results**
4. **Be covered by tests**

## Troubleshooting

### Common DSL Errors

_Content to be added as we encounter issues during implementation_

### Debugging DSL Issues

_Content to be added as we encounter issues during implementation_

### Migration from Old Syntax

_Content to be added as we encounter issues during implementation_

### Best Practices

_Content to be added as we encounter issues during implementation_

## Version History

- **v1.0** - Initial reference based on golden test file and nqueens example
- **Future changes** - Must be explicitly approved and documented

---

**REMINDER: This is the GOLDEN REFERENCE. Do not modify without explicit approval.**
