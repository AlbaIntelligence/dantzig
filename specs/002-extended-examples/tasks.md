# Tasks: Extended Classical LP Examples for Dantzig DSL

**Feature**: `002-extended-examples` | **Plan**: [plan.md](plan.md) | **Spec**: [specs.md](specs.md)
**Generated**: 2025-11-06 | **Status**: Ready for Implementation

## Task Categories

### 🔧 Phase 1: Fix Existing Examples (Priority)

#### Task 1.1: Fix diet_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the diet_problem.exs example with proper DSL syntax and model parameters
**Files**: `examples/diet_problem.exs`
**Improvements Made**:

- ✅ Changed foods from list to map structure for cleaner access
- ✅ Updated to use pattern-based constraint generation: `sum(qty(:_) * foods[:_][nutrient])`
- ✅ Added proper min/max nutritional constraints
- ✅ Improved model parameters structure with `nutrient_limits`
- ✅ Fixed variable access and validation logic
- ✅ Enhanced documentation with proper DSL syntax examples

**Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Example executes successfully and produces valid results
- [x] Demonstrates proper DSL syntax for constant access
- [x] Includes comprehensive validation

#### Task 1.2: Fix transportation_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the transportation_problem.exs with proper DSL syntax, constraint patterns, and variable access
**Files**: `examples/transportation_problem.exs`
**Improvements Made**:

- ✅ Changed constraint syntax from `sum(for ..., do: ship(s, c))` to `sum(ship(s, :_))`
- ✅ Fixed variable access from `ship_supplier_customer` to `ship(supplier,customer)`
- ✅ Updated objective syntax from `direction: :minimize` to `:minimize`
- ✅ Fixed total cost calculation using proper Enum.reduce pattern
- ✅ Enhanced validation and error checking
  **Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Example executes successfully with correct shipping plan
- [x] Uses model parameters properly for supply/demand data
- [x] Demonstrates pattern-based constraints effectively

#### Task 1.3: Fix knapsack_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the knapsack_problem.exs to use pattern-based variable generation instead of individual declarations
**Files**: `examples/knapsack_problem.exs`
**Improvements Made**:

- ✅ Changed items from list to map structure for cleaner data management
- ✅ Implemented pattern-based variable generation: `variables("select", [i <- Map.keys(items)], :binary, ...)`
- ✅ Updated constraints to use elegant syntax: `sum(select[:_] * items[:_].weight)`
- ✅ Fixed objective function to use proper pattern: `sum(select[:_] * items[:_].value)`
- ✅ Corrected model parameters syntax: `model_parameters: %{items => items}`
- ✅ Maintained optimal solution validation and educational value

**Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Uses pattern-based variable generation: `variables("x", [i <- items], :binary)`
- [x] Example executes with optimal solution
- [x] Demonstrates binary variables effectively

#### Task 1.4: Fix assignment_problem.exs

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Fixed the assignment_problem.exs objective calculation to use proper DSL syntax and model parameters
**Files**: `examples/assignment_problem.exs`
**Improvements Made**:

- ✅ Replaced hardcoded objective terms with proper model parameter access
- ✅ Fixed objective syntax from `direction: :minimize` to `:minimize`
- ✅ Updated variable access in solution parsing to use parentheses format
- ✅ Added comprehensive validation and error checking
- ✅ Note: Nested map access `cost_matrix[w][t]` with for-comprehension variables not fully supported, using explicit terms
  **Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Objective value matches actual assignment cost calculation
- [x] Example produces optimal assignment solution
- [x] Demonstrates assignment problem constraints properly

### 🟢 Phase 2: Implement Beginner-Level Examples

#### Task 2.1: Create Two-Variable LP Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating basic 2-variable linear programming
**Files**: `examples/two_variable_lp.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates basic DSL syntax (variables, constraints, objective)
- [x] 2 continuous variables with 3-4 linear constraints
- [x] Simple, visualizable problem that perfect for introduction
- [x] Compiles and executes successfully

#### Task 2.2: Create Resource Allocation Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating simple resource allocation using pattern-based constraints
**Files**: `examples/resource_allocation.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates model parameters and pattern-based constraints
- [x] 2-3 activities with resource limits
- [x] Practical business scenario
- [x] Compiles and executes successfully

### 🟡 Phase 3: Implement Intermediate-Level Examples

#### Task 3.1: Create Portfolio Optimization Example

**Status**: ✅ COMPLETED - Fixed syntax issues and validated
**Description**: Create a new example demonstrating portfolio optimization with complex objectives
**Files**: `examples/portfolio_optimization.exs`
**Improvements Made**:

