# Variables Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## Basic Variables (`variables/3`)

**Syntax:**

```elixir
variables("name", :type, "description")
variables("name", :type, "description", min_bound: value, max_bound: value)
```

**Types:**

- `:continuous` - Real numbers
- `:integer` - Integers
- `:binary` - 0 or 1

**Bounds:**

- ✅ `min_bound` and `max_bound` allowed for `:continuous` and `:integer`
- ✅ Infinity values: `:infinity`, `:infty`, `:inf`, `:pos_infinity`, `:pos_infty`, `:pos_inf`, `:neg_infinity`, `:neg_infty`, `:neg_inf`
- ❌ Bounds **not allowed** for `:binary` variables
- ❌ Floating-point bounds **not allowed** for `:integer` variables

**Examples:**

```elixir
variables("x", :continuous, "Decision variable")
variables("x", :continuous, "Bounded", min_bound: 0, max_bound: 100)
variables("x", :integer, "Integer", min_bound: 0, max_bound: :infinity)
```

## Generator Variables (`variables/4`)

**Syntax:**

```elixir
variables("name", [generators], :type, "description")
```

**Generator Syntax:**

```elixir
[variable <- domain]
[variable_1 <- domain_1, variable_2 <- domain_2, ...]
```

**Domain Types:**

- ✅ Literal lists: `[food <- ["bread", "milk"]]`
- ✅ Ranges: `[i <- 1..4]`
- ✅ Model parameters: `[food <- food_names]` (looked up in `model_parameters`)
- ✅ Multiple dimensions: `[i <- 1..4, j <- 1..4]`

**Rules:**

- ✅ Empty generator list `[]` is equivalent to `variables/3`
- ✅ Generators create cross-product of all combinations
- ❌ Generators **not allowed** outside `Problem.define`/`Problem.modify` blocks

**Examples:**

```elixir
variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity")
variables("x", [i <- 1..4], :binary, "Binary variable")
variables("queen", [i <- 1..4, j <- 1..4], :binary, "Queen position")
```

## Variable Redefinition

**Rules:**

- ❌ **Error**: Redefining same variable with identical generator ranges
- ✅ **Allowed**: Same variable name with different generator ranges (non-overlapping indices)

**Examples:**

```elixir
# ❌ ERROR: Duplicate definition
variables("x", [i <- 1..4], :binary, "X")
variables("x", [i <- 1..4], :binary, "X")

# ✅ OK: Different ranges (non-overlapping)
variables("x", [i <- 1..4], :binary, "X")
variables("x", [i <- 5..8], :binary, "X")
```

## Adding Variables Outside Blocks

**Syntax:**

```elixir
Problem.add_variable(problem, "name", :type, "description")
```

**Rules:**

- ❌ **No generators allowed** - must use actual variable names
- ✅ Use `Problem.modify` block if generators needed

## Variable Types

- `:continuous` - Real numbers
- `:integer` - Integers
- `:binary` - 0 or 1

## Infinity Values

- `:infinity`, `:infty`, `:inf`, `:pos_infinity`, `:pos_infty`, `:pos_inf` (positive infinity)
- `:neg_infinity`, `:neg_infty`, `:neg_inf` (negative infinity)

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Constraints Syntax](constraints.md) - Constraint syntax
- [Generators Syntax](generators.md) - Generator syntax details
