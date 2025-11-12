# Documentation Review: Uppercase Files in docs/

**Date**: 2025-11-12
**Purpose**: Review uppercase-named files in `docs/` directory for relevance and determine if they should be kept, moved, or deleted.

## Summary

Based on git history, there was a reorganization effort (commit 02cfe79) that moved files to `docs/user/`, `docs/developer/`, `docs/internal/`, but many uppercase files remain in the root `docs/` directory. This review assesses each file's current relevance and recommends actions.

---

## File-by-File Analysis

### ✅ KEEP & MOVE TO `docs/user/`

#### 1. `GETTING_STARTED.md`
- **Status**: ✅ **KEEP** - Core user documentation
- **Content**: Quick start guide for new users
- **Action**: Move to `docs/user/quickstart.md` (may already exist there, check for duplicates)
- **Priority**: High

#### 2. `COMPREHENSIVE_TUTORIAL.md`
- **Status**: ✅ **KEEP** - Core user documentation
- **Content**: Complete tutorial with examples
- **Action**: Move to `docs/user/tutorial/comprehensive.md` (may already exist)
- **Priority**: High

#### 3. `TUTORIAL.md`
- **Status**: ✅ **KEEP** - Core user documentation
- **Content**: Basic tutorial
- **Action**: Move to `docs/user/tutorial/basics.md` (may already exist)
- **Priority**: High
- **Note**: Check if this duplicates `COMPREHENSIVE_TUTORIAL.md`

#### 4. `DSL_SYNTAX_REFERENCE.md`
- **Status**: ✅ **KEEP** - GOLDEN REFERENCE (marked as "DO NOT MODIFY WITHOUT EXPLICIT APPROVAL")
- **Content**: Canonical DSL syntax reference
- **Action**: Move to `docs/user/reference/dsl-syntax.md` OR keep in root if it's truly the "golden reference"
- **Priority**: Critical
- **Note**: This is marked as the canonical reference - may need to stay prominent

#### 5. `MODELING_GUIDE.md`
- **Status**: ✅ **KEEP** - User guide
- **Content**: Best practices for optimization modeling (40 lines, brief)
- **Action**: Move to `docs/user/guides/modeling-patterns.md` (may already exist)
- **Priority**: Medium

#### 6. `DEPRECATION_NOTICE.md`
- **Status**: ✅ **KEEP** - Important user information
- **Content**: Deprecation notices for old API
- **Action**: Move to `docs/user/guides/DEPRECATION_NOTICE.md` (may already exist)
- **Priority**: High

#### 7. `PATTERN_BASED_OPERATIONS.md`
- **Status**: ✅ **KEEP** - User reference
- **Content**: Pattern-based operations documentation
- **Action**: Move to `docs/user/reference/pattern-operations.md` (may already exist)
- **Priority**: Medium

#### 8. `VARIADIC_OPERATIONS.md`
- **Status**: ✅ **KEEP** - User reference
- **Content**: Variadic operations documentation
- **Action**: Move to `docs/user/reference/variadic-operations.md` (may already exist)
- **Priority**: Medium

---

### ✅ KEEP & MOVE TO `docs/developer/`

#### 9. `ARCHITECTURE.md`
- **Status**: ✅ **KEEP** - Developer documentation
- **Content**: System architecture and design decisions
- **Action**: Move to `docs/developer/architecture/overview.md` (may already exist)
- **Priority**: High
- **Note**: Check if `docs/developer/architecture/` already has architecture docs

#### 10. `ADVANCED_AST.md`
- **Status**: ✅ **KEEP** - Developer documentation
- **Content**: Advanced AST & linearization (24 lines, brief overview)
- **Action**: Move to `docs/developer/architecture/advanced-ast.md`
- **Priority**: Medium
- **Note**: Very brief - may need expansion or merging with other AST docs

#### 11. `ELIXIR_MACROS_VS_LISP.md`
- **Status**: ✅ **KEEP** - Developer documentation
- **Content**: Comparison of Elixir macros vs LISP (369 lines)
- **Action**: Move to `docs/developer/architecture/ELIXIR_MACROS_VS_LISP.md` or `docs/internal/development-notes/`
- **Priority**: Low
- **Note**: May be more of an internal development note

#### 12. `STYLE_GUIDE.md`
- **Status**: ✅ **KEEP** - Developer documentation
- **Content**: Code style conventions (267 lines)
- **Action**: Move to `docs/developer/contributing/style-guide.md` (may already exist)
- **Priority**: Medium

---

### ⚠️ REVIEW & MOVE TO `docs/internal/` OR DELETE

#### 13. `ENHANCEMENT_PLAN.md`
- **Status**: ⚠️ **REVIEW** - Planning document from 2024-12-19
- **Content**: Documentation enhancement plan for 001-robustify feature
- **Action**: Move to `docs/internal/planning/ENHANCEMENT_PLAN.md` OR delete if superseded by actual implementation
- **Priority**: Low
- **Note**: This is a planning document - check if tasks are complete

#### 14. `SYNTAX_ISSUES.md`
- **Status**: ⚠️ **REVIEW** - Issue tracking document
- **Content**: Syntax issues found in example files (133 lines)
- **Action**: Move to `docs/internal/development-notes/SYNTAX_ISSUES.md` OR delete if issues are resolved
- **Priority**: Low
- **Note**: Check if issues are still relevant or have been fixed

