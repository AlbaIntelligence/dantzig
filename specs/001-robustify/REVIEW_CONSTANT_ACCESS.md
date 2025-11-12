# Review: Constant and Enumerated Constant Access Extension

**Date**: 2024-12-19
**Reviewed By**: AI Assistant
**Context**: New syntax extension for accessing constants and enumerated constants via map/list access (e.g., `cost[worker][task]`, `multiplier[i]`)

## Executive Summary

The DSL syntax reference (`docs/user/reference/dsl-syntax.md`) has been extended with section 6: "Access to Constants and to Enumerated Constants". This extension introduces support for:
- Named constants (scalars): `multiplier`
- Indexed constants (lists): `multiplier[i]`
- Nested indexed constants (lists of lists): `matrix[i][j]`
- Map access: `cost[worker][task]`

This review identifies inconsistencies and missing tasks needed to fully implement and document this feature.

## Issues Found

### 1. Inconsistency in `model-parameters-api.md` Contract

**Location**: `specs/001-robustify/contracts/model-parameters-api.md`

**Issue**: Lines 65 and 69 use `params.max_capacity` syntax, which contradicts:
- Line 150: "Parameters are NOT accessed via `params.key` syntax"
- DSL_SYNTAX_REFERENCE.md examples: Direct access like `multiplier`, `cost[worker][task]`

**Examples of inconsistency**:
```elixir
# Line 65 - WRONG syntax
constraints([i <- 1..10],
  x(i) <= params.max_capacity,  # ❌ Should be: max_capacity
  "Capacity constraint"
)

# Line 69 - WRONG syntax
constraints([i <- 1..10],
  x(i) >= params.min_demand,  # ❌ Should be: min_demand
  "Demand constraint"
)
```

**Recommendation**: Update all examples in `model-parameters-api.md` to use direct access syntax, matching `docs/user/reference/dsl-syntax.md`.

### 2. Missing Implementation Tasks

**Current State**: Phase 12 (T155-T162) covers model parameters, but does NOT include tasks for:
- Implementing map/list access (`cost[worker][task]`, `multiplier[i]`)
- Handling `Access.get` AST nodes in expression parsing
- Supporting nested `Access.get` (e.g., `cost[worker][task]`)

**Missing Tasks Needed**:

1. **Expression Parser Enhancement**:
   - Add support for `Access.get` AST nodes in `parse_expression_to_polynomial/3`
   - Handle nested `Access.get` (e.g., `{{:., _, [Access, :get]}, _, [{{:., _, [Access, :get]}, _, [cost, worker]}, task]}`)
   - Evaluate `Access.get` expressions using `evaluate_expression_with_bindings` and convert to constants

2. **Test Coverage**:
   - Tests for scalar constant access: `multiplier`
   - Tests for list index access: `multiplier[i]`
   - Tests for nested list access: `matrix[i][j]`
   - Tests for map access: `cost[worker][task]`
   - Tests for nested map access: `cost[worker][task]`
   - Tests for MapSet access: `tasks` (already supported in generators)

3. **Error Handling**:
   - Clear error messages for undefined constant access
   - Validation for invalid index access (e.g., out of bounds)
   - Type checking for constant access (e.g., list vs map)

### 3. Documentation Gaps

**`docs/user/reference/dsl-syntax.md`**: ✅ Complete (section 6 added)

**model-parameters-api.md**: ⚠️ Needs updates:
- Fix `params.key` syntax to direct access
- Add examples for map/list access patterns
- Update error cases to include map/list access errors

**tasks.md**: ⚠️ Missing tasks for implementation

**spec.md**: ⚠️ Missing functional requirement for constant access

### 4. Implementation Requirements Not Specified

The contract documents do not specify:
- How `Access.get` AST nodes should be evaluated in constraint/objective expressions
- Whether constants should be evaluated at parse time or runtime
- How to handle type mismatches (e.g., accessing list with string key)
- Performance considerations for nested map access

## Recommendations

### Priority 1: Fix Contract Inconsistencies

**Task**: Update `model-parameters-api.md`:
1. Replace all `params.key` syntax with direct access
2. Add examples demonstrating map/list access patterns from `docs/user/reference/dsl-syntax.md`
3. Update error cases to include map/list access scenarios

**Files to Update**:
- `specs/001-robustify/contracts/model-parameters-api.md`

### Priority 2: Add Missing Tasks

**Task**: Add new tasks to `tasks.md` in Phase 12 (or create new Phase 13):

