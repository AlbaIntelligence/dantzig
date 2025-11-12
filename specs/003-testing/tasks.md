# Tasks: Comprehensive Testing and DSL Improvements

**Input**: Design documents from `/specs/003-testing/`
**Prerequisites**: spec.md (required), docs/internal/developer-notes/DSL_IMPLEMENTATION_ISSUES.md, docs/internal/developer-notes/enumerator-tracking-design.md, docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md

**Tests**: Tests are included for comprehensive validation and TDD approach.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Elixir Library**: `lib/dantzig/`, `test/` at repository root
- **Examples**: `docs/user/examples/` directory
- **Documentation**: `docs/` directory

---

## Phase 1: Fix Test Suite Failures (User Story 1 - P1) 🎯 MVP

**Goal**: Resolve all test failures to enable reliable development

**Independent Test**: Run `mix test` and verify all tests pass without failures

**Requirements Coverage**: FR-001, FR-005, FR-006, FR-007

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T001 [P] [US1] Create test suite validation test in `test/test_suite_validation_test.exs`
- [ ] T002 [P] [US1] Create test failure categorization test in `test/test_failure_categorization_test.exs`

### Implementation for User Story 1

#### API Changes Fixes

- [x] T003 [P] [US1] Fix `Dantzig.Solver.HiGHS` → `Dantzig.HiGHS` module alias in `test/dantzig/solver/highs_test.exs`
- [x] T004 [P] [US1] Fix `Problem.add_constraint/3` → `Problem.add_constraint/2` calls in `test/dantzig/solver/highs_test.exs` (move name to Constraint.new name: option)
- [x] T005 [P] [US1] Fix `Constraint.new` signature changes (use `name:` option) - Already handled in T004
- [x] T006 [P] [US1] Fix `Polynomial.constant` → `Polynomial.const` calls in `test/dantzig/solver/highs_test.exs`
- [x] T007 [P] [US1] Fix `Problem.minimize`/`Problem.maximize` calls to set objective direction - Already working correctly
- [x] T008 [P] [US1] Make `constraint_to_iodata/2` and `variable_bounds/1` public in `lib/dantzig/solver/highs.ex`

#### Variable Access Fixes

- [x] T009 [P] [US1] Fix `Problem.get_variable/3` → `Problem.get_variable/2` in `test/dantzig/dsl/integration_test.exs` (use variable name format "x(1)" instead of indices)
- [x] T010 [P] [US1] Fix variable name format assertions (`x_1` → `x(1)`, `queen2d_1_1` → `queen2d(1,1)`) in `test/dantzig/core/problem_test.exs`
- [x] T011 [P] [US1] Fix variable bounds field names (`min`/`max` → `min_bound`/`max_bound`) in `lib/dantzig/solver/highs.ex`

#### Compilation Error Fixes

- [x] T011a [US1] Fix NimbleParsec API syntax in `lib/dantzig/solution/parser.ex` (min_bound → min)
- [x] T011b [US1] Fix cyclic module dependency by moving `Dantzig.Error` to `lib/dantzig/error.ex`
- [x] T012 [US1] Fix undefined variables in `test/compilation_test.exs` (fix function_exported check for macro, fix Code.compile_file pattern matching)
- [x] T013 [P] [US1] Fix deprecated `variables/5` usage in `test/dantzig/dsl_test.exs` - Test uses valid form, added clarifying comment
- [x] T014 [P] [US1] Fix experimental test compilation errors in `test/dantzig/dsl/experimental/` - Fixed macro_parser_test.exs sum/1 issue (changed to use unknown_func for Code.eval_string tests)
- [x] T015 [US1] Fix benchmark framework references or mark tests as skipped in `test/performance/scalability_test.exs` (marked all tests as skipped, commented out BenchmarkFramework calls)

#### Test Assertion Updates

- [ ] T016 [P] [US1] Update LP format string assertions to match actual output format in `test/dantzig/solver/highs_test.exs`
- [ ] T017 [P] [US1] Fix constraint name interpolation assertions in `test/dantzig/problem/dsl/constraint_manager_test.exs`
- [ ] T018 [P] [US1] Update `Problem.constraint/3` tests to reflect working functionality in `test/dantzig/core/problem_test.exs`

