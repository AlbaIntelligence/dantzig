# Model Parameters API Contract

**Feature**: 001-robustify | **Requirement**: FR-013
**Date**: 2024-12-19
**Purpose**: Define API contract for model parameters in `Problem.define`, enabling external values to be bound into generators, expressions, and descriptions

## Overview

Model parameters allow runtime values to be passed into `Problem.define` blocks, making problem definitions reusable and configurable. Parameters can be used in:
- Generator ranges (e.g., `[i <- 1..max_i]` where `max_i` comes from model parameters)
- Constraint expressions (e.g., `x(i) <= max_capacity` where `max_capacity` comes from model parameters)
- Variable descriptions (e.g., `"Variable #{product_name}_#{i}"` where `product_name` comes from model parameters)
- Objective expressions (e.g., `sum(costs[i] * x(i))` where `costs` comes from model parameters)

**Parameter Access**: Parameters are accessed DIRECTLY by their key name from the model parameters map. Unknown symbols in generators, expressions, and descriptions are automatically looked up in the model parameters map. This matches the DSL syntax reference (`docs/DSL_SYNTAX_REFERENCE.md`).

## API Contract

### `Problem.define/2` with Model Parameters

**Signature**: `Problem.define(opts, do: block)`

**Purpose**: Define an optimization problem with runtime model parameters accessible within the DSL block.

**Parameters**:
- `opts` (keyword list, required): Configuration options
  - `:model_parameters` (map, optional): Map of parameter names to values. Parameters are accessed directly by their key name (e.g., if map contains `%{n: 10}`, use `n` directly, not `params.n`)
- `do: block` (block, required): DSL block containing problem definition

**Returns**: `%Dantzig.Problem{}` struct representing the defined optimization problem

**Behavior**:
- Model parameters are evaluated at macro expansion time (parameters must be compile-time constants or runtime values)
- Parameters are accessed DIRECTLY by their key name from the model parameters map (e.g., `food_names`, `max_i`, `costs`)
- Unknown symbols in generators, expressions, and descriptions are automatically looked up in the model parameters map
- If a symbol is not found in the model parameters, an error is raised
- Parameters can be used in all DSL contexts: generators, expressions, descriptions
- If `:model_parameters` is omitted, behaves identically to `Problem.define/1` (backward compatible)

**Backward Compatibility**: 
- `Problem.define(do: block)` continues to work without parameters
- Existing code without model parameters requires no changes

## Parameter Access Syntax

### In Generators

```elixir
# Parameters can be used in generator ranges - accessed directly by name
model_parameters = %{food_names: ["bread", "milk"], max_i: 4, max_j: 4}

Problem.define(model_parameters: model_parameters) do
  variables("qty", [food <- food_names], :continuous, "Amount of food")
  variables("queen2d", [i <- 1..max_i, j <- 1..max_j], :binary, "Queen position")
end
```

### In Constraint Expressions

```elixir
# Parameters can be used in constraint bounds
Problem.define(model_parameters: %{max_capacity: 100, min_demand: 50}) do
  variables("x", [i <- 1..10], :continuous)
  constraints([i <- 1..10], 
    x(i) <= params.max_capacity,
    "Capacity constraint"
  )
  constraints([i <- 1..10],
    x(i) >= params.min_demand,
    "Demand constraint"
  )
end
```

### In Descriptions

```elixir
# Parameters can be interpolated in descriptions - accessed directly by name
model_parameters = %{product_name: "Widget", region: "North"}

Problem.define(model_parameters: model_parameters) do
  variables("qty", [i <- 1..5], :continuous,
    description: "#{product_name} quantity for #{region} region #{i}"
  )
end
```

### In Objective Expressions

```elixir
# Parameters can be used in objective coefficients - accessed directly by name
model_parameters = %{food_names: ["bread", "milk"]}

Problem.define(model_parameters: model_parameters) do
  variables("qty", [food <- food_names], :continuous, "Amount of food")
  objective(
    sum(for food <- food_names, do: qty(food)),
    :minimize
  )
end
```

**Note**: Objective function uses positional argument for direction: `objective(expression, :direction)`, matching the DSL syntax reference (`docs/DSL_SYNTAX_REFERENCE.md`).

## Data Structures

### Model Parameters Map

