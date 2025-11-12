# Phase 0 Baseline Validation Report

**Date:** 2025-01-08
**Branch:** 002-extended-examples
**Purpose:** Validate current state before proceeding with new examples

## Test Compilation Issues Fixed

1. ✅ Fixed syntax error: `print_optimizer_input:true` → `print_optimizer_input: true` (multiple files)
2. ✅ Fixed duplicate module: `Dantzig.DSL.IntegrationTest` → renamed to `Dantzig.DSL.ComprehensiveIntegrationTest`
3. ✅ Fixed undefined `highs` variable in test files

## Phase 1 Examples Status

### 1. diet_problem.exs - **PARTIALLY FIXED**

**Issues Found:**
- ❌ **CRITICAL**: Wildcard syntax `sum(qty(:_) * foods[:_][nutrient])` does NOT work with nested map access
  - LP showed all constraint coefficients as 0
  - DSL cannot evaluate `foods[:_][nutrient]` where `nutrient` is a generator variable
  
**Fixes Applied:**
- ✅ Replaced wildcard syntax with explicit for comprehensions
- ✅ Fixed variable name parsing: `qty_chicken` → `qty(chicken)`
- ✅ Fixed Enum.each → Enum.reduce for accumulating totals
- ✅ Removed `:infinity` constraint for protein max (causes Polynomial.const error)

**Current State:**
- ✅ LP formulation now correct
- ✅ Solution parsing works
- ⚠️ Solution appears incorrect (needs solver investigation)

**LP Verification:**
```
Min_calories: 420 qty(chicken) + 380 qty(fries) + ... >= 1800  ✅
Min_protein: 32 qty(chicken) + 4 qty(fries) + ... >= 91       ✅
Max_fat: 10 qty(chicken) + 19 qty(fries) + ... <= 65          ✅
```

**DSL Limitation Identified:**
Cannot use `foods[:_][nutrient]` in constraints - requires explicit for comprehensions instead.

---

### 2. transportation_problem.exs - **MINOR BUG**

**Issues Found:**
- ❌ `Float.round/2` called with integer `0` instead of float at line ~297
- ✅ LP formulation is CORRECT

**LP Verification:**
```
Minimize: 2 ship(S1,C1) + 3 ship(S1,C2) + ...  ✅
Constraints: All coefficients correct            ✅
```

**Status:** Needs simple fix (ensure values are floats before rounding)

---

### 3. knapsack_problem.exs - **PERFECT**

**Status:** ✅ No issues found
- LP formulation correct
- Solution correct
- Binary variables properly declared

**LP Verification:**
```
Maximize: 3 select(book) + 6 select(camera) + ... ✅
Weight: 1 select(book) + 2 select(camera) + ...  ✅
Binary variables: select(book), ...               ✅
```

---

### 4. assignment_problem.exs - **COSMETIC ISSUE**

**Issues Found:**
- ⚠️ Runs problem twice (first with wrong coefficients, second with correct)
- First run shows all 1s in objective
- Second run shows correct cost matrix values
- ✅ LP formulation eventually correct

**Status:** Needs investigation why it runs twice

---

## Critical DSL Enhancement Needed

### **Priority Task: Support Wildcard Placeholders with Nested Map Access**

**Current Limitation:**
The DSL cannot handle expressions like:
```elixir
sum(qty(:_) * foods[:_][nutrient])
```

Where:
- `:_` is a wildcard placeholder
- `nutrient` is a generator variable
- `foods[:_][nutrient]` is nested map access with both wildcard and variable

**Workaround:**
Use explicit for comprehensions:
```elixir
sum(for food <- food_names, do: qty(food) * foods[food][nutrient])
```

**Impact:**
- Reduces expressiveness of DSL
- Makes constraints more verbose
- Contradicts documentation comments that suggest wildcard syntax should work

**Recommendation:**
Enhance DSL expression parser to:
1. Detect nested bracket access with wildcards
2. Properly expand wildcards in nested contexts
3. Handle generator variables in nested map lookups

**Files to Modify:**
- `lib/dantzig/problem/dsl/expression_parser.ex`
- Likely need to enhance wildcard expansion logic

---

## Next Steps

1. **High Priority:**
   - Fix transportation_problem.exs Float.round error
   - Investigate diet_problem solver results
   - Investigate assignment_problem duplicate runs
   - **Enhance DSL for wildcard + nested map access**

2. **Medium Priority:**
   - Test Phase 2 examples (two_variable_lp.exs, resource_allocation.exs)
   - Test Phase 3 examples (portfolio_optimization.exs)

3. **Future:**
   - Update diet_problem.exs to demonstrate BOTH syntaxes once DSL is fixed
   - Document DSL patterns and limitations
   - Create comprehensive example validation tests

---

## Test Suite Status

- Full test suite: Compilation errors fixed
- Phase 1 examples: 1 perfect, 2 minor bugs, 1 critical DSL limitation found
- Phase 2 examples: Not yet tested
- Phase 3 examples: Not yet tested

---

**Conclusion:**

The baseline validation revealed one critical DSL limitation (wildcard + nested map access) that should be prioritized for fixing. This will significantly improve DSL expressiveness and make the diet_problem example cleaner and more aligned with the documented syntax patterns.
