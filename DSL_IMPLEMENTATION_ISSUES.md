# DSL Implementation Issues - Detailed List

**Last Updated:** 2025-01-27
**Status:** Active issues requiring implementation work
**Test Suite Status:** 288 failures remaining (down from 308)

---

## Overview

This document catalogs outstanding DSL implementation issues identified through test suite analysis. These issues require architectural changes or feature implementations rather than simple test updates.

---

## 1. Constant Access with Generator Bindings

### Issue Description

Constant access expressions like `multiplier[i]` where `i` comes from a generator binding (`[i <- 1..3]`) fail with "Cannot evaluate constant access expression... The expression evaluated to nil."

### Affected Tests

- `test/dantzig/dsl/constant_access_test.exs:69` - List constant accessible by index in constraint expression
- `test/dantzig/dsl/constant_access_test.exs:86` - List constant accessible by index in objective expression
- `test/dantzig/dsl/constant_access_test.exs:199` - Constant access works with generator bindings in constraints
- `test/dantzig/dsl/constant_access_test.exs:219` - Constant access works with multiple generator bindings
- `test/dantzig/dsl/constant_access_test.exs:227` - Nested constant access with bindings

### Root Cause

The expression parser attempts to evaluate constant access expressions (`multiplier[i]`) at parse time, but the binding `i` is not available until constraint generation time. The constant access evaluation happens before bindings are applied.

### Current Behavior

```elixir
# This fails:
Problem.define model_parameters: %{multiplier: [4.0, 5.0, 6.0]} do
  variables("x", [i <- 1..3], :continuous, "Xs")
  constraints([i <- 1..3], x(i) * multiplier[i] <= 10, "Constraint #{i}")
end
# Error: Cannot evaluate constant access expression... evaluated to nil
```

### Expected Behavior

The constant access should be deferred until constraint generation time when bindings are available. The expression `multiplier[i]` should resolve to `multiplier[1]`, `multiplier[2]`, `multiplier[3]` for each generated constraint.

### Implementation Requirements

1. **Deferred Constant Evaluation**: Modify `ExpressionParser.parse_expression_to_polynomial/3` to detect constant access expressions with binding variables and defer evaluation
2. **Binding-Aware Constant Access**: Create a mechanism to evaluate constant access expressions at constraint generation time with actual binding values
3. **Nested Access Support**: Support nested constant access like `matrix[i][j]` with multiple generator bindings

### Files to Modify

- `lib/dantzig/problem/dsl/expression_parser.ex` - Add deferred constant evaluation
- `lib/dantzig/problem/dsl/constraint_manager.ex` - Pass bindings to constant evaluation
- `lib/dantzig/core/problem/ast.ex` - Support binding-aware constant access AST nodes

### Priority: **HIGH** - Blocks 6+ tests, core DSL functionality

---

## 2. Description Interpolation with AST

### Issue Description

Constraint descriptions with AST interpolation (e.g., `quote do: "Position (#{i}, #{j})"`) are not properly evaluated, falling back to generic names like `"constraint_2_3"` instead of `"Position (2, 3)"`.

### Affected Tests

- `test/dantzig/problem/dsl/constraint_manager_test.exs:59` - Handles description with multiple AST interpolations
- `test/dantzig/problem/dsl/constraint_manager_test.exs:84` - Handles description with expression interpolation

### Root Cause

The `create_constraint_name/3` function attempts to use `Code.eval_quoted/2` for AST descriptions, but the evaluation is failing and falling back to the generic name pattern.

### Current Behavior

```elixir
description_ast = quote do: "Position (#{i}, #{j})"
bindings = %{i: 2, j: 3}
result = ConstraintManager.create_constraint_name(description_ast, bindings, [2, 3])
# Returns: "constraint_2_3" (fallback)
# Expected: "Position (2, 3)"
```

### Expected Behavior

AST descriptions should be properly evaluated with bindings to produce interpolated strings.

### Implementation Requirements

