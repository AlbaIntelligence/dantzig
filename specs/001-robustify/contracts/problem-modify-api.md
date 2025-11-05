# Problem.modify API Contract

**Feature**: 001-robustify | **Requirement**: FR-014
**Date**: 2024-12-19
**Purpose**: Define API contract for `Problem.modify` macro to declaratively apply additional variables/constraints/objective updates to an existing problem without rebuilding from scratch

## Overview

`Problem.modify` enables incremental problem construction by adding variables, constraints, or updating objectives to an existing problem. This allows:
- Building problems in stages
- Conditional problem augmentation
- Reusing base problem definitions
- Efficient problem updates without full reconstruction

## API Contract

### `Problem.modify/2`

**Signature**: `Problem.modify(problem, do: block)`

**Purpose**: Apply incremental updates to an existing problem by adding variables, constraints, or updating objectives.

**Parameters**:
- `problem` (%Dantzig.Problem{}, required): Existing problem to modify
- `do: block` (block, required): DSL block containing modifications

**Returns**: `%Dantzig.Problem{}` struct representing the modified problem

**Behavior**:
- Mutates the provided problem by adding new variables/constraints
- Updates objective if specified
- Preserves all existing problem state (variables, constraints, objective)
- Uses same DSL syntax as `Problem.define` for consistency
- Does not rebuild or recreate the problem structure

**Backward Compatibility**: 
- Does not affect existing `Problem.define` usage
- Existing imperative APIs continue to work
- No breaking changes to problem structure

## Supported Operations

### Adding Variables

```elixir
# Add new variables to existing problem
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

modified = Problem.modify(problem) do
  variables("y", [i <- 1..3], :binary)
end

# Modified problem now has both "x" and "y" variables
```

### Adding Constraints

```elixir
# Add new constraints to existing problem
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
  constraints([i <- 1..5], x(i) >= 0)
end

modified = Problem.modify(problem) do
  constraints([i <- 1..5], x(i) <= 100)
end

# Modified problem has both >= 0 and <= 100 constraints
```

### Updating Objective

```elixir
# Update objective function
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
  objective(sum(x(i) for i <- 1..5), direction: :maximize)
end

modified = Problem.modify(problem) do
  objective(sum(2 * x(i) for i <- 1..5), direction: :maximize)
end

# Modified problem has updated objective
```

### Combined Operations

```elixir
# Multiple operations in single modify block
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

modified = Problem.modify(problem) do
  variables("y", [i <- 1..3], :binary)
  constraints([i <- 1..5], x(i) >= 0)
  constraints([i <- 1..3], y(i) >= 0)
  objective(sum(x(i) for i <- 1..5) + sum(y(i) for i <- 1..3), direction: :maximize)
end
```

## DSL Syntax Compatibility

### Same Syntax as Problem.define

```elixir
# All Problem.define DSL syntax works in Problem.modify
Problem.modify(problem) do
  # Variable creation
  variables("var_name", [generators], :type, description: "Description")
  
  # Constraint creation
  constraints([generators], expression, description)
  
  # Objective setting
  objective(expression, direction: :maximize | :minimize)
  
  # Nested generators
  variables("x", [i <- 1..n, j <- 1..m], :continuous)
  
  # Sum expressions
  constraints([i <- 1..n], sum(x(i, j) for j <- 1..m) <= 100)
end
```

### Model Parameters Support

```elixir
# Problem.modify can accept model parameters (if implemented)
Problem.modify(problem, model_parameters: %{n: 10}) do
  variables("y", [i <- 1..params.n], :continuous)
end
```

**Note**: Model parameters in `Problem.modify` may be a future enhancement. Initial implementation focuses on basic modify functionality. When implemented, parameters follow the same direct-name access pattern as `Problem.define` (see `contracts/model-parameters-api.md`).

## State Preservation

### Existing Variables Preserved

```elixir
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

modified = Problem.modify(problem) do
  variables("y", [i <- 1..3], :binary)
end

# Original "x" variables still exist
assert Map.has_key?(modified.variables, "x")
assert Map.has_key?(modified.variables, "y")
```

### Existing Constraints Preserved

```elixir
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
  constraints([i <- 1..5], x(i) >= 0)
end

modified = Problem.modify(problem) do
  constraints([i <- 1..5], x(i) <= 100)
end

# Original constraints still exist
original_constraint_count = map_size(problem.constraints)
modified_constraint_count = map_size(modified.constraints)
assert modified_constraint_count > original_constraint_count
```

### Objective Replacement

