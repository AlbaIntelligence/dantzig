# Module Map

## Module Responsibilities Matrix

### Core Modules

| Module | Responsibility | Key Functions | Dependencies |
|--------|---------------|---------------|--------------|
| `Dantzig.Problem` | Problem definition and management | `define/2`, `modify/2`, `new_variable/3`, `add_constraint/2` | Polynomial, Constraint, Variable |
| `Dantzig.Polynomial` | Polynomial representation and algebra | `const/1`, `add/2`, `multiply/2`, `variables/1` | None |
| `Dantzig.Constraint` | Constraint representation | `new/3`, `new_linear/4`, `solve_for_variable/2` | Polynomial |
| `Dantzig.ProblemVariable` | Variable type and bounds | Type definitions | None |

### DSL Modules

| Module | Responsibility | Key Functions | Dependencies |
|--------|---------------|---------------|--------------|
| `Dantzig.Problem.DSL.ExpressionParser` | Expression parsing and evaluation | `try_evaluate_constant/2`, `evaluate_expression_with_bindings/2` | Problem |
| `Dantzig.Problem.DSL.ConstraintManager` | Constraint parsing and creation | `parse_constraint/3`, `create_constraint/4` | Constraint, ExpressionParser |
| `Dantzig.Problem.DSL.VariableManager` | Variable creation and management | `parse_generators/1`, `create_variables/5` | Problem |

### AST Modules

| Module | Responsibility | Key Functions | Dependencies |
|--------|---------------|---------------|--------------|
| `Dantzig.Problem.DSLReducer` | AST transformation pipeline | `reduce/2`, `transform_expression/3` | AST, Problem |
| `Dantzig.AST` | AST node definitions | Node structs | None |
| `Dantzig.AST.Parser` | Elixir AST → Dantzig AST | `parse/1` | AST |
| `Dantzig.AST.Transformer` | Non-linear → Linear | `transform/2` | AST, Problem |

### Solver Modules

| Module | Responsibility | Key Functions | Dependencies |
|--------|---------------|---------------|--------------|
| `Dantzig.Solver.HiGHS` | HiGHS solver integration | `solve/1`, `to_lp_iodata/1` | Problem, Solution.Parser |
| `Dantzig.Solution` | Solution representation | `evaluate/2` | Polynomial |
| `Dantzig.Solution.Parser` | Parse solver output | `parse/1` | Solution |

## Where to Find Functionality

### Variable Creation
- **DSL**: `lib/dantzig/core/problem.ex` - `Problem.define` macro
- **Implementation**: `lib/dantzig/problem/dsl/variable_manager.ex`
- **Storage**: `Problem.variables` map

### Constraint Creation
- **DSL**: `lib/dantzig/core/problem.ex` - `Problem.define` macro
- **Implementation**: `lib/dantzig/problem/dsl/constraint_manager.ex`
- **Storage**: `Problem.constraints` map

### Expression Evaluation
- **Parser**: `lib/dantzig/problem/dsl/expression_parser.ex`
- **Evaluation**: `try_evaluate_constant/2`, `evaluate_expression_with_bindings/2`
- **Environment**: Process dictionary `:dantzig_eval_env`

### AST Transformation
- **Pipeline**: `lib/dantzig/core/problem/dsl_reducer.ex`
- **Transformation**: `transform_expression/3`
- **Linearization**: Adds auxiliary variables and constraints

### Solver Integration
- **Export**: `lib/dantzig/solver/highs.ex` - `to_lp_iodata/1`
- **Execution**: `lib/dantzig/solver/highs.ex` - `solve/1`
- **Parsing**: `lib/dantzig/solution/parser.ex`

## Module Dependencies

```
Problem (macros)
  ├── VariableManager (variable creation)
  ├── ConstraintManager (constraint creation)
  ├── ExpressionParser (expression evaluation)
  └── DSLReducer (AST transformation)
        ├── AST.Parser (parse Elixir AST)
        └── AST.Transformer (linearize)
              └── Problem (add variables/constraints)

HiGHS (solver)
  ├── Problem (read problem structure)
  └── Solution.Parser (parse output)
```

## Extension Points

### Adding a New Operation
1. Add AST node in `lib/dantzig/ast.ex`
2. Extend parser in `lib/dantzig/ast/parser.ex`
3. Add transformation in `lib/dantzig/ast/transformer.ex`
4. Update `lib/dantzig/core/problem/dsl_reducer.ex` if needed

### Adding a New Solver
1. Create module in `lib/dantzig/solver/`
2. Implement `solve/1` and export function
3. Create solution parser if needed
4. Update `Dantzig.solve/1` to route to new solver

### Extending DSL Syntax
1. Add macro in `lib/dantzig/core/problem.ex`
2. Implement in appropriate DSL module
3. Update expression parser if needed
4. Add tests

## Related Documentation

- [Codebase Overview](codebase-overview.md) - Project structure
- [Key Concepts](key-concepts.md) - Core concepts
- [Extension Guide](extension-guide.md) - Step-by-step extension instructions
