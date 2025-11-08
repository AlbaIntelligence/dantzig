# DSL Syntax Enhancement Proposal: Wildcard + Nested Access

**Status:** PROPOSED - Awaiting Approval
**Date:** 2025-01-08
**Related Issue:** Phase 0 Baseline - diet_problem.exs constraint coefficients

## Current Limitation

The DSL currently **does NOT support** wildcard placeholders (`:_`) combined with nested map/bracket access when generator variables are involved.

### Broken Syntax (Current)

```elixir
# DOES NOT WORK - produces coefficients of 0
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_][nutrient]) <= limit,
  "Max #{nutrient}"
)
```

### Required Workaround

```elixir
# WORKS - but verbose
constraints(
  [nutrient <- nutrient_names],
  sum(for food <- food_names, do: qty(food) * foods[food][nutrient]) <= limit,
  "Max #{nutrient}"
)
```

## Proposed Enhancement

### Goal: Support Four Equivalent Syntaxes

All four syntaxes should produce **identical** results:

```elixir
# Given:
model_parameters: %{
  foods: %{
    "bread" => %{calories: 100, protein: 3, fat: 1},
    "milk" => %{calories: 150, protein: 8, fat: 2.5}
  },
  food_names: ["bread", "milk"],
  nutrient_names: ["calories", "protein", "fat"]
}

variables("qty", [food <- food_names], :continuous, "Food quantity")

# SYNTAX A: Explicit for comprehension with bracket access (CURRENT - WORKS)
constraints(
  [nutrient <- nutrient_names],
  sum(for food <- food_names, do: qty(food) * foods[food][nutrient]) <= limit,
  "Max #{nutrient}"
)

# SYNTAX B: Explicit for comprehension with dot notation (PROPOSED - verify)
constraints(
  [nutrient <- nutrient_names],
  sum(for food <- food_names, do: qty(food) * foods[food].nutrient) <= limit,
  "Max #{nutrient}"
)

# SYNTAX C: Wildcard with bracket access (PROPOSED - currently broken)
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_][nutrient]) <= limit,
  "Max #{nutrient}"
)

# SYNTAX D: Wildcard with dot notation (PROPOSED - currently broken)
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_].nutrient) <= limit,
  "Max #{nutrient}"
)
```

### Expected LP Output (All Should Produce This)

```lp
Max_calories: 100 qty(bread) + 150 qty(milk) <= 2000
Max_protein: 3 qty(bread) + 8 qty(milk) <= 100
Max_fat: 1 qty(bread) + 2.5 qty(milk) <= 50
```

## Implementation Notes

### Wildcard Expansion Logic

When the DSL encounters `foods[:_][nutrient]`:

1. **Detect wildcard in nested access:** Identify `:_` in bracket/dot access chain
2. **Determine expansion context:** Find the generator variables in scope
3. **Map wildcard to generator:** Match `:_` position to corresponding variable generator
4. **Expand before evaluation:** Transform to explicit access before constant lookup

Example expansion:

```elixir
# Input:
sum(qty(:_) * foods[:_][nutrient])

# With food <- food_names where food_names = ["bread", "milk"]
# And nutrient bound to "calories"

# Should expand to:
qty(bread) * foods[bread][calories] + qty(milk) * foods[milk][calories]

# Which evaluates to:
qty(bread) * 100 + qty(milk) * 150
```

### Dot Notation Support

Dot notation `foods[:_].nutrient` should be equivalent to bracket notation `foods[:_][nutrient]`:

```elixir
foods[:_].nutrient  ≡  foods[:_][nutrient]
```

Where `nutrient` is a generator variable that gets interpolated as an atom key.

### Generator Variable Scoping

The key insight is that `nutrient` in `foods[:_][nutrient]` is a **generator variable** bound in the constraint generator `[nutrient <- nutrient_names]`, not a symbolic reference.

The DSL must:

1. Recognize `nutrient` as a bound variable from the generator
2. Evaluate it to its current value (e.g., `"calories"`)
3. Use that value to access the nested map

## Future Enhancement: Einstein Notation

**Long-term vision:** Automatic index matching similar to Einstein summation notation.