```
## Phase 13: Constant and Enumerated Constant Access (Priority: P1)

**Goal**: Implement map/list access support for constants in constraint/objective expressions

**Dependencies**: Phase 12 (Model Parameters) must be complete

### Tests
- [ ] T164 [P] [CONST] Create tests for scalar constant access in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T165 [P] [CONST] Create tests for list index access (`multiplier[i]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T166 [P] [CONST] Create tests for nested list access (`matrix[i][j]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T167 [P] [CONST] Create tests for map access (`cost[worker][task]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T168 [P] [CONST] Create tests for error cases (undefined constants, invalid indices) in `test/dantzig/dsl/constant_access_test.exs`

### Implementation
- [ ] T169 [CONST] Add Access.get AST node handling to `parse_expression_to_polynomial/3` in `lib/dantzig/problem/dsl/expression_parser.ex`
- [ ] T170 [CONST] Add nested Access.get support (e.g., `cost[worker][task]`) to expression parser
- [ ] T171 [CONST] Integrate `evaluate_expression_with_bindings` for constant evaluation in polynomial parsing
- [ ] T172 [CONST] Add constant lookup in model_parameters for unknown symbols in expressions
- [ ] T173 [CONST] Add error handling for undefined constants, invalid indices, type mismatches
- [ ] T174 [DOC] Update `model-parameters-api.md` with constant access examples and error cases
- [ ] T175 [DOC] Verify `docs/user/reference/dsl-syntax.md` examples align with implementation
```

### Priority 3: Update Functional Requirements

**Task**: Add new functional requirement to `spec.md`:

```markdown
- **FR-015**: System MUST support accessing constants and enumerated constants from model_parameters in constraint/objective expressions via map/list access syntax (e.g., `cost[worker][task]`, `multiplier[i]`, `matrix[i][j]`)
  - **API Contract**: See `docs/user/reference/dsl-syntax.md` section 6 for syntax reference
  - **Acceptance Criteria**:
    1. Scalar constants accessible by direct name: `multiplier`
    2. List constants accessible by index: `multiplier[i]` where `i` is from generator
    3. Nested list constants accessible: `matrix[i][j]`
    4. Map constants accessible: `cost[worker][task]` where `worker` and `task` are from generators
    5. Constants evaluated at parse time and converted to polynomial coefficients
    6. Clear error messages for undefined constants, invalid indices, type mismatches
    7. Backward compatible: existing expressions without constant access continue to work
```

### Priority 4: Update Implementation Requirements

**Task**: Add to `model-parameters-api.md` (or create new section):

```markdown
## Constant Access in Expressions

### Access Pattern
- Constants accessed directly by name: `multiplier` (not `params.multiplier`)
- List constants accessed by index: `multiplier[i]` where `i` is from generator bindings
- Map constants accessed by key: `cost[worker][task]` where `worker` and `task` are from generators
- Nested access supported: `matrix[i][j]`, `cost[worker][task]`

### Evaluation
- Constants evaluated at parse time using `evaluate_expression_with_bindings` with generator bindings
- Evaluated constants converted to polynomial coefficients (numeric values)
- Generator variables (e.g., `i`, `worker`) resolved from generator bindings during evaluation

### Error Cases
- Undefined constant: `cost[worker][task]` where `cost` not in model_parameters
- Invalid index: `multiplier[i]` where `i` out of bounds for list
- Type mismatch: Accessing list with string key or map with integer key (where not supported)
```

## Implementation Strategy

### Step 1: Fix Documentation (Immediate)
- Update `model-parameters-api.md` to use direct access syntax
- Align all examples with `docs/user/reference/dsl-syntax.md`

### Step 2: Add Tests (TDD Approach)
- Write failing tests for constant access patterns
- Ensure tests cover all syntax patterns from `docs/user/reference/dsl-syntax.md`

### Step 3: Implement Expression Parser Support
- Extend `parse_expression_to_polynomial/3` to handle `Access.get` AST nodes
- Integrate with `evaluate_expression_with_bindings` for constant evaluation
- Support nested `Access.get` (e.g., `cost[worker][task]`)

### Step 4: Error Handling
- Add validation for undefined constants
- Add bounds checking for list access
- Add type checking for access patterns

### Step 5: Update Examples
- Update `assignment_problem.exs` to use new syntax (already partially done)
- Create new examples demonstrating constant access patterns

## Testing Requirements

### Test Cases Needed

1. **Scalar Constant Access**:
```elixir
test "scalar constant accessible in constraint" do
  problem = Problem.define(model_parameters: %{multiplier: 7.0}) do
    variables("x", :continuous, "X")
    constraints(x * multiplier <= 10, "Constraint")
  end
  # Verify constraint has correct coefficient
end
```

2. **List Index Access**:
```elixir
test "list constant accessible by index" do
  problem = Problem.define(model_parameters: %{multiplier: [4.0, 5.0, 6.0]}) do
    variables("x", [i <- 1..3], :continuous)
    constraints([i <- 1..3], x(i) * multiplier[i] <= 10, "Constraint")
  end
  # Verify each constraint has correct coefficient
end
```

3. **Map Access**:
```elixir
test "map constant accessible by key" do
  cost_matrix = %{"Alice" => %{"Task1" => 2}}
  problem = Problem.define(model_parameters: %{cost: cost_matrix, workers: ["Alice"], tasks: ["Task1"]}) do
    variables("assign", [worker <- workers, task <- tasks], :binary)
    objective(sum(for worker <- workers, task <- tasks, do: assign(worker, task) * cost[worker][task]), :minimize)
  end
  # Verify objective has correct coefficient
end
```

4. **Error Cases**:
```elixir
test "undefined constant raises error" do
  assert_raise ArgumentError, fn ->
    Problem.define(model_parameters: %{}) do
      variables("x", :continuous)
      constraints(x * undefined_constant <= 10, "Constraint")
    end
  end
end
```

## Success Criteria

- [ ] All examples in `docs/user/reference/dsl-syntax.md` section 6 execute successfully
- [ ] `assignment_problem.exs` uses new syntax and runs cleanly
- [ ] Test coverage includes all constant access patterns
- [ ] Error messages are clear and actionable
- [ ] Backward compatibility maintained (existing code without constant access works)
- [ ] Documentation consistent across all files

## Dependencies

- **Blocks**: None (can be implemented independently)
- **Blocked By**: Phase 12 (Model Parameters) should be complete for full integration
- **Related**: Expression parser enhancements, error handling improvements

## Notes

- Current implementation has `Access.get` handling in `evaluate_expression_with_bindings`, but NOT in `parse_expression_to_polynomial/3`
- Need to bridge these two functions to support constant access in expressions
- MapSet support in generators already works (no changes needed)
- Focus on expression parsing, not generator parsing (generators already support all enumerables)
