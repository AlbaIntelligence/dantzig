# Issue #1 Implementation Plan: Constant Access with Generator Bindings

**Status:** In Progress
**Priority:** HIGH
**Created:** 2025-01-27

---

## Problem Statement

Constant access expressions like `multiplier[i]` where `i` comes from a generator binding (`[i <- 1..3]`) fail with:

```
ArgumentError: Cannot evaluate constant access expression: {{:., ...}, [{:multiplier, ...}, {:i, ...}]}.
The expression evaluated to nil. Ensure the constant exists in model_parameters and indices are valid.
```

## Root Cause Analysis

### Current Flow

1. **Constraint Generation** (`constraint_manager.ex:17`):
   ```elixir
   def add_constraints(problem, generators, constraint_expr, description) do
     parsed_generators = parse_generators(generators)
     combinations = generate_combinations_from_parsed_generators(parsed_generators)

     Enum.reduce(combinations, problem, fn index_vals, current_problem ->
       bindings = create_bindings(parsed_generators, index_vals)  # ✅ Bindings created here
       constraint = parse_constraint_expression(constraint_expr, bindings, current_problem)
       # ...
     end)
   end
   ```

2. **Constraint Parsing** (`constraint_manager.ex:148`):
   ```elixir
   def parse_constraint_expression(constraint_expr, bindings, problem) do
     # ...
     left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)  # ✅ Bindings passed
   end
   ```

3. **Expression Parsing** (`expression_parser.ex`):
   ```elixir
   def parse_expression_to_polynomial(expr, bindings, problem) do
     # When encountering Access.get AST like multiplier[i]:
     case ConstantEvaluation.try_evaluate_constant(access_expr, bindings) do
       {:ok, val} -> # ✅ Bindings passed, but...
       {:error, _} -> raise ArgumentError  # ❌ Fails here
     end
   end
   ```

### The Issue

The AST for `multiplier[i]` looks like:
```elixir
{{:., [from_brackets: true], [Access, :get]},
 [{:multiplier, [], nil}, {:i, [], nil}]}
```

When `try_evaluate_constant` is called:
- `multiplier` is correctly identified as a constant from `model_parameters`
- `i` is an atom `:i` in the AST, not the bound value (e.g., `1`, `2`, `3`)
- The evaluation tries to access `multiplier[:i]` which doesn't exist, returning `nil`
- This triggers the error

### Why Bindings Aren't Applied

The `ConstantEvaluation.try_evaluate_constant` function receives bindings, but it needs to:
1. **Detect** that `:i` in the AST is a binding variable
2. **Substitute** the binding value before evaluating the constant access
3. **Evaluate** `multiplier[1]`, `multiplier[2]`, etc. instead of `multiplier[:i]`

## Solution Design

### Approach: Binding Substitution Before Constant Evaluation

Instead of trying to evaluate `multiplier[:i]` directly, we need to:

1. **Detect binding variables** in the constant access AST
2. **Substitute binding values** into the AST before evaluation
3. **Evaluate the substituted expression**

### Implementation Steps

#### Step 1: Create Binding Substitution Function

**File:** `lib/dantzig/problem/dsl/expression_parser/constant_evaluation.ex`

Add a function to substitute bindings in AST:

```elixir
defp substitute_bindings_in_ast(ast, bindings) do
  case ast do
    # If it's a binding variable (atom that exists in bindings), substitute
    atom when is_atom(atom) ->
      case Map.get(bindings, atom) do
        nil -> ast  # Not a binding, keep as-is
        value -> value  # Substitute with bound value
      end

    # Recursively substitute in tuples (Access.get nodes)
    {op, meta, args} when is_list(args) ->
      substituted_args = Enum.map(args, &substitute_bindings_in_ast(&1, bindings))
      {op, meta, substituted_args}

    # Lists (for nested access)
    list when is_list(list) ->
      Enum.map(list, &substitute_bindings_in_ast(&1, bindings))

    # Everything else passes through
    other -> other
  end
end
```

#### Step 2: Modify Constant Evaluation to Use Substitution

**File:** `lib/dantzig/problem/dsl/expression_parser.ex`

In the `Access.get` handling code (around line 579):

```elixir
# Before evaluation, substitute bindings
substituted_expr = substitute_bindings_in_ast(access_expr, bindings)

case ConstantEvaluation.try_evaluate_constant(substituted_expr, bindings) do
  {:ok, val} when is_number(val) ->
    Polynomial.const(val)
  # ... rest of handling
end
```

#### Step 3: Handle Nested Access

For nested access like `matrix[i][j]`:

```elixir
# The AST is nested: {{:., ...}, [{{:., ...}, [matrix, i]}, j]}
# We need to substitute both i and j
substituted_expr = substitute_bindings_in_ast(access_expr, bindings)
# This will transform matrix[i][j] to matrix[1][2] when i=1, j=2
```

#### Step 4: Test Cases

Test with the failing cases:

1. **Simple list access** (`test/dantzig/dsl/constant_access_test.exs:69`):
   ```elixir
   constraints(sum(for i <- 1..4, do: x(i) * multiplier[i]) <= 10, "Max constraint")
   ```

2. **Generator binding** (`test/dantzig/dsl/constant_access_test.exs:199`):
   ```elixir
   constraints([i <- 1..3], x(i) * multiplier[i] <= 10, "Constraint #{i}")
   ```

3. **Nested access** (`test/dantzig/dsl/constant_access_test.exs:219`):
   ```elixir
   constraints([i <- 1..2, j <- 1..2], x(i, j) * matrix[i][j] <= 100, "Constraint")
   ```

## Implementation Details

### File Modifications

1. **`lib/dantzig/problem/dsl/expression_parser.ex`**
   - Add `substitute_bindings_in_ast/2` function
   - Modify `Access.get` handling to substitute bindings before evaluation
   - Ensure bindings are passed through all recursive calls

2. **`lib/dantzig/problem/dsl/expression_parser/constant_evaluation.ex`** (if exists)
   - May need to add binding substitution here as well
   - Or ensure it's called before `try_evaluate_constant`

### Edge Cases to Handle

1. **Binding not found**: If `:i` is in AST but not in bindings, keep as-is (might be a variable)
2. **Nested bindings**: Ensure substitution works for deeply nested access
3. **Mixed bindings and variables**: Don't substitute actual variables, only binding atoms
4. **Performance**: Substitution should be efficient for large expressions

### Testing Strategy

1. **Unit tests** for `substitute_bindings_in_ast/2`:
   - Simple substitution: `:i` → `1`
   - Nested substitution: `matrix[:i][:j]` → `matrix[1][2]`
   - No substitution: variables that aren't bindings

2. **Integration tests** using existing failing tests:
   - Run `mix test test/dantzig/dsl/constant_access_test.exs:69`
   - Run `mix test test/dantzig/dsl/constant_access_test.exs:199`
   - Run `mix test test/dantzig/dsl/constant_access_test.exs:219`

3. **Regression tests**: Ensure existing working tests still pass

## Success Criteria

- [ ] All 6 failing constant access tests pass
- [ ] No regressions in existing tests
- [ ] Nested constant access works (`matrix[i][j]`)
- [ ] Performance is acceptable (no significant slowdown)

## Next Steps

1. ✅ Analyze current implementation (DONE)
2. ⏳ Implement `substitute_bindings_in_ast/2`
3. ⏳ Modify constant evaluation to use substitution
4. ⏳ Test with failing cases
5. ⏳ Run full test suite
6. ⏳ Document changes

---

**Notes:**
- This approach preserves the existing architecture
- Minimal changes required
- Backward compatible (only affects constant access with bindings)
- Can be implemented incrementally