```elixir
# Parameters can contain any Elixir values
%{
  # Scalars
  n: 10,
  max_capacity: 100.0,
  product_name: "Widget",
  
  # Lists/Accessible structures
  costs: [10.0, 20.0, 30.0],
  demands: %{1 => 50, 2 => 75, 3 => 100},
  
  # Nested structures (accessed via params.nested.key)
  regions: %{
    north: %{capacity: 100, cost: 5.0},
    south: %{capacity: 150, cost: 4.5}
  }
}
```

### Parameter Access Pattern

```elixir
# Access parameters DIRECTLY by their key name from model_parameters map
# Unknown symbols are automatically looked up in model_parameters

model_parameters = %{
  n: 10,
  costs: [10.0, 20.0, 30.0],
  regions: %{
    north: %{capacity: 100, cost: 5.0},
    south: %{capacity: 150, cost: 4.5}
  }
}

Problem.define(model_parameters: model_parameters) do
  variables("x", [i <- 1..n], :continuous)  # n accessed directly
  # costs[i] and regions.north.capacity accessed in expressions
end
```

**Important**: Parameters are NOT accessed via `params.key` syntax. They are accessed directly by name, and the DSL implementation looks up unknown symbols in the model_parameters map automatically.

## Error Cases

### Undefined Parameter Access

**Error**: Attempting to access a parameter that doesn't exist in the `:model_parameters` map

```elixir
Problem.define(model_parameters: %{n: 10}) do
  variables("x", [i <- 1..m], :continuous)  # Error: m not found in model_parameters
end
```

**Error Response**: Compile-time error or runtime error with clear message:
- `{:error, :undefined_parameter, key: :m, available_keys: [:n]}`
- Error message should indicate that `m` was not found in model_parameters map

### Invalid Parameter Type in Generator

**Error**: Using a parameter in a generator context where it's not a valid range

```elixir
Problem.define(model_parameters: %{n: "invalid"}) do
  variables("x", [i <- 1..n], :continuous)  # Error: n must be integer for range
end
```

**Error Response**: Clear error message indicating expected type:
- `{:error, :invalid_generator_range, parameter: :n, value: "invalid", expected_type: :integer}`

### Parameter Evaluation Failure

**Error**: Parameter expression fails to evaluate at runtime

```elixir
model_parameters = %{n: calculate_size()}  # calculate_size/0 raises error
Problem.define(model_parameters: model_parameters) do
  variables("x", [i <- 1..n], :continuous)
end
```

**Error Response**: Error from parameter evaluation propagated:
- `{:error, :parameter_evaluation_failed, parameter: :n, error: error_details}`

## Usage Examples

### Basic Parameter Usage

```elixir
# Define problem with size parameter - accessed directly by name
problem = Problem.define(model_parameters: %{n: 10}) do
  new(name: "Parameterized Problem")
  variables("x", [i <- 1..n], :continuous)
  constraints([i <- 1..n], x(i) >= 0, "Non-negativity")
  objective(sum(x(i) for i <- 1..n), :maximize)
end
```

### Multi-Parameter Problem

```elixir
# Define problem with multiple parameters
params = %{
  n_items: 5,
  max_weight: 100.0,
  costs: [10.0, 20.0, 30.0, 40.0, 50.0],
  weights: [15.0, 25.0, 35.0, 45.0, 55.0]
}

problem = Problem.define(model_parameters: params) do
  new(name: "Knapsack Problem")
  
  variables("x", [i <- 1..params.n_items], :binary)
  
  constraints([],
    sum(params.weights[i] * x(i) for i <- 1..params.n_items) <= params.max_weight,
    "Weight constraint"
  )
  
  objective(
    sum(params.costs[i] * x(i) for i <- 1..params.n_items),
    direction: :maximize
  )
end
```

### Nested Parameter Access

```elixir
# Parameters with nested structures - accessed directly by name
model_parameters = %{
  products: %{
    widget: %{cost: 10.0, demand: 50},
    gadget: %{cost: 20.0, demand: 30}
  },
  regions: ["north", "south"]
}

problem = Problem.define(model_parameters: model_parameters) do
  variables("qty", 
    [product <- [:widget, :gadget], region <- regions],
    :continuous
  )
  
  constraints([product <- [:widget, :gadget]],
    sum(qty(product, region) for region <- regions) >= products[product].demand,
    "Demand for #{product}"
  )
  
  objective(
    sum(products[product].cost * qty(product, region) 
        for product <- [:widget, :gadget], region <- regions),
    :minimize
  )
end
```

### Parameterized Description Interpolation

