# Debugging Guide

## Common Issues and Solutions

### Issue 1: Variable Not Found

**Symptom**: `ArgumentError: Variable 'x' not found`

**Where to Look:**
- Check variable creation in `variable_manager.ex`
- Verify variable name matches exactly
- Check if variable was created with correct generator ranges

**Solution:**
```elixir
# Verify variable exists
Problem.get_variable(problem, "x")

# Check variable map
problem.variables["x"]
```

### Issue 2: Constant Not Evaluated

**Symptom**: Expression contains unevaluated constant

**Where to Look:**
- `expression_parser.ex` - `try_evaluate_constant/2`
- Process dictionary `:dantzig_eval_env`
- Model parameters passed to `Problem.define`

**Solution:**
```elixir
# Check model parameters
model_params = Process.get(:dantzig_eval_env, %{})[:model_parameters]

# Verify constant access
try_evaluate_constant(ast, bindings)
```

### Issue 3: Binding Not Available

**Symptom**: Generator variable not accessible in expression

**Where to Look:**
- `variable_manager.ex` - binding creation
- `expression_parser.ex` - binding propagation
- Generator scope in DSL block

**Solution:**
```elixir
# Check bindings
bindings = Process.get(:dantzig_eval_env, %{})[:bindings]

# Verify generator variable is in bindings
Map.get(bindings, :i)
```

### Issue 4: AST Transformation Fails

**Symptom**: Error during AST transformation

**Where to Look:**
- `dsl_reducer.ex` - transformation pipeline
- `ast/transformer.ex` - specific transformation
- AST node structure

**Solution:**
```elixir
# Inspect AST
IO.inspect(ast, label: "AST")

# Check transformation
{problem, result} = transform_expression(ast, problem, bindings)
```

### Issue 5: Infinity Bounds

**Symptom**: Error with `:infinity` bounds

**Where to Look:**
- `constraint.ex` - `new_linear/4`
- Solver export in `highs.ex`

**Solution:**
```elixir
# Handle infinity specially
right_hand_side = case right do
  :infinity -> :infinity
  _ -> Polynomial.const(right)
end
```

## Debugging Strategies

### Strategy 1: Inspect Process Dictionary

```elixir
# Check evaluation environment
env = Process.get(:dantzig_eval_env)
IO.inspect(env, label: "Eval Environment")
```

### Strategy 2: Trace Expression Evaluation

```elixir
# Add logging to expression parser
def evaluate_expression_with_bindings(ast, model_params, bindings) do
  IO.inspect(ast, label: "Evaluating AST")
  IO.inspect(bindings, label: "Bindings")
  # ... evaluation
end
```

### Strategy 3: Dump Problem Structure

```elixir
# Inspect problem
IO.inspect(problem.variables, label: "Variables")
IO.inspect(problem.constraints, label: "Constraints")
IO.inspect(problem.objective, label: "Objective")
```

### Strategy 4: Check Solver Export

```elixir
# Export to file and inspect
Dantzig.dump_problem_to_file(problem, "debug.lp")
# Check debug.lp file
```

## Where to Look for Specific Issues

### Expression Evaluation Issues
- `lib/dantzig/problem/dsl/expression_parser.ex`
- Process dictionary `:dantzig_eval_env`
- Model parameters structure

### Variable Creation Issues
- `lib/dantzig/problem/dsl/variable_manager.ex`
- `Problem.variables` map
- Generator parsing

### Constraint Creation Issues
- `lib/dantzig/problem/dsl/constraint_manager.ex`
- `Problem.constraints` map
- Expression transformation

### AST Transformation Issues
- `lib/dantzig/core/problem/dsl_reducer.ex`
- `lib/dantzig/ast/transformer.ex`
- AST node definitions

### Solver Issues
- `lib/dantzig/solver/highs.ex`
- LP/QP export format
- Solution parsing

## Related Documentation

- [Key Concepts](key-concepts.md) - Core concepts
- [Module Map](module-map.md) - Module responsibilities
- [Common Patterns](common-patterns.md) - Code patterns