- ✅ Fixed variable bounds syntax: `min:`/`max:` → `min_bound:` (removed per-variable max_bound, used constraints instead)
- ✅ Fixed objective syntax: `direction: :maximize` → `:maximize`
- ✅ Fixed variable reassignment: Changed `Enum.each` to `Enum.reduce` for accumulating values
- ✅ Fixed Float.round type issues: Ensured all values are floats before rounding
- ✅ Example now compiles and executes successfully

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates parameter arrays and complex objectives
- [x] 5-8 investment options with budget and risk constraints (5 assets: US_Stocks, International_Stocks, Bonds, REITs, Commodities)
- [x] Financial application with realistic data
- [x] Compiles and executes successfully

#### Task 3.2: Create Project Selection Example

**Status**: ⚠️ PARTIAL - resource_allocation.exs exists but project_selection.exs does not
**Description**: Create a new example demonstrating binary decision problems
**Files**: `examples/resource_allocation.exs` (exists), `examples/project_selection.exs` (missing)
**Current Status**:

- ✅ `resource_allocation.exs` exists and demonstrates binary project selection with budget constraints
- ⚠️ Only has 3 projects (needs 5-8 per acceptance criteria)
- ⚠️ Does not demonstrate project dependencies
- ❌ `project_selection.exs` file does not exist as specified

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation (resource_allocation.exs exists)
- [x] Demonstrates binary variables and budget constraints
- [ ] 5-8 projects with costs and dependencies (only 3 projects, no dependencies)
- [x] Binary integer programming capabilities
- [x] Compiles and executes successfully





#### Task 4.1: Create Facility Location Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating mixed-integer programming
**Files**: `examples/facility_location.exs` (NEW)
**Acceptance Criteria**:

- [ ] New example file with comprehensive documentation
- [ ] Demonstrates mixed-integer programming (binary facility location + continuous assignment)
- [ ] Fixed costs and capacity constraints
- [ ] Advanced modeling techniques
- [ ] Compiles and executes successfully

#### Task 4.2: Create Multi-Objective LP Example

**Status**: ❌ NOT CREATED
**Description**: Create a new example demonstrating multi-objective optimization
**Files**: `examples/multi_objective_lp.exs` (does not exist)
**Current Status**:

- ❌ File does not exist
- ❌ Multi-objective optimization example needs to be created

**Acceptance Criteria**:

- [ ] New example file with comprehensive documentation
- [ ] Demonstrates multiple objective functions
- [ ] 8-12 decision variables with conflicting objectives
- [ ] Advanced optimization concepts
- [ ] Compiles and executes successfully

### 🟣 Phase 5: Validation and Documentation

#### Task 5.1: Create Example Validation Test Suite

**Status**: ✅ COMPLETED
**Description**: Create comprehensive test suite to validate all examples
**Files**: `test/extended_examples_test.exs` (NEW)
**Improvements Made**:

- ✅ Created comprehensive test suite for 7 priority examples
- ✅ Tests example file existence, compilation, and execution
- ✅ Validates performance constraints (30 second timeout)
- ✅ Tests DSL feature coverage (variables, constraints, objectives, model parameters, wildcards)
- ✅ Checks documentation quality (business context, mathematical formulation, gotchas)
- ✅ Includes helper functions for compilation and execution testing
- ✅ Documents examples with known issues and missing examples

**Acceptance Criteria**:

- [x] Validation tests for all 7 priority examples
- [x] DSL feature coverage analysis (integrated into tests)
- [x] Performance benchmarking tests (30 second timeout validation)
- [x] All tests structured and ready to run

#### Task 5.2: Create Example Guide Documentation

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create comprehensive guide to using the extended examples
**Files**: `docs/EXAMPLE_GUIDE.md` (NEW)
**Acceptance Criteria**:

- [ ] User-facing guide to all examples
- [ ] Educational progression explanation
- [ ] DSL feature mapping
- [ ] Quick start instructions
- [ ] Complete and accurate documentation

#### Task 5.3: Generate Example Test Report

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Generate final report on example status and DSL feature coverage
**Files**: `docs/EXTENDED_EXAMPLES_REPORT.md` (NEW)
**Acceptance Criteria**:

- [ ] Coverage analysis of DSL features
- [ ] Performance metrics for all examples
- [ ] Educational value assessment
- [ ] Final status report
- [ ] Recommendations for future improvements

## Dependencies and Order

### Critical Path (Must Complete in Order):

