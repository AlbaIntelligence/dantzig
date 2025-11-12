# Expression Evaluation

## Overview

Dantzig's DSL supports rich expression evaluation with access to model parameters, bindings from generators, and automatic constant evaluation.

## Model Parameters

Model parameters are runtime values passed to `Problem.define` that are accessible in expressions:

```elixir
problem = Problem.define(model_parameters: %{
  limit: 100,
  costs: [10, 20, 30],
  data: %{"A" => %{"value" => 5}}
}) do
  new(direction: :maximize)
  variables("x", :continuous, min_bound: 0)

  # Access simple constants
  constraints(x <= limit, "Bound")

  # Access array elements
  constraints(x <= costs[0], "Cost bound")

  # Access nested maps
  constraints(x <= data["A"]["value"], "Data bound")
end
```

## Constant Access

Constants are automatically identified and evaluated:

- **Simple values**: Numbers, atoms, strings
- **Map access**: `map[key]` or `map.key`
- **Nested access**: `map[key1][key2]`
- **Array access**: `array[index]`

### String/Atom Key Conversion

String keys are automatically converted to atom keys when accessing maps:

```elixir
# Both work:
cost["worker"]  # String key
cost[:worker]   # Atom key (converted automatically)
```

## Bindings

Generator variables create bindings available during expression evaluation:

```elixir
variables("x", [i <- 1..n], :continuous)
constraints([i <- 1..n], x(i) <= limit[i], "Bound #{i}")
```

**Binding Scope:**
- Only available within the DSL block where defined
- Can be used in constraint expressions and descriptions
- Not accessible outside `Problem.define` or `Problem.modify`

## Expression Types

### Arithmetic Expressions

```elixir
constraints(x + 2*y <= 10, "Sum")
constraints(x * y <= 5, "Product")
constraints(x / 2 >= 1, "Division")
```

### Comparison Operators

```elixir
constraints(x == 0, "Equality")
constraints(x <= 10, "Less than or equal")
constraints(x >= 0, "Greater than or equal")
constraints(x < 10, "Less than")
constraints(x > 0, "Greater than")
```

### Pattern Functions

```elixir
# Sum with wildcards
constraints(sum(x(:_)) <= 100, "Total")

# Sum with generators
constraints([i <- 1..n], sum(x(i, :_) for i <- 1..n) <= limit, "Row sum")
```

### Non-Linear Functions (Auto-Linearized)

```elixir
# Absolute value
constraints(abs(x - 5) <= 2, "Close to 5")

# Maximum
constraints(max(x, y, z) <= 10, "Bounded max")

# Minimum
constraints(min(x, y, z) >= 0, "Bounded min")

# Logical operations (binary variables)
constraints(x AND y, "Both required")
constraints(x OR y, "At least one")
```

## Evaluation Environment

The evaluation environment is stored in the process dictionary:

- **`:dantzig_eval_env`**: Contains model parameters and current bindings
- Automatically set during DSL block evaluation
- Cleaned up after evaluation

## Related Documentation

- [DSL Syntax Reference](dsl-syntax.md) - Complete syntax guide
- [Model Parameters](model-parameters.md) - Using constants and runtime data
- [Pattern Operations](pattern-operations.md) - Pattern-based operations
