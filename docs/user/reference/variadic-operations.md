# Variadic Operations

## Overview

The Dantzig AST system supports **variadic operations** for `max()`, `min()`, `and()`, and `or()` functions. This means these operations can take any number of arguments, just like the `sum()` function.

## What Changed

### Before (Binary Only)

```elixir
# Only supported 2 arguments
max(x, y)
min(x, y)
x AND y
x OR y
```

### After (Variadic)

```elixir
# Supports any number of arguments
max(x, y, z, w, ...)
min(x, y, z, w, ...)
x AND y AND z AND w AND ...
x OR y OR z OR w OR ...
```

## Examples

### Basic Variadic Operations

```elixir
# Max of 4 variables
max(x[1], x[2], x[3], x[4])

# Min of 3 variables
min(y[1], y[2], y[3])

# All must be true
a[1] AND a[2] AND a[3] AND a[4] AND a[5]

# At least one must be true
b[1] OR b[2] OR b[3]
```

### Complex Combinations

```elixir
# Nested operations
max(min(x[1], x[2]), min(x[3], x[4]))

# Mixed operations
a[1] AND (b[1] OR b[2] OR b[3])

# Multiple levels
max(x[1], x[2]) AND min(y[1], y[2], y[3])
```

### Practical Use Cases

#### Portfolio Optimization

```elixir
# Maximize best return while minimizing worst risk
max(return1, return2, return3, return4) - min(risk1, risk2, risk3)
```

#### Facility Location

```elixir
# Find minimum distance to any facility
min(distance1, distance2, distance3, distance4)
```

#### Resource Allocation

```elixir
# All resources must be available
resource1 AND resource2 AND resource3
```

#### Backup Systems

```elixir
# At least one system must be working
system1 OR system2 OR system3
```

#### Quality Control

```elixir
# Best quality with fewest defects
max(quality1, quality2) AND min(defect1, defect2)
```

## Linearization Rules

### Max Operation

For `max(x₁, x₂, ..., xₙ) = z`:

- **Constraints**: `z ≥ xᵢ` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Min Operation

For `min(x₁, x₂, ..., xₙ) = z`:

- **Constraints**: `z ≤ xᵢ` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### And Operation

For `x₁ AND x₂ AND ... AND xₙ = z` (where all `xᵢ` are binary):

- **Constraints**:
  - `z ≤ xᵢ` for all `i = 1, 2, ..., n`
  - `z ≥ ∑xᵢ - (n-1)`
- **Variable**: `z` is binary

### Or Operation

For `x₁ OR x₂ OR ... OR xₙ = z` (where all `xᵢ` are binary):

- **Constraints**:
  - `z ≥ xᵢ` for all `i = 1, 2, ..., n`
  - `z ≤ ∑xᵢ`
- **Variable**: `z` is binary

## Benefits

1. **Natural Syntax**: Matches mathematical notation exactly
2. **Automatic Linearization**: No manual constraint creation needed
3. **Scalable**: Works with any number of arguments
4. **Composable**: Can be nested and combined freely
5. **Efficient**: Creates optimal number of constraints
6. **Type Safe**: Maintains proper variable types (binary/continuous)

## Related Documentation

- [DSL Syntax Reference](dsl-syntax.md) - Complete syntax guide
- [Pattern Operations](pattern-operations.md) - Pattern-based operations with wildcards
- [Modeling Guide](../guides/modeling-patterns.md) - Best practices
