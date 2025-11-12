# Implementation Plan: Comprehensive Testing and DSL Improvements

**Branch**: `003-testing` | **Date**: 2025-11-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-testing/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

**Primary Requirement**: Comprehensive testing and DSL improvements for the Dantzig Elixir optimization package, including fixing all test failures, ensuring example execution, resolving DSL implementation issues, implementing enumerator tracking, and improving test suite quality.

**Technical Approach**: Leverage existing Elixir/OTP architecture with HiGHS solver integration, enhance test suite with ExUnit and ExCoveralls, fix API compatibility issues, implement DSL enhancements for constant access and model parameters, and add enumerator tracking infrastructure.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: HiGHS solver, ExUnit testing framework, ExCoveralls for coverage analysis, ExDoc documentation
**Storage**: N/A (in-memory optimization problems)
**Testing**: ExUnit with coverage analysis via ExCoveralls
**Target Platform**: Cross-platform (Linux, macOS, Windows) via HiGHS binary management
**Project Type**: Library package (Hex.pm distribution)
**Performance Goals**: Maintain existing performance characteristics (no degradation)
**Constraints**: Maintain backward compatibility with existing DSL API, zero breaking changes. All fixes must preserve existing functionality.
**Scale/Scope**: 105 tasks across 6 phases covering test fixes, example execution, DSL improvements, enumerator tracking, and test quality improvements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Library-First Principle ✅

- **Requirement**: Every feature starts as a standalone library
- **Compliance**: Dantzig is already a self-contained Hex package with clear purpose
- **Status**: PASS - Package is independently testable and documented

### Test-First Principle ✅

- **Requirement**: TDD mandatory - Tests written → User approved → Tests fail → Then implement
- **Compliance**: All tasks follow TDD approach with tests written first (explicitly noted in tasks.md)
- **Status**: PASS - Test-first approach clearly defined in tasks

### Integration Testing ✅

- **Requirement**: Focus on new library contract tests, contract changes, inter-service communication
- **Compliance**: Test fixes include integration test updates, example execution validation, DSL feature tests
- **Status**: PASS - Integration testing scope defined for DSL and solver components

### Observability ✅

- **Requirement**: Structured logging and debuggability
- **Compliance**: Error message improvements specified, test failure documentation required
- **Status**: PASS - Error handling and debugging improvements specified

### Simplicity ✅

- **Requirement**: Start simple, YAGNI principles
- **Compliance**: Focus on fixing existing functionality rather than adding new features (except Phase 3.5 which adds model parameters and Problem.modify)
- **Status**: PASS - Scope limited to improving existing package with minimal new features

## Project Structure

### Documentation (this feature)

```text
specs/003-testing/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification
├── tasks.md             # Detailed task breakdown
├── checklists/          # Quality checklists (if any)
└── contracts/           # API contracts (if any)
```

### Source Code (repository root)

```text
lib/dantzig/                    # Core library modules
├── core/                      # Core problem definition
│   ├── problem.ex            # Problem struct and management
│   └── problem/
│       └── dsl_reducer.ex    # DSL reducer (enumerator tracking)
├── problem/                   # Problem management
│   └── dsl/                  # Domain Specific Language
│       ├── expression_parser.ex          # Expression parsing (constant access)
│       ├── expression_parser/
│       │   └── constant_evaluation.ex    # Constant evaluation
│       ├── constraint_manager.ex          # Constraint creation (description interpolation)
│       ├── variable_manager.ex            # Variable creation (enumerator tracking)
│       └── objective_manager.ex          # Objective setting
└── solver/                    # HiGHS solver integration
    └── highs.ex               # HiGHS solver (API fixes)

test/                          # Test suite
├── dantzig/                   # Unit tests by module
│   ├── core/                 # Core functionality tests
│   ├── dsl/                  # DSL tests
│   │   ├── constant_access_test.exs
│   │   ├── model_parameters_test.exs
│   │   ├── problem_modify_test.exs
│   │   └── enumerator_tracking_test.exs
│   └── solver/               # Solver integration tests
├── examples/                 # Example validation tests
├── coverage/                 # Coverage validation tests
└── test_helper.exs

docs/user/examples/            # Example files (must execute successfully)
docs/internal/developer-notes/ # Internal documentation
docs/developer/architecture/   # Architecture documentation
```

**Structure Decision**: Elixir library package structure with clear separation of concerns:
- `lib/dantzig/` contains all library modules organized by functionality
- `test/` mirrors the lib structure for comprehensive testing
- `docs/user/examples/` provides learning resources
- `docs/` contains user-facing and developer documentation

## Complexity Tracking

> **No constitution violations detected - all gates passed successfully**

All constitution checks passed without violations. The testing and DSL improvements focus on fixing existing functionality and adding essential enhancements (model parameters, Problem.modify) while maintaining backward compatibility.

## Phase Structure

### Phase 1: Fix Test Suite Failures (P1) 🎯 MVP
**Goal**: Resolve all test failures to enable reliable development
**Dependencies**: None
**Key Activities**:
- Fix API signature mismatches (module aliases, function arities)
- Fix variable access patterns
- Fix compilation errors
- Update test assertions

### Phase 2: Fix Example Execution (P1)
**Goal**: Ensure all example files execute successfully
**Dependencies**: Can run in parallel with Phase 1
**Key Activities**:
- Fix compilation errors in examples
- Fix runtime errors in examples
- Verify examples produce valid solutions
- Update example documentation

