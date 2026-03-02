# Feature Specification: Comprehensive Testing and DSL Improvements

**Feature Branch**: `003-testing`
**Created**: 2025-11-12
**Status**: Draft
**Input**: Tasks document from `/specs/003-testing/tasks.md`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fix Test Suite Failures (Priority: P1) 🎯 MVP

**As a developer** working with the Dantzig package, **I need** all tests to compile and run successfully **so that** I can have confidence in the codebase stability and continue development without blocking compilation errors.

**Why this priority**: Compilation errors and test failures prevent any meaningful testing or development work. This is a foundational requirement that blocks all other improvements.

**Independent Test**: Can be fully tested by running `mix test` and verifying all tests compile and execute without errors.

**Acceptance Scenarios**:

1. **Given** the current codebase with test failures, **When** I run `mix test`, **Then** all tests compile successfully without errors
2. **Given** a clean test environment, **When** I run the full test suite, **Then** all tests pass or fail with meaningful assertions (not compilation errors)
3. **Given** API changes have occurred, **When** I review test files, **Then** all API calls match current function signatures
4. **Given** variable access patterns have changed, **When** I run tests, **Then** variable name formats and access methods match current API

---

### User Story 2 - Fix Example Execution (Priority: P1)

**As a user** learning the Dantzig package, **I need** all example files to execute successfully **so that** I can understand how to use the package effectively.

**Why this priority**: Examples serve as the primary learning resource. Broken examples create adoption barriers and incorrect usage patterns.

**Independent Test**: Can be fully tested by running each example file individually and verifying execution success.

**Acceptance Scenarios**:

1. **Given** all example files in `docs/user/examples/`, **When** I run each example individually, **Then** all examples execute without compilation or runtime errors
2. **Given** example files with optimization problems, **When** I run them, **Then** all examples produce valid optimization solutions
3. **Given** example documentation, **When** I review it, **Then** documentation matches current DSL syntax

---

### User Story 3 - Resolve DSL Implementation Issues (Priority: P1)

**As a developer** using the Dantzig DSL, **I need** all DSL features to work correctly with proper error handling **so that** I can build optimization problems reliably.

**Why this priority**: DSL issues prevent users from expressing optimization problems correctly, leading to frustration and incorrect models.

**Independent Test**: Can be fully tested by running DSL feature tests and verifying issues are resolved.

**Acceptance Scenarios**:

1. **Given** constant access expressions with generator bindings, **When** I use them in constraints, **Then** constants are correctly evaluated using generator bindings
2. **Given** map/list access patterns (e.g., `cost[worker][task]`), **When** I use them in expressions, **Then** constants are correctly accessed from model_parameters
3. **Given** description interpolation with AST, **When** I use variable references in descriptions, **Then** descriptions are correctly interpolated
4. **Given** generator domains, **When** I use any enumerable type, **Then** generators accept the type without errors
5. **Given** nested map access, **When** I use multiple generator bindings, **Then** nested access works correctly
6. **Given** sum expressions with constant access, **When** I use them, **Then** constants are correctly evaluated within sum expressions

---

### User Story 4 - Implement Enumerator Tracking (Priority: P2)

**As a developer** building optimization problems, **I need** enumerator tracking to validate variable and constraint relationships **so that** I can catch errors early and understand problem structure.

**Why this priority**: Enumerator tracking enables better error messages and problem validation, improving developer experience.

**Independent Test**: Can be fully tested by running enumerator tracking tests and verifying enumerators are registered.

**Acceptance Scenarios**:

1. **Given** variable definitions with generators, **When** I create variables, **Then** enumerators are registered in the Problem struct
2. **Given** constraint definitions, **When** I create constraints, **Then** enumerator validation checks that variables exist
3. **Given** nested enumerator patterns, **When** I use them, **Then** the system handles nested patterns correctly

---

### User Story 5 - Improve Test Suite Quality (Priority: P2)

**As a developer** maintaining the Dantzig package, **I need** comprehensive test coverage and quality metrics **so that** I can ensure code reliability and catch regressions.

**Why this priority**: High-quality tests are essential for maintaining a mathematical optimization library where correctness is critical.

**Independent Test**: Can be fully tested by running `mix test --cover` and reviewing quality metrics.

**Acceptance Scenarios**:

1. **Given** the test suite, **When** I run coverage analysis, **Then** overall coverage is at least 80%
2. **Given** core modules (Problem, DSL, AST, Solver), **When** I run focused coverage tests, **Then** each module has at least 85% coverage
3. **Given** test failures, **When** I review them, **Then** all failures are documented with clear reasons
4. **Given** edge cases from DSL issues, **When** I review tests, **Then** edge cases have appropriate test coverage

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST ensure all tests compile and run successfully without compilation errors or warnings
- **FR-002**: System MUST ensure all example files execute successfully and produce valid optimization solutions
- **FR-003**: System MUST resolve all high-priority DSL implementation issues including constant access, description interpolation, generator domain support, nested map access, and sum function constant access
- **FR-004**: System MUST implement enumerator tracking for variable enumerator registration and constraint validation
- **FR-005**: System MUST update all test files to use current API signatures (module aliases, function arities, option names)
- **FR-006**: System MUST fix all compilation errors in test files including undefined variables, deprecated function calls, and missing imports
- **FR-007**: System MUST fix all API-related test failures including variable access patterns, constraint name formats, and LP format string assertions
- **FR-008**: System MUST document all test failures and expected failures in `docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md`
- **FR-009**: System MUST maintain backward compatibility with existing public API (no breaking changes)
- **FR-010**: System MUST verify all examples produce valid optimization solutions (not just execute without errors)
- **FR-011**: System MUST track variable enumerators per variable definition with metadata (domain, name, source)
- **FR-012**: System MUST validate enumerators exist or are subsets during constraint generation
- **FR-013**: System MUST support model parameters in `Problem.define`, enabling external values to be bound into generators, expressions, and descriptions
  - Parameters accessible directly by name (e.g., `food_names`, `max_i`) in all DSL contexts
  - Parameters usable in generators: `[food <- food_names]` where `food_names` is looked up in model_parameters
  - Parameters usable in constraint/objective expressions by direct name access
  - Parameters interpolate in descriptions using direct name access: `"Variable #{product_name}_#{i}"`
  - Backward compatible: `Problem.define(do: block)` works without parameters
  - Clear error messages when symbols are not found in model_parameters map
