# DSL Syntax Advanced Topics

**Part of**: [DSL_SYNTAX_REFERENCE.md](DSL_SYNTAX_REFERENCE.md) | **See Also**: [DSL_SYNTAX_EXAMPLES.md](DSL_SYNTAX_EXAMPLES.md)

This document covers advanced DSL topics including implementation requirements, error handling, troubleshooting, and performance considerations.

## Implementation Requirements

The DSL implementation MUST support:

1. **Model parameter lookup** in generators: `[food <- food_names]` - food_names should be identified as an unknown symbol and looked up in the model parameters. If a symbol is not found in the model parameters, an error should be raised.
2. **Literal lists** in generators: `[food <- ["bread", "milk"]]`
3. **Literal dictionaries** in generators: `[k, v <- [{"bread", 1}, {"milk", 2}]]`
4. **Range syntax**: `[i <- 1..4, j <- 1..4]`
5. **Pattern matching** in variable access: `queen2d(i, :_)`
6. **Pattern functions** with wildcards: `sum(queen2d(i, :_))`, `max(queen2d(i, :_))`, `min(queen2d(i, :_))`, `count(queen2d(i, :_))`
7. **For comprehensions** in objectives: `sum(for food <- food_names, do: qty(food))`
8. **Variable interpolation** in constraint descriptions: `"One queen per row #{i}"`
9. **Constraint deduplication** and naming clash warnings
10. **Variable range validation** for constraints

## Error Cases

The following are NOT currently supported or should be clearly documented as limitations:

1. **Nested generators** beyond the documented patterns
2. **Complex expressions** in generator lists that cannot be evaluated at compile time
3. **Dynamic constraint names** that cannot be resolved at compile time

- `Problem.add_variable()` - no generators allowed
- `Problem.add_constraint()` - no generators allowed
- `Problem.set_objective()` - no generators allowed

Those limitations are due to the semantics of Elixir macros: it is not possible to provide generators as arguments to macros. `Problem.add_variables(problem, [i <- 1..4], "x", :binary, "Description")` cannot be implemented because it would require a macro to accept a list of generators as an argument.

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
   - Example: When `nutrient = "calories"`, expands to `foods[:_]["calories"]`

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

**Warning:** If sanitization changes a name, the DSL issues a warning:
```
warning: LP format: variable/constraint name 'Supplier A' was modified to 
'Supplier_A' for solver compatibility
```

#### Key Points

- **Dot vs Bracket:** Use bracket notation `[:_][key]` for robustness; dot notation only for simple atom keys
- **Generator Scope:** Generator variables (like `nutrient`) are evaluated before map access
- **Type Conversion:** String keys are automatically converted to atom keys when accessing maps
- **Validation:** The DSL validates that all accessed keys exist in the model parameters
- **DSL ≡ LP Format:** Both use parentheses `ship(A,B)`, only contents are sanitized `ship(A_sanitized,B_sanitized)`
- **Parentheses Preserved:** Maintains traceability from DSL to LP output for debugging

## Error Handling

### Constraint Redefinition

If a constraint with the same name is added multiple times, an error is issued:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row") # Error: duplicate constraint
end
```

### Variable Range Mismatch

If constraint ranges don't match variable ranges, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: constraint range (1..5) doesn't match variable range (1..4)
  constraints([i <- 1..5], sum(queen2d(i, :_)) == 1, "One queen per row")
end
```

### Unknown Variables in Constraints

If a variable referenced in a constraint hasn't been declared, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: queen3d variable not declared
  constraints([i <- 1..4], sum(queen3d(i, :_)) == 1, "One queen per row")
end
```

## Testing Requirements

All syntax patterns in this reference must:

1. **Compile without errors**
2. **Execute successfully**
3. **Produce expected results**
4. **Be covered by tests**

## Troubleshooting

### Common DSL Errors

#### 1. "Undefined variable" errors

**Problem**: `error: undefined variable "i"`

**Cause**: Using generator variables outside of `Problem.define` or `Problem.modify` blocks.

**Solution**: Move the code inside a `Problem.define` or `Problem.modify` block, or use imperative syntax with actual variable names. Generators are not available outside of `Problem.define` or `Problem.modify` blocks.

```elixir
# ❌ Wrong - generator outside block
problem = Problem.add_constraint(problem, queen2d(i, :_) == 1, "Constraint")

# ✅ Correct - inside block
problem = Problem.define do
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "Constraint")
end

# ✅ Correct - imperative with actual names
problem = Problem.add_constraint(problem, queen2d_1_1 + queen2d_1_2 == 1, "Constraint")
```

#### 2. "Function clause" errors

**Problem**: `** (FunctionClauseError) no function clause matching in Problem.new/1`

**Cause**: Passing wrong arguments to `Problem.new`.

**Solution**: Use keyword arguments.

```elixir
# ❌ Wrong
problem = Problem.new("My Problem")

# ✅ Correct
problem = Problem.define do
  new(name: "My Problem", description: "Description")