1. **Fix Code.eval_quoted Usage**: Ensure bindings are correctly passed to `Code.eval_quoted/2`
2. **Error Handling**: Improve error handling to diagnose why evaluation fails
3. **AST Transformation**: May need to transform the AST before evaluation to ensure compatibility

### Files to Modify

- `lib/dantzig/problem/dsl/constraint_manager.ex` - Fix `create_constraint_name/3` AST handling

### Priority: **MEDIUM** - Affects 2 tests, impacts user experience with constraint naming

---

## 3. Generator Domain Type Support

### Issue Description

Generators currently only support lists, but tests expect support for other enumerable types like `MapSet` and `Range` from `model_parameters`.

### Affected Tests

- `test/dantzig/dsl/constant_access_test.exs:335` - MapSet enumerable works in generators (partially fixed by converting to list)
- `test/dantzig/dsl/constant_access_test.exs:348` - Range enumerable works in generators

### Root Cause

The generator parser (`parse_generators`) checks that domains evaluate to lists and raises an error for other enumerable types.

### Current Behavior

```elixir
# This fails:
Problem.define model_parameters: %{range: 1..5} do
  variables("x", [i <- range], :continuous, "Xs")  # Error: must evaluate to a list
end
```

### Expected Behavior

Generators should accept any enumerable type (lists, ranges, MapSets, etc.) and convert them to lists internally.

### Implementation Requirements

1. **Enumerable Support**: Modify `parse_generators` to accept any enumerable and convert to list
2. **Type Conversion**: Add conversion logic for Range, MapSet, and other enumerables
3. **Error Messages**: Improve error messages to suggest conversion if needed

### Files to Modify

- `lib/dantzig/problem/dsl/variable_manager.ex` - Update `parse_generators` to handle enumerables
- `lib/dantzig/core/problem/ast.ex` - Support enumerable domain types

### Priority: **MEDIUM** - Affects 2 tests, improves DSL usability

---

## 4. Nested Map Access with Bindings

### Issue Description

Nested map access patterns like `cost[worker][task]` or `matrix[i][j]` with generator bindings may not be fully supported in all contexts.

### Affected Tests

- `test/dantzig/dsl/constant_access_test.exs:219` - Constant access with multiple generator bindings
- `test/dantzig/problem/dsl/nested_access_bindings_test.exs:181` - Diet problem scenario (may be expected to fail for non-numeric access)

### Root Cause

Nested constant access requires proper binding propagation through multiple levels of map access.

### Current Behavior

```elixir
# This may fail:
Problem.define model_parameters: %{matrix: %{1 => %{1 => 10, 2 => 20}}} do
  variables("x", [i <- 1..2, j <- 1..2], :continuous, "Xs")
  constraints([i <- 1..2, j <- 1..2], x(i, j) * matrix[i][j] <= 100, "Constraint")
end
```

### Expected Behavior

Nested map access should work with multiple generator bindings, resolving `matrix[i][j]` to `matrix[1][1]`, `matrix[1][2]`, etc.

### Implementation Requirements

1. **Nested Access Parsing**: Ensure nested `Access.get` AST nodes are properly parsed
2. **Binding Propagation**: Propagate multiple bindings through nested access levels
3. **Evaluation Order**: Ensure bindings are applied in correct order for nested access

### Files to Modify

- `lib/dantzig/problem/dsl/expression_parser.ex` - Support nested constant access
- `lib/dantzig/core/problem/ast.ex` - Handle nested Access.get nodes

### Priority: **MEDIUM** - Affects nested data structure usage

---

## 5. Variable-to-Variable Constraints

### Issue Description

Constraints where both sides involve variables (e.g., `y(i,j) <= x(i)`) were previously problematic but may need further testing.

### Status

**PARTIALLY FIXED** - The facility_location example now works, but edge cases may remain.

### Implementation Requirements

1. **Comprehensive Testing**: Ensure all variable-to-variable constraint patterns work
2. **Performance**: Verify performance with large numbers of variable-to-variable constraints
3. **Error Messages**: Improve error messages for unsupported patterns

