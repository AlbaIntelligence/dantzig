# Developer Documentation

Documentation for developers contributing to Dantzig.

## Architecture

System architecture and design:

- **[Overview](architecture/overview.md)** - High-level architecture
- **[DSL System](architecture/dsl-system.md)** - DSL implementation details
- **[AST Transformation](architecture/ast-transformation.md)** - AST transformation details
- **[Expression Evaluation](architecture/expression-evaluation.md)** - Expression evaluation system
- **[Solver Integration](architecture/solver-integration.md)** - Solver integration architecture

## Code Structure

Module organization and structure:

- **[Module Overview](code-structure/module-overview.md)** - Module organization and dependencies
- **[Core Modules](code-structure/core-modules.md)** - Core module details
- **[DSL Modules](code-structure/dsl-modules.md)** - DSL module details
- **[Solver Modules](code-structure/solver-modules.md)** - Solver module details

## Data Structures

Core data structure reference:

- **[Problem](data-structures/problem.md)** - Problem structure
- **[Polynomial](data-structures/polynomial.md)** - Polynomial representation
- **[Constraint](data-structures/constraint.md)** - Constraint representation
- **[Variable](data-structures/variable.md)** - Variable representation

## Extension Points

How to extend Dantzig:

- **[Adding Operations](extension-points/adding-operations.md)** - Guide for adding operations
- **[Adding Solvers](extension-points/adding-solvers.md)** - Guide for adding solvers
- **[Extending DSL](extension-points/extending-dsl.md)** - Guide for extending DSL
- **[Hooks and Callbacks](extension-points/hooks-and-callbacks.md)** - Available hooks

## Contributing

Contribution guidelines:

- **[Setup](contributing/setup.md)** - Development setup
- **[Testing](contributing/testing.md)** - Testing guidelines
- **[Style Guide](contributing/style-guide.md)** - Code style guidelines

## API Reference

The API reference is generated from code documentation using ExDoc. Run:

```bash
mix docs
```

This generates HTML documentation in `doc/` with complete API reference.

## Related Documentation

- [User Documentation](../user/README.md) - User-facing documentation
- [AI Assistant Documentation](../ai-assistant/README.md) - For AI assistants
