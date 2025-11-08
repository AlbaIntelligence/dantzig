# DSL Syntax Reference

**GOLDEN REFERENCE - DO NOT MODIFY WITHOUT EXPLICIT APPROVAL**

This document is the **canonical, self-contained reference** for Dantzig DSL syntax. It provides complete and succinct syntax rules, including disallowed patterns.

## Quick Reference

### Function Signatures

| Context        | Function                   | Signature                                              | Generators?            |
| -------------- | -------------------------- | ------------------------------------------------------ | ---------------------- |
| Inside blocks  | `variables/3`              | `variables("name", :type, "description")`              | ❌ No                  |
| Inside blocks  | `variables/4`              | `variables("name", [gens], :type, "description")`      | ✅ Yes                 |
| Inside blocks  | `constraints/2`            | `constraints(expression, "description")`               | ❌ No                  |
| Inside blocks  | `constraints/3`            | `constraints([gens], expression, "description")`       | ✅ Yes                 |
| Inside blocks  | `objective/2`              | `objective(expression, :direction)`                    | ✅ Yes (in expression) |
| Outside blocks | `Problem.add_variable/4`   | `Problem.add_variable(problem, "name", :type, "desc")` | ❌ No                  |
| Outside blocks | `Problem.add_constraint/3` | `Problem.add_constraint(problem, expr, "desc")`        | ❌ No                  |
| Outside blocks | `Problem.set_objective/3`  | `Problem.set_objective(problem, expr, :direction)`     | ❌ No                  |

**Key Rule**: Generators `[i <- 1..4]` are **only allowed** inside `Problem.define` and `Problem.modify` blocks.

---

## Problem Definition

### `Problem.define`

Creates a new optimization problem.

**Syntax:**

```elixir
problem = Problem.define do
  new(name: "Name", description: "Description")
  # variables, constraints, objective
end
```

**With model parameters:**

```elixir
problem = Problem.define(model_parameters: %{key: value}) do
  # ...
end
```

**Rules:**

- ✅ Must contain exactly one `new()` call
- ✅ Can contain multiple `variables()`, `constraints()`, and one `objective()`
- ❌ Cannot be nested

### `Problem.modify`

Amends an existing problem.

**Syntax:**

```elixir
problem = Problem.modify(problem) do
  # variables, constraints, objective
end
```

**With model parameters:**

```elixir
problem = Problem.modify(problem, model_parameters: %{key: value}) do
  # ...
end
```

**Rules:**

- ✅ Can add/modify variables, constraints, objectives
- ❌ Cannot contain `new()` statement
- ⚠️ Warning issued if variable/constraint name already exists

---

## Variables

### Basic Variables (`variables/3`)

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

### Generator Variables (`variables/4`)

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

### Variable Redefinition

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

### Adding Variables Outside Blocks

**Syntax:**

```elixir
Problem.add_variable(problem, "name", :type, "description")
```

**Rules:**

- ❌ **No generators allowed** - must use actual variable names
- ✅ Use `Problem.modify` block if generators needed

---

## Constraints

### Simple Constraints (`constraints/2`)

**Syntax:**

```elixir
constraints(expression, "description")
```

**Operators:**

- ✅ `==`, `<=`, `>=`, `<`, `>`
- ✅ Arithmetic: `+`, `-`, `*`, `/`
- ✅ Variable access: `var_name(index1, index2, ...)`
- ✅ Wildcards: `var_name(:_, index)` (see Wildcards section)

**Examples:**

```elixir
constraints(x >= 0, "Non-negative")
constraints(queen2d_1_1 + queen2d_1_2 == 1, "Row 1")
constraints(sum(queen2d(:_, :_)) == 4, "Total queens")
```

### Generator Constraints (`constraints/3`)

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

### Adding Constraints Outside Blocks

**Syntax:**

```elixir
Problem.add_constraint(problem, expression, "description")
```

**Rules:**

- ❌ **No generators allowed** - must use actual variable names (e.g., `queen2d_1_1`, not `queen2d(1, :_)`)
- ✅ Use `Problem.modify` block if generators needed

---

## Objectives

### `objective/2`

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

### `Problem.set_objective/3`

**Syntax:**

```elixir
Problem.set_objective(problem, expression, :direction)
```

**Rules:**

- ❌ **No generators allowed** in expression (must use `for` comprehensions or actual variable names)
- ⚠️ Warning (not error) if objective already exists

---

## Generators

### Generator Syntax

**Format:**

```elixir
[variable <- domain]
[variable_1 <- domain_1, variable_2 <- domain_2, ...]
```

**Domain Types:**

- ✅ Literal lists: `["bread", "milk"]`
- ✅ Ranges: `1..4`
- ✅ Model parameters: `food_names` (looked up in `model_parameters`)
- ✅ Variables from outer scope (evaluated at macro expansion time)

**Rules:**

