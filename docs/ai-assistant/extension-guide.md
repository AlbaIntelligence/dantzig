# Extension Guide

Step-by-step guides for adding new functionality to Dantzig.

## Adding a New Operation

### Step 1: Define AST Node

Add the node type to `lib/dantzig/ast.ex`:

```elixir
defmodule Dantzig.AST.NewOperation do
  defstruct [:args]
end
```

### Step 2: Extend Parser

Add parsing logic to `lib/dantzig/ast/parser.ex`:

```elixir
def parse({:new_operation, _, args}, _bindings) do
  %AST.NewOperation{args: Enum.map(args, &parse/1)}
end
```

### Step 3: Add Transformation

Add linearization logic to `lib/dantzig/ast/transformer.ex`:

```elixir
def transform(%AST.NewOperation{args: args}, problem, bindings) do
  # Transform arguments
  {problem, transformed_args} = transform_args(args, problem, bindings)

  # Create auxiliary variable
  {problem, aux_var} = Problem.new_variable(problem, "new_op_aux", type: :continuous)

  # Add linearization constraints
  problem = add_linearization_constraints(problem, aux_var, transformed_args)

  {problem, aux_var}
end
```

### Step 4: Update DSL Reducer

If needed, update `lib/dantzig/core/problem/dsl_reducer.ex` to handle the new node type.

### Step 5: Add Tests

Create tests in `test/dantzig/ast/` for the new operation.

## Adding a New Solver

### Step 1: Create Solver Module

Create `lib/dantzig/solver/new_solver.ex`:

```elixir
defmodule Dantzig.Solver.NewSolver do
  @moduledoc """
  Integration with NewSolver.
  """

  def solve(problem) do
    # Export problem
    model_data = export_problem(problem)

    # Execute solver
    solution_data = execute_solver(model_data)

    # Parse solution
    parse_solution(solution_data)
  end

  defp export_problem(problem) do
    # Convert Problem to solver format
  end

  defp execute_solver(model_data) do
    # Run solver binary/API
  end

  defp parse_solution(solution_data) do
    # Parse solver output to Dantzig.Solution
  end
end
```

### Step 2: Update Main API

Update `lib/dantzig.ex` to support the new solver:

```elixir
def solve(problem, solver: :new_solver) do
  Dantzig.Solver.NewSolver.solve(problem)
end
```

### Step 3: Add Tests

Create tests in `test/dantzig/solver/new_solver_test.exs`.

## Extending DSL Syntax

### Step 1: Add Macro

Add macro to `lib/dantzig/core/problem.ex`:

```elixir
defmacro new_feature(arg1, arg2) do
  quote do
    # Implementation
  end
end
```

### Step 2: Implement Logic

Implement in appropriate DSL module:

```elixir
# In lib/dantzig/problem/dsl/feature_manager.ex
def create_feature(arg1, arg2, problem, bindings) do
  # Implementation
end
```

### Step 3: Update Expression Parser

If the feature uses expressions, update `lib/dantzig/problem/dsl/expression_parser.ex`.

### Step 4: Add Tests

Create tests in `test/dantzig/dsl/`.

## Common Patterns

### Pattern 1: Generator-Based Features

```elixir
defmacro feature([generator | rest], expression, description) do
  quote do
    # Parse generators
    parsed_generators = parse_generators([unquote(generator) | unquote(rest)])

    # Generate combinations
    combinations = generate_combinations(parsed_generators)

    # Create feature for each combination
    Enum.reduce(combinations, var!(problem), fn combination, problem ->
      bindings = create_bindings(parsed_generators, combination)
      create_feature(problem, unquote(expression), bindings, unquote(description))
    end)
  end
end
```

### Pattern 2: Expression Evaluation

```elixir
def evaluate_expression(ast, bindings) do
  # Get model parameters from process dictionary
  model_params = Process.get(:dantzig_eval_env, %{})

  # Evaluate with bindings
  evaluate_expression_with_bindings(ast, model_params, bindings)
end
```

### Pattern 3: Constant Access

```elixir
def try_evaluate_constant(ast, bindings) do
  case ast do
    {:access, _, [map, key]} ->
      # Access map with key
      map_value = get_map_value(map, key, bindings)
      try_evaluate_constant(map_value, bindings)

    {:., _, [map, key]} ->
      # Dot notation access
      map_value = get_map_value(map, key, bindings)
      try_evaluate_constant(map_value, bindings)

    literal when is_number(literal) or is_atom(literal) ->
      literal

    _ ->
      nil
  end
end
```

## Testing Extensions

### Test Structure

```elixir
defmodule Dantzig.FeatureTest do
  use ExUnit.Case

  describe "new_feature/2" do
    test "creates feature correctly" do
      problem = Problem.define do
        new(direction: :maximize)
        new_feature(arg1, arg2)
      end

      # Assertions
    end
  end
end
```

## Related Documentation

- [Module Map](module-map.md) - Module responsibilities
- [Key Concepts](key-concepts.md) - Core concepts
- [Common Patterns](common-patterns.md) - Code patterns
