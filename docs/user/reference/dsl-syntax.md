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

## Detailed Syntax Reference

For detailed syntax information, see:

- **[Variables Syntax](syntax/variables.md)** - Variable creation, types, bounds, generators
- **[Constraints Syntax](syntax/constraints.md)** - Constraint definition, operators, generators
- **[Objectives Syntax](syntax/objectives.md)** - Objective functions, directions
- **[Generators Syntax](syntax/generators.md)** - Generator syntax, domains, rules
- **[Wildcards Syntax](syntax/wildcards.md)** - Wildcard usage, sum functions
- **[Constants Syntax](syntax/constants.md)** - Model parameters, nested access

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

**Pattern Functions:** `sum(expression)` (see [Wildcards Syntax](syntax/wildcards.md))

---

## Related Documentation

- [Pattern Operations](pattern-operations.md) - Pattern-based operations with wildcards
- [Variadic Operations](variadic-operations.md) - Variadic max/min/and/or functions
- [Expressions](expressions.md) - Expression evaluation and model parameters
- [Model Parameters](model-parameters.md) - Using constants and runtime data
- [Advanced Topics](DSL_SYNTAX_ADVANCED.md) - Advanced DSL features

---

**REMINDER: This is the GOLDEN REFERENCE. Do not modify without explicit approval.**