### Priority: **LOW** - Core functionality works, needs validation

---

## 6. Sum Function with Constant Access

### Issue Description

Sum functions with constant access in the expression (e.g., `sum(for i <- 1..4, do: x(i) * multiplier[i])`) may have issues with constant evaluation timing.

### Affected Tests

- `test/dantzig/dsl/constant_access_test.exs:69` - Uses sum with constant access

### Root Cause

Similar to issue #1 - constant access within sum expressions needs deferred evaluation.

### Implementation Requirements

1. **Sum Expression Parsing**: Ensure sum expressions properly handle constant access
2. **Binding Context**: Pass bindings correctly through sum expression evaluation
3. **Integration**: Integrate with deferred constant evaluation (Issue #1)

### Files to Modify

- `lib/dantzig/dsl/sum_function.ex` - Support constant access in sum expressions
- `lib/dantzig/problem/dsl/expression_parser/sum_processing.ex` - Handle constants in sums

### Priority: **MEDIUM** - Related to Issue #1

---

## 7. Error Message Quality

### Issue Description

Some error messages may not be clear enough for users to understand what went wrong and how to fix it.

### Examples

- "Cannot evaluate constant access expression... evaluated to nil" - doesn't explain that bindings aren't available yet
- "Generator domain must evaluate to a list" - doesn't suggest converting MapSet to list

### Implementation Requirements

1. **Context-Aware Messages**: Include context about why evaluation failed
2. **Suggestions**: Provide actionable suggestions for fixing issues
3. **Documentation Links**: Reference relevant documentation sections

### Files to Modify

- All error-raising locations in DSL modules
- `lib/dantzig/problem/dsl/expression_parser.ex`
- `lib/dantzig/problem/dsl/variable_manager.ex`
- `lib/dantzig/problem/dsl/constraint_manager.ex`

### Priority: **LOW** - Improves developer experience

---

## 8. Performance with Large Problems

### Issue Description

No specific test failures, but performance may degrade with:

- Large numbers of variables (1000+)
- Deeply nested constant access
- Complex sum expressions

### Implementation Requirements

1. **Profiling**: Profile DSL parsing with large problems
2. **Optimization**: Optimize hot paths in expression parsing
3. **Caching**: Consider caching parsed expressions where safe

### Priority: **LOW** - No current test failures, proactive improvement

---

## Implementation Priority Summary

### High Priority (Blocks Core Functionality)

1. **Constant Access with Generator Bindings** - Blocks 6+ tests, core DSL feature

### Medium Priority (Affects Usability)

2. **Description Interpolation with AST** - Affects 2 tests, user experience
3. **Generator Domain Type Support** - Affects 2 tests, usability improvement
4. **Nested Map Access with Bindings** - Affects nested data usage
5. **Sum Function with Constant Access** - Related to Issue #1

### Low Priority (Enhancements)

6. **Variable-to-Variable Constraints** - Core works, needs validation
7. **Error Message Quality** - Developer experience
8. **Performance Optimization** - Proactive improvement

---

## Testing Strategy

For each issue:

1. **Identify Test Cases**: Use existing failing tests as specification
2. **Create Minimal Reproducers**: Extract minimal examples that demonstrate the issue
3. **Implement Fix**: Make targeted changes to address the root cause
4. **Validate**: Run full test suite to ensure no regressions
5. **Document**: Update DSL documentation with new capabilities

---

## Related Documentation

- `docs/DSL_SYNTAX_REFERENCE.md` - DSL syntax specification
- `docs/ARCHITECTURE.md` - System architecture
- `specs/001-robustify/` - Robustification specification
- `TEST_FAILURE_ANALYSIS.md` - Test failure analysis

---

**Next Steps:**

1. Start with Issue #1 (Constant Access with Generator Bindings) - highest priority
2. Create detailed implementation plan for deferred constant evaluation
3. Implement and test incrementally
4. Move to medium-priority issues once high-priority is resolved
