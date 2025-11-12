# Error Handling and Troubleshooting

**Part of**: [DSL Syntax Advanced Topics](../DSL_SYNTAX_ADVANCED.md) | **See Also**: [DSL Syntax Reference](../dsl-syntax.md), [Troubleshooting Guide](../../guides/troubleshooting.md)

## Error Cases

The following are NOT currently supported or should be clearly documented as limitations:

1. **Nested generators** beyond the documented patterns
2. **Complex expressions** in generator lists that cannot be evaluated at compile time
3. **Dynamic constraint names** that cannot be resolved at compile time

- `Problem.add_variable()` - no generators allowed
- `Problem.add_constraint()` - no generators allowed
- `Problem.set_objective()` - no generators allowed

Those limitations are due to the semantics of Elixir macros: it is not possible to provide generators as arguments to macros. `Problem.add_variables(problem, [i <- 1..4], "x", :binary, "Description")` cannot be implemented because it would require a macro to accept a list of generators as an argument.

## Common Errors

### Constraint Redefinition

If a constraint with the same name is added multiple times, an error is issued:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row") # Error: duplicate constraint
end
```

### Variable Range Mismatch

If constraint ranges don't match variable ranges, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: constraint range (1..5) doesn't match variable range (1..4)
  constraints([i <- 1..5], sum(queen2d(i, :_)) == 1, "One queen per row")
end
```

### Unknown Variables in Constraints

If a variable referenced in a constraint hasn't been declared, an error is raised:

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

  # ERROR: queen3d variable not declared
  constraints([i <- 1..4], sum(queen3d(i, :_)) == 1, "One queen per row")
end
```

## Common DSL Errors

### 1. "Undefined variable" errors

**Problem**: `error: undefined variable "i"`

**Cause**: Using generator variables outside of `Problem.define` or `Problem.modify` blocks.

**Solution**: Move the code inside a `Problem.define` or `Problem.modify` block, or use imperative syntax with actual variable names. Generators are not available outside of `Problem.define` or `Problem.modify` blocks.

```elixir
# ❌ Wrong - generator outside block
problem = Problem.add_constraint(problem, queen2d(i, :_) == 1, "Constraint")

# ✅ Correct - inside block
problem = Problem.define do
  constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "Constraint")
end

# ✅ Correct - imperative with actual names
problem = Problem.add_constraint(problem, queen2d_1_1 + queen2d_1_2 == 1, "Constraint")
```

### 2. "Function clause" errors

**Problem**: `** (FunctionClauseError) no function clause matching in Problem.new/1`

**Cause**: Passing wrong arguments to `Problem.new`.

**Solution**: Use keyword arguments.

```elixir
# ❌ Wrong
problem = Problem.new("My Problem")

# ✅ Correct
problem = Problem.define do
  new(name: "My Problem", description: "Description")
end
```

### 3. Constraint name interpolation issues

**Problem**: Constraint names not interpolating correctly (e.g., "One queen per main diagonal" instead of "One queen per diagonal 1").

**Cause**: Missing variable placeholders in constraint descriptions.

**Solution**: Include variable placeholders in descriptions.

```elixir
# ❌ Wrong - no placeholder
constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per diagonal")

# ✅ Correct - with placeholder
constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per diagonal #{i}")
```

## Debugging DSL Issues

### 1. Check variable names

Use `IO.inspect(problem.variables)` to see actual variable names generated.

### 2. Verify constraint generation

Use `IO.inspect(problem.constraints)` to see generated constraints.

### 3. Test with simple examples

Start with basic examples before adding complexity:

```elixir
# Start simple
problem = Problem.define do
  new(name: "Test", description: "Test")
  variables("x", :continuous, "Variable")
  constraints(x >= 0, "Non-negative")
end
```

## Migration from Old Syntax

### From imperative to declarative

**Old syntax**:

```elixir
problem = Problem.new(name: "Test")
problem = Problem.add_variables(problem, [i <- 1..3], "x", :continuous)
problem = Problem.add_constraints(problem, [i <- 1..3], x(i) >= 0, "Constraint")
```

**New syntax**:

```elixir
problem = Problem.define do
  new(name: "Test", description: "Test")
  variables("x", [i <- 1..3], :continuous, "Variable")
  constraints([i <- 1..3], x(i) >= 0, "Constraint")
end
```

## Related Documentation

- [DSL Syntax Reference](../dsl-syntax.md) - Complete syntax guide
- [Troubleshooting Guide](../../guides/troubleshooting.md) - Common issues and solutions
- [Best Practices](best-practices.md) - Best practices and patterns