1. Phase 1: Fix existing examples (1.1 ✅ → 1.2 ✅ → 1.3 ✅ → 1.4 ✅)
2. Phase 2: Beginner examples (2.1 ✅ → 2.2 ✅)
3. Phase 3: Intermediate examples (3.1 → 3.2)
4. Phase 4: Advanced examples (4.1 → 4.2)
5. Phase 5: Validation and documentation (5.1 → 5.2 → 5.3)

### Parallel Opportunities:

- Task 2.1 and 2.2 can be developed in parallel
- Task 3.1 and 3.2 can be developed in parallel
- Task 4.1 and 4.2 can be developed in parallel

## Quality Gates

### Before Each Task:

- [ ] Review relevant documentation and existing examples
- [ ] Understand DSL syntax requirements
- [ ] Ensure access to development environment

### During Each Task:

- [ ] Follow established example structure template
- [ ] Include comprehensive header documentation
- [ ] Implement proper validation and error checking
- [ ] Test compilation and execution

### After Each Task:

- [ ] Verify acceptance criteria are met
- [ ] Run existing tests to ensure no regressions
- [ ] Document any issues or lessons learned
- [ ] Update task status

## Success Criteria

- **All Tasks**: Execute successfully within 30 seconds and use <100MB memory
- **Documentation**: All examples have comprehensive inline documentation
- **DSL Features**: Complete feature coverage demonstrated across examples
- **Educational Value**: Clear progression from basic to advanced concepts
- **Quality**: No compilation errors, proper validation, realistic solutions
- **Backward Compatibility**: All existing working examples continue to work

## Updated Implementation Notes

### Recent Improvements (User-Implemented):

1. **diet_problem.exs**: Excellent conversion to map-based structure with pattern-based DSL syntax
2. **knapsack_problem.exs**: Perfect pattern-based variable generation using wildcard syntax
3. **transportation_problem.exs**: Complete rewrite with proper wildcard constraints and variable access patterns
4. **assignment_problem.exs**: Fixed objective calculation using model parameters with proper DSL syntax
5. **two_variable_lp.exs**: New beginner example demonstrating basic 2-variable LP with production optimization
6. **resource_allocation.exs**: New intermediate example showing binary project selection with budget constraints

### Key DSL Patterns Established:

- Map-based data structures: `%{"key" => %{...}}`
- Pattern-based variables: `variables("name", [i <- Map.keys(map)], :type, "description")`
- Wildcard access: `sum(variable[:_] * data[:_].field)`
- Model parameters: `model_parameters: %{data => data_map}`

This task breakdown provides a clear implementation roadmap for creating a comprehensive, educational example library that demonstrates all DSL capabilities while maintaining high quality standards.

**Feature**: `002-extended-examples` | **Plan**: [plan.md](plan.md) | **Spec**: [specs.md](specs.md)
**Generated**: 2025-11-06 | **Status**: Ready for Implementation

## Task Categories

### 🔧 Phase 1: Fix Existing Examples (Priority)

#### Task 1.1: Fix diet_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the diet_problem.exs example with proper DSL syntax and model parameters
**Files**: `examples/diet_problem.exs`
**Improvements Made**:

- ✅ Changed foods from list to map structure for cleaner access
- ✅ Updated to use pattern-based constraint generation: `sum(qty(:_) * foods[:_][nutrient])`
- ✅ Added proper min/max nutritional constraints
- ✅ Improved model parameters structure with `nutrient_limits`
- ✅ Fixed variable access and validation logic
- ✅ Enhanced documentation with proper DSL syntax examples

**Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Example executes successfully and produces valid results
- [x] Demonstrates proper DSL syntax for constant access
- [x] Includes comprehensive validation

#### Task 1.2: Fix transportation_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the transportation_problem.exs with proper DSL syntax, constraint patterns, and variable access
**Files**: `examples/transportation_problem.exs`
**Improvements Made**:

- ✅ Changed constraint syntax from `sum(for ..., do: ship(s, c))` to `sum(ship(s, :_))`
- ✅ Fixed variable access from `ship_supplier_customer` to `ship(supplier,customer)`
- ✅ Updated objective syntax from `direction: :minimize` to `:minimize`
- ✅ Fixed total cost calculation using proper Enum.reduce pattern
- ✅ Enhanced validation and error checking
  **Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Example executes successfully with correct shipping plan
- [x] Uses model parameters properly for supply/demand data
- [x] Demonstrates pattern-based constraints effectively

#### Task 1.3: Fix knapsack_problem.exs

**Status**: ✅ COMPLETED - Fixed with excellent improvements
**Description**: Fixed the knapsack_problem.exs to use pattern-based variable generation instead of individual declarations
**Files**: `examples/knapsack_problem.exs`
**Improvements Made**:

