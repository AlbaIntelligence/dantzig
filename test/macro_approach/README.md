# Macro Approach Tests - Audit & Migration Status

This directory contains tests from the prototype/experimental "macro approach" phase of DSL development.

## Migration Strategy

Tests have been categorized as:
- **KEEP & UPDATE**: Tests that verify real DSL functionality - update to use `Problem.define`
- **KEEP AS-IS**: Tests already using `Problem.define` correctly
- **RETIRE**: Prototype tests that verify internal macro generation logic (obsolete)

## Status

### KEEP & UPDATE (Using old imperative API → Convert to Problem.define)
- [x] `nqueens_integration_test.exs` - ✅ Updated, all tests passing
- [ ] `multiple_generator_constraint_test.exs` - Needs update
- [ ] `complex_constraint_expression_test.exs` - Needs update  
- [ ] `constraint_from_scratch_test.exs` - Needs update

### KEEP AS-IS (Already using Problem.define correctly)
- [ ] `nqueens_integration_test_rewrite.exs` - Already correct, verify it passes
- [ ] `dsl_constraint_test.exs` - Already correct, verify it passes

### RETIRE (Prototype/experimental macro generation tests - no longer relevant)
- [ ] `simple_constraint_test.exs` - Tests macro generation internals
- [ ] `constraint_generation_test.exs` - Tests macro generation internals
- [ ] `simple_constraint_generation_test.exs` - Tests macro generation internals
- [ ] `iterator_extraction_test.exs` - Tests AST parsing internals
- [ ] `nested_loop_generation_test.exs` - Tests loop generation internals
- [ ] `integration_test.exs` - Mock DSL prototype (superseded by real DSL)
- [ ] `complete_transformation_test.exs` - Mock DSL prototype
- [ ] `constraint_resolution_test.exs` - Tests internal resolution logic
- [ ] `env_resolution_test.exs` - Tests environment resolution internals

## Notes

- Real DSL functionality is now tested in `test/dantzig/dsl/experimental/`
- The macro_approach tests were experimental prototypes for how to generate code
- Now that we have `Problem.define` working, the prototype macro generation tests are obsolete

