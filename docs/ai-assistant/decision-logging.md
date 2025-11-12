# Decision Logging

Important design decisions, rationale, and trade-offs in the Dantzig codebase.

## Design Decisions

### Decision 1: Process Dictionary for Evaluation Environment

**Decision**: Use process dictionary (`:dantzig_eval_env`) to store model parameters and bindings during expression evaluation.

**Rationale**:
- Allows access to runtime data during macro expansion
- Avoids passing context through many function calls
- Matches Elixir macro evaluation patterns

**Trade-offs**:
- ✅ Simple access pattern
- ✅ Works with macro evaluation
- ❌ Process dictionary is process-local
- ❌ Must clean up after evaluation

**Location**: `lib/dantzig/problem/dsl/expression_parser.ex`

### Decision 2: Sparse Polynomial Representation

**Decision**: Represent polynomials as sparse maps: `%{[variable_tuple] => coefficient}`

**Rationale**:
- Efficient for large, sparse problems
- Easy to manipulate algebraically
- Natural representation for optimization problems

**Trade-offs**:
- ✅ Memory efficient for sparse problems
- ✅ Fast algebraic operations
- ❌ Less efficient for dense problems
- ❌ Requires custom serialization

**Location**: `lib/dantzig/core/polynomial.ex`

### Decision 3: AST-Based Linearization

**Decision**: Use AST transformation to automatically linearize non-linear expressions.

**Rationale**:
- Allows natural mathematical syntax
- Automatic handling of complex expressions
- Extensible for new operations

**Trade-offs**:
- ✅ Natural syntax for users
- ✅ Automatic optimization
- ❌ More complex implementation
- ❌ Potential performance overhead

**Location**: `lib/dantzig/core/problem/dsl_reducer.ex`, `lib/dantzig/ast/transformer.ex`

### Decision 4: Generator Syntax for N-dimensional Variables

**Decision**: Use generator syntax `[i <- 1..n]` for creating N-dimensional variables.

**Rationale**:
- Matches mathematical notation
- Concise for large variable sets
- Familiar to users of JuMP/other modeling languages

**Trade-offs**:
- ✅ Concise and readable
- ✅ Scales to large problems
- ❌ Requires macro expansion
- ❌ Limited to compile-time evaluation

**Location**: `lib/dantzig/core/problem.ex` (macros), `lib/dantzig/problem/dsl/variable_manager.ex`

### Decision 5: String/Atom Key Conversion for Map Access

**Decision**: Automatically convert string keys to atom keys when accessing maps in model parameters.

**Rationale**:
- Allows flexible key types in user data
- Reduces user errors
- Matches Elixir conventions

**Trade-offs**:
- ✅ User-friendly
- ✅ Flexible input
- ❌ Potential performance cost
- ❌ May hide key type issues

**Location**: `lib/dantzig/problem/dsl/expression_parser.ex`

### Decision 6: Infinity Handling in Constraints

**Decision**: Handle `:infinity` specially in constraints, not converting to Polynomial.

**Rationale**:
- `:infinity` cannot be represented as a polynomial coefficient
- Needed for unbounded variables
- Solver format requires special handling

**Trade-offs**:
- ✅ Supports unbounded variables
- ✅ Matches solver requirements
- ❌ Special case handling needed
- ❌ Solver export pending

**Location**: `lib/dantzig/core/constraint.ex`

### Decision 7: DSL as Primary API

**Decision**: Make DSL (`Problem.define`) the primary API, deprecate imperative API.

**Rationale**:
- More natural and concise
- Better error messages
- Supports advanced features (generators, AST)

**Trade-offs**:
- ✅ Better user experience
- ✅ More powerful
- ❌ Breaking change for existing code
- ❌ More complex implementation

**Location**: `lib/dantzig/core/problem.ex`

## Future Considerations

### Potential Changes

1. **Streaming for Large Models**: Stream LP export to avoid memory issues
2. **Matrix Representation**: Add matrix form for dense problems
3. **Parallel Constraint Generation**: Parallelize for large pattern-based models
4. **AST Optimization**: Optimize AST transformations for common patterns

### Open Questions

1. **Tuple Destructuring in Generators**: Currently not supported, may add in future
2. **Solver Export for Infinity**: Pending implementation
3. **Custom Linearization Rules**: May allow user-defined transformations

## Related Documentation

- [Architecture Overview](../developer/architecture/overview.md) - System architecture
- [Key Concepts](key-concepts.md) - Core concepts
- [Extension Guide](extension-guide.md) - Adding features
