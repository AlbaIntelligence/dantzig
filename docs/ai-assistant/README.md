# AI Assistant Documentation

This directory contains documentation specifically designed to help AI assistants understand the Dantzig codebase, architecture, and development patterns.

## Overview

These documents provide AI assistants with:

- **Codebase structure** - How the project is organized
- **Key concepts** - Core ideas and patterns used throughout
- **Module responsibilities** - What each module does and where to find functionality
- **Extension points** - Where and how to add new features
- **Common patterns** - Code idioms and conventions
- **Debugging strategies** - How to troubleshoot issues
- **Design decisions** - Rationale behind architectural choices

## Documentation Files

- **[Codebase Overview](codebase-overview.md)** - High-level codebase structure and organization
- **[Key Concepts](key-concepts.md)** - Core concepts (DSL system, AST transformation, expression evaluation, bindings)
- **[Module Map](module-map.md)** - Module responsibilities matrix, dependencies, where to find functionality
- **[Extension Guide](extension-guide.md)** - Step-by-step guide for adding features (operations, solvers, DSL extensions)
- **[Common Patterns](common-patterns.md)** - Code patterns, idioms, conventions
- **[Debugging Guide](debugging-guide.md)** - Common issues, debugging strategies, where to look
- **[Decision Logging](decision-logging.md)** - Important design decisions, rationale, trade-offs

## Quick Reference

### Where to Find...

- **DSL implementation**: `lib/dantzig/problem/dsl/` - Expression parser, constraint manager, variable manager
- **Core data structures**: `lib/dantzig/core/` - Problem, Polynomial, Constraint, Variable
- **AST transformation**: `lib/dantzig/core/problem/ast.ex`, `lib/dantzig/core/problem/dsl_reducer.ex`
- **Solver integration**: `lib/dantzig/solver/highs.ex`
- **Public API**: `lib/dantzig/core/problem.ex` - `Problem.define` and `Problem.modify` macros

### Key Concepts

- **DSL System**: Pattern-based modeling with generator syntax
- **AST Transformation**: Automatic linearization of non-linear expressions
- **Expression Evaluation**: Runtime evaluation with bindings and constants
- **Model Parameters**: Runtime data passed to `Problem.define(model_parameters: %{...})`
- **Bindings**: Generator variables available during expression evaluation

### Common Tasks

- **Adding a new operation**: See [Extension Guide](extension-guide.md)
- **Adding a new solver**: See [Extension Guide](extension-guide.md)
- **Extending DSL syntax**: See [Extension Guide](extension-guide.md)
- **Debugging expression evaluation**: See [Debugging Guide](debugging-guide.md)
- **Understanding AST transformation**: See [Key Concepts](key-concepts.md)

## Related Documentation

- [User Documentation](../user/README.md) - User-facing documentation
- [Developer Documentation](../developer/README.md) - Developer documentation
- [Architecture Overview](../developer/architecture/overview.md) - System architecture