### Phase 3: Resolve DSL Implementation Issues (P1)
**Goal**: Fix all high-priority DSL implementation issues
**Dependencies**: Can start in parallel with Phase 1, but benefits from Phase 1 completion
**Key Activities**:
- Constant access with generator bindings
- Description interpolation with AST
- Generator domain type support
- Nested map access with bindings
- Sum function with constant access
- Constant and enumerated constant access (depends on Phase 3.5)

### Phase 3.5: Model Parameters & Problem.modify (P1)
**Goal**: Add model parameters and Problem.modify capability
**Dependencies**: Can start after Phase 3 (Issue #1) completion
**Key Activities**:
- Implement model parameters in Problem.define
- Implement Problem.modify macro
- Ensure backward compatibility
- Document new features

### Phase 4: Implement Enumerator Tracking (P2)
**Goal**: Implement Phase 1 of enumerator tracking
**Dependencies**: Can start after Phase 3 (Issue #1) completion
**Key Activities**:
- Add enumerator fields to Problem struct
- Register enumerators during variable creation
- Validate enumerators during constraint generation
- Document enumerator tracking design

### Phase 5: Test Suite Quality (P2)
**Goal**: Improve test suite quality and maintain coverage
**Dependencies**: Depends on Phase 1 completion
**Key Activities**:
- Document test failures
- Update test documentation
- Ensure coverage targets met (≥80% overall, ≥85% core)
- Add edge case tests

### Phase 6: Documentation and Validation
**Goal**: Document improvements and validate completion
**Dependencies**: Depends on all previous phases
**Key Activities**:
- Update implementation status documents
- Run validation tests
- Create comprehensive status report

## Technical Decisions

### Test Framework
- **Decision**: Use ExUnit with ExCoveralls for coverage
- **Rationale**: Standard Elixir testing stack, already in use
- **Alternatives Considered**: None (existing choice)

### DSL Enhancement Approach
- **Decision**: Extend existing expression parser with constant evaluation
- **Rationale**: Minimal changes to existing architecture, maintains backward compatibility
- **Alternatives Considered**: Complete rewrite (rejected - too risky, breaks compatibility)

### Model Parameters Implementation
- **Decision**: Thread model_parameters through macro expansion and expression evaluation
- **Rationale**: Enables direct name access without `params.key` syntax, cleaner DSL
- **Alternatives Considered**: Explicit `params.key` syntax (rejected - less ergonomic)

### Enumerator Tracking Storage
- **Decision**: Add fields to Problem struct (`enumerators`, `variable_enumerators`)
- **Rationale**: Keeps enumerator metadata with problem definition, enables validation
- **Alternatives Considered**: Separate registry module (rejected - adds complexity)

### Backward Compatibility Strategy
- **Decision**: Maintain 100% backward compatibility, no breaking changes
- **Rationale**: Critical for existing users, enables incremental adoption
- **Alternatives Considered**: Breaking changes with migration guide (rejected - violates FR-009)

## Data Model

### Problem Struct Extensions
- `enumerators`: Dictionary of enumerator metadata
- `variable_enumerators`: Map of variable names to enumerator sequences
- `linearization_variables`: Placeholder for future linearization variable tracking

### Enumerator Metadata
- Domain: The enumerable collection (list, map, range, etc.)
- Name: Generated name from AST/expression
- Source: Where the enumerator was defined (variable, constraint)

### Model Parameters
- Map structure: `%{key => value}` where keys are atom or string identifiers
- Access pattern: Direct name access in DSL (e.g., `food_names`, not `params.food_names`)
- Evaluation: At macro expansion time using generator bindings

## Constraints

### Backward Compatibility
- **Constraint**: Zero breaking changes to public API
- **Impact**: All fixes must preserve existing function signatures and behavior
- **Mitigation**: Comprehensive backward compatibility tests (FR-009)

### Test Coverage Targets
- **Constraint**: ≥80% overall, ≥85% core modules
- **Impact**: May require additional tests beyond fixes
- **Mitigation**: Coverage validation tests and monitoring (NFR-001)

### File Size Limits
- **Constraint**: Code files under 500 lines, documentation files under 300 lines (unless no other options)
- **Impact**: May require refactoring large files or splitting into modules
- **Mitigation**: Review file sizes during implementation, refactor if feasible

### DSL Syntax Consistency
- **Constraint**: Model parameters and Problem.modify must use same DSL syntax as Problem.define
- **Impact**: Requires careful macro design
- **Mitigation**: Reuse existing DSL infrastructure

## Risk Assessment

### High Risk
- **Breaking backward compatibility**: Mitigated by explicit compatibility tests
- **DSL parsing complexity**: Mitigated by incremental implementation and comprehensive tests

### Medium Risk
- **Enumerator tracking performance**: Low impact, metadata only
- **Test coverage gaps**: Mitigated by coverage validation

### Low Risk
- **Example execution failures**: Straightforward fixes
- **Documentation updates**: Mechanical task

## Success Metrics

- **SC-001**: All tests compile and run (FR-001)
- **SC-002**: All examples execute (FR-002, FR-010)
- **SC-003**: DSL issues resolved (FR-003)
- **SC-004**: Enumerator tracking implemented (FR-004, FR-011)
- **SC-005**: Coverage targets met (NFR-001)
- **SC-011**: Model parameters work (FR-013)
- **SC-012**: Problem.modify works (FR-014)
- **SC-013**: Constant access works (FR-015)
- **SC-015**: Code files under 500 lines, documentation files under 300 lines (unless no other options) (NFR-005)

## Notes

- All phases follow TDD: tests written first, then implementation
- Tasks are organized to enable independent implementation
- Phase 3.5 is a capability addition, not a bug fix
- Enumerator tracking Phase 1 focuses on registration; validation is Phase 2 (future)
- Documentation updates are deferred to Phase 6 to avoid churn during implementation
