# Enumerator Tracking Design Specification

**Based on:** Answers in `LIST_OF_QUESTIONS.md`
**Date:** 2025-01-27
**Status:** Ready for Phase 1 Implementation

---

## Summary of Design Decisions

### 1. Enumerator Identification

**Uniqueness:** Context-aware
- Same enumerator if clear from context (e.g., same `model_parameters`)
- Separate entries if context unclear
- `model_parameters` provides the necessary context

**Naming Strategy:**
- Use parameter names (e.g., `"n"`) not values
- Format: `"enum_{type}_{param_name}"` (e.g., `"enum_range_n"`)
- For literals: Use descriptive identifier based on values

**Equality Detection:**
- **Ranges:** Different if different start OR end value
- **Lists:** Same if values match (structural equality)
- **Maps:** Same if key-value pairs match (order-independent)
- **No source context:** Don't consider where enumerator was defined (too complicated)

### 2. Enumerator Structure

**Metadata to Store:**
- `domain`: Actual enumerable value
- `source`: Map of variables using this enumerator and their positions
- `type`: `:range`, `:list`, `:map`, `:mapset`, etc. (if easy to implement)
- `size`: Number of elements (if computable)
- `source_location`: File/line (if easy to implement)
- `model_parameter_key`: If from `model_parameters` (if easy to implement)
- `name`: String representation (e.g., `"0..n"` or `"n"`)
- `normalized`: Normalized representation (if applicable)
- `is_linearization`: Track if used by linearization-created variables

**Source Tracking:**
- Format: `%{"x" => [0], "y" => [1], "z" => [0, 1]}`
- Don't track: definition order, constraint vs variable usage

### 3. Subset Enumerators

**Approach:**
- Don't create separate enumerator entries for subsets
- Validate during constraint generation: check that each generated variable name exists
- Focus on variable existence validation, not subset tracking for its own sake

**Validation Rules:**
- Enumerators used in constraints must exist OR be valid subsets of variable enumerators
- Index variable names don't matter (e.g., `i` vs `j`)
- Enumerator order doesn't matter as long as enumerators are valid

### 4. Implementation Phases

**Phase 1: Variable Enumerator Tracking (1a, 1b)**
- Add `enumerators` dictionary to `Problem` struct
- Add `variable_enumerators` map to track per-variable enumerator sequences
- Implement enumerator registration during variable definition
- Track enumerator usage in `source` map

**Phase 3: Linearization Variable Tracking (1c, TODO 2)**
- Add `linearization_variables` placeholder to `Problem` struct
- Document design for linearization variable creation
- Create plan/task for full implementation

**Phase 2: Constraint Enumerator Validation**
- Validate enumerators exist or are valid subsets
- Check variable names exist during constraint generation
- Provide helpful error messages

### 5. Data Structure Design

**Problem Struct Additions:**
```elixir
defstruct
  # ... existing fields ...
  enumerators: %{},  # Global enumerator registry
  variable_enumerators: %{},  # Per-variable enumerator key lists
  linearization_variables: %{},  # Placeholder for Phase 3
```

**Enumerator Entry Structure:**
```elixir
%{
  "enum_range_n" => %{
    domain: 0..n,  # Actual enumerable value
    name: "0..n",  # String representation
    normalized: ...,  # Normalized form (if applicable)
    type: :range,  # Optional: if easy to implement
    size: n + 1,   # Optional: if computable
    source_location: {...},  # Optional: if easy
    model_parameter_key: "n",  # Optional: if from model_parameters
    is_linearization: false,  # Track if used by linearization vars
    source: %{
      "x" => [0],  # Variable "x" uses this as first index
      "y" => [1],  # Variable "y" uses this as second index
      "z" => [0, 1]  # Variable "z" uses this as both first and second
    }
  }
}
```

**Variable Enumerator Tracking:**
```elixir
%{
  "x" => ["enum_range_n", "enum_range_m"],  # Ordered list of enumerator keys
  "y" => ["enum_range_n"]
}
```

### 6. Edge Cases

**Dynamic Enumerators:**
- Enumerators evaluated once at definition time
- No support for dynamic `model_parameters` changes

**Nested Enumerators:**
- Support pattern: `variables("x", [i <- 0..n, j <- items[i]], ...)`
- Store `items` as enumerator
- Don't track per-`i` enumerator differences
- Validate variable names exist when creating constraints
- Solver (HiGHS) will catch undefined variables

### 7. Backward Compatibility

- Enumerator tracking is **optional** for now
- Default: empty maps if not used
- **Future task:** Make it required (breaking change)

---

## Implementation Plan

### Phase 1: Variable Enumerator Tracking

**Tasks:**
1. Add fields to `Problem` struct
2. Create enumerator registry functions
3. Modify `VariableManager.add_variables` to register enumerators
4. Track enumerator sequences per variable
5. Generate enumerator names from AST/expressions
6. Store enumerator metadata (domain, name, source, etc.)

**Files to Modify:**
- `lib/dantzig/core/problem.ex` - Add struct fields
- `lib/dantzig/problem/dsl/variable_manager.ex` - Register enumerators
- `lib/dantzig/core/problem/dsl_reducer.ex` - Pass enumerator info

**Testing:**
- Test enumerator registration for variables
- Test enumerator name generation
- Test source tracking
- Test backward compatibility (optional mode)

### Phase 3: Linearization Variable Tracking (Placeholder)

**Tasks:**
1. Add `linearization_variables` field to `Problem` struct
2. Document design for linearization variable creation
3. Create task/plan document for full implementation
4. Add placeholder structure

**Files to Modify:**
- `lib/dantzig/core/problem.ex` - Add placeholder field
- `docs/developer/architecture/` - Document design

### Phase 2: Constraint Enumerator Validation

**Tasks:**
1. Validate enumerators exist or are subsets
2. Check variable names exist during constraint generation
3. Provide helpful error messages
4. Handle nested enumerator patterns

**Files to Modify:**
- `lib/dantzig/problem/dsl/constraint_manager.ex` - Add validation
- `lib/dantzig/problem/dsl/variable_manager.ex` - Helper functions

---

## Open Questions / Future Work

1. **Enumerator Normalization:** How to normalize different enumerable types?
2. **Subset Detection:** Algorithm for detecting if one enumerator is subset of another
3. **Linearization Implementation:** Full design for creating auxiliary variables
4. **Performance:** Impact of enumerator tracking on large problems
5. **Error Messages:** How to present enumerator-related errors to users

---

## Notes

- Keep implementation simple - "if easy to implement" metadata is optional
- Focus on correctness over completeness
- Solver will catch undefined variables, so validation is for better UX
- Index variable names (`i`, `j`) are not important - only enumerator values matter
