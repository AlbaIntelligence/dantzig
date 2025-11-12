# Modeling Guide

Best practices and patterns for building robust optimization models in Dantzig.

## General Tips

- Normalize units and domains early; prefer integer/binary where meaningful
- Keep constraints simple and interpretable; decompose when complex
- Name variables/constraints descriptively for debugging

## Variables

- Use `:binary` for 0/1 decisions, `:continuous` where appropriate
- Use patterns to generate large structured variable sets concisely

## Constraints

- Prefer pattern sums (e.g., `{i, :_}`, `{:_, j}`) over manual loops
- Group related constraints with meaningful description strings

## Objectives

- Build objectives incrementally with `Problem.increment_objective/2`
- For multi-objective, use weighted sum or lexicographic passes

## Variadic & Pattern Operations

- `max(x[_])`, `min(z[i, _])`, `a[_] AND ...`, `b[_] OR ...` are supported via AST
- Expect auxiliary variables & constraints behind the scenes

## Debugging

- Dump LP with `Dantzig.dump_problem_to_file(problem, "model.lp")`
- Inspect constraint and variable maps

## Performance

- Limit big-M values; tighten bounds
- Reduce symmetry via indexing or additional constraints

## Common Patterns

### Production Planning

```elixir
variables("production", [product <- products, time <- 1..T], :continuous, min_bound: 0)
constraints([time <- 1..T], sum(production(product, time) for product <- products) <= capacity[time])
```

### Assignment Problems

```elixir
variables("assign", [worker <- workers, task <- tasks], :binary)
constraints([task <- tasks], sum(assign(worker, task) for worker <- workers) == 1)
```

### Network Flow

```elixir
variables("flow", [from <- nodes, to <- nodes], :continuous, min_bound: 0)
constraints([node <- nodes],
  sum(flow(from, node) for from <- nodes) == sum(flow(node, to) for to <- nodes))
```

## Related Documentation

- [DSL Syntax Reference](../reference/dsl-syntax.md) - Complete syntax guide
- [Pattern Operations](../reference/pattern-operations.md) - Pattern-based operations
- [Variadic Operations](../reference/variadic-operations.md) - Variadic functions