```elixir
# Objective updates replace previous objective
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
  objective(sum(x(i) for i <- 1..5), direction: :maximize)
end

modified = Problem.modify(problem) do
  objective(sum(2 * x(i) for i <- 1..5), direction: :maximize)
end

# Modified problem has new objective
assert modified.objective != problem.objective
```

## Error Cases

### Variable Name Conflicts

**Error**: Attempting to add variables with names that already exist

```elixir
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

# Error: variable "x" already exists
Problem.modify(problem) do
  variables("x", [i <- 1..10], :continuous)  # Conflict
end
```

**Error Response**: Clear error indicating conflict:
- `{:error, :variable_exists, name: "x", existing_indices: [...], new_indices: [...]}`
- Or: Warning + merge behavior (implementation choice)

**Recommendation**: Either raise error or merge (document chosen behavior)

### Invalid Problem Reference

**Error**: Modifying a problem that is not a valid `%Dantzig.Problem{}` struct

```elixir
invalid_problem = %{not_a_problem: true}
Problem.modify(invalid_problem) do
  variables("x", [i <- 1..5], :continuous)
end
```

**Error Response**: Type validation error:
- `{:error, :invalid_problem, expected: %Dantzig.Problem{}, received: actual_type}`

### Constraint Syntax Errors

**Error**: Invalid constraint syntax in modify block

```elixir
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

Problem.modify(problem) do
  constraints([i <- 1..5], x(i) == invalid_expr)  # Error: invalid expression
end
```

**Error Response**: Same error handling as `Problem.define`:
- Clear DSL syntax error messages
- Location information for debugging

### Undefined Variable References

**Error**: Referencing variables that don't exist in constraints/objectives

```elixir
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

Problem.modify(problem) do
  constraints([i <- 1..5], y(i) >= 0)  # Error: y not defined
end
```

**Error Response**: Variable resolution error:
- `{:error, :undefined_variable, name: "y", available_variables: ["x"]}`

## Usage Examples

### Incremental Problem Building

```elixir
# Build problem in stages
base_problem = Problem.define do
  new(name: "Production Planning")
  variables("production", [month <- 1..12], :continuous)
end

# Add capacity constraints
problem_with_capacity = Problem.modify(base_problem) do
  constraints([month <- 1..12], 
    production(month) <= 1000,
    "Capacity constraint"
  )
end

# Add demand constraints
final_problem = Problem.modify(problem_with_capacity) do
  constraints([month <- 1..12],
    production(month) >= demands[month],
    "Demand constraint"
  )
  objective(
    sum(costs[month] * production(month) for month <- 1..12),
    direction: :minimize
  )
end
```

### Conditional Problem Augmentation

```elixir
# Add constraints conditionally
base_problem = Problem.define do
  variables("x", [i <- 1..10], :continuous)
end

# Conditionally add constraints
final_problem = if include_additional_constraints do
  Problem.modify(base_problem) do
    constraints([i <- 1..10], x(i) <= 50)
  end
else
  base_problem
end
```

### Problem Reuse

```elixir
# Define base problem once
base_problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
  constraints([i <- 1..5], x(i) >= 0)
end

# Create variations with different objectives
maximize_problem = Problem.modify(base_problem) do
  objective(sum(x(i) for i <- 1..5), direction: :maximize)
end

minimize_problem = Problem.modify(base_problem) do
  objective(sum(x(i) for i <- 1..5), direction: :minimize)
end
```

### Complex Modifications

```elixir
# Multiple modifications in sequence
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

# Step 1: Add variables
problem = Problem.modify(problem) do
  variables("y", [i <- 1..3], :binary)
end

# Step 2: Add constraints
problem = Problem.modify(problem) do
  constraints([i <- 1..5], x(i) <= 100)
  constraints([i <- 1..3], y(i) >= 0)
end

# Step 3: Set objective
final_problem = Problem.modify(problem) do
  objective(
    sum(x(i) for i <- 1..5) + 10 * sum(y(i) for i <- 1..3),
    direction: :maximize
  )
end
```

## Backward Compatibility Guarantees

### Existing APIs Unchanged

```elixir
# Existing Problem.define usage unchanged
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

# Existing imperative APIs still work
problem = Problem.new_variable(problem, "y", type: :continuous)

# Problem.modify is additive, not replacement
```

### No Breaking Changes

- All existing `Problem.define` code works unchanged
- Problem structure remains identical
- DSL syntax compatibility maintained
- No migration required for existing code

## Implementation Requirements

### Macro Expansion

