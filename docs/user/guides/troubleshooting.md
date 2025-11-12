# Troubleshooting

Common issues and solutions when using Dantzig.

## Variable Not Found

**Error**: `ArgumentError: Variable 'x' not found`

**Causes:**
- Variable not created before use
- Variable name mismatch (case-sensitive)
- Generator variable not in scope

**Solutions:**
```elixir
# ✅ Correct: Create variable first
problem = Problem.define do
  variables("x", :continuous)
  constraints(x <= 10, "Bound")
end

# ❌ Wrong: Using variable before creation
problem = Problem.define do
  constraints(x <= 10, "Bound")  # x not defined yet
  variables("x", :continuous)
end
```

## Constant Not Evaluated

**Error**: Expression contains unevaluated constant

**Causes:**
- Model parameter not passed
- Parameter name mismatch
- Nested map access issue

**Solutions:**
```elixir
# ✅ Correct: Pass model parameters
problem = Problem.define(model_parameters: %{limit: 100}) do
  constraints(x <= limit, "Bound")
end

# ❌ Wrong: Missing model parameters
problem = Problem.define do
  constraints(x <= limit, "Bound")  # limit not defined
end
```

## Generator Variable Not Available

**Error**: Generator variable not accessible in expression

**Causes:**
- Generator variable used outside its scope
- Generator syntax error

**Solutions:**
```elixir
# ✅ Correct: Generator variable in scope
constraints([i <- 1..n], x(i) <= limit[i], "Bound #{i}")

# ❌ Wrong: Generator variable outside scope
variables("x", [i <- 1..n], :continuous)
constraints(x(i) <= limit[i], "Bound")  # i not in scope
```

## Infinity Bounds

**Error**: Issues with `:infinity` bounds

**Causes:**
- Trying to convert `:infinity` to polynomial
- Solver export issue

**Solutions:**
```elixir
# ✅ Correct: Use :infinity directly
variables("x", :continuous, min_bound: 0, max_bound: :infinity)

# ✅ Correct: In constraints
constraints(x <= :infinity, "Unbounded")
```

## Expression Evaluation Issues

**Error**: Expression evaluation fails

**Causes:**
- Complex expression not supported
- Binding propagation issue

**Solutions:**
- Simplify expressions
- Check binding scope
- Verify model parameters structure

## Solver Errors

**Error**: Solver returns error

**Causes:**
- Infeasible problem
- Unbounded objective
- Solver binary not found

**Solutions:**
```elixir
# Check solution status
case Dantzig.solve(problem) do
  {:ok, solution} ->
    IO.puts("Status: #{solution.status}")

  {:error, :infeasible} ->
    IO.puts("Problem has no feasible solution")

  {:error, :unbounded} ->
    IO.puts("Objective is unbounded")

  {:error, reason} ->
    IO.puts("Solver error: #{reason}")
end
```

## Debugging Tips

### Dump Problem to File

```elixir
Dantzig.dump_problem_to_file(problem, "debug.lp")
# Inspect debug.lp file
```

### Inspect Problem Structure

```elixir
IO.inspect(problem.variables, label: "Variables")
IO.inspect(problem.constraints, label: "Constraints")
IO.inspect(problem.objective, label: "Objective")
```

### Check Evaluation Environment

```elixir
# In expression parser (for debugging)
env = Process.get(:dantzig_eval_env)
IO.inspect(env, label: "Eval Environment")
```

## Related Documentation

- [DSL Syntax Reference](reference/dsl-syntax.md) - Complete syntax guide
- [Modeling Patterns](modeling-patterns.md) - Best practices
- [Quick Start](quickstart.md) - Getting started
