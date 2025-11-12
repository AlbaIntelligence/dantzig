# Generators Syntax

**Part of**: [DSL Syntax Reference](../dsl-syntax.md)

## Generator Syntax

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

## Key Rule

Generators `[i <- 1..4]` are **only allowed** inside `Problem.define` and `Problem.modify` blocks.

## Limitations

These limitations exist due to Elixir macro semantics:

1. **No generator arguments to macros**: Cannot pass generators as arguments to functions outside blocks
2. **Compile-time evaluation**: Generator domains must be evaluable at compile time
3. **Scope restrictions**: Generator variables only available within their defining block

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Variables Syntax](variables.md) - Using generators with variables
- [Constraints Syntax](constraints.md) - Using generators with constraints