- `Problem.modify` must expand DSL macros correctly
- Generator syntax must work identically to `Problem.define`
- Sum expressions must resolve correctly
- Variable access macros must function

### State Management

- Must preserve existing problem state
- Must add new variables/constraints incrementally
- Must update objective correctly
- Must maintain problem counters correctly

### Error Handling

- Clear error messages for conflicts
- Type validation for problem parameter
- DSL syntax error handling consistent with `Problem.define`
- Variable resolution errors

## Testing Requirements

### Acceptance Criteria

1. **Variable Addition**: Can add new variables to existing problem
2. **Constraint Addition**: Can add new constraints to existing problem
3. **Objective Update**: Can update objective function
4. **State Preservation**: Existing problem state preserved
5. **DSL Compatibility**: Same DSL syntax as `Problem.define`
6. **Error Handling**: Clear errors for conflicts/invalid usage

### Test Cases

```elixir
# Test 1: Add variables
test "modify adds new variables" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
  end
  
  modified = Problem.modify(problem) do
    variables("y", [i <- 1..3], :binary)
  end
  
  assert Map.has_key?(modified.variables, "x")
  assert Map.has_key?(modified.variables, "y")
end

# Test 2: Add constraints
test "modify adds new constraints" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
  end
  
  modified = Problem.modify(problem) do
    constraints([i <- 1..5], x(i) >= 0)
  end
  
  assert map_size(modified.constraints) > map_size(problem.constraints)
end

# Test 3: Update objective
test "modify updates objective" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
    objective(sum(x(i) for i <- 1..5), direction: :maximize)
  end
  
  modified = Problem.modify(problem) do
    objective(sum(2 * x(i) for i <- 1..5), direction: :maximize)
  end
  
  assert modified.objective != problem.objective
end

# Test 4: State preservation
test "modify preserves existing state" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
    constraints([i <- 1..5], x(i) >= 0)
  end
  
  original_constraint_count = map_size(problem.constraints)
  
  modified = Problem.modify(problem) do
    variables("y", [i <- 1..3], :binary)
  end
  
  assert Map.has_key?(modified.variables, "x")
  assert map_size(modified.constraints) == original_constraint_count
end

# Test 5: Error handling
test "modify raises error for undefined variables" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
  end
  
  assert_raise ArgumentError, fn ->
    Problem.modify(problem) do
      constraints([i <- 1..5], y(i) >= 0)  # y not defined
    end
  end
end
```

## Integration Points

### With Problem.define

```elixir
# Define base problem
base = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

# Modify with same DSL syntax
modified = Problem.modify(base) do
  variables("y", [i <- 1..3], :binary)
end
```

### With Model Parameters (Future)

```elixir
# Future: modify with parameters - accessed directly by name
model_parameters = %{food_names: ["bread", "milk"]}

base = Problem.define(model_parameters: model_parameters) do
  variables("qty", [food <- food_names], :continuous, "Amount")
end

modified = Problem.modify(base, model_parameters: model_parameters) do
  variables("price", [food <- food_names], :continuous, "Price")
end
```

### With Existing Imperative APIs

```elixir
# Can mix modify with imperative APIs
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

# Use modify
problem = Problem.modify(problem) do
  variables("y", [i <- 1..3], :binary)
end

# Use imperative API
problem = Problem.new_variable(problem, "z", type: :continuous)
```

## Performance Considerations

- Modify should be efficient (no full problem rebuild)
- Incremental updates should be faster than full redefinition
- Should handle large problems efficiently
- State copying should be minimal

## Edge Cases

### Empty Modify Block

```elixir
# Modify with no operations returns original problem
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

modified = Problem.modify(problem) do
  # Empty block
end

assert modified == problem
```

### Multiple Objective Updates

```elixir
# Last objective wins
problem = Problem.define do
  variables("x", [i <- 1..5], :continuous)
end

modified = Problem.modify(problem) do
  objective(sum(x(i) for i <- 1..5), direction: :maximize)
end

modified = Problem.modify(modified) do
  objective(sum(2 * x(i) for i <- 1..5), direction: :minimize)
end

# Final objective is minimize
```

## Future Enhancements (Out of Scope)

- Removing variables/constraints
- Updating existing constraints
- Conditional modifications
- Batch operations
- Modification history/undo

## Migration Notes

### For Existing Code

No migration required. `Problem.modify` is purely additive. Existing code using `Problem.define` or imperative APIs continues to work unchanged.

### Adoption Path

1. Existing code: No changes needed
2. New incremental code: Use `Problem.modify` for staged building
3. Refactoring: Optionally refactor to use `Problem.modify` for clarity