- **FR-014**: System MUST provide a `Problem.modify` macro to declaratively apply additional variables/constraints/objective updates to an existing problem without rebuilding from scratch
  - Can add new variables to existing problem
  - Can add new constraints to existing problem
  - Can update objective function (uses `objective(expression, :direction)` syntax)
  - Preserves existing problem state (variables, constraints)
  - Uses same DSL syntax as `Problem.define` for consistency
  - Clear error messages for conflicts/invalid usage
- **FR-015**: System MUST support accessing constants and enumerated constants from model_parameters in constraint/objective expressions via map/list access syntax (e.g., `cost[worker][task]`, `multiplier[i]`, `matrix[i][j]`)
  - Scalar constants accessible by direct name: `multiplier` (not `params.multiplier`)
  - List constants accessible by index: `multiplier[i]` where `i` is from generator bindings
  - Nested list constants accessible: `matrix[i][j]` where `i` and `j` are from generator bindings
  - Map constants accessible: `cost[worker][task]` where `worker` and `task` are from generators
  - Constants evaluated at parse time using generator bindings and converted to polynomial coefficients
  - Clear error messages for undefined constants, invalid indices, type mismatches
  - Backward compatible: existing expressions without constant access continue to work
  - Supports all enumerable types: lists, maps, mapsets, ranges, etc.
- **FR-016**: System MUST document enumerator tracking design in `docs/developer/architecture/enumerator-tracking-design.md`

### Non-Functional Requirements

- **NFR-001**: Test coverage MUST meet targets: ≥80% overall, ≥85% for core modules (Problem, DSL, AST, Solver)
- **NFR-002**: All fixes MUST maintain backward compatibility (FR-009)
- **NFR-003**: Error messages MUST be clear and actionable for common usage mistakes
- **NFR-004**: Documentation MUST be updated to reflect current API and DSL syntax
- **NFR-005**: Code files SHOULD be under 500 lines, documentation files SHOULD be under 300 lines, unless no other options are feasible

### Key Entities

- **Test Suite**: Collection of unit, integration, and performance tests covering all functionality
- **Example Files**: Code examples demonstrating package usage located in `docs/user/examples/`
- **DSL Issues**: Known problems with DSL implementation including constant access, description interpolation, generator support
- **Enumerator Tracking**: System for tracking and validating variable enumerators and their relationships
- **Model Parameters**: Runtime values passed to `Problem.define` for use in DSL expressions
- **Problem.modify**: Macro for incrementally updating existing optimization problems

---

## Edge Cases

- What happens when test files reference deprecated API functions?
- How does the system handle undefined variables in test generators?
- What occurs when example files use outdated DSL syntax?
- How are compilation errors in experimental test files handled?
- What happens when model_parameters contains missing keys referenced in DSL?
- How does the system handle invalid constant access patterns (out of bounds, wrong types)?
- What occurs when `Problem.modify` attempts to add duplicate variables or constraints?
- How are nested enumerator patterns validated (e.g., `j <- items[i]`)?
- What happens when generator domains are not enumerable?
- How does constant access handle nil values or missing map keys?

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All tests compile and run successfully with zero compilation errors (FR-001)
- **SC-002**: All example files execute successfully and produce valid solutions (FR-002, FR-010)
- **SC-003**: All high-priority DSL issues are resolved (FR-003)
- **SC-004**: Enumerator tracking is implemented for variable registration (FR-004, FR-011)
- **SC-005**: Test coverage meets targets: ≥80% overall, ≥85% core modules (NFR-001)
- **SC-006**: All API updates are applied consistently across test files (FR-005)
- **SC-007**: All compilation errors are fixed (FR-006)
- **SC-008**: All API-related test failures are resolved (FR-007)
- **SC-009**: Test failures are documented in `docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md` (FR-008)
- **SC-010**: Backward compatibility is maintained (FR-009)
- **SC-011**: Model parameters work in all DSL contexts (FR-013)
- **SC-012**: `Problem.modify` supports incremental updates (FR-014)
- **SC-013**: Constant access works for all access patterns (FR-015)
- **SC-014**: Enumerator tracking design is documented (FR-016)
- **SC-015**: Code files are under 500 lines and documentation files are under 300 lines, unless no other options are feasible (NFR-005)

---

## Dependencies

- **Prerequisites**:
  - `docs/internal/developer-notes/DSL_IMPLEMENTATION_ISSUES.md` (if exists)
  - `docs/developer/architecture/enumerator-tracking-design.md` (if exists)
  - `docs/internal/developer-notes/TEST_FAILURE_ANALYSIS.md` (if exists)
- **Blocking**: None (can start immediately)
- **Blocked By**: None

---

## Notes

- This specification is derived from the tasks document and represents the comprehensive testing and DSL improvements feature
- User Stories are mapped to Phases in the tasks document (US1→Phase 1, US2→Phase 2, etc.)
- Phase 3.5 (Model Parameters & Problem.modify) is a capability addition that supports FR-013 and FR-014
- All tasks follow TDD approach: tests written first, then implementation
- Tasks are organized to enable independent implementation and testing of each user story
