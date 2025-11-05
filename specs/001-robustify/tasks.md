# Tasks: Robustify Elixir Linear Programming Package

**Input**: Design documents from `/specs/001-robustify/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are included for comprehensive coverage validation and TDD approach as specified in the feature requirements.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Elixir Library**: `lib/dantzig/`, `test/` at repository root
- **Examples**: `examples/` directory for learning resources
- **Documentation**: `docs/` directory for user guides

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create test coverage analysis infrastructure in test/coverage/
- [x] T002 [P] Configure ExCoveralls for coverage reporting in mix.exs
- [x] T003 [P] Setup performance benchmarking infrastructure in test/performance/
- [x] T004 [P] Create example validation framework in test/examples/
- [x] T005 Initialize documentation enhancement structure in docs/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Fix all compilation errors in test/dantzig/dsl/experimental/integration_test.exs
- [x] T007 Fix undefined variable errors in test files (variables "i", "j" in generators)
- [x] T008 Resolve unused variable warnings across all test files
- [x] T009 Fix missing imports and dependencies in test files
- [x] T010 Ensure all test files compile without errors or warnings
- [x] T011 [P] Setup ExCoveralls configuration for 80% overall, 85% core module coverage
- [x] T012 [P] Create test coverage validation scripts in scripts/coverage_validation.exs
- [x] T013 [P] Setup performance monitoring infrastructure in test/performance/
- [x] T014 [P] Create example execution validation framework in test/examples/
- [x] T015 [P] Fix compilation errors in all test files beyond integration_test.exs
- [x] T016 [P] Resolve all undefined function errors across the codebase
- [x] T017 [P] Fix all type compatibility warnings in expression parser
- [x] T018 [P] Ensure all test files pass compilation with zero warnings

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Active Work: DSL Nested Generators & Integration

> Outstanding tasks aligned to current nested-loop DSL work. Uses standard task format.

- [x] T141a [P] [US1] Add failing tests for description interpolation and single‑constraint syntax in `test/dantzig/dsl/experimental/integration_test.exs`
- [x] T141b [P] [US1] Add failing tests for variable refs in constraints/objectives in `test/dantzig/dsl/experimental/simple_generator_test.exs`
- [x] T141c [P] [US1] Add failing test for `transform_constraint_expression_to_ast/1` variable refs in `test/dantzig/core/problem_test.exs`
- [x] T142 [P] [US1] Implement `transform_constraint_expression_to_ast/1` for variable refs (e.g., `queen2d(i, :_)`) in `lib/dantzig/core/problem.ex`
- [x] T141d [P] [US1] Add failing test for `transform_objective_expression_to_ast/1` variable refs in `test/dantzig/core/problem_test.exs`
- [x] T143 [P] [US1] Implement `transform_objective_expression_to_ast/1` for variable refs inside objectives in `lib/dantzig/core/problem.ex`
- [x] T141e [P] [US1] Add failing test for `transform_description_to_ast/1` interpolation in `test/dantzig/core/problem_test.exs`
- [x] T144 [P] [US1] Implement `transform_description_to_ast/1` for `"name_#{i}_#{j}"` interpolation in `lib/dantzig/core/problem.ex`
- [x] T141f [P] [US1] Add failing test for `Problem.constraint/3` no-generator single constraints in `test/dantzig/core/problem_test.exs`
- [x] T145 [P] [US1] Implement `Problem.constraint/3` parsing for no‑generator single constraints in `lib/dantzig/core/problem.ex`
- [x] T141g [P] [US1] Add failing test for `interpolate_variables_in_description/2` in `test/dantzig/problem/dsl/constraint_manager_test.exs`
- [x] T146 [P] [US1] Finalize `interpolate_variables_in_description/2` in `lib/dantzig/problem/dsl/constraint_manager.ex`
- [x] T147 [P] [BC] Align or remove placeholder `process_define_block/1` in `lib/dantzig/problem/dsl.ex` to avoid drift with `Problem.define`
- [ ] T141h [P] [US1] Add failing test for model parameters in `Problem.define` in `test/dantzig/dsl/model_parameters_test.exs` (precursor to T155)
- [ ] T148 [P] [US1] Add model parameters support to `Problem.define` in `lib/dantzig/core/problem.ex` or `lib/dantzig/problem/dsl.ex`
- [ ] T141i [P] [BC] Add failing test for `Problem.modify` macro in `test/dantzig/dsl/problem_modify_test.exs` (precursor to T156)
- [ ] T149 [P] [BC] Implement or improve `Problem.modify` macro; update related tests in `test/macro_approach/*`
- [ ] T150 [P] [US2] Fix macro availability and unskip imperative chained‑constraints tests in `test/dantzig/dsl/experimental/integration_test.exs`
- [ ] T151 [P] [US2] Fix variable access macro generation and unskip tests in `test/dantzig/dsl/experimental/simple_integration_test.exs`
- [ ] T152 [P] [US2] Deprecate `test/macro_approach/*`; migrate relevant cases into `test/dantzig/dsl/experimental/*` and remove obsolete tests
- [ ] T153 [P] [DOC] Update DSL docs to reflect description interpolation and single‑constraint syntax in `docs/DSL_SYNTAX_REFERENCE.md`

> Note: Phase 2 is complete; this Active Work section is an overlay focus list. IDs remain unique and do not alter phase sequencing.

---

## Phase 3: User Story 1 - Fix Compilation Issues (Priority: P1) 🎯 MVP

**Goal**: Resolve all test compilation errors to enable development and testing

**Independent Test**: Run `mix test` and verify all tests compile and execute without errors

**Requirements Coverage**: FR-001

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T019 [P] [US1] Create compilation validation test in test/compilation_test.exs
- [x] T020 [P] [US1] Create test suite execution validation in test/test_suite_validation_test.exs
- [x] T021 [P] [US1] Create backward compatibility validation test in test/backward_compatibility_test.exs
- [x] T022 [P] [US1] Create error message quality validation test in test/error_message_quality_test.exs

### Implementation for User Story 1

- [x] T023 [US1] Fix undefined variables in test/dantzig/dsl/experimental/integration_test.exs
- [x] T024 [US1] Fix variable scope issues in test generators (lines 140, 160)
- [x] T025 [US1] Resolve unused variable warnings in lib/dantzig/ast.ex
- [x] T026 [US1] Fix unused variable warnings in lib/dantzig/core/problem.ex
- [x] T027 [US1] Resolve unused variable warnings in lib/dantzig/dsl/constraint_parser.ex
- [x] T028 [US1] Fix unused variable warnings in lib/dantzig/dsl/variable_access.ex
- [x] T029 [US1] Fix undefined function warnings in lib/dantzig/problem/dsl.ex
- [x] T030 [US1] Resolve typing violations in lib/dantzig/problem/dsl/expression_parser.ex
- [x] T031 [US1] Fix missing imports and dependencies across all test files
- [x] T032 [US1] Validate all tests compile successfully with `mix test --compile`
- [x] T033 [US1] Implement backward compatibility validation for existing API usage patterns
- [x] T034 [US1] Enhance error messages for common DSL usage mistakes with clear, actionable guidance
- [x] T035 [US1] Add error message tests for at least 90% of common usage mistakes

---

## Phase 4: User Story 2 - Comprehensive Test Coverage (Priority: P1)

**Goal**: Achieve 80%+ overall test coverage and 85%+ core module coverage

**Independent Test**: Run `mix test --cover` and verify coverage metrics meet targets

**Requirements Coverage**: FR-002, FR-003

### Tests for User Story 2

- [x] T036 [P] [US2] Create coverage analysis test in test/coverage/coverage_analysis_test.exs
- [x] T037 [P] [US2] Create core module coverage validation in test/coverage/core_modules_test.exs
- [x] T038 [P] [US2] Create edge case testing framework in test/edge_cases_test.exs

### Implementation for User Story 2

- [x] T039 [US2] Add unit tests for Dantzig.Problem module in test/dantzig/core/problem_test.exs
- [x] T040 [US2] Add unit tests for Dantzig.DSL module in test/dantzig/dsl/dsl_test.exs
- [x] T041 [US2] Add unit tests for Dantzig.AST module in test/dantzig/ast/ast_test.exs
- [x] T042 [US2] Add unit tests for Dantzig.Solver module in test/dantzig/solver/solver_test.exs
- [x] T043 [P] [US2] Add integration tests for DSL functionality in test/dantzig/dsl/integration_test.exs
- [x] T044 [P] [US2] Add integration tests for HiGHS solver in test/dantzig/solver/highs_integration_test.exs
- [x] T045 [P] [US2] Add edge case tests for infeasible problems in test/edge_cases/infeasible_problems_test.exs
- [ ] T046 [P] [US2] Add edge case tests for unbounded objectives in test/edge_cases/unbounded_objectives_test.exs
- [ ] T047 [P] [US2] Add edge case tests for invalid constraint syntax in test/edge_cases/invalid_syntax_test.exs
- [ ] T048 [P] [US2] Add edge case tests for numerical precision in test/edge_cases/numerical_precision_test.exs
- [ ] T049 [P] [US2] Add edge case tests for solver failures in test/edge_cases/solver_failures_test.exs
- [ ] T050 [P] [US2] Add edge case tests for large variable sets in test/edge_cases/large_problems_test.exs
- [ ] T051 [P] [US2] Add edge case tests for undefined variables in test/edge_cases/undefined_variables_test.exs
- [ ] T052 [US2] Add performance tests for scalability in test/performance/scalability_test.exs
- [ ] T053 [US2] Validate coverage targets: 80%+ overall, 85%+ core modules

---

## Phase 5: User Story 3 - Well-Documented Examples (Priority: P2)

**Goal**: Enhance all existing examples with comprehensive documentation explaining syntax, reasoning, and gotchas

**Independent Test**: Run individual example files and verify they execute successfully with comprehensive documentation

**Requirements Coverage**: FR-004

### Tests for User Story 3

- [ ] T054 [P] [US3] Create example execution validation test in test/examples/example_execution_test.exs
- [ ] T055 [P] [US3] Create documentation quality validation in test/examples/documentation_quality_test.exs

### Implementation for User Story 3

- [ ] T056 [US3] Enhance documentation for examples/simple_working_example.exs
- [ ] T057 [US3] Enhance documentation for examples/assignment_problem.exs
- [ ] T058 [US3] Enhance documentation for examples/blending_problem.exs
- [ ] T059 [US3] Enhance documentation for examples/knapsack_problem.exs
- [ ] T060 [US3] Enhance documentation for examples/network_flow.exs (create if missing, or document why excluded)
- [ ] T061 [US3] Enhance documentation for examples/nqueens_dsl_working.exs
- [ ] T062 [US3] Enhance documentation for examples/production_planning.exs
- [ ] T063 [US3] Enhance documentation for examples/transportation_problem.exs
- [ ] T064 [US3] Enhance documentation for examples/working_example.exs
- [ ] T065 [P] [US3] Add business context explanations to all examples
- [ ] T066 [P] [US3] Add mathematical formulation explanations to all examples
- [ ] T067 [P] [US3] Add DSL syntax explanations to all examples
- [ ] T068 [P] [US3] Add common gotchas documentation to all examples
- [ ] T069 [US3] Validate all examples execute successfully and produce expected outputs

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Real-World Problem Examples (Priority: P2)

**Goal**: Add diverse, realistic examples covering 5+ optimization problem types with comprehensive documentation

**Independent Test**: Run each real-world example and verify it solves a meaningful optimization problem with reasonable results

**Requirements Coverage**: FR-005

### Tests for User Story 4

- [ ] T070 [P] [US4] Create real-world example validation test in test/examples/real_world_validation_test.exs
- [ ] T071 [P] [US4] Create problem type coverage validation in test/examples/problem_type_coverage_test.exs

### Implementation for User Story 4

- [ ] T072 [US4] Create diet problem example in examples/diet_problem.exs
- [ ] T073 [US4] Create facility location example in examples/facility_location.exs
- [ ] T074 [US4] Create portfolio optimization example in examples/portfolio_optimization.exs
- [ ] T075 [US4] Create job shop scheduling example in examples/job_shop_scheduling.exs
- [ ] T076 [US4] Create cutting stock example in examples/cutting_stock.exs
- [ ] T077 [P] [US4] Add comprehensive documentation to diet_problem.exs
- [ ] T078 [P] [US4] Add comprehensive documentation to facility_location.exs
- [ ] T079 [P] [US4] Add comprehensive documentation to portfolio_optimization.exs
- [ ] T080 [P] [US4] Add comprehensive documentation to job_shop_scheduling.exs
- [ ] T081 [P] [US4] Add comprehensive documentation to cutting_stock.exs
- [ ] T082 [US4] Validate all examples cover 5+ distinct optimization problem domains
- [ ] T083 [US4] Validate all examples demonstrate appropriate modeling techniques
- [ ] T084 [US4] Validate all examples complete within reasonable time limits

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: User Story 5 - Performance and Scalability Validation (Priority: P3)

**Goal**: Implement performance benchmarks and validate scalability for production readiness

**Independent Test**: Run performance benchmarks with increasing problem sizes and verify execution times and memory usage stay within acceptable limits

**Requirements Coverage**: FR-007, FR-012

### Tests for User Story 5

- [ ] T085 [P] [US5] Create performance benchmark test in test/performance/benchmark_test.exs
- [ ] T086 [P] [US5] Create scalability validation test in test/performance/scalability_validation_test.exs

### Implementation for User Story 5

- [ ] T087 [US5] Implement performance benchmarking framework in test/performance/benchmark_framework.exs
- [ ] T088 [US5] Create benchmarks for problems up to 1000 variables in test/performance/large_problem_benchmarks.exs (benchmark set: assignment_problem at 100/500/1000 vars, knapsack at 50/200/500 vars, nqueens at 8/10/12, transportation at 10x10/20x20/30x30; all must complete within SC-006 thresholds)
- [ ] T089 [US5] Implement memory usage monitoring in test/performance/memory_monitoring.exs
- [ ] T090 [US5] Create concurrent usage tests in test/performance/concurrent_usage_test.exs
- [ ] T091 [P] [US5] Validate execution time < 30 seconds for 1000 variables
- [ ] T092 [P] [US5] Validate memory usage < 100MB for typical problems
- [ ] T093 [P] [US5] Validate reasonable scaling with problem size
- [ ] T094 [US5] Create performance regression detection in test/performance/regression_detection.exs
- [ ] T094a [P] [US5] Add CI gate script `scripts/perf_gate.exs` to fail pipeline if SC‑006 thresholds are not met (execution time <30s for 1000 vars, memory <100MB); run benchmark set from T088; wire into CI

**Checkpoint**: All user stories should now be independently functional

---

## Phase 8: Error Handling and Edge Cases (Priority: P2)

**Goal**: Implement comprehensive error handling and edge case management

**Independent Test**: Verify all edge cases are handled gracefully with appropriate error messages

**Requirements Coverage**: FR-006, FR-008

**Success Criteria**: SC-007 (error messages clear and actionable for ≥90% of common mistakes)

**Edge Case Mapping** (from spec.md): 
- No feasible solution → T045
- Unbounded objectives → T046
- Invalid constraint syntax → T047, T097
- Numerical precision → T048
- HiGHS solver unavailable/fails → T049
- Very large variable sets → T050, T052
- Undefined variables in constraints → T051, T099
- Mixed-integer programming incomplete → Note in docs (not a blocking edge case)

### Tests for Error Handling

- [ ] T095 [P] [EH] Create edge case error handling validation test in test/error_handling/edge_case_handling_test.exs (NOTE: Error message quality test already created in T022; comprehensive error message tests will be added in T035)
- [ ] T096 [P] [EH] Create edge case scenario test suite in test/error_handling/edge_case_scenarios_test.exs (NOTE: Focuses on testing edge case handling across different problem types)

### Implementation for Error Handling

- [ ] T097 [EH] Improve DSL parse errors at constraint/objective parsing sites with actionable messages in `lib/dantzig/problem/dsl/*` (NOTE: T034 enhanced error messages in expression_parser.ex; this task focuses on constraint_manager.ex and other DSL parsing sites)
- [ ] T098 [EH] Surface infeasible/unbounded indications with clear guidance at solver call sites in `lib/dantzig/solver/highs_solver.ex`
- [ ] T099 [EH] Validate and message invalid/undefined variables at constraint build time in `lib/dantzig/problem/dsl/constraint_manager.ex` (NOTE: T034 enhanced undefined variable errors in expression_parser.ex; this task focuses on constraint_manager.ex validation)
- [ ] T100 [EH] Add regression tests for each improved message under `test/error_handling/*`
- [ ] T105 [P] [EH] Validate error messages are clear and actionable for ≥90% of common mistakes (SC-007 requirement; NOTE: T035 adds comprehensive error message tests; this task validates coverage across all error handling improvements including T034, T097, T099)
- [ ] T106 [P] [EH] Validate all edge cases have appropriate error handling (aligns with FR-008)

---

## Phase 9: Documentation and Onboarding (Priority: P2)

**Goal**: Create comprehensive documentation enabling 30-minute user onboarding

**Independent Test**: Verify new users can understand and use the package within 30 minutes

**Requirements Coverage**: FR-011

### Tests for Documentation

- [ ] T107 [P] [DOC] Create onboarding validation test in test/documentation/onboarding_validation_test.exs
- [ ] T108 [P] [DOC] Create documentation quality validation test in test/documentation/documentation_quality_test.exs

### Implementation for Documentation

- [ ] T109 [DOC] Create comprehensive getting started guide in docs/GETTING_STARTED.md
- [ ] T110 [DOC] Create comprehensive tutorial in docs/COMPREHENSIVE_TUTORIAL.md
- [ ] T111 [DOC] Create architecture documentation in docs/ARCHITECTURE.md
- [ ] T112 [DOC] Create DSL syntax reference in docs/DSL_SYNTAX_REFERENCE.md
- [ ] T113 [DOC] Create modeling guide in docs/MODELING_GUIDE.md
- [ ] T114 [DOC] Create troubleshooting guide in docs/TROUBLESHOOTING.md
- [ ] T115 [DOC] Create API reference documentation in docs/API_REFERENCE.md
- [ ] T116 [DOC] Create migration guide for existing users in docs/MIGRATION_GUIDE.md
- [ ] T117 [P] [DOC] Validate documentation enables 30-minute onboarding (SC-005): Test checklist: (1) New user can install package, (2) Can run first example successfully, (3) Can understand DSL syntax from examples, (4) Can modify example to solve different problem, (5) Can find error message guidance; all within 30 minutes; rubric in test/documentation/onboarding_validation_test.exs
- [ ] T118 [P] [DOC] Validate all documentation is comprehensive and user-friendly: Check that all docs have (1) Clear purpose statement, (2) Code examples, (3) Gotchas/troubleshooting sections, (4) Links to related docs; rubric in test/documentation/documentation_quality_test.exs
- [ ] T163 [DOC] Incorporate spec/001-robustify information into general documentation:
  - **Model Parameters**: Add comprehensive model parameters documentation to `docs/DSL_SYNTAX_REFERENCE.md` based on `contracts/model-parameters-api.md`:
    - Parameter access syntax (direct name access, not `params.key`)
    - Usage in generators, expressions, descriptions, objectives
    - Error handling for undefined parameters
    - Complete examples from contract
  - **Problem.modify**: Add comprehensive `Problem.modify` documentation to `docs/DSL_SYNTAX_REFERENCE.md` based on `contracts/problem-modify-api.md`:
    - Incremental problem building patterns
    - State preservation guarantees
    - Syntax consistency with `Problem.define`
    - Complete examples from contract
  - **Test Coverage**: Add test coverage guidance to `docs/MODELING_GUIDE.md` based on `contracts/test-coverage-api.md`:
    - Coverage targets (80% overall, 85% core modules)
    - Testing best practices from research.md
    - Coverage validation approach
  - **Performance**: Add performance considerations to `docs/MODELING_GUIDE.md` based on spec.md requirements:
    - Performance targets (FR-012: <30s for 1000 vars, <100MB memory)
    - Scalability guidelines
    - Benchmarking approach
  - **Error Handling**: Add error handling patterns to `docs/TROUBLESHOOTING.md` based on spec.md edge cases:
    - Infeasible problems
    - Unbounded objectives
    - Invalid constraint syntax
    - Numerical precision issues
    - Solver failures
    - Undefined variables
  - **Example Best Practices**: Add example documentation standards to `docs/MODELING_GUIDE.md` based on `contracts/example-validation-api.md`:
    - Business context requirements
    - Mathematical formulation documentation
    - DSL syntax explanations
    - Gotchas documentation
  - **Backward Compatibility**: Document backward compatibility guarantees in `docs/MIGRATION_GUIDE.md`:
    - FR-009 requirements
    - API contract guarantees
    - Migration paths
  - **Quickstart Content**: Incorporate useful quickstart patterns from `quickstart.md` into `docs/GETTING_STARTED.md`:
    - Common compilation issues and fixes
    - Coverage setup steps
    - Example validation approach
  - **Research Insights**: Incorporate technical decisions from `research.md` into relevant docs:
    - Test coverage best practices → `docs/MODELING_GUIDE.md`
    - DSL documentation approach → `docs/DSL_SYNTAX_REFERENCE.md`
    - Error handling patterns → `docs/TROUBLESHOOTING.md`
    - Performance benchmarking → `docs/MODELING_GUIDE.md`
  - **Data Model Insights**: Incorporate data model insights from `data-model.md` into architecture docs:
    - Test suite entity structure → `docs/ARCHITECTURE.md`
    - Example file entity requirements → `docs/MODELING_GUIDE.md`
    - Performance benchmark entity → `docs/MODELING_GUIDE.md`
  - **Plan Context**: Incorporate technical context from `plan.md` into relevant docs:
    - Technical stack decisions → `docs/ARCHITECTURE.md`
    - Performance goals → `docs/MODELING_GUIDE.md`
    - Constraints and scope → `docs/ARCHITECTURE.md`
  - **Cross-reference**: Ensure all documentation cross-references:
    - Link model parameters docs to Problem.modify docs
    - Link DSL syntax to examples
    - Link troubleshooting to relevant syntax sections
    - Create navigation structure between docs
  - **Validation**: Verify all incorporated information:
    - Matches spec/001-robustify contracts exactly
    - Uses consistent terminology with DSL_SYNTAX_REFERENCE.md
    - Includes working code examples
    - Maintains backward compatibility documentation
    - Updates API reference if needed

---

## Observability Alignment (Cross-Cutting)

**Requirements Coverage**: Constitution Principle IV (Observability)

**Goal**: Ensure structured logging and debuggability across critical paths

- [ ] T154a [P] [OBS] Add structured logs/diagnostic hooks to DSL parsing (Active Work) and solver integration (`lib/dantzig/solver/highs_solver.ex`)
- [ ] T154b [P] [OBS] Create tests in `test/dantzig/observability/dsl_parsing_logs_test.exs` that assert log events contain required fields (parse_start, parse_end, parse_errors) for constraint/objective parsing
- [ ] T154c [P] [OBS] Create tests in `test/dantzig/observability/solver_integration_logs_test.exs` that assert log events contain required fields (solver_call, solver_status, solve_time, memory_usage) for HiGHS solver calls
- [ ] T154d [P] [OBS] Create tests in `test/dantzig/observability/problem_build_logs_test.exs` that assert log events during Problem.define execution (build_start, variable_count, constraint_count, build_complete)

---

## Phase 10: Backward Compatibility (Priority: P1)

**Goal**: Maintain 100% backward compatibility with existing public API

**Independent Test**: Verify all existing API usage patterns continue to work

**Requirements Coverage**: FR-009

### Tests for Backward Compatibility

- [ ] T119 [P] [BC] Create API contract validation test in test/backward_compatibility/api_contract_test.exs (NOTE: T021 and T033 already created/expanded backward compatibility tests; this task focuses on API contract validation)
- [ ] T120 [P] [BC] Create backward compatibility regression test suite in test/backward_compatibility/regression_test.exs (NOTE: Expands on T021/T033 with comprehensive regression scenarios)

### Implementation for Backward Compatibility

- [ ] T121 [BC] Validate existing Problem.define syntax works unchanged in lib/dantzig/problem/dsl.ex
- [ ] T122 [BC] Validate existing variable creation syntax works unchanged in lib/dantzig/problem/dsl/variable_manager.ex
- [ ] T123 [BC] Validate existing constraint creation syntax works unchanged in lib/dantzig/problem/dsl/constraint_manager.ex
- [ ] T124 [BC] Validate existing objective setting syntax works unchanged in lib/dantzig/problem/dsl/objective_manager.ex
- [ ] T125 [BC] Validate existing solver integration works unchanged in lib/dantzig/solver/highs_solver.ex
- [ ] T126 [BC] Validate existing AST functionality works unchanged in lib/dantzig/ast/
- [ ] T127 [BC] Validate existing polynomial operations work unchanged in lib/dantzig/polynomial/
- [ ] T128 [BC] Validate existing constraint parsing works unchanged in lib/dantzig/dsl/constraint_parser.ex
- [ ] T129 [P] [BC] Validate 100% backward compatibility with existing public API
- [ ] T130 [P] [BC] Validate no breaking changes in public interfaces

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

**Note**: Documentation tasks T109-T116 in Phase 9 create initial docs. These tasks update them based on implementation learnings.

- [ ] T131 [P] Update main documentation in docs/GETTING_STARTED.md (refine based on Phase 9 learnings; cross-reference T109)
- [ ] T132 [P] Update comprehensive tutorial in docs/COMPREHENSIVE_TUTORIAL.md (refine based on Phase 9 learnings; cross-reference T110)
- [ ] T133 [P] Update architecture documentation in docs/ARCHITECTURE.md (refine based on Phase 9 learnings; cross-reference T111)
- [ ] T134 [P] Code cleanup and refactoring across all modules
- [ ] T135 [P] Performance optimization across all components
- [ ] T136 [P] Additional unit tests for edge cases in test/unit/
- [ ] T137 [P] Security hardening for solver integration (no spec requirement; remove if not needed or add NFR to spec)
- [ ] T138 [P] Run quickstart.md validation
- [ ] T139 [P] Update README.md with robustification improvements
- [ ] T140 [P] Create migration guide for existing users (may duplicate T116; ensure T116 creates initial guide, T140 refines it)
- [ ] T141 [P] Final integration testing across all user stories (scope: run full test suite, verify all user stories independently testable, validate no regressions in backward compatibility)

---

## Phase 12: Model Parameters & Problem.modify (Priority: P1)

**Goal**: Add model parameters to `Problem.define` and provide `Problem.modify` for incremental updates, without breaking existing DSL.

**Independent Test**: New tests under `test/dantzig/dsl/` fail first, then pass after implementation.

**Requirements Coverage**: FR-013, FR-014, FR-009

**User Story**: Capability addition (not US1). Supports FR-013/FR-014 with backward compatibility (FR-009).

### Tests

- [ ] T155 [P] [PARAM] Create model parameters tests in `test/dantzig/dsl/model_parameters_test.exs` (expands on T141h from Active Work)
- [ ] T156 [P] [MODIFY] Create Problem.modify tests in `test/dantzig/dsl/problem_modify_test.exs` (expands on T141i from Active Work)

### Implementation

- [ ] T157 [PARAM] Implement model parameters in `Problem.define` (thread env/bindings) in `lib/dantzig/core/problem.ex` and/or `lib/dantzig/problem/dsl.ex`
- [ ] T158 [PARAM] Ensure parameters can be used in generators, expressions, descriptions
- [ ] T159 [BC] [MODIFY] Implement `Problem.modify` macro in `lib/dantzig/core/problem.ex` or `lib/dantzig/problem/dsl.ex`
- [ ] T160 [BC] [MODIFY] Support adding variables/constraints/objective updates without rebuild
- [ ] T161 [BC] [MODIFY] Add/port tests under `test/dantzig/dsl/experimental/problem_modify_test.exs` to reflect `Problem.modify` behavior; remove `test/macro_approach/*`
- [ ] T162 [DOC] Document parameters and modify in `docs/DSL_SYNTAX_REFERENCE.md`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Model Parameters & Problem.modify (Phase 12)**: Depends on Foundational phase completion
- **Constant Access (Phase 13)**: Can be implemented independently, but benefits from Phase 12 completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Depends on US1 completion
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - May integrate with previous stories but should be independently testable
- **Error Handling (P2)**: Can start after Foundational (Phase 2) - May integrate with other stories
- **Documentation (P2)**: Can start after Foundational (Phase 2) - May integrate with other stories
- **Backward Compatibility (P1)**: Can start after Foundational (Phase 2) - Critical for all stories

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Add User Story 5 → Test independently → Deploy/Demo
7. Add Error Handling → Test independently → Deploy/Demo
8. Add Documentation → Test independently → Deploy/Demo
9. Add Backward Compatibility → Test independently → Deploy/Demo
10. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Fix Compilation)
   - Developer B: User Story 2 (Test Coverage)
   - Developer C: User Story 3 (Documentation)
   - Developer D: Error Handling
   - Developer E: Backward Compatibility
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

## Requirements Coverage Summary

| Requirement                        | Phase         | Task Count | Status     |
| ---------------------------------- | ------------- | ---------- | ---------- |
| FR-001: Compile all test files     | Phase 3 (US1) | 15 tasks   | ✅ Covered |
| FR-002: 80% overall coverage       | Phase 4 (US2) | 18 tasks   | ✅ Covered |
| FR-003: 85% core coverage          | Phase 4 (US2) | 18 tasks   | ✅ Covered |
| FR-004: Comprehensive example docs | Phase 5 (US3) | 16 tasks   | ✅ Covered |
| FR-005: 5+ problem types           | Phase 6 (US4) | 15 tasks   | ✅ Covered |
| FR-006: Clear error messages       | Phase 8 (EH)  | 12 tasks   | ✅ Covered |
| FR-007: Performance benchmarks     | Phase 7 (US5) | 10 tasks   | ✅ Covered |
| FR-008: Handle edge cases          | Phase 8 (EH)  | 12 tasks   | ✅ Covered |
| FR-009: Backward compatibility     | Phase 10 (BC) | 12 tasks   | ✅ Covered |
| FR-011: 30min onboarding           | Phase 9 (DOC) | 12 tasks   | ✅ Covered |
| FR-012: Performance targets        | Phase 7 (US5) | 10 tasks   | ✅ Covered |
| FR-013: Model parameters           | Phase 12       | 8 tasks    | ✅ Covered |
| FR-014: Problem.modify             | Phase 12       | 8 tasks    | ✅ Covered |
| FR-015: Constant access           | Phase 13       | 12 tasks   | ✅ Covered |

**Total Tasks**: 153 tasks covering all 15 functional requirements