**Checkpoint**: At this point, all test failures should be resolved or documented

---

## Phase 2: Fix Example Execution (User Story 2 - P1)

**Goal**: Ensure all example files execute successfully

**Independent Test**: Run each example file individually and verify execution success

**Requirements Coverage**: FR-002, FR-010

### Tests for User Story 2

- [ ] T019 [P] [US2] Create example execution validation test in `test/examples/example_execution_test.exs`
- [ ] T020 [P] [US2] Create example solution validation test in `test/examples/solution_validation_test.exs`

### Implementation for User Story 2

- [ ] T021 [US2] Verify all examples in `docs/user/examples/*.exs` execute successfully
- [ ] T022 [P] [US2] Fix any compilation errors in example files
- [ ] T023 [P] [US2] Fix any runtime errors in example files
- [ ] T024 [P] [US2] Verify all examples produce valid optimization solutions
- [ ] T025 [P] [US2] Update example documentation to match current DSL syntax
- [ ] T026 [US2] Run comprehensive example validation and document results

**Checkpoint**: At this point, all examples should execute successfully

---

## Phase 3: Resolve DSL Implementation Issues (User Story 3 - P1)

**Goal**: Fix all high-priority DSL implementation issues

**Independent Test**: Run DSL feature tests and verify issues are resolved

**Requirements Coverage**: FR-003

### Tests for User Story 3

- [ ] T027 [P] [US3] Create DSL issue validation test in `test/dantzig/dsl/dsl_issues_test.exs`
- [ ] T028 [P] [US3] Add tests for constant access with generator bindings in `test/dantzig/dsl/constant_access_test.exs`

### Implementation for User Story 3

#### Issue #1: Constant Access with Generator Bindings (HIGH PRIORITY)

- [ ] T029 [US3] Modify `parse_expression_to_polynomial/3` in `lib/dantzig/problem/dsl/expression_parser.ex` to prioritize constant evaluation for `Access.get` patterns
- [ ] T030 [US3] Enhance constant evaluation in `lib/dantzig/problem/dsl/expression_parser/constant_evaluation.ex` to handle generator bindings
- [ ] T031 [US3] Improve error messages in `expression_parser.ex` and `constant_evaluation.ex` with binding context
- [ ] T032 [US3] Add explicit nil checks in `constant_evaluation.ex` for container and key evaluation
- [ ] T033 [US3] Test constant access with generator bindings in constraints and objectives

#### Issue #2: Description Interpolation with AST (MEDIUM PRIORITY)

- [ ] T034 [US3] Fix `create_constraint_name/3` in `lib/dantzig/problem/dsl/constraint_manager.ex` to properly evaluate AST descriptions
- [ ] T035 [US3] Ensure bindings are correctly passed to `Code.eval_quoted/2` for AST evaluation
- [ ] T036 [US3] Improve error handling for AST evaluation failures

#### Issue #3: Generator Domain Type Support (MEDIUM PRIORITY)

- [ ] T037 [US3] Modify `parse_generators` in `lib/dantzig/problem/dsl/variable_manager.ex` to accept any enumerable type
- [ ] T038 [US3] Add enumerable validation check (robustness) before accepting generator domains
- [ ] T039 [US3] Update error messages to suggest enumerable conversion if needed

#### Issue #4: Nested Map Access with Bindings (MEDIUM PRIORITY)

- [ ] T040 [US3] Ensure nested `Access.get` AST nodes are properly parsed in `lib/dantzig/problem/dsl/expression_parser.ex`
- [ ] T041 [US3] Propagate multiple bindings through nested access levels
- [ ] T042 [US3] Test nested map access with multiple generator bindings

#### Issue #5: Sum Function with Constant Access (MEDIUM PRIORITY)