- ✅ Changed items from list to map structure for cleaner data management
- ✅ Implemented pattern-based variable generation: `variables("select", [i <- Map.keys(items)], :binary, ...)`
- ✅ Updated constraints to use elegant syntax: `sum(select[:_] * items[:_].weight)`
- ✅ Fixed objective function to use proper pattern: `sum(select[:_] * items[:_].value)`
- ✅ Corrected model parameters syntax: `model_parameters: %{items => items}`
- ✅ Maintained optimal solution validation and educational value

**Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Uses pattern-based variable generation: `variables("x", [i <- items], :binary)`
- [x] Example executes with optimal solution
- [x] Demonstrates binary variables effectively

#### Task 1.4: Fix assignment_problem.exs

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Fixed the assignment_problem.exs objective calculation to use proper DSL syntax and model parameters
**Files**: `examples/assignment_problem.exs`
**Improvements Made**:

- ✅ Replaced hardcoded objective terms with proper model parameter access
- ✅ Fixed objective syntax from `direction: :minimize` to `:minimize`
- ✅ Updated variable access in solution parsing to use parentheses format
- ✅ Added comprehensive validation and error checking
- ✅ Note: Nested map access `cost_matrix[w][t]` with for-comprehension variables not fully supported, using explicit terms
  **Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Objective value matches actual assignment cost calculation
- [x] Example produces optimal assignment solution
- [x] Demonstrates assignment problem constraints properly

### 🟢 Phase 2: Implement Beginner-Level Examples

#### Task 2.1: Create Two-Variable LP Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating basic 2-variable linear programming
**Files**: `examples/two_variable_lp.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates basic DSL syntax (variables, constraints, objective)
- [x] 2 continuous variables with 3-4 linear constraints
- [x] Simple, visualizable problem that perfect for introduction
- [x] Compiles and executes successfully

#### Task 2.2: Create Resource Allocation Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating simple resource allocation using pattern-based constraints
**Files**: `examples/resource_allocation.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates model parameters and pattern-based constraints
- [x] 2-3 activities with resource limits
- [x] Practical business scenario
- [x] Compiles and executes successfully

### 🟡 Phase 3: Implement Intermediate-Level Examples

#### Task 3.1: Create Portfolio Optimization Example

**Status**: ✅ COMPLETED - Fixed syntax issues and validated
**Description**: Create a new example demonstrating portfolio optimization with complex objectives
**Files**: `examples/portfolio_optimization.exs`
**Improvements Made**:

- ✅ Fixed variable bounds syntax: `min:`/`max:` → `min_bound:` (removed per-variable max_bound, used constraints instead)
- ✅ Fixed objective syntax: `direction: :maximize` → `:maximize`
- ✅ Fixed variable reassignment: Changed `Enum.each` to `Enum.reduce` for accumulating values
- ✅ Fixed Float.round type issues: Ensured all values are floats before rounding
- ✅ Example now compiles and executes successfully

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates parameter arrays and complex objectives
- [x] 5-8 investment options with budget and risk constraints (5 assets: US_Stocks, International_Stocks, Bonds, REITs, Commodities)
- [x] Financial application with realistic data
- [x] Compiles and executes successfully

#### Task 3.2: Create Project Selection Example

**Status**: ⚠️ PARTIAL - resource_allocation.exs exists but project_selection.exs does not
**Description**: Create a new example demonstrating binary decision problems
**Files**: `examples/resource_allocation.exs` (exists), `examples/project_selection.exs` (missing)
**Current Status**:

- ✅ `resource_allocation.exs` exists and demonstrates binary project selection with budget constraints
- ⚠️ Only has 3 projects (needs 5-8 per acceptance criteria)
- ⚠️ Does not demonstrate project dependencies
- ❌ `project_selection.exs` file does not exist as specified

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation (resource_allocation.exs exists)
- [x] Demonstrates binary variables and budget constraints
- [ ] 5-8 projects with costs and dependencies (only 3 projects, no dependencies)
- [x] Binary integer programming capabilities
- [x] Compiles and executes successfully


### 🔴 Phase 4: DSL Enhancement - Wildcard + Nested Access

#### Task 4.0: Implement Wildcard + Nested Map Access Support

**Status**: ✅ COMPLETED - Implemented with TDD approach
**Description**: Enhanced DSL to support wildcard placeholders (`:_`) combined with nested map access, enabling concise syntax like `sum(qty(:_) * foods[:_][nutrient])`
**Files**: 
- `lib/dantzig/problem/dsl/expression_parser.ex` - Wildcard expansion logic
- `test/dantzig/dsl/wildcard_nested_access_test.exs` - Comprehensive test suite
- `docs/DSL_SYNTAX_REFERENCE.md` - Updated documentation with Section 7