#### 15. `EXAMPLE_TEST_REPORT.md`
- **Status**: ⚠️ **REVIEW** - Status report
- **Content**: Example files testing report (213 lines)
- **Action**: Move to `docs/internal/reports/example-reports/EXAMPLE_TEST_REPORT.md` OR archive/delete if outdated
- **Priority**: Low
- **Note**: This is a status report - may be outdated

#### 16. `TEST_SUMMARY.md`
- **Status**: ⚠️ **REVIEW** - Status report from 2025-10-30
- **Content**: Test summary for model parameters implementation (103 lines)
- **Action**: Move to `docs/internal/reports/test-reports/TEST_SUMMARY.md` OR archive/delete if outdated
- **Priority**: Low
- **Note**: This is a historical test summary - may be outdated

#### 17. `001-ROBUSTIFY-SUMMARY.md`
- **Status**: ⚠️ **REVIEW** - Feature summary from 2025-11-06
- **Content**: Implementation summary for 001-robustify feature (219 lines)
- **Action**: Move to `docs/internal/reports/phase-reports/001-ROBUSTIFY-SUMMARY.md` OR keep if it's still relevant
- **Priority**: Low
- **Note**: Recent summary - may be worth keeping for historical reference

---

## Recommended Actions

### Immediate Actions (High Priority)

1. **Check for duplicates**: Verify if files already exist in `docs/user/`, `docs/developer/`, `docs/internal/` directories
2. **Move core user docs**: `GETTING_STARTED.md`, `COMPREHENSIVE_TUTORIAL.md`, `TUTORIAL.md`, `DSL_SYNTAX_REFERENCE.md`
3. **Move developer docs**: `ARCHITECTURE.md`, `STYLE_GUIDE.md`

### Secondary Actions (Medium Priority)

4. **Move user reference docs**: `MODELING_GUIDE.md`, `PATTERN_BASED_OPERATIONS.md`, `VARIADIC_OPERATIONS.md`, `DEPRECATION_NOTICE.md`
5. **Move developer architecture docs**: `ADVANCED_AST.md`, `ELIXIR_MACROS_VS_LISP.md`

### Cleanup Actions (Low Priority)

6. **Review and archive**: `ENHANCEMENT_PLAN.md`, `SYNTAX_ISSUES.md`, `EXAMPLE_TEST_REPORT.md`, `TEST_SUMMARY.md`, `001-ROBUSTIFY-SUMMARY.md`
   - Check if content is still relevant
   - Move to `docs/internal/` if historical value
   - Delete if completely outdated

---

## Duplicate Detection

Before moving files, check if they already exist in the new structure:

```bash
# Check for existing files in new structure
ls -la docs/user/quickstart.md
ls -la docs/user/tutorial/
ls -la docs/user/reference/
ls -la docs/developer/architecture/
ls -la docs/internal/
```

---

## File Organization Target Structure

```
docs/
├── user/
│   ├── quickstart.md (from GETTING_STARTED.md)
│   ├── tutorial/
│   │   ├── basics.md (from TUTORIAL.md)
│   │   └── comprehensive.md (from COMPREHENSIVE_TUTORIAL.md)
│   ├── reference/
│   │   ├── dsl-syntax.md (from DSL_SYNTAX_REFERENCE.md)
│   │   ├── pattern-operations.md (from PATTERN_BASED_OPERATIONS.md)
│   │   └── variadic-operations.md (from VARIADIC_OPERATIONS.md)
│   └── guides/
│       ├── modeling-patterns.md (from MODELING_GUIDE.md)
│       └── DEPRECATION_NOTICE.md (from DEPRECATION_NOTICE.md)
├── developer/
│   ├── architecture/
│   │   ├── overview.md (from ARCHITECTURE.md)
│   │   └── advanced-ast.md (from ADVANCED_AST.md)
│   └── contributing/
│       └── style-guide.md (from STYLE_GUIDE.md)
└── internal/
    ├── planning/
    │   └── ENHANCEMENT_PLAN.md (from ENHANCEMENT_PLAN.md)
    ├── development-notes/
    │   └── SYNTAX_ISSUES.md (from SYNTAX_ISSUES.md)
    └── reports/
        ├── example-reports/
        │   └── EXAMPLE_TEST_REPORT.md (from EXAMPLE_TEST_REPORT.md)
        ├── test-reports/
        │   └── TEST_SUMMARY.md (from TEST_SUMMARY.md)
        └── phase-reports/
            └── 001-ROBUSTIFY-SUMMARY.md (from 001-ROBUSTIFY-SUMMARY.md)
```

---

## Special Considerations

### `DSL_SYNTAX_REFERENCE.md`
- **Marked as "GOLDEN REFERENCE - DO NOT MODIFY WITHOUT EXPLICIT APPROVAL"**
- This is the canonical syntax reference
- Consider keeping in root `docs/` OR making it very prominent in `docs/user/reference/`
- May need to update internal links if moved

### Planning/Status Documents
- These are historical records
- Consider archiving rather than deleting
- May be useful for understanding project history
- Check if they're referenced elsewhere before deleting

---

## Next Steps

1. **Run duplicate check**: Verify which files already exist in new structure
2. **Create missing directories**: Ensure target directories exist
3. **Move files systematically**: Start with high-priority user docs
4. **Update links**: Search codebase for references to old paths
5. **Archive old files**: Move to `docs/internal/` rather than deleting
6. **Update README**: Update any documentation index/README files
