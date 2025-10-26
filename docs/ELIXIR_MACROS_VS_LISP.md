# Elixir Macro System Study Plan

## **Elixir Macro System Study Plan**

### **Phase 1: Understanding Elixir Macro Constraints (2-3 days)**

#### **1.1 Elixir vs Lisp Macro Differences**

- **Variable Hygiene**: Elixir macros are hygienic by default, unlike Lisp where you control hygiene manually
- **Compile-time vs Runtime**: Elixir macros operate at compile-time with limited runtime access
- **AST Immutability**: Elixir ASTs are immutable, requiring careful `quote`/`unquote` patterns
- **Environment Binding**: Elixir's `binding()` is more limited than Lisp's environment manipulation

#### **1.2 Key Elixir Macro Limitations**

- **No `gensym` equivalent**: Elixir doesn't have Lisp's `gensym` for unique variable generation
- **Limited environment access**: Can't freely manipulate variable environments like in Lisp
- **Quote hygiene**: Variables in `quote` blocks are hygienic by default
- **AST traversal constraints**: `Macro.prewalk`/`postwalk` have limitations with complex transformations

### **Phase 2: Experimental Implementation Approaches (3-4 days)**

#### **2.1 Approach A: Pure Macro Transformation**

```elixir
# Test if we can transform raw syntax at compile-time
defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
  # Transform [i <- 1..4] into proper AST without evaluation
  transformed = Macro.prewalk(generators, fn
    {:<-, meta, [var, range]} ->
      # Keep as AST node, don't evaluate var
      {:<-, meta, [var, range]}
    other -> other
  end)

  quote do
    # Delegate to runtime function with transformed AST
    Dantzig.Problem.DSL.__add_variables__(
      unquote(problem),
      unquote(transformed),
      unquote(var_name),
      unquote(var_type),
      unquote(description)
    )
  end
end
```

#### **2.2 Approach B: Runtime Environment Binding**

```elixir
# Use Process dictionary to store environment
defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
  quote do
    # Store current binding in process dictionary
    Process.put(:dantzig_env, binding())

    try do
      Dantzig.Problem.DSL.__add_variables__(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(var_type),
        unquote(description)
      )
    after
      Process.delete(:dantzig_env)
    end
  end
end
```

#### **2.3 Approach C: AST Rewriting with `Macro.expand`**

```elixir
# Use Macro.expand to fully expand the AST
defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
  expanded_generators = Macro.expand(generators, __ENV__)

  quote do
    Dantzig.Problem.DSL.__add_variables__(
      unquote(problem),
      unquote(expanded_generators),
      unquote(var_name),
      unquote(var_type),
      unquote(description)
    )
  end
end
```

#### **2.4 Approach D: Hybrid Macro + Runtime**

```elixir
# Combine macro transformation with runtime processing
defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
  # Pre-process generators to extract variable names
  var_names = extract_variable_names(generators)

  quote do
    # Create a closure that captures the environment
    env = binding()

    Dantzig.Problem.DSL.__add_variables_with_env__(
      unquote(problem),
      unquote(generators),
      unquote(var_name),
      unquote(var_type),
      unquote(description),
      env,
      unquote(var_names)
    )
  end
end
```

### **Phase 3: Testing and Validation (2-3 days)**

#### **3.1 Create Test Harness**

```elixir
# Create comprehensive test for each approach
defmodule MacroApproachTest do
  use ExUnit.Case

  test "approach A: pure macro transformation" do
    # Test with simple generators
    # Test with complex generators
    # Test with nested expressions
  end

  test "approach B: runtime environment binding" do
    # Test environment capture
    # Test variable resolution
    # Test cleanup
  end

  # ... more tests
end
```

#### **3.2 Performance Benchmarking**

```elixir
# Benchmark each approach
defmodule MacroBenchmark do
  def benchmark_approaches do
    # Test compilation time
    # Test runtime performance
    # Test memory usage
  end
end
```

### **Phase 4: DSL Syntax Reference Redesign (2-3 days)**

#### **4.1 Analyze Current Syntax Reference**

- Review `docs/DSL_SYNTAX_REFERENCE.md`
- Identify which syntax patterns are problematic
- Document which patterns work vs. don't work

#### **4.2 Design New Syntax Reference**

```markdown
# NEW DSL SYNTAX REFERENCE

## Working Patterns (Elixir-compatible)

### 1. Declarative API (Problem.define)
```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
  objective(sum(queen2d(:_, :_)), direction: :maximize)
