# Codebase Overview

## High-Level Structure

The Dantzig codebase is organized into several main directories:

```
lib/
├── dantzig/
│   ├── core/                    # Core data structures and operations
│   │   ├── problem.ex          # Problem definition and management
│   │   ├── polynomial.ex       # Polynomial representation and algebra
│   │   ├── constraint.ex       # Constraint representation
│   │   └── variable.ex         # Variable types and bounds
│   ├── problem/
│   │   └── dsl/                # DSL implementation
│   │       ├── expression_parser.ex    # Expression parsing and evaluation
│   │       ├── constraint_manager.ex    # Constraint parsing and creation
│   │       └── variable_manager.ex      # Variable creation and management
│   ├── solver/
│   │   └── highs.ex            # HiGHS solver integration
│   └── core/problem/
│       ├── ast.ex              # AST utilities
│       └── dsl_reducer.ex      # AST transformation pipeline
```

## Module Organization

### Core Modules (`lib/dantzig/core/`)

**Purpose**: Fundamental data structures and operations

- **`Problem`**: Main problem structure, holds variables, constraints, objective
- **`Polynomial`**: Sparse polynomial representation with algebraic operations
- **`Constraint`**: Constraint representation with normalization
- **`Variable`**: Variable type definitions and bounds

### DSL Modules (`lib/dantzig/problem/dsl/`)

**Purpose**: DSL implementation for pattern-based modeling

- **`expression_parser.ex`**: Parses and evaluates DSL expressions
  - Handles constant access from `model_parameters`
  - Manages binding propagation from generators
  - Evaluates expressions with runtime bindings

- **`constraint_manager.ex`**: Parses and creates constraints
  - Handles generator-based constraints
  - Manages constraint naming and metadata

- **`variable_manager.ex`**: Creates and manages variables
  - Parses generator syntax
  - Creates N-dimensional variable families
  - Manages variable naming

### AST Modules (`lib/dantzig/core/problem/`)

**Purpose**: AST transformation for automatic linearization

- **`ast.ex`**: AST node definitions and utilities
- **`dsl_reducer.ex`**: Main transformation pipeline
  - Converts Elixir AST to Dantzig AST
  - Transforms non-linear expressions to linear constraints
  - Adds auxiliary variables and constraints

### Solver Modules (`lib/dantzig/solver/`)

**Purpose**: Solver integration

- **`highs.ex`**: HiGHS solver integration
  - Serializes problems to LP/QP format
  - Executes solver binary
  - Parses solution output

## Key Data Structures

### Problem Structure

```elixir
%Dantzig.Problem{
  variable_counter: integer,
  constraint_counter: integer,
  objective: Polynomial.t(),
  direction: :maximize | :minimize,
  name: String.t() | nil,
  description: String.t() | nil,
  variable_defs: %{String.t() => ProblemVariable.t()},
  variables: %{String.t() => %{tuple() => Polynomial.t()}},
  constraints: %{String.t() => Constraint.t()},
  contraints_metadata: %{}
}
```

### Polynomial Structure

Sparse representation: `%{[variable_tuple] => coefficient}`

### Constraint Structure

```elixir
%Dantzig.Constraint{
  left_hand_side: Polynomial.t(),
  operator: :== | :<= | :>=,
  right_hand_side: number | :infinity
}
```

## Data Flow

1. **DSL Input**: User writes `Problem.define do ... end`
2. **Macro Expansion**: `Problem.define` macro processes the block
3. **Expression Parsing**: `expression_parser.ex` evaluates expressions
4. **Variable Creation**: `variable_manager.ex` creates variables
5. **Constraint Creation**: `constraint_manager.ex` creates constraints
6. **AST Transformation**: `dsl_reducer.ex` linearizes non-linear expressions
7. **Problem Building**: Variables, constraints, objective added to Problem struct
8. **Solver Export**: `highs.ex` serializes to LP/QP format
9. **Solution Parsing**: Solver output parsed back to Elixir structures

## Evaluation Environment

The DSL uses a process dictionary-based evaluation environment:

- **`:dantzig_eval_env`**: Stores model parameters and bindings
- **Model Parameters**: Passed via `Problem.define(model_parameters: %{...})`
- **Bindings**: Generator variables available during expression evaluation

## Related Documentation

- [Key Concepts](key-concepts.md) - Core concepts and patterns
- [Module Map](module-map.md) - Detailed module responsibilities
- [Extension Guide](extension-guide.md) - How to add features
