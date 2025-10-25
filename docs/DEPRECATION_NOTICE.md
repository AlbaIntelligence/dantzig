# Deprecation Notice

**⚠️ IMPORTANT: Old Syntax Deprecated ⚠️**

This document lists the deprecated syntax patterns that should no longer be used in new code.

## Deprecated Syntax Patterns

### 1. Old Imperative Syntax

**❌ DEPRECATED:**
```elixir
# Old imperative approach
problem = Problem.new(direction: :maximize)
{problem, x} = Problem.new_variable(problem, "x", min: 0)
{problem, y} = Problem.new_variable(problem, "y", min: 0)
problem = Problem.add_constraint(problem, Constraint.new_linear(x + 2*y, :<=, 14))
problem = Problem.maximize(problem, 3*x + 4*y)
```

**✅ USE INSTEAD:**
```elixir
# New DSL approach
problem = Problem.define do
  new(name: "Example", direction: :maximize)
  variables("x", :continuous, min: 0, description: "Variable x")
  variables("y", :continuous, min: 0, description: "Variable y")
  constraints(x + 2*y <= 14, "Resource constraint")
  objective(3*x + 4*y, direction: :maximize)
end
```

### 2. Old Constraint Macros

**❌ DEPRECATED:**
```elixir
# Old constraint creation
constraint = Dantzig.Constraint.new(x + y == 10, name: "balance")
constraint = Dantzig.Constraint.new_linear(2*x + 3*y <= 20, name: "capacity")
problem = Problem.add_constraint(problem, constraint)
```

**✅ USE INSTEAD:**
```elixir
# New DSL constraint syntax
problem = Problem.define do
  new(name: "Example")
  variables("x", :continuous)
  variables("y", :continuous)
  constraints(x + y == 10, "balance")
  constraints(2*x + 3*y <= 20, "capacity")
end
```

### 3. Old Variable Creation

**❌ DEPRECATED:**
```elixir
# Old variable creation
{problem, x} = Problem.new_variable(problem, "x", type: :binary, min: 0, max: 1)
problem = Problem.variables(problem, "x", quote(do: [i <- 1..4, j <- 1..4]), :binary)
```

**✅ USE INSTEAD:**
```elixir
# New DSL variable syntax
problem = Problem.define do
  new(name: "Example")
  variables("x", :binary, min: 0, max: 1, description: "Binary variable")
  variables("x", [i <- 1..4, j <- 1..4], :binary, "2D variables")
end
```

### 4. Old Objective Setting

**❌ DEPRECATED:**
```elixir
# Old objective setting
problem = Problem.maximize(problem, 3*x + 4*y)
problem = Problem.minimize(problem, obj)
```

**✅ USE INSTEAD:**
```elixir
# New DSL objective syntax
problem = Problem.define do
  new(name: "Example")
  variables("x", :continuous)
  variables("y", :continuous)
  objective(3*x + 4*y, direction: :maximize)
  # or
  objective(obj, direction: :minimize)
end
```

## Migration Guide

### Step 1: Replace Problem.new() with Problem.define do
```elixir
# Old
problem = Problem.new(direction: :maximize)

# New
problem = Problem.define do
  new(direction: :maximize)
end
```

### Step 2: Replace variable creation
```elixir
# Old
{problem, x} = Problem.new_variable(problem, "x", type: :binary)

# New
problem = Problem.define do
  variables("x", :binary, description: "Binary variable")
end
```

### Step 3: Replace constraint creation
```elixir
# Old
problem = Problem.add_constraint(problem, Constraint.new_linear(x + y <= 10))

# New
problem = Problem.define do
  variables("x", :continuous)
  variables("y", :continuous)
  constraints(x + y <= 10, "Constraint description")
end
```

### Step 4: Replace objective setting
```elixir
# Old
problem = Problem.maximize(problem, 3*x + 4*y)

# New
problem = Problem.define do
  variables("x", :continuous)
  variables("y", :continuous)
  objective(3*x + 4*y, direction: :maximize)
end
```

## Timeline

- **v0.2.0**: Old syntax marked as deprecated
- **v0.3.0**: Old syntax will show deprecation warnings
- **v1.0.0**: Old syntax will be removed

## Benefits of New Syntax

1. **Cleaner code**: Less boilerplate, more readable
2. **Better error messages**: DSL provides better error context
3. **Generator support**: Easy creation of multi-dimensional variables
4. **Pattern matching**: Natural syntax for constraints and objectives
5. **Type safety**: Better compile-time checking

## Support

If you need help migrating from old to new syntax, please:
1. Check the [DSL Syntax Reference](DSL_SYNTAX_REFERENCE.md)
2. Look at the updated examples in the `examples/` directory
3. Review the [Comprehensive Tutorial](COMPREHENSIVE_TUTORIAL.md)

---

**Remember: The DSL Syntax Reference is the single source of truth for correct syntax.**
