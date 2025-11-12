# Fix Summary: sum(for ...) with Nested Generators

## Problem Identified

In `school_timetabling.exs`, constraints using `sum(for ...)` with nested generators were showing `0 <= 1` or `0 = 1` in the LP output instead of proper variables.

**Example of problematic constraint:**
```elixir
constraints(
  [t <- teachers, m <- time_slots],
  sum(for s <- subjects, r <- rooms, do: schedule(t, s, r, m)) <= 1,
  "Teacher time conflict constraint"
)
```

**LP Output (BEFORE FIX):**
```
Teacher_time_conflict_constraint: 0 <= 1
```

**LP Output (AFTER FIX):**
```
Teacher_time_conflict_constraint: 1 schedule(Teacher1,Math,Room1,Slot1) + 1 schedule(Teacher1,Math,Room2,Slot1) + ... <= 1
```

## Root Cause

The issue was in `lib/dantzig/problem/dsl/expression_parser.ex` in the variable index resolution code. When parsing expressions like `x(o, i)` where `o` and `i` are generator variables:

1. The AST contains atoms `:o` and `:i` as indices
2. The code tried to look them up in the bindings map using `Map.get(bindings, var, ...)`
3. If not found, it fell back to `Enum.find_value` which also failed
4. Finally, it used `|| var`, which returned the atom itself (`:o` or `:i`) instead of the actual value (`"A"` or `"X"`)
5. This caused variable lookup to fail, resulting in zero polynomials

## Solution

Fixed the index resolution in `lib/dantzig/problem/dsl/expression_parser.ex` to properly look up atoms in the bindings map using `Map.fetch/2` instead of `Map.get/3` with a fallback that returns the atom.

**Key Change:**
- Changed from: `Map.get(bindings, var, Enum.find_value(...) || var)`
- Changed to: `Map.fetch(bindings, var)` with proper error handling

This ensures that when we have `x(o, i)` with bindings `%{o: "A", i: "X"}`, the indices are correctly resolved to `["A", "X"]` instead of `[:o, :i]`.

## Would max()/min() Have the Same Issue?

**Yes**, if `max()` or `min()` support `for`-comprehensions with nested generators, they would have the same issue. The fix applies to all expression parsing that uses variable indices, so it would automatically fix `max()`/`min()` as well.

The same index resolution code is used for all variable access patterns, so any function that:
1. Uses `for`-comprehensions with nested generators
2. Accesses variables with indices from those generators

Would benefit from this fix.

## Toy Examples Created

1. **toy_1_sum_for_issue.exs** - Reproduces the issue with minimal example
2. **toy_2_max_min_issue.exs** - Documents that max()/min() would have same issue
3. **toy_3_debug_environment.exs** - Debugs environment access
4. **toy_5_fix_verification.exs** - Verifies the fix works

## Testing

✅ **Toy Example 1**: Now correctly shows `1 x(A,X) + 1 x(A,Y)` instead of `0`
✅ **Toy Example 5**: All 6 constraints have proper variables
✅ **school_timetabling.exs**: Constraints now show proper variables in LP output

## Files Modified

1. `lib/dantzig/problem/dsl/expression_parser.ex` - Fixed index resolution for variable access
2. `lib/dantzig/problem/dsl/expression_parser/sum_processing.ex` - Improved error messages
3. `examples/school_timetabling.exs` - Added model_parameters (though not strictly necessary after fix)

## Next Steps

The fix is complete and working. The constraints in `school_timetabling.exs` now properly include variables in the LP output. The same fix would apply to `max()`/`min()` if they support nested generators.