```elixir
# Future syntax - DSL auto-detects shared indices
variables("x", [i <- 1..3], :continuous, "X")
variables("y", [i <- 1..3, j <- 1..4], :continuous, "Y")

# Einstein-like notation - automatically matches index i
objective(sum(x(:_) * y(:_, :_)), :maximize)

# Expands to:
objective(
  sum(for i <- 1..3, j <- 1..4, do: x(i) * y(i, j)),
  :maximize
)
```

**Benefits:**

- More concise notation
- Automatic index alignment (like matrix/tensor operations)
- Reduces cognitive load for complex multi-dimensional problems

**Challenges:**

- Need to track dimension metadata for each variable
- Ambiguity resolution when multiple index patterns match
- Backward compatibility with explicit syntax

## Proposed DSL_SYNTAX_REFERENCE.md Addition

Add new section **"### 7. Wildcard Access with Nested Maps"** after section 6:

````markdown
### 7. Wildcard Access with Nested Maps

The DSL supports wildcard placeholders (`:_`) combined with nested map access, allowing concise notation for constraints involving multidimensional data structures.

#### Equivalent Syntaxes

All four syntaxes below are equivalent and produce identical constraints:

```elixir
# Setup
model_parameters: %{
  foods: %{
    "bread" => %{calories: 100, protein: 3},
    "milk" => %{calories: 150, protein: 8}
  },
  food_names: ["bread", "milk"],
  nutrient_names: ["calories", "protein"]
}

variables("qty", [food <- food_names], :continuous, "Food quantity")

# Syntax A: Explicit for comprehension with bracket access
constraints(
  [nutrient <- nutrient_names],
  sum(for food <- food_names, do: qty(food) * foods[food][nutrient]) <= limit[nutrient],
  "Max #{nutrient}"
)

# Syntax B: Explicit for comprehension with dot notation
constraints(
  [nutrient <- nutrient_names],
  sum(for food <- food_names, do: qty(food) * foods[food].nutrient) <= limit[nutrient],
  "Max #{nutrient}"
)

# Syntax C: Wildcard with bracket access (concise)
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_][nutrient]) <= limit[nutrient],
  "Max #{nutrient}"
)

# Syntax D: Wildcard with dot notation (concise)
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_].nutrient) <= limit[nutrient],
  "Max #{nutrient}"
)
```
````

#### Wildcard Expansion Rules

1. **Single wildcard with nested access:**

   - `foods[:_][nutrient]` expands to `foods[food_1][nutrient] + foods[food_2][nutrient] + ...`
   - Where `food_1, food_2, ...` are values from the variable generator

2. **Multiple wildcards:**

   - `matrix[:_][:_]` expands to all combinations
   - Wildcards are matched positionally to variable generators

3. **Mixed wildcards and explicit indices:**

   - `data[i][:_]` - second dimension uses wildcard, first is explicit
   - `data[:_][j]` - first dimension uses wildcard, second is explicit

4. **Generator variable in nested access:**
   - `foods[:_][nutrient]` where `nutrient` is a generator variable
   - The generator variable value is evaluated at expansion time
   - Example: When `nutrient = "calories"`, expands to `foods[:_][calories]`

#### Complete Diet Problem Example

```elixir
# Diet problem demonstrating wildcard + nested access
foods = %{
  "bread" => %{cost: 2.0, calories: 100, protein: 3, fat: 1},
  "milk" => %{cost: 1.0, calories: 150, protein: 8, fat: 2.5},
  "cheese" => %{cost: 3.0, calories: 200, protein: 10, fat: 8}
}

nutrient_limits = %{
  "calories" => %{min: 1800, max: 2200},
  "protein" => %{min: 50, max: :infinity},
  "fat" => %{min: 0, max: 65}
}

problem = Problem.define model_parameters: %{
  foods: foods,
  food_names: Map.keys(foods),
  nutrient_names: Map.keys(nutrient_limits),
  nutrient_limits: nutrient_limits
} do
  new(name: "Diet Problem", description: "Minimize cost while meeting nutrition")

  variables("qty", [food <- food_names], :continuous,
    min_bound: 0.0,
    description: "Quantity of each food"
  )

  # CONCISE SYNTAX using wildcards:
  constraints(
    [nutrient <- nutrient_names],
    sum(qty(:_) * foods[:_][nutrient]) >= nutrient_limits[nutrient].min,
    "Min #{nutrient}"
  )

  constraints(
    [nutrient <- nutrient_names],
    sum(qty(:_) * foods[:_][nutrient]) <= nutrient_limits[nutrient].max,
    "Max #{nutrient}"
  )

  # OR EQUIVALENT VERBOSE SYNTAX:
  # constraints(
  #   [nutrient <- nutrient_names],
  #   sum(for food <- food_names, do: qty(food) * foods[food][nutrient]) >= nutrient_limits[nutrient].min,
  #   "Min #{nutrient}"
  # )

  objective(sum(qty(:_) * foods[:_].cost), :minimize)
end
```

