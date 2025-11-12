# Constraints Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## Simple Constraints (`constraints/2`)

**Syntax:**

```elixir
constraints(expression, "description")
```

**Operators:**

- ✅ `==`, `<=`, `>=`, `<`, `>`
- ✅ Arithmetic: `+`, `-`, `*`, `/`
- ✅ Variable access: `var_name(index1, index2, ...)`
- ✅ Wildcards: `var_name(:_, index)` (see [Wildcards Syntax](wildcards.md))

**Examples:**

```elixir
constraints(x >= 0, "Non-negative")
constraints(queen2d_1_1 + queen2d_1_2 == 1, "Row 1")
constraints(sum(queen2d(:_, :_)) == 4, "Total queens")
```

## Generator Constraints (`constraints/3`)

**Syntax:**

```elixir
constraints([generators], expression, "description")
```

**Description Interpolation:**

- ✅ String interpolation: `"Constraint #{i}"` expands to `"Constraint 1"`, `"Constraint 2"`, etc.

**Examples:**

```elixir
constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "Row #{i}")
constraints([i <- 1..2, k <- 1..3], sum(queen3d(i, :_, k)) == 1, "Axis #{i},#{k}")
```

**Rules:**

- ✅ Empty generator list `[]` is equivalent to `constraints/2`
- ❌ Generator variables **not accessible** outside constraint expression (only in description interpolation)

## Adding Constraints Outside Blocks

**Syntax:**

```elixir
Problem.add_constraint(problem, expression, "description")
```

**Rules:**

- ❌ **No generators allowed** - must use actual variable names (e.g., `queen2d_1_1`, not `queen2d(1, :_)`)
- ✅ Use `Problem.modify` block if generators needed

## Operators

**Comparison:** `==`, `<=`, `>=`, `<`, `>`

**Arithmetic:** `+`, `-`, `*`, `/`

**Pattern Functions:** `sum(expression)` (see [Wildcards Syntax](wildcards.md))

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Variables Syntax](variables.md) - Variable syntax
- [Wildcards Syntax](wildcards.md) - Wildcard usage