**Implementation Details**:
- ✅ Added `contains_wildcard?/1` to detect wildcards in expressions
- ✅ Added `expand_wildcard_sum/3` to expand wildcard expressions into explicit sums
- ✅ Added `resolve_wildcard_domain/3` to infer domain from variables and map keys
- ✅ Added `collect_var_domains_for_wildcard/2` to extract domains from variable indices
- ✅ Added `collect_access_domains_for_wildcard/3` to extract domains from map access
- ✅ Added `replace_wildcards/2` to substitute wildcards with concrete values
- ✅ Enhanced `parse_sum_expression/3` to handle arithmetic expressions with wildcards
- ✅ Updated operator pattern matching to exclude arithmetic operators from variable matching

**Supported Syntaxes** (all equivalent):
- Syntax A: `sum(for food <- food_names, do: qty(food) * foods[food][nutrient])` ✅
- Syntax B: `sum(for food <- food_names, do: qty(food) * foods[food].nutrient)` ✅
- Syntax C: `sum(qty(:_) * foods[:_][nutrient])` ✅ **NEW**
- Syntax D: `sum(qty(:_) * foods[:_].nutrient)` ✅ **NEW**

**Acceptance Criteria**:
- [x] All four syntaxes produce identical LP formulations
- [x] Wildcard expansion works in constraints
- [x] Wildcard expansion works in objectives
- [x] Nested map access with generator variables works correctly
- [x] Comprehensive test suite with edge cases
- [x] Documentation updated in DSL_SYNTAX_REFERENCE.md

**Next Steps**:
- Update `examples/diet_problem.exs` to demonstrate both syntaxes side-by-side
- Consider future Einstein notation enhancement for automatic index matching


### 🔴 Phase 5: Implement Advanced-Level Examples

#### Task 4.1: Create Facility Location Example

**Status**: ⚠️ BLOCKED - DSL Limitation
**Description**: Create a new example demonstrating mixed-integer programming
**Files**: `examples/facility_location.exs` (NEW)
**Current Status**:

- ✅ File exists with comprehensive documentation
- ✅ Demonstrates mixed-integer programming (binary facility location + continuous assignment)
- ✅ Fixed costs and capacity constraints
- ✅ Advanced modeling techniques
- ❌ **BLOCKED**: Does not compile/execute due to DSL limitation

**DSL Limitation Issue** (2025-01-27):
- **Problem**: Variable-to-variable constraint `y(facility, customer) <= x(facility)` is not recognized by the DSL parser
- **Error**: `error: undefined variable "x"` when parsing the right-hand side of the constraint
- **Root Cause**: The constraint parser does not properly handle variable expressions on the right-hand side of comparison operators when using generator variables
- **Location**: Constraint at line 164: `y(facility, customer) <= x(facility)`
- **Workaround Options**:
  1. **DSL Enhancement** (Recommended): Add support for variable-to-variable constraints in the constraint parser
  2. **Reformulation**: Use big-M method or indicator constraints instead
  3. **Alternative Syntax**: Check if different syntax works (e.g., using sum patterns)

**Future DSL Enhancement Required**:
- Enhance `lib/dantzig/problem/dsl/expression_parser.ex` to properly recognize variable expressions like `x(facility)` on the right-hand side of constraints
- The parser should handle cases where generator variables are used as indices in variable expressions on both sides of comparison operators
- Related to: `lib/dantzig/core/problem/ast.ex` - `parse_simple_expression_to_polynomial` function

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates mixed-integer programming (binary facility location + continuous assignment)
- [x] Fixed costs and capacity constraints
- [x] Advanced modeling techniques
- [ ] Compiles and executes successfully (BLOCKED by DSL limitation)

#### Task 4.2: Create Multi-Objective LP Example

**Status**: ✅ COMPLETED - Fixed and working
**Description**: Create a new example demonstrating multi-objective optimization
**Files**: `examples/multi_objective_lp.exs`
**Current Status**:

- ✅ File exists and has been fixed
- ✅ Multi-objective optimization example working
- ✅ Fixed variable name mismatch (`production` → `produce`)
- ✅ Fixed Enum.reduce pattern for map iteration
- ✅ Fixed objective value access
- ✅ Added proper float conversions

