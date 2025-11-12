# Common Patterns

## Code Patterns and Idioms

### Pattern 1: Generator Parsing

```elixir
def parse_generators(generators) do
  Enum.map(generators, fn
    {:<-, _, [var, domain]} -> {var, domain}
    _ -> raise ArgumentError, "Invalid generator syntax"
  end)
end
```

### Pattern 2: Binding Creation

```elixir
def create_bindings(parsed_generators, index_vals) do
  Enum.zip(parsed_generators, index_vals)
  |> Enum.into(%{}, fn {{var, _domain}, val} -> {var, val} end)
end
```

### Pattern 3: Variable Name Generation

```elixir
def create_var_name(var_name, index_vals) do
  suffix = index_vals
    |> Tuple.to_list()
    |> Enum.join("_")

  "#{var_name}_#{suffix}"
end
```

### Pattern 4: Expression Evaluation with Bindings

```elixir
def evaluate_expression_with_bindings(ast, model_params, bindings) do
  # Store in process dictionary
  Process.put(:dantzig_eval_env, %{
    model_parameters: model_params,
    bindings: bindings
  })

  # Evaluate
  result = Code.eval_quoted(ast)

  # Clean up
  Process.delete(:dantzig_eval_env)

  result
end
```

### Pattern 5: Constant Access

```elixir
def try_evaluate_constant(ast, bindings) do
  case ast do
    {:access, _, [map_ast, key_ast]} ->
      map = try_evaluate_constant(map_ast, bindings)
      key = try_evaluate_constant(key_ast, bindings)
      get_map_value(map, key, bindings)

    literal when is_number(literal) or is_atom(literal) ->
      literal

    _ ->
      nil
  end
end
```

### Pattern 6: Map Access with String/Atom Conversion

```elixir
def get_map_value(map, key, _bindings) when is_map(map) do
  # Try atom key first
  case Map.get(map, key) do
    nil when is_binary(key) ->
      # Try string key
      Map.get(map, String.to_atom(key))
    value ->
      value
  end
end
```

### Pattern 7: AST Transformation

```elixir
def transform_expression(ast, problem, bindings) do
  case ast do
    %AST.Variable{} = var ->
      get_variable_polynomial(var, problem)

    %AST.Max{args: args} ->
      transform_max(args, problem, bindings)

    %AST.Abs{arg: arg} ->
      transform_abs(arg, problem, bindings)

    _ ->
      raise ArgumentError, "Unsupported AST node: #{inspect(ast)}"
  end
end
```

### Pattern 8: Constraint Creation

```elixir
def create_constraint(left, operator, right, description, problem, bindings) do
  # Evaluate left-hand side
  {problem, left_poly} = transform_expression(left, problem, bindings)

  # Handle right-hand side
  right_value = case right do
    :infinity -> :infinity
    _ -> try_evaluate_constant(right, bindings) || 0
  end

  # Create constraint
  constraint = Constraint.new_linear(left_poly, operator, right_value)

  # Add to problem
  problem = Problem.add_constraint(problem, constraint)

  problem
end
```

## Conventions

### Naming Conventions

- **Variables**: `var_name` (snake_case)
- **Functions**: `function_name/arity` (snake_case)
- **Modules**: `Dantzig.Module.Name` (PascalCase)
- **AST Nodes**: `AST.NodeName` (PascalCase)

### Error Handling

```elixir
# Use descriptive error messages
raise ArgumentError, "Variable '#{var_name}' not found in problem"

# Include context
raise ArgumentError, """
  Cannot evaluate expression: #{inspect(ast)}
  Bindings: #{inspect(bindings)}
  Model parameters: #{inspect(model_params)}
"""
```

### Process Dictionary Usage

```elixir
# Store evaluation environment
Process.put(:dantzig_eval_env, %{
  model_parameters: model_params,
  bindings: bindings
})

# Always clean up
try do
  # Use environment
rescue
  e -> raise e
after
  Process.delete(:dantzig_eval_env)
end
```

## Related Documentation

- [Extension Guide](extension-guide.md) - How to add features
- [Key Concepts](key-concepts.md) - Core concepts
- [Debugging Guide](debugging-guide.md) - Troubleshooting
