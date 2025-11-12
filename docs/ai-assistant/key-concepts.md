# Key Concepts

## DSL System

The DSL (Domain-Specific Language) provides a natural syntax for defining optimization problems:

```elixir
Problem.define do
  new(direction: :maximize)
  variables("x", [i <- 1..n], :continuous, min_bound: 0)
  constraints([i <- 1..n], x(i) <= limit[i], "Constraint")
  objective(sum(x(:_)), direction: :maximize)
end
```

**Key Features:**
- Pattern-based modeling with generator syntax
- Automatic variable creation from generators
- Expression evaluation with bindings and constants
- Model parameters for runtime data

## AST Transformation

The AST (Abstract Syntax Tree) system automatically linearizes non-linear expressions:

**Process:**
1. Parse Elixir AST to Dantzig AST
2. Transform non-linear nodes (abs, max, min, and, or)
3. Add auxiliary variables and constraints
4. Return linear problem

**Supported Transformations:**
- `abs(x)` → auxiliary variable with bounds
- `max(x, y, z)` → auxiliary variable with constraints
- `x AND y AND z` → binary linearization
- `x OR y OR z` → binary linearization

## Expression Evaluation

Expressions are evaluated at runtime with access to:

**Model Parameters:**
- Constants passed via `model_parameters: %{...}`
- Accessible in expressions: `constraints(x <= limit)`
- Nested map access: `cost[worker][task]`

**Bindings:**
- Generator variables: `[i <- 1..n]` creates binding `i`
- Available during expression evaluation
- Used in constraints: `constraints([i <- 1..n], x(i) <= limit[i])`

**Evaluation Environment:**
- Stored in process dictionary: `:dantzig_eval_env`
- Contains model parameters and current bindings
- Accessed via `try_evaluate_constant/2` and `evaluate_expression_with_bindings/2`

## Binding Propagation

Generator variables create bindings that propagate through the DSL:

```elixir
variables("x", [i <- 1..n], :continuous)  # Creates binding: i
constraints([i <- 1..n], x(i) <= limit[i])  # Uses binding: i
```

**Binding Scope:**
- Only available within the DSL block where defined
- Not accessible outside `Problem.define` or `Problem.modify`
- Can be used in constraint expressions and descriptions

## Constant Access

Constants from `model_parameters` are accessed in expressions:

**Simple Constants:**
```elixir
Problem.define(model_parameters: %{limit: 100}) do
  constraints(x <= limit)  # limit = 100
end
```

**Nested Map Access:**
```elixir
Problem.define(model_parameters: %{cost: %{"A" => %{"T1" => 10}}}) do
  constraints(sum(assign(w, t) * cost[w][t]) <= budget)
end
```

**String/Atom Key Conversion:**
- String keys automatically converted to atom keys when accessing maps
- Both `cost["worker"]` and `cost[:worker]` work

## Variable Creation

Variables are created with generator syntax:

```elixir
variables("x", [i <- 1..n], :continuous)
```

**Process:**
1. Parse generators: `[i <- 1..n]`
2. Generate combinations: `[1, 2, 3, ..., n]`
3. Create variables: `x_1, x_2, x_3, ..., x_n`
4. Store in Problem struct: `variables: %{"x" => %{...}}`

**N-dimensional Variables:**
```elixir
variables("x", [i <- 1..m, j <- 1..n], :binary)
# Creates: x_1_1, x_1_2, ..., x_m_n
```

## Constraint Creation

Constraints can be created with or without generators:

**Simple Constraints:**
```elixir
constraints(x <= 10, "Bound")
```

**Generator Constraints:**
```elixir
constraints([i <- 1..n], x(i) <= limit[i], "Bound #{i}")
```

**Description Interpolation:**
- Generator variables available in description strings
- `"Constraint #{i}"` expands to `"Constraint 1"`, `"Constraint 2"`, etc.

## Infinity Handling

Special handling for `:infinity` bounds:

- `:infinity` cannot be converted to `Polynomial.const/1`
- `Constraint.new_linear/4` handles `right_hand_side: :infinity` directly
- Solver export for `:infinity` bounds is pending (LP format issue)

## Related Documentation

- [Codebase Overview](codebase-overview.md) - Project structure
- [Module Map](module-map.md) - Module responsibilities
- [Extension Guide](extension-guide.md) - Adding features