end
```

### 2. Imperative API (Working patterns only)

```elixir
# Pattern 1: Pre-defined variables
problem = Problem.new()
problem = Problem.add_variables(problem, "queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
problem = Problem.add_constraints(problem, [i <- 1..4], queen2d(i, :_) == 1, "One queen per row")

# Pattern 2: Runtime variable binding
problem = Problem.new()
problem = Problem.add_variables(problem, "queen2d", quote(do: [i <- 1..4, j <- 1..4]), :binary, "Queen position")
```

## Non-Working Patterns (Elixir limitations)

### Raw Generator Syntax in Imperative API

```elixir
# This doesn't work due to Elixir macro limitations
problem = Problem.add_variables(problem, "queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
# Error: undefined variable "i"
```

## Recommended Patterns

### 1. Use Declarative API for Complex Cases

```elixir
problem = Problem.define do
  variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
  constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
  objective(sum(queen2d(:_, :_)), direction: :maximize)
end
```

### 2. Use Imperative API for Simple Cases

```elixir
problem = Problem.new()
problem = Problem.add_variable(problem, "x", :binary, "Simple variable")
problem = Problem.add_constraint(problem, x == 1, "Simple constraint")
```

### 3. Hybrid Approach for Complex Imperative Cases

```elixir
# Use quote blocks for complex syntax
problem = Problem.new()
problem = Problem.add_variables(problem, "queen2d", quote(do: [i <- 1..4, j <- 1..4]), :binary, "Queen position")
```

## Implementation Notes

### Why Some Patterns Don't Work

1. **Variable Hygiene**: Elixir macros can't freely introduce variables into caller scope
2. **Compile-time vs Runtime**: Generator variables need to be available at compile-time
3. **AST Immutability**: Can't modify AST nodes after creation

### Workarounds

1. **Use `quote` blocks**: Wrap complex syntax in `quote do ... end`
2. **Pre-define variables**: Define variables before using in generators
3. **Use declarative API**: For complex cases, use `Problem.define` blocks

### **Phase 5: Implementation and Documentation (2-3 days)**

#### **5.1 Implement Working Solutions**

- Choose the best approach from testing
- Implement the solution
- Update the codebase
- Fix the integration test

#### **5.2 Update Documentation**

- Create new DSL syntax reference
- Update tutorial with working patterns
- Document limitations and workarounds
- Create migration guide

## **Additional Suggestions**

### **1. Consider Alternative Architectures**

- **Protocol-based approach**: Use Elixir protocols for extensibility
- **Behaviour-based approach**: Define behaviours for different syntax patterns
- **Compile-time code generation**: Generate functions at compile-time

### **2. Explore Elixir-Specific Solutions**

- **`use` macros**: Leverage `use` for module injection
- **`import` with `only`**: Control what gets imported
- **`require` patterns**: Use `require` for compile-time dependencies

### **3. Consider External Tools**

- **Code generation tools**: Use tools like `mix gen` for code generation
- **AST manipulation libraries**: Explore libraries for AST manipulation
- **Compile-time plugins**: Use Elixir's plugin system

### **4. Long-term Architectural Changes**

- **Separate syntax from semantics**: Decouple syntax from implementation
- **Plugin architecture**: Allow users to define custom syntax
- **Multiple DSL variants**: Support different syntax styles

## **Key Research Findings**

### **Elixir Macro System Limitations**

Based on web research, here are the key constraints of Elixir's macro system compared to Lisp:

#### **1. Variable Hygiene**

- Elixir macros are hygienic by default, preventing accidental variable capture
- Unlike Lisp, you can't freely introduce variables into the caller's scope
- Variables in `quote` blocks are automatically hygienic

#### **2. Compile-time vs Runtime**

- Elixir macros operate at compile-time with limited runtime access
- Can't freely manipulate variable environments like in Lisp
- `binding()` provides limited access to the calling environment

#### **3. AST Immutability**

- Elixir ASTs are immutable, requiring careful `quote`/`unquote` patterns
- Can't modify AST nodes after creation
- Need to use `Macro.prewalk`/`postwalk` for transformations

#### **4. No `gensym` Equivalent**

- Elixir doesn't have Lisp's `gensym` for unique variable generation
- Limited ability to create unique variable names
- Need to work within Elixir's naming constraints

#### **5. Environment Binding Limitations**

- `binding()` is more limited than Lisp's environment manipulation
- Can't freely access or modify variable bindings
- Process dictionary can be used as a workaround but is not ideal

### **Practical Solutions**

#### **1. Use `Macro.prewalk` for AST Transformation**

```elixir
# Transform AST without evaluating variables
transformed = Macro.prewalk(generators, fn
  {:<-, meta, [var, range]} ->
    # Keep as AST node, don't evaluate var
    {:<-, meta, [var, range]}
  other -> other
end)
```

#### **2. Use `Macro.expand` for Full Expansion**

```elixir
# Fully expand macros in AST
expanded = Macro.expand(generators, __ENV__)
```

#### **3. Use Process Dictionary for Environment**

```elixir
# Store environment in process dictionary
Process.put(:dantzig_env, binding())
```

#### **4. Use `quote` Blocks for Complex Syntax**

```elixir
# Wrap complex syntax in quote blocks
problem = Problem.add_variables(problem, "queen2d", quote(do: [i <- 1..4, j <- 1..4]), :binary, "Queen position")
```

## **Conclusion**

This study plan should help you understand Elixir's macro limitations and find practical solutions. The key insight is that Elixir macros are more constrained than Lisp macros, so we need to work within those constraints rather than trying to replicate Lisp-style flexibility.

The recommended approach is to:

1. **Use declarative API** (`Problem.define`) for complex cases
2. **Use imperative API** for simple cases
3. **Use `quote` blocks** for complex syntax in imperative API
4. **Consider alternative architectures** for long-term solutions

This approach respects Elixir's macro system constraints while providing a practical solution for the DSL implementation.
