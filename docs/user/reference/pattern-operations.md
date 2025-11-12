# Pattern-Based Operations

## Overview

The Dantzig AST system supports **pattern-based operations** that allow you to write concise expressions like `max(x[_])` instead of `max(x[1], x[2], x[3], x[4], x[5])`. This makes optimization modeling much more elegant and maintainable.

## What Are Pattern-Based Operations?

Pattern-based operations use the `_` (underscore) wildcard to represent "all variables" in a dimension. This allows you to write expressions that automatically scale with the number of variables.

### Basic Pattern Syntax

| Pattern   | Meaning                                 | Example                               |
| --------- | --------------------------------------- | ------------------------------------- |
| `x[_]`    | All x variables                         | `x[1], x[2], x[3], ..., x[n]`         |
| `x[_, j]` | All x variables with fixed second index | `x[1,j], x[2,j], x[3,j], ..., x[n,j]` |
| `x[i, _]` | All x variables with fixed first index  | `x[i,1], x[i,2], x[i,3], ..., x[i,m]` |
| `x[_, _]` | All x variables (2D)                    | `x[1,1], x[1,2], ..., x[n,m]`         |

## Supported Operations

### Max Operation

```elixir
# Pattern-based syntax
max(x[_])           # Maximum of all x variables
max(x[_, j])        # Maximum over first dimension
max(x[i, _])        # Maximum over second dimension
max(x[_, _])        # Maximum of all 2D x variables

# Equivalent explicit syntax
max(x[1], x[2], x[3], x[4], x[5])
max(x[1,j], x[2,j], x[3,j])
max(x[i,1], x[i,2], x[i,3])
max(x[1,1], x[1,2], x[2,1], x[2,2], x[3,1], x[3,2])
```

### Min Operation

```elixir
# Pattern-based syntax
min(y[_])           # Minimum of all y variables
min(y[_, j])        # Minimum over first dimension
min(y[i, _])        # Minimum over second dimension
min(y[_, _])        # Minimum of all 2D y variables

# Equivalent explicit syntax
min(y[1], y[2], y[3])
min(y[1,j], y[2,j], y[3,j])
min(y[i,1], y[i,2], y[i,3])
min(y[1,1], y[1,2], y[2,1], y[2,2], y[3,1], y[3,2])
```

### And Operation (Binary Variables)

```elixir
# Pattern-based syntax
a[_] AND a[_] AND a[_] AND a[_]    # All a variables must be true

# Equivalent explicit syntax
a[1] AND a[2] AND a[3] AND a[4]
```

### Or Operation (Binary Variables)

```elixir
# Pattern-based syntax
b[_] OR b[_] OR b[_]               # At least one b variable must be true

# Equivalent explicit syntax
b[1] OR b[2] OR b[3]
```

## Examples

### Basic Examples

```elixir
# 1D variables
max(x[_])                    # max(x[1], x[2], x[3], x[4], x[5])
min(y[_])                    # min(y[1], y[2], y[3])

# 2D variables
max(z[_, j])                 # max(z[1,j], z[2,j], z[3,j])
min(z[i, _])                 # min(z[i,1], z[i,2])
max(z[_, _])                 # max(z[1,1], z[1,2], z[2,1], z[2,2], z[3,1], z[3,2])

# Binary variables
a[_] AND a[_] AND a[_]       # a[1] AND a[2] AND a[3]
b[_] OR b[_] OR b[_]         # b[1] OR b[2] OR b[3]
```

### 4D Variables

```elixir
# Create 4D variables busy[i, j, k, l]
max(busy[_, j, k, l])   # max over i dimension
min(busy[i, _, k, l])   # min over j dimension
max(busy[i, j, _, l])   # max over k dimension
min(busy[i, j, k, _])   # min over l dimension
max(busy[_, _, _, _])   # max across all 4D entries
```

### Complex Combinations

```elixir
# Mixed operations
max(x[_]) + min(y[_])        # max(x[1],...,x[n]) + min(y[1],...,y[m])
max(x[_, j]) - min(x[i, _])  # max(x[1,j],...,x[n,j]) - min(x[i,1],...,x[i,m])

# Nested operations
max(min(x[_, j]), min(x[i, _]))  # max of minimums
a[_] AND (b[_] OR c[_])          # all a's AND (at least one b OR at least one c)
```

### Practical Use Cases

#### Portfolio Optimization

```elixir
# Maximize best return while minimizing worst risk
max(return[_]) - min(risk[_])
```

#### Facility Location

```elixir
# Find minimum distance to any customer
min(distance[_, customer])
```

#### Resource Allocation

```elixir
# All resources must be available
resource[_] AND resource[_] AND resource[_]
```

#### Quality Control

```elixir
# Best quality with fewest defects
max(quality[_]) AND min(defect[_])
```

#### Network Optimization

```elixir
# Maximum flow to any destination
max(flow[_, destination])
```

## Benefits

### 1. Concise Syntax

- `max(x[_])` instead of `max(x[1], x[2], x[3], x[4], x[5])`
- Reduces code verbosity significantly

### 2. Automatic Scaling

- Works with any number of variables
- No need to update code when adding/removing variables

### 3. Less Error-Prone

- No need to list variables explicitly
- Reduces chance of missing variables or typos

### 4. More Readable

- Intent is clearer: "maximum of all x variables"
- Easier to understand the mathematical meaning

### 5. Maintainable

- Adding variables doesn't require code changes
- Easier to refactor and modify

### 6. Flexible

- Supports complex patterns like `x[_, j]` or `x[i, _]`
- Can be combined with other operations

## Variable Naming

Pattern-based operations generate descriptive variable names:

```elixir
# max(x[_]) creates variable: max_x_all
# min(y[_, j]) creates variable: min_y_all_j
# max(z[i, _]) creates variable: max_z_i_all
```

The naming convention is:

- `{operation}_{var_name}_{pattern_description}`
- `_` becomes `all`
- Fixed indices are included as-is

## Linearization Rules

### Pattern-Based Max

For `max(x[_]) = z` where `x[_]` represents `x[1], x[2], ..., x[n]`:

- **Constraints**: `z ≥ x[i]` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Pattern-Based Min

For `min(x[_]) = z` where `x[_]` represents `x[1], x[2], ..., x[n]`:

- **Constraints**: `z ≤ x[i]` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Pattern-Based And

For `x[_] AND x[_] AND ... AND x[_] = z` (where all `x[i]` are binary):

- **Constraints**:
  - `z ≤ x[i]` for all `i = 1, 2, ..., n`
  - `z ≥ ∑x[i] - (n-1)`
- **Variable**: `z` is binary

### Pattern-Based Or

For `x[_] OR x[_] OR ... OR x[_] = z` (where all `x[i]` are binary):

- **Constraints**:
  - `z ≥ x[i]` for all `i = 1, 2, ..., n`
  - `z ≤ ∑x[i]`
- **Variable**: `z` is binary

## Related Documentation

- [DSL Syntax Reference](dsl-syntax.md) - Complete syntax guide
- [Variadic Operations](variadic-operations.md) - Variadic max/min/and/or functions
- [Modeling Guide](../guides/modeling-patterns.md) - Best practices
