# Examples

Complete, runnable examples demonstrating Dantzig's capabilities across various optimization problem types.

## Running Examples

All examples can be run directly:

```bash
# Run a specific example
mix run docs/user/examples/knapsack_problem.exs

# Or from the project root
elixir docs/user/examples/knapsack_problem.exs
```

## Examples by Category

### Tutorial Examples

**Comprehensive Tutorial** - Learn Dantzig through practical examples:
- **[Tutorial Examples](tutorial_examples.exs)** - Complete tutorial covering all DSL features

### Classic Problems

**Fundamental Optimization Problems:**

- **[Knapsack Problem](knapsack_problem.exs)** - Binary selection with weight constraints
- **[Assignment Problem](assignment_problem.exs)** - Optimal matching/assignment
- **[Transportation Problem](transportation_problem.exs)** - Network flow with supply/demand
- **[Diet Problem](diet_problem.exs)** - Linear programming with nutritional constraints
- **[N-Queens Problem](nqueens_dsl.exs)** - Constraint satisfaction with pattern-based modeling

### Production & Operations

**Manufacturing and Operations Management:**

- **[Production Planning](production_planning.exs)** - Multi-period production with inventory
- **[Blending Problem](blending_problem.exs)** - Optimal blending/mixing
- **[Resource Allocation](resource_allocation.exs)** - Resource assignment optimization
- **[Facility Location](facility_location.exs)** - Optimal facility placement

### Scheduling & Timetabling

**Time-based Optimization:**

- **[School Timetabling](school_timetabling.exs)** - Complex multi-dimensional scheduling
- **[Minimax Scheduling](minimax_scheduling.exs)** - Fairness in scheduling

### Network & Flow

**Network Optimization:**

- **[Network Flow](network_flow.exs)** - Flow optimization through networks
- **[Supply Chain Network Design](supply_chain_network_design.exs)** - Supply chain optimization

### Advanced Features

**Demonstrating Advanced DSL Features:**

- **[Pattern-Based Operations](pattern_based_operations_example.exs)** - Wildcard patterns and aggregations
- **[Variadic Operations](variadic_operations_example.exs)** - Variadic max/min/and/or functions
- **[New DSL Example](new_dsl_example.exs)** - Modern DSL syntax demonstration
- **[Integer Programming](integer_programming.exs)** - Integer variable optimization
- **[Multi-Objective LP](multi_objective_lp.exs)** - Multiple objective optimization

### Academic Examples

**Classic Academic Problems:**

- **[Two Variable LP](two_variable_lp.exs)** - Simple two-variable linear program
- **[LP 1986 UG Exam](lp_1986_ug_exam.exs)** - University exam problem
- **[LP 1987 UG Exam](lp_1987_ug_exam.exs)** - University exam problem
- **[LP 1988 UG Exam](lp_1988_ug_exam.exs)** - University exam problem
- **[LP 1992 UG Exam](lp_1992_ug_exam.exs)** - University exam problem
- **[LP 1994 UG Exam](lp_1994_ug_exam.exs)** - University exam problem
- **[LP 1995 UG Exam](lp_1995_ug_exam.exs)** - University exam problem
- **[LP 1997 UG Exam](lp_1997_ug_exam.exs)** - University exam problem

### Financial & Portfolio

**Financial Optimization:**

- **[Portfolio Optimization](portfolio_optimization.exs)** - Investment portfolio selection
- **[Project Selection](project_selection.exs)** - Project investment decisions

### Testing & Development

**Development and Testing Examples:**

- **[Simple Working Example](simple_working_example.exs)** - Basic working example
- **[Working Example](working_example.exs)** - Another basic example
- **[Test Basic DSL](test_basic_dsl.exs)** - DSL syntax testing
- **[Generate Timetable SVG](generate_timetable_svg.exs)** - Visualization example

## Examples by Complexity

### Simple (Beginner)

Good starting points for learning Dantzig:

- [Two Variable LP](two_variable_lp.exs)
- [Simple Working Example](simple_working_example.exs)
- [Working Example](working_example.exs)
- [Knapsack Problem](knapsack_problem.exs)
- [Assignment Problem](assignment_problem.exs)

### Medium (Intermediate)

More complex problems with multiple constraints:

- [Transportation Problem](transportation_problem.exs)
- [Production Planning](production_planning.exs)
- [Blending Problem](blending_problem.exs)
- [Diet Problem](diet_problem.exs)
- [Resource Allocation](resource_allocation.exs)

### Complex (Advanced)

Multi-dimensional problems with advanced features:

- [N-Queens Problem](nqueens_dsl.exs)
- [School Timetabling](school_timetabling.exs)
- [Network Flow](network_flow.exs)
- [Supply Chain Network Design](supply_chain_network_design.exs)
- [Pattern-Based Operations](pattern_based_operations_example.exs)

## Examples by Feature

### Model Parameters

Examples using `model_parameters`:

- [Knapsack Problem](knapsack_problem.exs)
- [Diet Problem](diet_problem.exs)
- [Production Planning](production_planning.exs)
- [School Timetabling](school_timetabling.exs)

### Pattern-Based Modeling

Examples with generators and wildcards:

- [N-Queens Problem](nqueens_dsl.exs)
- [Transportation Problem](transportation_problem.exs)
- [Pattern-Based Operations](pattern_based_operations_example.exs)

### Automatic Linearization

Examples using abs, max, min, and logical operations:

- [Variadic Operations](variadic_operations_example.exs)
- [Pattern-Based Operations](pattern_based_operations_example.exs)

### Integer Programming

Examples with integer variables:

- [Integer Programming](integer_programming.exs)
- [Production Planning](production_planning.exs)

## Related Documentation

- [Quick Start Guide](../quickstart.md) - Getting started with Dantzig
- [Tutorial](../tutorial/comprehensive.md) - Comprehensive tutorial
- [DSL Syntax Reference](../reference/dsl-syntax.md) - Complete syntax guide
- [Modeling Guide](../guides/modeling-patterns.md) - Best practices