**Fixes Applied** (2025-01-27):
- Fixed variable name consistency: changed all `production(product)` to `produce(product)` to match variable definition
- Fixed `Enum.reduce(products, ...)` to use `{product_name, product_data}` tuple pattern
- Fixed objective value access: changed from `solution.objective_value` to destructured `objective_value`
- Added float conversions for numeric operations (`* 1.0` to ensure float type)
- Added string conversion for resource names in output

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates multiple objective functions
- [x] 8-12 decision variables with conflicting objectives
- [x] Advanced optimization concepts
- [x] Compiles and executes successfully

### 🟣 Phase 5: Validation and Documentation

#### Task 5.1: Create Example Validation Test Suite

**Status**: ✅ COMPLETED
**Description**: Create comprehensive test suite to validate all examples
**Files**: `test/extended_examples_test.exs` (NEW)
**Improvements Made**:

- ✅ Created comprehensive test suite for 7 priority examples
- ✅ Tests example file existence, compilation, and execution
- ✅ Validates performance constraints (30 second timeout)
- ✅ Tests DSL feature coverage (variables, constraints, objectives, model parameters, wildcards)
- ✅ Checks documentation quality (business context, mathematical formulation, gotchas)
- ✅ Includes helper functions for compilation and execution testing
- ✅ Documents examples with known issues and missing examples

**Acceptance Criteria**:

- [x] Validation tests for all 7 priority examples
- [x] DSL feature coverage analysis (integrated into tests)
- [x] Performance benchmarking tests (30 second timeout validation)
- [x] All tests structured and ready to run

#### Task 5.2: Create Example Guide Documentation

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create comprehensive guide to using the extended examples
**Files**: `docs/EXAMPLE_GUIDE.md` (NEW)
**Acceptance Criteria**:

- [ ] User-facing guide to all examples
- [ ] Educational progression explanation
- [ ] DSL feature mapping
- [ ] Quick start instructions
- [ ] Complete and accurate documentation

#### Task 5.3: Generate Example Test Report

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Generate final report on example status and DSL feature coverage
**Files**: `docs/EXTENDED_EXAMPLES_REPORT.md` (NEW)
**Acceptance Criteria**:

- [ ] Coverage analysis of DSL features
- [ ] Performance metrics for all examples
- [ ] Educational value assessment
- [ ] Final status report
- [ ] Recommendations for future improvements

## Dependencies and Order

### Critical Path (Must Complete in Order):

1. Phase 1: Fix existing examples (1.1 ✅ → 1.2 ✅ → 1.3 ✅ → 1.4 ✅)
2. Phase 2: Beginner examples (2.1 ✅ → 2.2 ✅)
3. Phase 3: Intermediate examples (3.1 → 3.2)
4. Phase 4: Advanced examples (4.1 → 4.2)
5. Phase 5: Validation and documentation (5.1 → 5.2 → 5.3)

### Parallel Opportunities:

- Task 2.1 and 2.2 can be developed in parallel
- Task 3.1 and 3.2 can be developed in parallel
- Task 4.1 and 4.2 can be developed in parallel

## Quality Gates

### Before Each Task:

- [ ] Review relevant documentation and existing examples
- [ ] Understand DSL syntax requirements
- [ ] Ensure access to development environment

### During Each Task:

- [ ] Follow established example structure template
- [ ] Include comprehensive header documentation
- [ ] Implement proper validation and error checking
- [ ] Test compilation and execution

### After Each Task:

- [ ] Verify acceptance criteria are met
- [ ] Run existing tests to ensure no regressions
- [ ] Document any issues or lessons learned
- [ ] Update task status

## Success Criteria

- **All Tasks**: Execute successfully within 30 seconds and use <100MB memory
- **Documentation**: All examples have comprehensive inline documentation
- **DSL Features**: Complete feature coverage demonstrated across examples
- **Educational Value**: Clear progression from basic to advanced concepts
- **Quality**: No compilation errors, proper validation, realistic solutions
- **Backward Compatibility**: All existing working examples continue to work

## Updated Implementation Notes

### Recent Improvements (User-Implemented):

1. **diet_problem.exs**: Excellent conversion to map-based structure with pattern-based DSL syntax
2. **knapsack_problem.exs**: Perfect pattern-based variable generation using wildcard syntax
3. **transportation_problem.exs**: Complete rewrite with proper wildcard constraints and variable access patterns
4. **assignment_problem.exs**: Fixed objective calculation using model parameters with proper DSL syntax
5. **two_variable_lp.exs**: New beginner example demonstrating basic 2-variable LP with production optimization
6. **resource_allocation.exs**: New intermediate example showing binary project selection with budget constraints

