# File Refactoring Plan

**Goal**: Reduce file sizes to ~500 lines to improve focus and reduce token usage

## Files to Refactor

### 1. `docs/DSL_SYNTAX_REFERENCE.md` (1531 lines → 3 files)

**Current Structure:**
- Lines 1-623: Core DSL Syntax (Quick Start, Variables, Constraints, Objectives)
- Lines 624-693: Complete Working Examples
- Lines 694-933: Function Signatures, Key Syntax Rules
- Lines 934-1261: Implementation Requirements, Error Cases
- Lines 1262-1531: Error Handling, Testing, Troubleshooting, Performance, Version History

**Proposed Split:**

1. **`docs/DSL_SYNTAX_REFERENCE.md`** (~700 lines)
   - Source of Truth
   - Quick Start
   - Core DSL Syntax (Variables, Constraints, Objectives)
   - Function Signatures
   - Key Syntax Rules

2. **`docs/DSL_SYNTAX_EXAMPLES.md`** (~300 lines)
   - Complete Working Examples
   - All code examples and golden references

3. **`docs/DSL_SYNTAX_ADVANCED.md`** (~500 lines)
   - Implementation Requirements
   - Error Cases
   - Error Handling
   - Testing Requirements
   - Troubleshooting
   - Performance Considerations
   - Version History

**Benefits:**
- Main reference stays focused on syntax
- Examples separated for easier navigation
- Advanced topics in dedicated file

---

### 2. `lib/dantzig/problem/dsl/expression_parser.ex` (1153 lines → 3 modules)

**Current Structure:**
- Lines 1-540: Main expression parsing (`parse_expression_to_polynomial`)
- Lines 541-810: Normalization and evaluation helpers
- Lines 811-1009: Sum expression processing
- Lines 1010-1153: Wildcard expansion (newly added)

**Proposed Split:**

1. **`lib/dantzig/problem/dsl/expression_parser.ex`** (~600 lines)
   - Main `parse_expression_to_polynomial/3`
   - Expression normalization
   - Basic arithmetic parsing
   - Delegates to sub-modules

2. **`lib/dantzig/problem/dsl/expression_parser/wildcard_expansion.ex`** (~150 lines)
   - `contains_wildcard?/1`
   - `expand_wildcard_sum/3`
   - `resolve_wildcard_domain/3`
   - `collect_var_domains_for_wildcard/2`
   - `collect_access_domains_for_wildcard/3`
   - `replace_wildcards/2`

3. **`lib/dantzig/problem/dsl/expression_parser/sum_processing.ex`** (~200 lines)
   - `parse_sum_expression/3`
   - `enumerate_for_bindings/2`
   - For-comprehension handling
   - Variable wildcard expansion

4. **`lib/dantzig/problem/dsl/expression_parser/constant_evaluation.ex`** (~200 lines)
   - `try_evaluate_constant/2`
   - `evaluate_expression_with_bindings/2`
   - `eval_with_env/1`
   - `safe_to_atom/1`
   - Nested map access evaluation

**Benefits:**
- Clear separation of concerns
- Wildcard logic isolated (recent addition)
- Easier to test individual components
- Better code organization

---

### 3. `specs/002-extended-examples/tasks.md` (891 lines → 2 files)

**Current Structure:**
- Multiple phases with completed and pending tasks
- Lots of historical/completed task details

**Proposed Split:**

1. **`specs/002-extended-examples/tasks.md`** (~400 lines)
   - Active/in-progress tasks only
   - Current phase focus
   - Quick reference

2. **`specs/002-extended-examples/tasks_archive.md`** (~500 lines)
   - Completed tasks (marked as ✅)
   - Historical context
   - Detailed implementation notes

**Benefits:**
- Focus on active work
- Archive preserves history
- Easier to navigate current tasks

---

## Implementation Order

1. **Phase 1: Documentation Split** (Lowest risk)
   - Split DSL_SYNTAX_REFERENCE.md
   - Update cross-references
   - Test documentation links

2. **Phase 2: Code Module Split** (Medium risk)
   - Extract wildcard_expansion module
   - Extract sum_processing module
   - Extract constant_evaluation module
   - Update imports and tests

3. **Phase 3: Tasks Split** (Low risk)
   - Archive completed tasks
   - Keep active tasks in main file

---

## Verification Steps

After each split:
- [ ] All tests pass
- [ ] No broken imports/references
- [ ] Documentation links updated
- [ ] File sizes < 600 lines
- [ ] Git commit with clear message

---

## Estimated Impact

**Before:**
- DSL_SYNTAX_REFERENCE.md: 1531 lines
- expression_parser.ex: 1153 lines
- tasks.md: 891 lines
- **Total: 3575 lines in 3 files**

**After:**
- DSL_SYNTAX_REFERENCE.md: ~700 lines
- DSL_SYNTAX_EXAMPLES.md: ~300 lines
- DSL_SYNTAX_ADVANCED.md: ~500 lines
- expression_parser.ex: ~600 lines
- expression_parser/wildcard_expansion.ex: ~150 lines
- expression_parser/sum_processing.ex: ~200 lines
- expression_parser/constant_evaluation.ex: ~200 lines
- tasks.md: ~400 lines
- tasks_archive.md: ~500 lines
- **Total: ~3950 lines in 9 files (but better organized, max ~700 lines per file)**

**Token Usage Reduction:**
- Smaller files = less context needed per operation
- Better focus = more efficient AI assistance
- Clearer structure = easier navigation
