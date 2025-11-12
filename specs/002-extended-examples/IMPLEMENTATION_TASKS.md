# Implementation Tasks: Extended Examples Feature

**Feature**: `002-extended-examples` | **Date**: 2025-01-27 | **Status**: In Progress

This document provides an updated, prioritized list of implementation tasks based on current progress and analysis.

## Current Status Summary

### ✅ Completed Tasks
- Task 1: Phase 3 examples validation (portfolio_optimization.exs fixed)
- Task 2: Phase 4 examples validation (facility_location.exs issues documented)
- Task 3: DSL feature coverage matrix created
- Task 4: Example validation test suite created
- Portfolio optimization example fixed and working

### ⚠️ In Progress / Partial
- Task 3.2: Project selection (resource_allocation.exs exists but needs enhancement)
- Task 4.1: Facility location (has DSL syntax issue)

### ❌ Missing / Not Started
- Task 4.2: Multi-objective LP example (file doesn't exist)
- Examples demonstrating non-linear functions (abs, max, min, and, or)
- Examples demonstrating integer variables
- Examples demonstrating Problem.modify API

## Priority 1: Critical Missing Examples

### Task 1.1: Create Multi-Objective LP Example
**Status**: ❌ Not Started  
**Priority**: P1 (Critical - specified in requirements)  
**File**: `examples/multi_objective_lp.exs`  
**Source Inspiration**: JuMP `multi_objective_knapsack.jl`, `multi_objective_examples.jl`

**Requirements**:
- Demonstrate multiple conflicting objectives
- 8-12 decision variables
- Show Pareto frontier concept (or weighted sum approach)
- Comprehensive documentation with business context
- Compiles and executes successfully

**Acceptance Criteria**:
- [ ] New example file with comprehensive documentation
- [ ] Demonstrates multiple objective functions
- [ ] 8-12 decision variables with conflicting objectives
- [ ] Advanced optimization concepts explained
- [ ] Compiles and executes successfully

**Estimated Effort**: Medium (4-6 hours)

---

### Task 1.2: Fix Facility Location DSL Syntax Issue
**Status**: ⚠️ Blocked - DSL limitation  
**Priority**: P1 (Critical - example exists but doesn't work)  
**File**: `examples/facility_location.exs`  
**Issue**: Variable-to-variable constraint `y(facility, customer) <= x(facility)` not recognized

**Requirements**:
- Either fix DSL to support variable-to-variable constraints, OR
- Reformulate example to avoid variable-to-variable constraints
- Ensure example compiles and executes successfully

**Options**:
1. **DSL Enhancement**: Add support for variable-to-variable constraints in constraint parser
2. **Reformulation**: Use big-M method or indicator constraints instead
3. **Alternative Syntax**: Check if different syntax works (e.g., using sum patterns)

**Acceptance Criteria**:
- [ ] Example compiles without errors
- [ ] Example executes successfully
- [ ] Demonstrates mixed-integer programming concepts
- [ ] Solution is valid and optimal

**Estimated Effort**: High (6-8 hours if DSL fix needed, 2-3 hours if reformulation)

---

### Task 1.3: Create Example Demonstrating Non-Linear Functions
**Status**: ❌ Not Started  
**Priority**: P1 (Critical - DSL feature not demonstrated)  
**File**: `examples/minimax_scheduling.exs` (recommended) or `examples/target_tracking.exs`  
**Source Inspiration**: NONLINEAR_FUNCTION_EXAMPLES.md, JuMP tutorials

**Requirements**:
- Demonstrate `max()` function in constraints or objective
- OR demonstrate `abs()` function for deviation minimization
- Clear educational value
- Comprehensive documentation

**Recommended Options**:
1. **Minimax Scheduling** - Minimize maximum completion time (makespan)
2. **Target Tracking** - Minimize absolute deviation from target values

**Acceptance Criteria**:
- [ ] New example file with comprehensive documentation
- [ ] Demonstrates `max()`, `min()`, or `abs()` function in DSL
- [ ] Shows automatic linearization in action
- [ ] Compiles and executes successfully
- [ ] Solution validation included

**Estimated Effort**: Medium (4-6 hours)

---

## Priority 2: Enhance Existing Examples

### Task 2.1: Enhance Resource Allocation to Full Project Selection
**Status**: ⚠️ Partial  
**Priority**: P2 (Important - acceptance criteria not fully met)  
**File**: `examples/resource_allocation.exs` or create `examples/project_selection.exs`

**Current State**:
- ✅ Has 3 projects (needs 5-8)
- ❌ Missing project dependencies
- ✅ Demonstrates binary variables and budget constraints

**Requirements**:
- Expand to 5-8 projects
- Add project dependencies (e.g., project A requires project B)
- Use `and()` function to model dependencies: `select_A AND select_B`
- Comprehensive documentation

**Acceptance Criteria**:
- [ ] 5-8 projects with costs and dependencies
- [ ] Demonstrates `and()` function for dependencies
- [ ] Binary integer programming capabilities shown
- [ ] Compiles and executes successfully

**Estimated Effort**: Medium (3-4 hours)

---

### Task 2.2: Add Integer Variable Example
**Status**: ❌ Not Started  
**Priority**: P2 (Important - DSL feature gap)  
**File**: `examples/integer_programming.exs` (new) or enhance existing

**Requirements**:
- Demonstrate integer variables (not just binary)
- Clear use case (e.g., production quantities must be whole units)
- Show difference from continuous variables
- Comprehensive documentation

**Suggested Problems**:
- Production planning with integer units
- Cutting stock problem
- Workforce scheduling with integer workers

**Acceptance Criteria**:
- [ ] Example demonstrates `:integer` variable type
- [ ] Clear business case for integer requirement
- [ ] Compiles and executes successfully
- [ ] Solution shows integer values

**Estimated Effort**: Low-Medium (2-3 hours)

---

## Priority 3: Documentation and Organization

### Task 3.1: Create EXAMPLE_GUIDE.md
**Status**: ❌ Not Started  
**Priority**: P2 (Important - user-facing documentation)  
**File**: `docs/EXAMPLE_GUIDE.md`

**Requirements**:
- User-facing guide to all examples
- Educational progression explanation (beginner → intermediate → advanced)
- DSL feature mapping (which example demonstrates which features)
- Quick start instructions
- Example categorization by complexity
- Links to relevant examples

**Structure**:
1. Introduction and Quick Start
2. Example Categories (Beginner, Intermediate, Advanced)
3. DSL Feature Index
4. Educational Progression Guide
5. Example Descriptions with links

**Acceptance Criteria**:
- [ ] Comprehensive guide covering all priority examples
- [ ] Clear educational progression
- [ ] DSL feature mapping complete
- [ ] Easy to navigate and understand

**Estimated Effort**: Medium (4-5 hours)

---

### Task 3.2: Generate EXTENDED_EXAMPLES_REPORT.md
**Status**: ❌ Not Started  
**Priority**: P2 (Important - status reporting)  
**File**: `docs/EXTENDED_EXAMPLES_REPORT.md`

**Requirements**:
- DSL feature coverage analysis (from DSL_FEATURE_COVERAGE.md)
- Performance metrics for all examples
- Educational value assessment
- Final status report
- Recommendations for future improvements

**Content**:
- Executive summary
- Example status table
- DSL feature coverage matrix
- Performance benchmarks
- Gaps and recommendations

**Acceptance Criteria**:
- [ ] Coverage analysis of DSL features
- [ ] Performance metrics for all examples
- [ ] Educational value assessment
- [ ] Final status report
- [ ] Recommendations documented

**Estimated Effort**: Medium (3-4 hours)

---

### Task 3.3: Organize Examples by Complexity Level
**Status**: ⚠️ Partial  
**Priority**: P2 (Important - FR-003 requirement)  
**Files**: All example files, `docs/EXAMPLE_GUIDE.md`

**Requirements**:
- Clear categorization: beginner (2-5 vars), intermediate (5-15 vars), advanced (10-30 vars)
- Documentation in each example file header
- Index/guide showing progression

**Current Categorization Needed**:
- **Beginner**: two_variable_lp.exs, resource_allocation.exs
- **Intermediate**: portfolio_optimization.exs, (project_selection.exs)
- **Advanced**: facility_location.exs, multi_objective_lp.exs (when created)

**Acceptance Criteria**:
- [ ] All examples clearly categorized
- [ ] Documentation reflects complexity level
- [ ] Clear progression path documented
- [ ] Example guide includes categorization

**Estimated Effort**: Low (1-2 hours)

---

## Priority 4: Additional Non-Linear Function Examples

### Task 4.1: Create Target Tracking Example (abs function)
**Status**: ❌ Not Started  
**Priority**: P3 (Nice to have - demonstrates abs)  
**File**: `examples/target_tracking.exs`

**Requirements**:
- Minimize absolute deviation from target values
- Simple, intuitive problem
- Demonstrates `abs()` function
- Good for beginners learning non-linear functions

**Acceptance Criteria**:
- [ ] Demonstrates `abs()` in objective or constraints
- [ ] Simple, understandable problem
- [ ] Compiles and executes successfully

**Estimated Effort**: Low-Medium (2-3 hours)

---

### Task 4.2: Create Factory Schedule Example (max/and functions)
**Status**: ❌ Not Started  
**Priority**: P3 (Nice to have - from JuMP)  
**File**: `examples/factory_schedule.exs`

**Requirements**:
- Fixed costs when factory runs
- Production scheduling over time
- Could demonstrate `max()` or `and()` for fixed cost logic
- Based on JuMP factory_schedule.jl

**Acceptance Criteria**:
- [ ] Demonstrates fixed costs with conditional logic
- [ ] Time-based production planning
- [ ] Compiles and executes successfully

**Estimated Effort**: Medium (3-4 hours)

---

## Priority 5: Problem Modification API Examples

### Task 5.1: Create Example Demonstrating Problem.modify
**Status**: ❌ Not Started  
**Priority**: P3 (Nice to have - DSL feature gap)  
**File**: `examples/problem_modification.exs` or enhance existing

**Requirements**:
- Demonstrate `Problem.modify()` macro
- Show adding variables/constraints to existing problem
- Show modifying existing constraints
- Comprehensive documentation

**Acceptance Criteria**:
- [ ] Demonstrates Problem.modify() usage
- [ ] Shows adding variables and constraints
- [ ] Shows modifying existing elements
- [ ] Compiles and executes successfully

**Estimated Effort**: Low-Medium (2-3 hours)

---

### Task 5.2: Create Example Demonstrating Problem.add_variable/add_constraint
**Status**: ❌ Not Started  
**Priority**: P3 (Nice to have - DSL feature gap)  
**File**: Enhance existing example or create new

**Requirements**:
- Demonstrate `Problem.add_variable()` outside blocks
- Demonstrate `Problem.add_constraint()` outside blocks
- Show when to use these vs. Problem.modify()
- Documentation explaining use cases

**Acceptance Criteria**:
- [ ] Demonstrates Problem.add_variable() usage
- [ ] Demonstrates Problem.add_constraint() usage
- [ ] Clear documentation on when to use
- [ ] Compiles and executes successfully

**Estimated Effort**: Low (1-2 hours)

---

## Priority 6: Validation and Testing

### Task 6.1: Run and Fix Example Validation Tests
**Status**: ⚠️ Partial  
**Priority**: P2 (Important - ensure quality)  
**File**: `test/extended_examples_test.exs`

**Requirements**:
- Run the test suite: `mix test test/extended_examples_test.exs`
- Fix any failing tests
- Ensure all 7 priority examples pass validation
- Document any known issues

**Acceptance Criteria**:
- [ ] All tests pass for working examples
- [ ] Known issues documented for problematic examples
- [ ] Test suite provides clear feedback

**Estimated Effort**: Low-Medium (2-3 hours)

---

### Task 6.2: Performance Benchmarking
**Status**: ❌ Not Started  
**Priority**: P2 (Important - FR-007 requirement)  
**Files**: All example files

**Requirements**:
- Measure execution time for all examples
- Verify all complete within 30 seconds
- Check memory usage (if possible)
- Document performance characteristics

**Acceptance Criteria**:
- [ ] All examples execute within 30 seconds
- [ ] Performance metrics documented
- [ ] Any slow examples identified and optimized

**Estimated Effort**: Low (1-2 hours)

---

## Priority 7: Documentation Quality Verification

### Task 7.1: Verify All Examples Have Comprehensive Headers
**Status**: ⚠️ Partial  
**Priority**: P2 (Important - FR-004 requirement)  
**Files**: All priority example files

**Required Sections** (per FR-004):
- Business context
- Mathematical formulation
- DSL syntax highlights
- Common gotchas

**Checklist for Each Example**:
- [ ] Business context section present
- [ ] Mathematical formulation clearly explained
- [ ] DSL syntax highlights documented
- [ ] Common gotchas section included
- [ ] Learning insights provided

**Estimated Effort**: Medium (3-4 hours to review and enhance all)

---

## Implementation Order Recommendation

### Phase 1: Critical Missing Examples (Week 1)
1. **Task 1.1**: Create Multi-Objective LP Example
2. **Task 1.3**: Create Non-Linear Function Example (minimax or target tracking)
3. **Task 1.2**: Fix Facility Location (or document workaround)

### Phase 2: Enhancements (Week 2)
4. **Task 2.1**: Enhance Resource Allocation to Full Project Selection
5. **Task 2.2**: Add Integer Variable Example
6. **Task 6.1**: Run and Fix Validation Tests

### Phase 3: Documentation (Week 2-3)
7. **Task 3.1**: Create EXAMPLE_GUIDE.md
8. **Task 3.3**: Organize Examples by Complexity
9. **Task 7.1**: Verify Documentation Quality

### Phase 4: Additional Features (Week 3)
10. **Task 4.1**: Create Target Tracking Example (if not done in Phase 1)
11. **Task 5.1**: Create Problem.modify Example
12. **Task 3.2**: Generate EXTENDED_EXAMPLES_REPORT.md

### Phase 5: Final Validation (Week 3)
13. **Task 6.2**: Performance Benchmarking
14. **Task 5.2**: Create Problem.add_variable/add_constraint Example (optional)

## Success Metrics

### Must Have (P1):
- ✅ All 7 priority examples exist and execute
- ⚠️ Multi-objective LP example created
- ⚠️ At least one non-linear function example (abs, max, or min)
- ⚠️ Facility location fixed or workaround documented

### Should Have (P2):
- ⚠️ Project selection enhanced to meet all criteria
- ⚠️ Integer variable example created
- ⚠️ EXAMPLE_GUIDE.md created
- ⚠️ Examples organized by complexity
- ⚠️ All examples have comprehensive documentation

### Nice to Have (P3):
- Additional non-linear function examples
- Problem modification API examples
- Performance benchmarking complete

## Notes

- **DSL Limitations**: Some features (variable-to-variable constraints) may require DSL enhancements
- **Non-Linear Functions**: Currently no priority examples demonstrate these - this is a critical gap
- **Multi-Objective**: File missing, but JuMP provides excellent reference implementations
- **Test Coverage**: Validation test suite created but needs to be run and verified

## Dependencies

- Task 1.2 (Facility Location) may block on DSL enhancements
- Task 2.1 (Project Selection) can use Task 1.3 patterns for `and()` function
- Task 3.1 (EXAMPLE_GUIDE) depends on examples being complete
- Task 3.2 (Report) depends on all examples being validated
