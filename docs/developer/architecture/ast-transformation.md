# Advanced AST & Linearization

## Overview

The AST stack (`Parser`, `Analyzer`, `Transformer`) turns high-level expressions into linear models.

## Supported Transforms

- **abs(x)**: absolute value is converted into 3 constraints + 1 auxiliary variable (abs_x >= x, abs_x >= -x, abs_x >= 0)
- **max/min(args)**: bound constraints + auxiliary variable (variadic)
- **and/or(args)**: binary auxiliary variable with standard linearization
- **piecewise linear**: segment binaries + big-M bounds

## Pattern-based Arguments

Expressions like `max(x[_])` are parsed as a Sum over the pattern, then linearized.

## Extensibility

Add new nodes to `Dantzig.AST`, extend `Parser`, analyze with `Analyzer`, and linearize in `Transformer`.

## AST Node Types

The AST system supports various node types:

- `Variable` - Variable references
- `Sum` - Sum expressions with wildcards
- `Abs` - Absolute value operations
- `Max` - Maximum operations (variadic)
- `Min` - Minimum operations (variadic)
- `Constraint` - Constraint expressions
- `BinaryOp` - Binary operations (+, -, *, /)
- `PiecewiseLinear` - Piecewise linear functions
- `And` - Logical AND operations (variadic)
- `Or` - Logical OR operations (variadic)
- `IfThenElse` - Conditional expressions

## Transformation Process

1. **Parsing**: Elixir AST → Dantzig AST
2. **Analysis**: Validation and optimization opportunities
3. **Transformation**: Non-linear → Linear constraints
4. **Integration**: Add auxiliary variables and constraints to problem

## Linearization Rules

### Absolute Value

For `abs(x) = z`:

- Constraints: `z >= x`, `z >= -x`, `z >= 0`
- Variable: `z` is continuous

### Maximum

For `max(x₁, x₂, ..., xₙ) = z`:

- Constraints: `z >= xᵢ` for all `i = 1, 2, ..., n`
- Variable: `z` is continuous

### Minimum

For `min(x₁, x₂, ..., xₙ) = z`:

- Constraints: `z <= xᵢ` for all `i = 1, 2, ..., n`
- Variable: `z` is continuous

### Logical AND

For `x₁ AND x₂ AND ... AND xₙ = z` (where all `xᵢ` are binary):

- Constraints:
  - `z <= xᵢ` for all `i = 1, 2, ..., n`
  - `z >= ∑xᵢ - (n-1)`
- Variable: `z` is binary

### Logical OR

For `x₁ OR x₂ OR ... OR xₙ = z` (where all `xᵢ` are binary):

- Constraints:
  - `z >= xᵢ` for all `i = 1, 2, ..., n`
  - `z <= ∑xᵢ`
- Variable: `z` is binary

## Related Documentation

- [Architecture Overview](overview.md) - High-level architecture
- [DSL System](dsl-system.md) - DSL implementation
- [Expression Evaluation](expression-evaluation.md) - Expression evaluation system
- [Extension Points](../extension-points/extending-dsl.md) - How to extend the DSL