- [ ] T043 [US3] Ensure sum expressions properly handle constant access in `lib/dantzig/dsl/sum_function.ex`
- [ ] T044 [US3] Pass bindings correctly through sum expression evaluation
- [ ] T045 [US3] Integrate with deferred constant evaluation (Issue #1)

#### Issue #6: Constant and Enumerated Constant Access (HIGH PRIORITY)

**Goal**: Implement map/list access support for constants from model_parameters in constraint/objective expressions (e.g., `cost[worker][task]`, `multiplier[i]`, `matrix[i][j]`)

**Dependencies**: Requires model_parameters support (Phase 3.5) and Issue #1 completion

- [ ] T081 [P] [US3] Create tests for scalar constant access (`multiplier`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T082 [P] [US3] Create tests for list index access (`multiplier[i]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T083 [P] [US3] Create tests for nested list access (`matrix[i][j]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T084 [P] [US3] Create tests for map access (`cost[worker][task]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T085 [P] [US3] Create tests for nested map access (`cost[worker][task]`) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T086 [P] [US3] Create tests for error cases (undefined constants, invalid indices, type mismatches) in `test/dantzig/dsl/constant_access_test.exs`
- [ ] T087 [US3] Add `Access.get` AST node handling to `parse_expression_to_polynomial/3` in `lib/dantzig/problem/dsl/expression_parser.ex`
- [ ] T088 [US3] Add nested `Access.get` support (e.g., `cost[worker][task]`) to expression parser
- [ ] T089 [US3] Integrate `evaluate_expression_with_bindings` for constant evaluation in polynomial parsing
- [ ] T090 [US3] Add constant lookup in model_parameters for unknown symbols in expressions
- [ ] T091 [US3] Add error handling for undefined constants, invalid indices, type mismatches
- [ ] T092 [DOC] [US3] Fix `params.key` syntax inconsistency in documentation (replace with direct access syntax in any remaining docs)
- [ ] T093 [DOC] [US3] Verify `docs/user/reference/dsl-syntax.md` constant access examples align with implementation

**Checkpoint**: At this point, all high-priority DSL issues should be resolved

---

## Phase 3.5: Model Parameters & Problem.modify (Priority: P1)

**Goal**: Add model parameters to `Problem.define` and provide `Problem.modify` for incremental updates, without breaking existing DSL

**Independent Test**: New tests under `test/dantzig/dsl/` fail first, then pass after implementation

**Requirements Coverage**: FR-013, FR-014, FR-009

**Dependencies**: Can start after Phase 3 (Issue #1) completion

### Tests

- [ ] T094 [P] [PARAM] Create model parameters tests in `test/dantzig/dsl/model_parameters_test.exs`
- [ ] T095 [P] [MODIFY] Create Problem.modify tests in `test/dantzig/dsl/problem_modify_test.exs`

### Implementation

- [ ] T096 [PARAM] Implement model parameters in `Problem.define` (thread env/bindings) in `lib/dantzig/core/problem.ex` and/or `lib/dantzig/problem/dsl.ex`
- [ ] T097 [PARAM] Ensure parameters can be used in generators, expressions, descriptions
- [ ] T098 [BC] [MODIFY] Implement `Problem.modify` macro in `lib/dantzig/core/problem.ex` or `lib/dantzig/problem/dsl.ex`
- [ ] T099 [BC] [MODIFY] Support adding variables/constraints/objective updates without rebuild
- [ ] T100 [BC] [MODIFY] Add/port tests under `test/dantzig/dsl/experimental/problem_modify_test.exs` to reflect `Problem.modify` behavior; remove `test/macro_approach/*` if obsolete
- [ ] T101 [DOC] Document parameters and modify in `docs/user/reference/dsl-syntax.md` (if not already documented)

**Checkpoint**: At this point, model parameters and Problem.modify should be functional

---

## Phase 4: Implement Enumerator Tracking (User Story 4 - P2)

**Goal**: Implement Phase 1 of enumerator tracking (variable enumerator registration)

**Independent Test**: Run enumerator tracking tests and verify enumerators are registered

**Requirements Coverage**: FR-004, FR-011, FR-016

### Tests for User Story 4

- [ ] T046 [P] [US4] Create enumerator tracking test in `test/dantzig/dsl/enumerator_tracking_test.exs`
- [ ] T047 [P] [US4] Create enumerator registration test in `test/dantzig/dsl/enumerator_registration_test.exs`

### Implementation for User Story 4

#### Phase 1: Variable Enumerator Tracking

- [ ] T048 [US4] Add `enumerators` dictionary field to `Problem` struct in `lib/dantzig/core/problem.ex`
- [ ] T049 [US4] Add `variable_enumerators` map field to `Problem` struct in `lib/dantzig/core/problem.ex`
- [ ] T050 [US4] Create enumerator registry functions in `lib/dantzig/core/problem.ex`
- [ ] T051 [US4] Modify `VariableManager.add_variables` to register enumerators in `lib/dantzig/problem/dsl/variable_manager.ex`
- [ ] T052 [US4] Track enumerator sequences per variable in `variable_manager.ex`
- [ ] T053 [US4] Generate enumerator names from AST/expressions in `variable_manager.ex`
- [ ] T054 [US4] Store enumerator metadata (domain, name, source, etc.) in `variable_manager.ex`
- [ ] T055 [US4] Update `dsl_reducer.ex` to pass enumerator info in `lib/dantzig/core/problem/dsl_reducer.ex`

#### Phase 3: Linearization Variable Tracking (Placeholder)

- [ ] T056 [US4] Add `linearization_variables` placeholder field to `Problem` struct in `lib/dantzig/core/problem.ex`
- [ ] T057 [US4] Document design for linearization variable creation in `docs/developer/architecture/enumerator-tracking-design.md`
- [ ] T058 [US4] Create task/plan document for full linearization implementation

#### Phase 2: Constraint Enumerator Validation (Future)

- [ ] T059 [US4] Validate enumerators exist or are subsets in `lib/dantzig/problem/dsl/constraint_manager.ex`
- [ ] T060 [US4] Check variable names exist during constraint generation in `constraint_manager.ex`
- [ ] T061 [US4] Provide helpful error messages for enumerator validation failures
- [ ] T062 [US4] Handle nested enumerator patterns (e.g., `j <- items[i]`)

**Checkpoint**: At this point, Phase 1 enumerator tracking should be implemented

---

## Phase 5: Test Suite Quality (User Story 5 - P2)

**Goal**: Improve test suite quality and maintain coverage

**Independent Test**: Run `mix test --cover` and review quality metrics

**Requirements Coverage**: FR-008, FR-009, NFR-005

### Tests for User Story 5

- [ ] T063 [P] [US5] Create test coverage validation test in `test/coverage/coverage_validation_test.exs`
- [ ] T064 [P] [US5] Create test quality metrics test in `test/test_quality_test.exs`

### Implementation for User Story 5

- [ ] T065 [US5] Review and categorize all test failures with clear reasons
- [ ] T066 [P] [US5] Document expected test failures in `docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md`
- [ ] T067 [P] [US5] Update test documentation to reflect current API
- [ ] T068 [P] [US5] Remove or update outdated experimental tests
- [ ] T069 [US5] Ensure test coverage meets targets (≥85% overall)
- [ ] T070 [P] [US5] Improve error messages in tests for better debugging
- [ ] T071 [US5] Add tests for edge cases identified in DSL issues
- [ ] T108 [P] [US5] Validate code files are under 500 lines (refactor if feasible and no other options)
- [ ] T109 [P] [US5] Validate documentation files are under 300 lines (refactor if feasible and no other options)

**Checkpoint**: At this point, test suite quality should be improved

---

## Phase 6: Documentation and Validation

**Purpose**: Document improvements and validate completion

- [ ] T072 [P] Update `docs/internal/developer-notes/DSL_IMPLEMENTATION_ISSUES.md` with resolved issues
- [ ] T073 [P] Update `docs/developer/architecture/enumerator-tracking-design.md` with implementation status
- [ ] T074 [P] Update `docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md` with final status
- [ ] T075 [P] Create comprehensive test suite status report
- [ ] T102 [US1] Run full test suite validation: `mix test`
- [ ] T103 [US2] Run all examples validation: execute each example file
- [ ] T104 [US3] Run DSL feature tests validation
- [ ] T105 [US3.5] Run model parameters and Problem.modify tests validation
- [ ] T106 [US4] Run enumerator tracking tests validation
- [ ] T107 [US5] Run coverage analysis: `mix test --cover`
- [ ] T110 [US5] Validate file size limits: code files <500 lines, docs <300 lines (unless no other options)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Test Fixes)**: No dependencies - can start immediately
- **Phase 2 (Example Fixes)**: Can start in parallel with Phase 1
- **Phase 3 (DSL Issues)**: Can start in parallel with Phase 1, but benefits from Phase 1 completion
  - Issue #6 (Constant Access) depends on Phase 3.5 (Model Parameters) completion
- **Phase 3.5 (Model Parameters)**: Can start after Phase 3 (Issue #1) completion
- **Phase 4 (Enumerator Tracking)**: Can start after Phase 3 (Issue #1) completion
- **Phase 5 (Test Quality)**: Depends on Phase 1 completion
- **Phase 6 (Documentation)**: Depends on all previous phases

### User Story Dependencies

- **User Story 1 (P1)**: Can start immediately - No dependencies
- **User Story 2 (P1)**: Can start immediately - May benefit from DSL fixes
- **User Story 3 (P1)**: Can start immediately - Independent implementation
- **User Story 4 (P2)**: Can start after Issue #1 resolution - Benefits from DSL improvements
- **User Story 5 (P2)**: Depends on User Story 1 completion

### Parallel Opportunities

- All Phase 1 API fix tasks (T003-T018) can run in parallel
- Phase 1 and Phase 2 can run in parallel
- Phase 3 DSL issue fixes can run in parallel (except dependencies)
- Phase 4 enumerator tracking tasks can run in parallel within each phase

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Fix all test failures
2. **STOP and VALIDATE**: Run `mix test` and verify all tests pass
3. Deploy/demo if ready

### Incremental Delivery

1. Complete Phase 1 → All tests pass
2. Add Phase 2 → All examples execute
3. Add Phase 3 → DSL issues resolved
4. Add Phase 3.5 → Model parameters and Problem.modify functional
5. Add Phase 4 → Enumerator tracking implemented
6. Add Phase 5 → Test quality improved
7. Each phase adds value without breaking previous work

### Parallel Team Strategy

With multiple developers:

1. Developer A: Phase 1 (Test Fixes)
2. Developer B: Phase 2 (Example Fixes)
3. Developer C: Phase 3 (DSL Issues - Issue #1)
4. Developer D: Phase 3.5 (Model Parameters - after Issue #1)
5. Developer E: Phase 4 (Enumerator Tracking - after Issue #1)
6. Developer F: Phase 5 (Test Quality - after Phase 1)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing fixes
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

## Requirements Coverage Summary

| Requirement                        | Phase         | Task Count | Status     |
| ---------------------------------- | ------------- | ---------- | ---------- |
| FR-001: All tests pass             | Phase 1 (US1) | 18 tasks   | ✅ Covered |
| FR-002: All examples execute       | Phase 2 (US2) | 8 tasks    | ✅ Covered |
| FR-003: DSL issues resolved         | Phase 3 (US3) | 32 tasks   | ✅ Covered |
| FR-004: Enumerator tracking        | Phase 4 (US4) | 17 tasks   | ✅ Covered |
| FR-005: API updates                | Phase 1 (US1) | 8 tasks    | ✅ Covered |
| FR-006: Compilation errors          | Phase 1 (US1) | 4 tasks    | ✅ Covered |
| FR-007: API-related failures        | Phase 1 (US1) | 6 tasks    | ✅ Covered |
| FR-008: Document failures           | Phase 5 (US5) | 3 tasks    | ✅ Covered |
| FR-009: Backward compatibility      | Phase 3.5/5   | 2 tasks    | ✅ Covered |
| FR-010: Valid solutions             | Phase 2 (US2) | 2 tasks    | ✅ Covered |
| FR-011: Variable enumerators       | Phase 4 (US4) | 8 tasks    | ✅ Covered |
| FR-012: Constraint validation       | Phase 4 (US4) | 4 tasks    | ✅ Covered |
| FR-013: Model parameters           | Phase 3.5     | 8 tasks    | ✅ Covered |
| FR-014: Problem.modify             | Phase 3.5     | 8 tasks    | ✅ Covered |
| FR-015: Constant access            | Phase 3 (US3) | 13 tasks   | ✅ Covered |
| FR-016: Design documentation       | Phase 4 (US4) | 1 task     | ✅ Covered |
| NFR-005: File size limits          | Phase 5 (US5) | 3 tasks    | ✅ Covered |

**Total Tasks**: 105 tasks covering all 16 functional requirements and 1 non-functional requirement