end
```

#### 3. Constraint name interpolation issues

**Problem**: Constraint names not interpolating correctly (e.g., "One queen per main diagonal" instead of "One queen per diagonal 1").

**Cause**: Missing variable placeholders in constraint descriptions.

**Solution**: Include variable placeholders in descriptions.

```elixir
# ❌ Wrong - no placeholder
constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per diagonal")

# ✅ Correct - with placeholder
constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per diagonal #{i}")
```

### Debugging DSL Issues

#### 1. Check variable names

Use `IO.inspect(problem.variables)` to see actual variable names generated.

#### 2. Verify constraint generation

Use `IO.inspect(problem.constraints)` to see generated constraints.

#### 3. Test with simple examples

Start with basic examples before adding complexity:

```elixir
# Start simple
problem = Problem.define do
  new(name: "Test", description: "Test")
  variables("x", :continuous, "Variable")
  constraints(x >= 0, "Non-negative")
end
```

### Migration from Old Syntax

#### From imperative to declarative

**Old syntax**:

```elixir
problem = Problem.new(name: "Test")
problem = Problem.add_variables(problem, [i <- 1..3], "x", :continuous)
problem = Problem.add_constraints(problem, [i <- 1..3], x(i) >= 0, "Constraint")
```

**New syntax**:

```elixir
problem = Problem.define do
  new(name: "Test", description: "Test")
  variables("x", [i <- 1..3], :continuous, "Variable")
  constraints([i <- 1..3], x(i) >= 0, "Constraint")
end
```

### Best Practices

#### 1. Use descriptive names

```elixir
# ✅ Good
variables("queen_position", [i <- 1..8, j <- 1..8], :binary, "Queen at position (i,j)")

# ❌ Poor
variables("q", [i <- 1..8, j <- 1..8], :binary, "q")
```

#### 2. Use interpolation for constraint names

```elixir
# ✅ Good - descriptive and unique
constraints([i <- 1..8], sum(queen_position(i, :_)) == 1, "One queen per row #{i}")

# ❌ Poor - not unique
constraints([i <- 1..8], sum(queen_position(i, :_)) == 1, "Row constraint")
```

#### 3. Group related variables

```elixir
# ✅ Good - logical grouping
problem = Problem.define do
  new(name: "Production Planning", description: "Production planning problem")

  # Production variables
  variables("produce", [product <- products, month <- months], :continuous, "Production amount")

  # Inventory variables
  variables("inventory", [product <- products, month <- months], :continuous, "Inventory level")

  # Constraints
  constraints([product <- products], sum(produce(product, :_)) >= demand(product), "Demand constraint")
end
```

#### 4. Use model parameters for flexibility

```elixir
# ✅ Good - parameterized
params = %{products: ["A", "B"], months: 1..12}
problem = Problem.define(model_parameters: params) do
  variables("produce", [product <- products, month <- months], :continuous, "Production")
end

# ❌ Poor - hardcoded
problem = Problem.define do
  variables("produce", [product <- ["A", "B"], month <- 1..12], :continuous, "Production")
end
```

## Performance Considerations

### Compile-time vs Runtime

The DSL is designed to generate efficient code at compile time:

- **Variable generation**: All variable combinations are generated at compile time
- **Constraint generation**: All constraint combinations are generated at compile time
- **Pattern expansion**: `sum()`, `max()`, `min()` functions are expanded at compile time

### Memory Usage

- **Variable storage**: Each generated variable is stored as a separate entry
- **Constraint storage**: Each generated constraint is stored as a separate entry
- **Large problems**: For problems with many variables/constraints, consider using model parameters to control size

### Optimization Tips

#### 1. Use appropriate variable types

```elixir
# ✅ Good - binary for yes/no decisions
variables("assign", [task <- tasks, worker <- workers], :binary, "Assignment")

# ❌ Poor - continuous for binary decisions
variables("assign", [task <- tasks, worker <- workers], :continuous, "Assignment")
```

#### 2. Minimize constraint complexity

```elixir
# ✅ Good - simple constraints
constraints([task <- tasks], sum(assign(task, :_)) == 1, "One worker per task")

# ❌ Poor - complex nested constraints (when possible)
constraints([task <- tasks], sum(for worker <- workers, do: assign(task, worker) * skill(worker)) >= 1, "Skilled worker")
```

#### 3. Use model parameters for scalability

```elixir
# ✅ Good - parameterized size
params = %{board_size: 8}
problem = Problem.define(model_parameters: params) do
  variables("queen", [i <- 1..board_size, j <- 1..board_size], :binary, "Queen position")
end

# ❌ Poor - hardcoded size
problem = Problem.define do
  variables("queen", [i <- 1..8, j <- 1..8], :binary, "Queen position")
end
```

## Version History

- **v1.0** - Initial reference based on golden test file and nqueens example
- **Future changes** - Must be explicitly approved and documented

---

**Navigation:**
- [← Back to DSL Syntax Reference](DSL_SYNTAX_REFERENCE.md)
- [← Examples](DSL_SYNTAX_EXAMPLES.md)