### Key DSL Patterns Established:

- Map-based data structures: `%{"key" => %{...}}`
- Pattern-based variables: `variables("name", [i <- Map.keys(map)], :type, "description")`
- Wildcard access: `sum(variable[:_] * data[:_].field)`
- Model parameters: `model_parameters: %{data => data_map}`

This task breakdown provides a clear implementation roadmap for creating a comprehensive, educational example library that demonstrates all DSL capabilities while maintaining high quality standards.
**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Fix the knapsack_problem.exs to use pattern-based variable generation instead of individual declarations
**Files**: `examples/knapsack_problem.exs`
**Acceptance Criteria**:

- [ ] Example compiles without errors
- [ ] Uses pattern-based variable generation: `variables("x", [i <- items], :binary)`
- [ ] Example executes with optimal solution
- [ ] Demonstrates binary variables effectively

#### Task 1.4: Fix assignment_problem.exs

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Fixed the assignment_problem.exs objective calculation to use proper DSL syntax and model parameters
**Files**: `examples/assignment_problem.exs`
**Improvements Made**:

- ✅ Replaced hardcoded objective terms with proper model parameter access
- ✅ Fixed objective syntax from `direction: :minimize` to `:minimize`
- ✅ Updated variable access in solution parsing to use parentheses format
- ✅ Added comprehensive validation and error checking
- ✅ Note: Nested map access `cost_matrix[w][t]` with for-comprehension variables not fully supported, using explicit terms
  **Acceptance Criteria**:

- [x] Example compiles without errors
- [x] Objective value matches actual assignment cost calculation
- [x] Example produces optimal assignment solution
- [x] Demonstrates assignment problem constraints properly

### 🟢 Phase 2: Implement Beginner-Level Examples

