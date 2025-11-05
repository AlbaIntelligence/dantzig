# AI Assistant Guide for Dantzig Project

This document helps AI assistants understand the Dantzig project structure, current work context, and where to find essential information.

## 🎯 Project Overview

**Dantzig** is an Elixir library for mathematical optimization (linear programming, mixed-integer programming). It provides a DSL (Domain-Specific Language) for writing optimization problems in a natural, mathematical notation style.

**Key Characteristics:**
- Pattern-based modeling with generator syntax (`variables("x", [i <- 1..n], :binary)`)
- Automatic linearization of non-linear expressions (abs, max/min, logical ops)
- Integration with HiGHS solver
- DSL-based API (`Problem.define do ... end`) as the primary interface
- AST transformation for expression parsing and evaluation

## 📚 Essential Documentation Locations

### Primary Documentation (`docs/`)

**Start Here:**
- **`docs/GETTING_STARTED.md`** - Entry point for understanding the project
- **`docs/DSL_SYNTAX_REFERENCE.md`** - Complete DSL syntax reference (critical for understanding current API)
- **`docs/COMPREHENSIVE_TUTORIAL.md`** - Comprehensive tutorial with examples
- **`docs/ARCHITECTURE.md`** - System design and internal architecture

**Advanced Topics:**
- **`docs/ADVANCED_AST.md`** - AST transformation details
- **`docs/MODELING_GUIDE.md`** - Best practices for modeling optimization problems
- **`docs/PATTERN_BASED_OPERATIONS.md`** - Pattern-based features
- **`docs/VARIADIC_OPERATIONS.md`** - Variadic operations (max, min, and, or)

**Important Notes:**
- **`docs/DEPRECATION_NOTICE.md`** - Old imperative API is deprecated, DSL is current
- **`docs/STYLE_GUIDE.md`** - Code style conventions

### Feature Specifications (`specs/`)

**Current Active Feature:**
- **`specs/001-robustify/`** - Active feature branch for robustification
  - **`specs/001-robustify/spec.md`** - Full feature specification
  - **`specs/001-robustify/tasks.md`** - Detailed task breakdown
  - **`specs/001-robustify/quickstart.md`** - Quick start guide for the feature
  - **`specs/001-robustify/plan.md`** - Implementation plan
  - **`specs/001-robustify/contracts/`** - API contracts (model-parameters-api.md, problem-modify-api.md, etc.)

**When Working on Features:**
- Check `specs/001-robustify/tasks.md` for current task status
- Review `specs/001-robustify/contracts/` for API requirements
- Follow the patterns in `specs/001-robustify/quickstart.md`

### Project Status Documents

**Current Work Context:**
- **`EXAMPLE_TEST_REPORT.md`** - Status of example files (compliance, working status)
- **`SYNTAX_ISSUES.md`** - Known syntax/parsing issues
- **`DEBUG_FINDINGS.md`** - Debug findings and solutions
- **`TEST_SUMMARY.md`** - Test coverage and status

## 🏗️ Project Structure

### Core Library (`lib/`)

**Main Modules:**
- **`lib/dantzig/core/problem.ex`** - Problem definition and management (includes `Problem.define` and `Problem.modify` macros)
- **`lib/dantzig/problem/dsl/`** - DSL implementation
  - **`expression_parser.ex`** - Expression parsing and evaluation (critical for constant access, bindings)
  - **`constraint_manager.ex`** - Constraint parsing and creation
  - **`variable_manager.ex`** - Variable creation and management
- **`lib/dantzig/core/polynomial.ex`** - Polynomial representation
- **`lib/dantzig/core/constraint.ex`** - Constraint representation
- **`lib/dantzig/core/problem/ast.ex`** - AST transformation utilities

**Key Concepts:**
- **Model Parameters**: Runtime data passed to `Problem.define(model_parameters: %{...})` for constant access in DSL expressions
- **Bindings**: Runtime bindings from generator variables (`i <- 1..n`) available during expression evaluation
- **Evaluation Environment**: Stored in process dictionary (`:dantzig_eval_env`) for runtime lookups

### Examples (`examples/`)

**Reference Examples:**
- **`examples/tutorial_examples.exs`** - Comprehensive tutorial examples (✅ working)
- **`examples/knapsack_problem.exs`** - Knapsack problem (✅ working)
- **`examples/diet_problem.exs`** - Diet problem with nested map access (⚠️ solver export pending for `:infinity`)
- **`examples/transportation_problem.exs`** - Transportation problem
- **`examples/production_planning.exs`** - Production planning
- **`examples/assignment_problem.exs`** - Assignment problem
- **`examples/school_timetabling.exs`** - Complex timetabling (may have issues)
- **`examples/blending_problem.exs`** - Blending optimization
- **`examples/network_flow.exs`** - Network flow (tuple destructuring issues)

**Status:** Check `EXAMPLE_TEST_REPORT.md` for current compliance and working status.

### Tests (`test/`)

**Test Organization:**
- **`test/dantzig/dsl/`** - DSL tests
  - **`constant_access_test.exs`** - Tests for constant access from model_parameters
  - **`nested_access_bindings_test.exs`** - Tests for nested map access with bindings
  - **`problem_modify_test.exs`** - Tests for `Problem.modify` macro
- **`test/dantzig/core/`** - Core functionality tests

## 🔑 Current Work Context (001-robustify)

**Active Branch:** `001-robustify`

**Primary Goals:**
1. Fix compilation issues
2. Achieve comprehensive test coverage (80%+ overall, 85%+ core)
3. Enhance documentation with well-documented examples

