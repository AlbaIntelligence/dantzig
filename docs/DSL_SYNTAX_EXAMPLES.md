# DSL Syntax Examples

**Part of**: [DSL_SYNTAX_REFERENCE.md](DSL_SYNTAX_REFERENCE.md) | **See Also**: [DSL_SYNTAX_ADVANCED.md](DSL_SYNTAX_ADVANCED.md)

This document contains complete working examples demonstrating the Dantzig DSL syntax. These examples serve as golden references for correct DSL usage.

## Complete Working Examples

### Example 1: Simple Generator (Golden Reference)

```elixir
defmodule Dantzig.DSL.SimpleGeneratorTest do
  @moduledoc """
  The syntax in this module is _golden_.
  It should be considered the canonical way to write generator syntax.
  """

  test "Simple generator syntax" do
    params = %{food_names: ["bread", "milk"]}

    problem =
      Problem.define(model_parameters: params) do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end

  test "Generator with objective" do
    params = %{food_names: ["bread", "milk"]}

    problem =
      Problem.define(model_parameters: params) do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food)), :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
```

### Example 2: N-Queens Problem

```elixir
# N-Queens problem using the new DSL
require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Create the problem
problem2d =
  Problem.define do
    new(
      name: "N-Queens",
      description: "Place N queens on an N×N chessboard so that no two queens attack each other."
    )

    # Add binary variables for queen positions (4x4 board)
    variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Add constraints: one queen per row
    constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints([j <- 1..4], sum(queen2d(:_, j)) == 1, "One queen per column")

    # Set objective (squeeze as many queens as possible)
    objective(sum(queen2d(:_, :_)), :maximize)
  end
```

---

**Navigation:**
- [← Back to DSL Syntax Reference](DSL_SYNTAX_REFERENCE.md)
- [→ Advanced Topics](DSL_SYNTAX_ADVANCED.md)
