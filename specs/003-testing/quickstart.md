# Quickstart: Comprehensive Testing and DSL Improvements

**Feature**: `003-testing` | **Status**: Ready for Implementation

## Overview

This feature ensures all tests pass, all examples execute successfully, and resolves DSL implementation issues while implementing enumerator tracking.

## Prerequisites

- Elixir 1.15+ / OTP 26+
- Nix development environment (if using)
- Access to test suite and example files
- Understanding of DSL architecture (see `docs/developer/architecture/dsl-architecture.md`)

## Quick Start

### 1. Review Current Status

```bash
# Run test suite to see current failures
mix test

# Run examples to see execution status
mix run docs/user/examples/[example].exs

# Review DSL issues
cat DSL_IMPLEMENTATION_ISSUES.md

# Review enumerator tracking design
cat docs/developer/architecture/enumerator-tracking-design.md
```

### 2. Start with Phase 1: Fix Test Failures

**Priority**: P1 (Highest)

**Key Tasks**:
- Fix API changes (module names, function signatures)
- Fix variable access patterns
- Fix compilation errors
- Update test assertions

**Example Fix**:
```elixir
# Before (fails):
alias Dantzig.Solver.HiGHS
Problem.add_constraint(problem, constraint, "name")

# After (works):
alias Dantzig.HiGHS
Problem.add_constraint(problem, Constraint.new(left, op, right, name: "name"))
```

### 3. Continue with Phase 2: Fix Examples

**Priority**: P1

**Key Tasks**:
- Verify all examples execute
- Fix compilation/runtime errors
- Validate solutions

**Validation**:
```bash
# Run each example
for example in docs/user/examples/*.exs; do
  mix run "$example"
done
```

### 4. Address Phase 3: DSL Issues

**Priority**: P1

**Key Issue**: Constant Access with Generator Bindings (Issue #1)

**Example Problem**:
```elixir
# This currently fails:
Problem.define model_parameters: %{multiplier: [4.0, 5.0, 6.0]} do
  variables("x", [i <- 1..3], :continuous, "Xs")
  constraints([i <- 1..3], x(i) * multiplier[i] <= 10, "Constraint #{i}")
end
```

**Solution**: Defer constant evaluation until constraint generation time when bindings are available.

### 5. Implement Phase 4: Enumerator Tracking

**Priority**: P2

**Key Tasks**:
- Add enumerator fields to Problem struct
- Implement enumerator registration
- Track enumerator sequences per variable

**Example**:
```elixir
# After implementation:
problem = Problem.define do
  variables("x", [i <- 1..n], :continuous, "Xs")
end

# problem.enumerators contains:
# %{"enum_range_n" => %{domain: 1..n, source: %{"x" => [0]}, ...}}
# problem.variable_enumerators contains:
# %{"x" => ["enum_range_n"]}
```

## Common Issues and Solutions

### Issue: Test Failures Due to API Changes

**Solution**: Update tests to match current API. See `TEST_FAILURE_ANALYSIS.md` for details.

### Issue: Constant Access Fails with Generator Bindings

**Solution**: This is Issue #1 - requires deferred constant evaluation. See `DSL_IMPLEMENTATION_ISSUES.md`.

### Issue: Examples Don't Execute

**Solution**: Check for:
1. Compilation errors (syntax issues)
2. Runtime errors (DSL limitations)
3. Missing dependencies

### Issue: Enumerator Tracking Breaks Existing Code

**Solution**: Enumerator tracking is optional (empty maps by default). Ensure backward compatibility.

## Testing Strategy

### For Test Fixes

1. Run `mix test` to identify failures
2. Fix one test file at a time
3. Verify fix doesn't break other tests
4. Commit after each file

### For DSL Issues

1. Create minimal reproducer test
2. Implement fix incrementally
3. Test with existing examples
4. Verify no regressions

### For Enumerator Tracking

1. Start with Problem struct changes
2. Implement registration incrementally
3. Test with simple cases first
4. Expand to complex cases

## Validation Checklist

Before considering complete:

- [ ] All tests pass: `mix test` shows 0 failures
- [ ] All examples execute: Each example runs successfully
- [ ] DSL Issue #1 resolved: Constant access with bindings works
- [ ] Enumerator tracking Phase 1 implemented: Variables register enumerators
- [ ] Test coverage maintained: `mix test --cover` shows ≥80% overall
- [ ] Documentation updated: All changes documented

## Resources

- **Specification**: `specs/003-testing/spec.md`
- **Tasks**: `specs/003-testing/tasks.md`
- **Plan**: `specs/003-testing/plan.md`
- **DSL Issues**: `DSL_IMPLEMENTATION_ISSUES.md`
- **Enumerator Design**: `docs/developer/architecture/enumerator-tracking-design.md`
- **Test Analysis**: `TEST_FAILURE_ANALYSIS.md`
- **DSL Architecture**: `docs/developer/architecture/dsl-architecture.md`

## Next Steps

1. Review this quickstart
2. Review `spec.md` for full requirements
3. Review `tasks.md` for detailed task breakdown
4. Start with Phase 1 (Test Fixes)
5. Proceed through phases sequentially or in parallel as dependencies allow