**Recent Work:**
- ✅ Fixed constant access in DSL expressions (nested map access with bindings)
- ✅ Fixed `:infinity` handling in constraint bounds
- ✅ Updated examples to use new DSL syntax
- ⚠️ Pending: Solver export handling for `:infinity` bounds
- ⚠️ Pending: Some examples still need fixes (network_flow.exs tuple destructuring, school_timetabling.exs)

**Key Technical Context:**
- **Constant Access**: Model parameters are accessible in DSL expressions via `try_evaluate_constant/2` and `evaluate_expression_with_bindings/2`
- **Binding Propagation**: Generator variables (`i <- 1..n`) create bindings available during expression evaluation
- **`:infinity` Bounds**: Special handling in `Constraint.new_linear/4` to pass `:infinity` directly without converting to Polynomial
- **String/Atom Key Conversion**: Map access (`map[key]`) automatically converts string keys to atom keys when needed

## ⚠️ Important Patterns & Conventions

### DSL Syntax

**Current API (Preferred):**
```elixir
Problem.define model_parameters: %{data: data} do
  new(name: "Problem", direction: :minimize)
  variables("x", [i <- 1..n], :continuous, min: 0)
  constraints([i <- 1..n], sum(x(i)) <= limit[i], "Constraint")
  objective(sum(x(:_)), direction: :minimize)
end
```

**Deprecated API (Avoid):**
```elixir
problem = Problem.new()
# Old imperative syntax - do not use
```

### Expression Evaluation

**Constant Access Pattern:**
- Constants from `model_parameters` are evaluated via `try_evaluate_constant/2`
- Generator bindings are propagated via `evaluate_expression_with_bindings/2`
- String literals are handled explicitly in `evaluate_expression_with_bindings/2`

**Nested Map Access:**
- `map[key1][key2]` is parsed as nested `Access.get` AST nodes
- String keys are automatically converted to atom keys when accessing maps
- Generator variables from `for` comprehensions create bindings accessible during evaluation

### Constraint Bounds

**`:infinity` Handling:**
- `:infinity` cannot be converted to `Polynomial.const/1`
- `Constraint.new_linear/4` handles `right_hand_side: :infinity` directly
- Solver export for `:infinity` bounds is pending (LP format issue)

### Testing Patterns

**TDD Approach:**
- Tests should use public DSL API (`Problem.define`) rather than internal functions
- Tests should assert against problem structure (constraints, objectives) rather than internal parsing
- Public test helpers are available: `enumerate_for_bindings/2`, `try_evaluate_constant/2`

## 🚨 Common Pitfalls

1. **Tuple Destructuring in Generators**: Not currently supported (e.g., `[{from, to, _} <- arcs]`). Use explicit indices instead.

2. **String Interpolation in Descriptions**: Function-based descriptions (`fn var -> "..." end`) may not work in all contexts. Use string literals or interpolation-safe patterns.

3. **`:infinity` in Polynomials**: Never call `Polynomial.const(:infinity)` or `Polynomial.to_polynomial(:infinity)`. Handle `:infinity` at the constraint level.

4. **Binding Scope**: Generator variables (`i`, `j`, etc.) are only available within the DSL block where they're defined. They're not accessible outside.

5. **Map Key Types**: When accessing maps with string keys, the system automatically converts to atom keys. Use atoms (`:key`) or strings (`"key"`) consistently.

## 📖 Quick Reference

**Where to find...**

- **DSL syntax**: `docs/DSL_SYNTAX_REFERENCE.md`
- **Current tasks**: `specs/001-robustify/tasks.md`
- **Example status**: `EXAMPLE_TEST_REPORT.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **API contracts**: `specs/001-robustify/contracts/`
- **Getting started**: `docs/GETTING_STARTED.md`
- **Tutorial**: `docs/COMPREHENSIVE_TUTORIAL.md`

**When starting work...**

1. Read `specs/001-robustify/tasks.md` to understand current priorities
2. Check `EXAMPLE_TEST_REPORT.md` for example file status
3. Review relevant contracts in `specs/001-robustify/contracts/`
4. Consult `docs/DSL_SYNTAX_REFERENCE.md` for syntax questions
5. Look at working examples in `examples/tutorial_examples.exs` or `examples/knapsack_problem.exs`

## 🔧 Development Workflow

**Testing:**
```bash
mix test                          # Run all tests
mix test test/dantzig/dsl/        # Run DSL tests
mix run examples/[example].exs    # Test an example
mix test --cover                  # With coverage
```

**Documentation:**
```bash
mix docs                          # Generate documentation
```

**Current Branch:**
- Branch: `001-robustify`
- Focus: Robustification, test coverage, example compliance

## 📝 Notes for AI Assistants

**When helping with this project:**

1. **Always check DSL syntax** in `docs/DSL_SYNTAX_REFERENCE.md` before suggesting syntax
2. **Verify example status** in `EXAMPLE_TEST_REPORT.md` before modifying examples
3. **Follow task priorities** in `specs/001-robustify/tasks.md`
4. **Use public API** in tests and examples (avoid internal functions)
5. **Handle `:infinity` specially** - never convert to Polynomial
6. **Propagate bindings correctly** - generator variables must be available during expression evaluation
7. **Support string/atom keys** - map access should work with both

**Cursor-specific (`.cursor/`):**
- `.cursor/rules/specify-rules.mdc` - May contain Cursor-specific rules
- `.cursor/commands/` - Speckit workflow commands (specification tools)

**Specify-specific (`.specify/`):**
- `.specify/templates/` - Specification templates
- `.specify/memory/` - Project memory/constitution

These directories are primarily for tooling and may be less relevant for general AI assistance, but can be referenced if needed for specification workflows.

---

**Last Updated:** Based on work context as of recent example fixes and constant access implementation.