#### Naming Constraints and Best Practices

##### Variable Index Names

When using generator variables to create variable indices, the index values become part of variable names. Both DSL and LP formats use **parenthesis notation**. Only the characters **inside** the parentheses are sanitized for LP compatibility.

**Example:**

```elixir
suppliers = ["Supplier A", "Supplier-1", "Tokyo (Main)"]
customers = ["Customer #1", "NYC Office"]

variables("ship", [s <- suppliers, c <- customers], :continuous)

# DSL level (what you write):
ship(Supplier A, Customer #1)
ship(Supplier A, NYC Office)
ship(Tokyo (Main), Customer #1)

# LP level (parentheses preserved, contents sanitized):
ship(Supplier_A,Customer_1)
ship(Supplier_A,NYC_Office)
ship(Tokyo_Main,Customer_1)
```

**Key Point:** Parentheses are **preserved** in LP format. Only spaces and special characters **within** the indices are sanitized.

**Best Practice:** Use simple identifiers when possible:

- ✅ Good: `["supplier_a", "supplier_b"]` → `ship(supplier_a,customer_1)`
- ⚠️ Works: `["Supplier A", "Tokyo (Main)"]` → `ship(Supplier_A,Tokyo_Main)` (contents sanitized)
- ❌ Avoid: Excessively long names or extreme special characters

**Benefits of Preserving Parentheses:**

- Easy visual verification: DSL `qty(bread)` matches LP `qty(bread)`
- Clearer debugging: Can trace variables from DSL to LP format
- Maintains consistency across representation layers

**Note:** The DSL issues a warning when index contents are sanitized for LP compatibility.

##### Map Keys in Nested Access

Map keys used in nested access (e.g., `foods[:_][nutrient]`) are **only used for constant evaluation** at the Elixir level, not as symbolic names. Therefore, they can contain any valid map key characters.

**Example:**

```elixir
# Map keys with spaces and special characters are fine
foods = %{
  "bread" => %{
    "total calories": 100,
    "protein (g)": 3,
    "fat %": 1.5
  }
}

nutrient_names = ["total calories", "protein (g)", "fat %"]

# This works correctly:
constraints(
  [nutrient <- nutrient_names],
  sum(qty(:_) * foods[:_][nutrient]) >= min_nutrient[nutrient],
  "Min #{nutrient}"
)

# Generated constraint names (sanitized for LP):
# Min_total_calories
# Min_protein_g
# Min_fat_
```

**Key Point:** The nested map access `foods[:_][nutrient]` is evaluated to numeric constants (100, 3, 1.5) before LP generation. Only the constraint description `"Min #{nutrient}"` uses the key as a string, which is then sanitized.

##### Bracket vs Dot Notation: When to Use Each

The DSL supports both bracket and dot notation for nested map access, but they have different constraints:

**Bracket Notation (Recommended - Most General)**

**Syntax:** `foods[:_][nutrient]`

**Use when:**

- Map keys contain spaces: `"total calories"`
- Map keys contain special characters: `"protein (g)"`, `"fat %"`
- Keys are strings (not atoms)
- Generator variables may produce complex keys
- Maximum flexibility needed

**Example:**

```elixir
nutrient_names = ["total calories", "protein (g)", "fat %"]
foods = %{"bread" => %{"total calories": 100, "protein (g)": 3}}

# Works perfectly:
sum(qty(:_) * foods[:_][nutrient])  # ✅
```

**Dot Notation (Syntactic Sugar - Simple Keys Only)**

