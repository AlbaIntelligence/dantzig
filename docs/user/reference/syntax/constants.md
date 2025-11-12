# Constants Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## Named Constants

Single values passed via `model_parameters`.

**Syntax:**

```elixir
Problem.define(model_parameters: %{multiplier: 7.0}) do
  constraints(x1 + multiplier * x2 <= 10, "Constraint")
end
```

**Rules:**

- ✅ Constants identified automatically (not variables)
- ✅ Can be used in expressions and generator domains

## Enumerated Constants

Indexed sets of values (arrays, maps).

**Syntax:**

```elixir
# 1D array
model_parameters: %{multiplier: [4.0, 5.0, 6.0]}
constraints(sum(for i <- 1..3, do: x(i) * multiplier[i]) <= 10, "...")

# 2D map
model_parameters: %{cost: %{"Alice" => %{"Task1" => 2, "Task2" => 3}}}
constraints(sum(for w <- workers, do: assign(w, t) * cost[w][t]) <= 10, "...")
```

**Access Patterns:**

- ✅ Bracket notation: `cost[worker][task]` (recommended, most general)
- ✅ Dot notation: `cost[worker].task` (only for simple atom keys)
- ✅ Nested access: `foods[:_][nutrient]` (with wildcards, see [Advanced Topics](../advanced/wildcards-and-nested-maps.md))

**Rules:**

- ✅ String keys automatically converted to atom keys when accessing maps
- ✅ Map keys can contain spaces/special characters (only used for constant lookup)
- ❌ Dot notation fails for keys with spaces/special characters

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Model Parameters](../model-parameters.md) - Using constants and runtime data
- [Wildcards and Nested Maps](../advanced/wildcards-and-nested-maps.md) - Advanced constant access
