# Wildcards Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## Wildcard Symbol: `:_`

The `:_` symbol means "iterate through all values" for that dimension.

## Variable Access Patterns

**Syntax:**

```elixir
var_name(index1, :_, index3)    # Wildcard in second position
var_name(:_, index2)             # Wildcard in first position
var_name(:_, :_)                 # All variables
```

**Rules:**

- ✅ `:_` expands to all values from variable's generator domain
- ✅ Can mix explicit indices and wildcards
- ✅ Multiple wildcards expand to cross-product

**Examples:**

```elixir
queen2d(i, :_)      # All j values for fixed i
queen2d(:_, j)      # All i values for fixed j
queen2d(:_, :_)     # All (i, j) combinations
```

## Wildcard in Sum Functions

**Syntax:**

```elixir
sum(var_name(i, :_))      # Sum over j for each i
sum(var_name(:_, :_))     # Sum all variables
sum(qty(:_) * cost[:_])   # With nested map access (see Constants)
```

**Rules:**

- ✅ `sum()` expands wildcards to sum all matching variables
- ✅ Can combine with generator constraints: `constraints([i <- 1..4], sum(x(i, :_)) == 1, "...")`

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Pattern Operations](../pattern-operations.md) - Pattern-based operations
- [Wildcards and Nested Maps](../advanced/wildcards-and-nested-maps.md) - Advanced wildcard usage