- ✅ Multiple generators create cross-product
- ✅ Generator variables available in block expressions and description interpolation
- ❌ Generator variables **not available** outside `Problem.define`/`Problem.modify` blocks
- ❌ Complex expressions in domain that cannot be evaluated at compile time

**Examples:**

```elixir
[food <- ["bread", "milk"]]
[i <- 1..4]
[i <- 1..4, j <- 1..4]
[food <- food_names]  # food_names from model_parameters
```

---

## Wildcards

### Wildcard Symbol: `:_`

The `:_` symbol means "iterate through all values" for that dimension.

### Variable Access Patterns

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

### Wildcard in Sum Functions

**Syntax:**

```elixir
sum(var_name(i, :_))      # Sum over j for each i
sum(var_name(:_, :_))     # Sum all variables
sum(qty(:_) * cost[:_])   # With nested map access (see Constants)
```

**Rules:**

- ✅ `sum()` expands wildcards to sum all matching variables
- ✅ Can combine with generator constraints: `constraints([i <- 1..4], sum(x(i, :_)) == 1, "...")`

---

## Constants

### Named Constants

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

### Enumerated Constants

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
- ✅ Nested access: `foods[:_][nutrient]` (with wildcards, see Advanced)

**Rules:**

- ✅ String keys automatically converted to atom keys when accessing maps
- ✅ Map keys can contain spaces/special characters (only used for constant lookup)
- ❌ Dot notation fails for keys with spaces/special characters

---

## Restrictions

### Disallowed Patterns

#### Outside Blocks

- ❌ **Generators not allowed** in `Problem.add_variable()`, `Problem.add_constraint()`, `Problem.set_objective()`
- ❌ **Wildcard syntax not allowed** outside blocks (must use actual variable names)

#### Variable Bounds

- ❌ **No bounds** for `:binary` variables
- ❌ **No floating-point bounds** for `:integer` variables

#### Problem Definition

- ❌ **No `new()`** in `Problem.modify()` blocks
- ❌ **Multiple `objective()`** in same `Problem.define` block

#### Generators

- ❌ **Complex expressions** in generator domains that cannot be evaluated at compile time
- ❌ **Nested generators** beyond documented patterns
- ❌ **Generator variables** not accessible outside `Problem.define`/`Problem.modify` blocks

#### Constraints

- ❌ **Dynamic constraint names** that cannot be resolved at compile time
- ❌ **Generator variables** in constraint expressions outside the generator scope

### Limitations

These limitations exist due to Elixir macro semantics:

1. **No generator arguments to macros**: Cannot pass generators as arguments to functions outside blocks
2. **Compile-time evaluation**: Generator domains must be evaluable at compile time
3. **Scope restrictions**: Generator variables only available within their defining block

---

## Function Reference

### Inside Blocks

| Function      | Arity | Signature                                  | Description             |
| ------------- | ----- | ------------------------------------------ | ----------------------- |
| `new`         | 1     | `new(name: string, description: string)`   | Create problem metadata |
| `variables`   | 3     | `variables("name", :type, "desc")`         | Single variable         |
| `variables`   | 4     | `variables("name", [gens], :type, "desc")` | Multiple variables      |
| `constraints` | 2     | `constraints(expr, "desc")`                | Single constraint       |
| `constraints` | 3     | `constraints([gens], expr, "desc")`        | Multiple constraints    |
| `objective`   | 2     | `objective(expr, :direction)`              | Objective function      |

### Outside Blocks

| Function                 | Arity | Signature                                              | Description           |
| ------------------------ | ----- | ------------------------------------------------------ | --------------------- |
| `Problem.add_variable`   | 4     | `Problem.add_variable(problem, "name", :type, "desc")` | Add single variable   |
| `Problem.add_constraint` | 3     | `Problem.add_constraint(problem, expr, "desc")`        | Add single constraint |
| `Problem.set_objective`  | 3     | `Problem.set_objective(problem, expr, :direction)`     | Set objective         |

### Variable Types

- `:continuous` - Real numbers
- `:integer` - Integers
- `:binary` - 0 or 1

### Infinity Values

- `:infinity`, `:infty`, `:inf`, `:pos_infinity`, `:pos_infty`, `:pos_inf` (positive infinity)
- `:neg_infinity`, `:neg_infty`, `:neg_inf` (negative infinity)

### Operators

**Comparison:** `==`, `<=`, `>=`, `<`, `>`

**Arithmetic:** `+`, `-`, `*`, `/`

**Pattern Functions:** `sum(expression)` (see Wildcards section)

---

## Related Documentation

- **[DSL_SYNTAX_EXAMPLES.md](DSL_SYNTAX_EXAMPLES.md)** - Complete working examples
- **[DSL_SYNTAX_ADVANCED.md](DSL_SYNTAX_ADVANCED.md)** - Wildcard + nested maps, error handling, troubleshooting

---

**REMINDER: This is the GOLDEN REFERENCE. Do not modify without explicit approval.**