**Syntax:** `foods[:_].nutrient`

**Use when:**

- Map keys are simple atoms: `:calories`, `:protein`, `:fat`
- Keys have no spaces or special characters
- Cleaner, more Elixir-idiomatic syntax desired

**Example:**

```elixir
nutrient_names = [:calories, :protein, :fat]  # Atoms, no spaces
foods = %{bread: %{calories: 100, protein: 3}}

# Clean and idiomatic:
sum(qty(:_) * foods[:_].nutrient)  # ✅
```

**Avoid dot notation when:**

- Keys contain spaces or special chars
- Would require quoted atom syntax: `.:"complex key"`

**Equivalence (Simple Keys Only)**

For simple atom keys, these are equivalent:

```elixir
foods[:_].calories  ≡  foods[:_][:calories]
foods[:_][nutrient] ≡  foods[:_].nutrient   # Only if nutrient is simple atom
```

**Best Practice:** Use bracket notation `[:_][key]` for robustness unless you're certain all keys are simple atoms.

##### When Sanitization Occurs

The DSL sanitizes names automatically in these contexts:

1. **Variable names** - When generating LP variable declarations
2. **Constraint names** - When generating LP constraint declarations
3. **Objective name** - When generating LP objective declaration

**What is NOT sanitized:**

- Map keys in `model_parameters` (used only for constant lookup)
- Values in generator lists (used only for constant lookup)

##### Sanitization Rules

The LP sanitization process:

- Replaces spaces with underscores: `"Supplier A"` → `"Supplier_A"`
- Removes special characters: `"Item #1"` → `"Item_1"`
- Adds prefix if starts with digit: `"1st_item"` → `"x_1st_item"`
- Truncates if too long (solver-dependent)

**Warning:** If sanitization changes a name, the DSL issues an info warning:

```
info: LP format: variable/constraint name 'Supplier A' was modified to
'Supplier_A' for solver compatibility
```

#### Key Points

- **Dot vs Bracket:** Use bracket notation `[:_][key]` for robustness; dot notation only for simple atom keys
- **Generator Scope:** Generator variables (like `nutrient`) are evaluated before map access
- **Type Conversion:** String keys are automatically converted to atom keys when accessing maps
- **Validation:** The DSL validates that all accessed keys exist in the model parameters
- **DSL ≡ LP Format:** Both use parentheses `ship(A,B)`, only contents are sanitized `ship(A_sanitized,B_sanitized)`
- **Parentheses Preserved:** Maintains traceability from DSL to LP output for debugging

```

## Backward Compatibility

✅ **Fully backward compatible** - existing explicit syntax continues to work
✅ **Opt-in enhancement** - new wildcard syntax is optional
✅ **No breaking changes** - only adds new supported patterns

## Testing Requirements

1. **Unit tests** for wildcard expansion with nested access
2. **Integration tests** comparing all four syntaxes produce identical LP
3. **Edge cases:**
   - Missing keys in nested maps
   - Type mismatches (string vs atom keys)
   - Multiple levels of nesting
   - Mixed wildcard and explicit indices

## Files to Modify

### Core Implementation
- `lib/dantzig/problem/dsl/expression_parser.ex` - Wildcard expansion logic
- `lib/dantzig/problem/dsl/constraint_manager.ex` - Constraint parsing with wildcards

### Tests
- `test/dantzig/dsl/wildcard_nested_access_test.exs` (NEW)
- Update existing DSL tests to cover new patterns

### Documentation
- `docs/DSL_SYNTAX_REFERENCE.md` - Add section 7 as shown above
- `examples/diet_problem.exs` - Show both syntaxes side-by-side

## Questions for Approval

1. **Approve the four equivalent syntaxes?** (A, B, C, D as shown)
2. **Approve the DSL_SYNTAX_REFERENCE.md addition?** (Section 7)
3. **Priority for implementation?** (Should this block other example work?)
4. **Einstein notation vision?** (Keep as future enhancement or deprioritize?)

---

**Awaiting your approval to:**
1. Update DSL_SYNTAX_REFERENCE.md with Section 7
2. Begin implementation of wildcard + nested access support
3. Update diet_problem.exs to demonstrate both syntaxes once implemented
```
