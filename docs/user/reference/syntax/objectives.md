# Objectives Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## `objective/2`

**Syntax:**

```elixir
objective(expression, :direction)
```

**Direction:**

- ✅ `:minimize` or `:maximize` (required, no default)

**Rules:**

- ✅ Only **one** `objective()` allowed per `Problem.define` block
- ❌ **Error**: Multiple `objective()` calls in same block
- ⚠️ **Warning**: Redefining objective with `Problem.set_objective()` (not error)

**Examples:**

```elixir
objective(sum(x(:_)), :maximize)
objective(sum(for food <- food_names, do: qty(food)), :minimize)
```

## `Problem.set_objective/3`

**Syntax:**

```elixir
Problem.set_objective(problem, expression, :direction)
```

**Rules:**

- ❌ **No generators allowed** in expression (must use `for` comprehensions or actual variable names)
- ⚠️ Warning (not error) if objective already exists

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Variables Syntax](variables.md) - Variable syntax
- [Constraints Syntax](constraints.md) - Constraint syntax
