# Syntax Issues Found in Example Files

## Summary
Reviewing all example files for DSL syntax correctness. Issues found:

## Files Needing Fixes

### 1. `tutorial_examples.exs` - **MAJOR ISSUES**
**Status**: Uses old imperative API, needs complete rewrite

**Issues**:
- Uses `Problem.new()` instead of `Problem.define do ... end`
- Uses `Problem.variables()` instead of `variables()` inside `Problem.define`
- Uses `Problem.constraints()` instead of `constraints()` inside `Problem.define`
- Uses `Problem.get_var_map()` instead of `Problem.get_variables_nd()`
- Uses `description:` keyword in `Problem.variables()` calls (old API)
- Missing `direction:` parameter in `new()` calls

**Pattern to fix**:
```elixir
# OLD (wrong):
problem = Problem.new(direction: :minimize)
problem = Problem.variables(problem, "x", [i <- 1..4], :binary, description: "X")
problem = Problem.constraints(problem, [i <- 1..4], x(i) == 1, "Constraint")
var_map = Problem.get_var_map(problem, "x")

# NEW (correct):
problem =
  Problem.define do
    new(name: "Problem Name", direction: :minimize)
    variables("x", [i <- 1..4], :binary, "X")
    constraints([i <- 1..4], x(i) == 1, "Constraint")
  end
var_map = Problem.get_variables_nd(problem, "x")
```

**Affected lines**: 
- Lines 19-32 (Example 1: N-Queens)
- Lines 52-69 (Example 2: TSP)
- Lines 80-107 (Example 3: Timetabling)
- Lines 118-131 (Example 4: Knapsack) - also has wrong constraint `x(:_, :_, :_)` for 1D variable
- Lines 142-159 (Example 5: Assignment)
- Lines 170-205 (Example 6: Facility Location)
- Lines 216-241 (Example 7: 3D Problem)
- Lines 251-276 (Summary section using wrong API)

**Number of problems**: 7 examples, all need conversion

---

### 2. `test_basic_dsl.exs` - **MINOR INCONSISTENCY**
**Status**: Works but uses inconsistent syntax

**Issue**:
- Line 18: Uses `description:` keyword argument instead of positional string
- Should be: `variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variables")`
- Currently: `variables("x", [i <- 1..2, j <- 1..2], :binary, description: "Test variables")`

**Note**: This file runs successfully, so the macro might accept both forms, but it's inconsistent with other examples like `simple_working_example.exs` and `assignment_problem.exs` which use positional strings.

---

## Files Already Correct

### ✅ `simple_working_example.exs`
- Uses `Problem.define do ... end`
- Uses `variables()` and `constraints()` correctly
- Uses `Problem.get_variables_nd()` correctly

### ✅ `assignment_problem.exs`
- Uses `Problem.define do ... end`
- Uses `variables()` and `constraints()` correctly
- Uses positional string descriptions

### ✅ `pattern_based_operations_example.exs`
- Fixed in previous commit
- Uses correct syntax

### ✅ `variadic_operations_example.exs`
- Fixed in previous commit
- Uses correct syntax

---

## Unexpected/Non-Obvious Issues

### Issue 1: `description:` keyword vs positional string
**Finding**: Two different syntaxes appear to work:
- Positional: `variables("x", [gens], :type, "description")` ← Most examples use this
- Keyword: `variables("x", [gens], :type, description: "description")` ← Only `test_basic_dsl.exs` uses this

**Question**: Which is the correct/intended syntax? The macro signature at line 199 of `dsl.ex` shows: `variables(var_name, generators, var_type, description)` which suggests positional string is correct.

**Recommendation**: Standardize on positional string (matches most examples and macro signature)

---

### Issue 2: Missing `direction:` in `new()` calls
**Finding**: Some examples omit `direction:` parameter in `new()` calls.

**Examples**:
- `test_basic_dsl.exs` line 12: `new(name: "Test Problem")` - missing `direction:`
- `tutorial_examples.exs` - all `new()` calls missing `direction:`

**Question**: Is `direction:` required or optional? Most working examples include it.

**Recommendation**: Include `direction:` parameter for consistency

---

### Issue 3: Wrong constraint syntax in `tutorial_examples.exs` Example 4
**Line 129**: `Problem.constraints(problem4, [], x(:_, :_, :_) <= 3, "Weight limit")`
- Problem: Uses 3 wildcards `x(:_, :_, :_)` but variable `x` is 1D (only `i <- items`)
- Should be: `x(:_)` or `sum(x(:_))`

**This is a logic error, not just syntax**

---

## Action Items

1. **Fix `tutorial_examples.exs`**: Convert all 7 examples from old API to new DSL syntax
2. **Fix `test_basic_dsl.exs`**: Change `description:` keyword to positional string for consistency
3. **Verify**: Check if `description:` keyword form should be supported or deprecated

---

## Notes

- The old imperative API (`Problem.new()`, `Problem.variables()`, `Problem.constraints()`) appears to still exist but is deprecated in favor of the DSL (`Problem.define` blocks)
- `Problem.modify` exists and is valid (used in `test_basic_dsl.exs` and `assignment_problem.exs`)
- Function name changed: `Problem.get_var_map()` → `Problem.get_variables_nd()`