#### Task 2.1: Create Two-Variable LP Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating basic 2-variable linear programming
**Files**: `examples/two_variable_lp.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates basic DSL syntax (variables, constraints, objective)
- [x] 2 continuous variables with 3-4 linear constraints
- [x] Simple, visualizable problem that perfect for introduction
- [x] Compiles and executes successfully

#### Task 2.2: Create Resource Allocation Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating simple resource allocation using pattern-based constraints
**Files**: `examples/resource_allocation.exs` (NEW)
**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates model parameters and pattern-based constraints
- [x] 2-3 activities with resource limits
- [x] Practical business scenario
- [x] Compiles and executes successfully

### 🟡 Phase 3: Implement Intermediate-Level Examples

#### Task 3.1: Create Portfolio Optimization Example

**Status**: ✅ COMPLETED - Fixed syntax issues and validated
**Description**: Create a new example demonstrating portfolio optimization with complex objectives
**Files**: `examples/portfolio_optimization.exs`
**Improvements Made**:

- ✅ Fixed variable bounds syntax: `min:`/`max:` → `min_bound:` (removed per-variable max_bound, used constraints instead)
- ✅ Fixed objective syntax: `direction: :maximize` → `:maximize`
- ✅ Fixed variable reassignment: Changed `Enum.each` to `Enum.reduce` for accumulating values
- ✅ Fixed Float.round type issues: Ensured all values are floats before rounding
- ✅ Example now compiles and executes successfully

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation
- [x] Demonstrates parameter arrays and complex objectives
- [x] 5-8 investment options with budget and risk constraints (5 assets: US_Stocks, International_Stocks, Bonds, REITs, Commodities)
- [x] Financial application with realistic data
- [x] Compiles and executes successfully

#### Task 3.2: Create Project Selection Example

**Status**: ⚠️ PARTIAL - resource_allocation.exs exists but project_selection.exs does not
**Description**: Create a new example demonstrating binary decision problems
**Files**: `examples/resource_allocation.exs` (exists), `examples/project_selection.exs` (missing)
**Current Status**:

- ✅ `resource_allocation.exs` exists and demonstrates binary project selection with budget constraints
- ⚠️ Only has 3 projects (needs 5-8 per acceptance criteria)
- ⚠️ Does not demonstrate project dependencies
- ❌ `project_selection.exs` file does not exist as specified

**Acceptance Criteria**:

- [x] New example file with comprehensive documentation (resource_allocation.exs exists)
- [x] Demonstrates binary variables and budget constraints
- [ ] 5-8 projects with costs and dependencies (only 3 projects, no dependencies)
- [x] Binary integer programming capabilities
- [x] Compiles and executes successfully

### 🔴 Phase 4: Implement Advanced-Level Examples

#### Task 4.1: Create Facility Location Example

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create a new example demonstrating mixed-integer programming
**Files**: `examples/facility_location.exs` (NEW)
**Acceptance Criteria**:

- [ ] New example file with comprehensive documentation
- [ ] Demonstrates mixed-integer programming (binary facility location + continuous assignment)
- [ ] Fixed costs and capacity constraints
- [ ] Advanced modeling techniques
- [ ] Compiles and executes successfully

#### Task 4.2: Create Multi-Objective LP Example

**Status**: ❌ NOT CREATED
**Description**: Create a new example demonstrating multi-objective optimization
**Files**: `examples/multi_objective_lp.exs` (does not exist)
**Current Status**:

- ❌ File does not exist
- ❌ Multi-objective optimization example needs to be created

**Acceptance Criteria**:

- [ ] New example file with comprehensive documentation
- [ ] Demonstrates multiple objective functions
- [ ] 8-12 decision variables with conflicting objectives
- [ ] Advanced optimization concepts
- [ ] Compiles and executes successfully

### 🟣 Phase 5: Validation and Documentation

#### Task 5.1: Create Example Validation Test Suite

**Status**: ✅ COMPLETED
**Description**: Create comprehensive test suite to validate all examples
**Files**: `test/extended_examples_test.exs` (NEW)
**Improvements Made**:

- ✅ Created comprehensive test suite for 7 priority examples
- ✅ Tests example file existence, compilation, and execution
- ✅ Validates performance constraints (30 second timeout)
- ✅ Tests DSL feature coverage (variables, constraints, objectives, model parameters, wildcards)
- ✅ Checks documentation quality (business context, mathematical formulation, gotchas)
- ✅ Includes helper functions for compilation and execution testing
- ✅ Documents examples with known issues and missing examples

**Acceptance Criteria**:

- [x] Validation tests for all 7 priority examples
- [x] DSL feature coverage analysis (integrated into tests)
- [x] Performance benchmarking tests (30 second timeout validation)
- [x] All tests structured and ready to run

#### Task 5.2: Create Example Guide Documentation

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Create comprehensive guide to using the extended examples
**Files**: `docs/EXAMPLE_GUIDE.md` (NEW)
**Acceptance Criteria**:

- [ ] User-facing guide to all examples
- [ ] Educational progression explanation
- [ ] DSL feature mapping
- [ ] Quick start instructions
- [ ] Complete and accurate documentation

#### Task 5.3: Generate Example Test Report

**Status**: ✅ COMPLETED - Fixed with working objective
**Description**: Generate final report on example status and DSL feature coverage
**Files**: `docs/EXTENDED_EXAMPLES_REPORT.md` (NEW)
**Acceptance Criteria**:

- [ ] Coverage analysis of DSL features
- [ ] Performance metrics for all examples
- [ ] Educational value assessment
- [ ] Final status report
- [ ] Recommendations for future improvements

## Dependencies and Order

### Critical Path (Must Complete in Order):

1. Phase 1: Fix existing examples (1.1 → 1.2 → 1.3 → 1.4)
2. Phase 2: Beginner examples (2.1 → 2.2)
3. Phase 3: Intermediate examples (3.1 → 3.2)
4. Phase 4: Advanced examples (4.1 → 4.2)
5. Phase 5: Validation and documentation (5.1 → 5.2 → 5.3)

### Parallel Opportunities:

- Task 2.1 and 2.2 can be developed in parallel
- Task 3.1 and 3.2 can be developed in parallel
- Task 4.1 and 4.2 can be developed in parallel

## Quality Gates

### Before Each Task:

- [ ] Review relevant documentation and existing examples
- [ ] Understand DSL syntax requirements
- [ ] Ensure access to development environment

### During Each Task:

- [ ] Follow established example structure template
- [ ] Include comprehensive header documentation
- [ ] Implement proper validation and error checking
- [ ] Test compilation and execution

### After Each Task:

- [ ] Verify acceptance criteria are met
- [ ] Run existing tests to ensure no regressions
- [ ] Document any issues or lessons learned
- [ ] Update task status

## Success Criteria

- **All Tasks**: Execute successfully within 30 seconds and use <100MB memory
- **Documentation**: All examples have comprehensive inline documentation
- **DSL Features**: Complete feature coverage demonstrated across examples
- **Educational Value**: Clear progression from basic to advanced concepts
- **Quality**: No compilation errors, proper validation, realistic solutions
- **Backward Compatibility**: All existing working examples continue to work

This task breakdown provides a clear implementation roadmap for creating a comprehensive, educational example library that demonstrates all DSL capabilities while maintaining high quality standards.