```elixir
# Use parameters in descriptions for better debugging - accessed directly by name
model_parameters = %{scenario: "baseline", year: 2024}

problem = Problem.define(model_parameters: model_parameters) do
  variables("production", [month <- 1..12], :continuous,
    description: "#{scenario} production for #{year} month #{month}"
  )
end
```

## Backward Compatibility Guarantees

### Existing Code Continues to Work

```elixir
# This existing code requires no changes
problem = Problem.define do
  new(name: "Existing Problem")
  variables("x", [i <- 1..10], :continuous)
  constraints([i <- 1..10], x(i) >= 0)
  objective(sum(x(i) for i <- 1..10), direction: :maximize)
end
```

### Optional Parameter Usage

```elixir
# Parameters are optional - can be omitted
problem = Problem.define do
  # Works exactly as before
end

# Or provided when needed
problem = Problem.define(model_parameters: %{n: 10}) do
  # Uses parameters
end
```

### No Breaking Changes

- Existing `Problem.define(do: block)` syntax unchanged
- All existing DSL syntax works identically
- Parameters are additive enhancement, not replacement

## Implementation Requirements

### Macro Expansion

- Model parameters must be available during macro expansion
- Parameter access (direct name access, e.g., `n`, `costs[i]`) must resolve to actual values
- Generator ranges using parameters must expand correctly
- Expression evaluation must have access to parameter values

### Evaluation Context

- Parameters must be accessible in all DSL contexts:
  - Variable generators
  - Constraint generators
  - Constraint expressions
  - Objective expressions
  - Description interpolation

### Error Handling

- Clear error messages for undefined parameters
- Type validation for parameters used in generators
- Graceful handling of parameter evaluation failures

## Testing Requirements

### Acceptance Criteria

1. **Parameter Access**: Parameters accessible via `params.key` syntax
2. **Generator Usage**: Parameters work in generator ranges `[i <- 1..params.n]`
3. **Expression Usage**: Parameters usable in constraint/objective expressions
4. **Description Interpolation**: Parameters interpolate in descriptions
5. **Backward Compatibility**: Existing code without parameters works unchanged
6. **Error Handling**: Clear errors for undefined/invalid parameters

### Test Cases

```elixir
# Test 1: Basic parameter access
test "parameters accessible in generators" do
  problem = Problem.define(model_parameters: %{n: 5}) do
    variables("x", [i <- 1..params.n], :continuous)
  end
  assert map_size(problem.variables["x"]) == 5
end

# Test 2: Parameter in expressions
test "parameters usable in constraints" do
  problem = Problem.define(model_parameters: %{max_val: 100}) do
    variables("x", [i <- 1..3], :continuous)
    constraints([i <- 1..3], x(i) <= params.max_val)
  end
  assert map_size(problem.constraints) == 3
end

# Test 3: Backward compatibility
test "works without parameters" do
  problem = Problem.define do
    variables("x", [i <- 1..5], :continuous)
  end
  assert map_size(problem.variables["x"]) == 5
end

# Test 4: Error handling
test "undefined parameter raises error" do
  assert_raise ArgumentError, fn ->
    Problem.define(model_parameters: %{n: 5}) do
      variables("x", [i <- 1..m], :continuous)  # m not found in model_parameters
    end
  end
end
```

## Integration Points

### With Problem.modify

```elixir
# Parameters can be used in Problem.modify blocks - accessed directly by name
problem = Problem.define(model_parameters: %{n: 10}) do
  variables("x", [i <- 1..n], :continuous)
end

# Modify with same parameters
modified = Problem.modify(problem, model_parameters: %{n: 10}) do
  variables("y", [i <- 1..n], :continuous)
end
```

### With Existing DSL

```elixir
# Parameters work with all existing DSL features - accessed directly by name
problem = Problem.define(model_parameters: %{n: 10, max_val: 100}) do
  new(name: "Parameterized")
  variables("x", [i <- 1..n], :continuous)
  constraints([i <- 1..n], x(i) <= max_val)
  objective(sum(x(i) for i <- 1..n), :maximize)
end
```

## Performance Considerations

- Parameter evaluation should be efficient (no repeated evaluation)
- Parameter access should not add significant overhead to macro expansion
- Large parameter maps should be handled efficiently

## Future Enhancements (Out of Scope)

- Type checking for parameters
- Default parameter values
- Parameter validation/schema
- Parameter documentation generation
e checking for parameters
- Default parameter values
- Parameter validation/schema
- Parameter documentation generation
meter values
- Parameter validation/schema
- Parameter documentation generation
