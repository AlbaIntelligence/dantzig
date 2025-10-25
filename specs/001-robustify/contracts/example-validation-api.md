# Example Validation API Contract

**Feature**: 001-robustify
**Date**: 2024-12-19
**Purpose**: Define API contract for example validation and documentation

## Example Validation API

### `Dantzig.Examples.validate_all/1`

**Purpose**: Validate all example files execute successfully

**Parameters**:
- `opts` (keyword list, optional): Validation options
  - `:timeout` (integer, default: 60): Execution timeout in seconds
  - `:include_documentation_check` (boolean, default: true): Check documentation quality

**Returns**:
```elixir
{:ok, %Dantzig.Examples.ValidationReport{
  total_examples: 15,
  successful_executions: 15,
  failed_executions: 0,
  documentation_quality: %{
    comprehensive: 12,
    adequate: 3,
    needs_improvement: 0
  },
  problem_types_covered: [:diet, :transportation, :assignment, :production, :facility_location],
  execution_times: %{
    "examples/diet_problem.exs" => 1500,
    "examples/transportation_problem.exs" => 2300
  },
  status: :all_passed | :some_failed
}}
```

**Error Cases**:
- `{:error, :execution_failed, failures}` - Examples failed to execute
- `{:error, :documentation_insufficient, violations}` - Documentation quality issues

### `Dantzig.Examples.validate_file/2`

**Purpose**: Validate a specific example file

**Parameters**:
- `file_path` (string): Path to example file
- `opts` (keyword list, optional): Validation options

**Returns**:
```elixir
{:ok, %Dantzig.Examples.FileValidation{
  file_path: "examples/diet_problem.exs",
  execution_status: :success,
  execution_time_ms: 1500,
  documentation_quality: :comprehensive,
  problem_type: :diet,
  business_context_present: true,
  mathematical_formulation_present: true,
  dsl_syntax_explanation_present: true,
  gotchas_documented: true,
  learning_objectives: ["Understand nutritional optimization", "Learn constraint modeling"],
  status: :passed | :failed
}}
```

**Error Cases**:
- `{:error, :file_not_found}` - Example file doesn't exist
- `{:error, :execution_failed, error_details}` - Example failed to execute
- `{:error, :documentation_insufficient, missing_elements}` - Documentation issues

## Documentation Quality API

### `Dantzig.Examples.analyze_documentation/2`

**Purpose**: Analyze documentation quality for example files

**Parameters**:
- `file_path` (string): Path to example file
- `opts` (keyword list, optional): Analysis options
  - `:check_business_context` (boolean, default: true)
  - `:check_mathematical_formulation` (boolean, default: true)
  - `:check_dsl_syntax` (boolean, default: true)
  - `:check_gotchas` (boolean, default: true)

**Returns**:
```elixir
{:ok, %Dantzig.Examples.DocumentationAnalysis{
  file_path: "examples/diet_problem.exs",
  overall_quality: :comprehensive,
  elements: %{
    business_context: %{
      present: true,
      quality: :excellent,
      explanation: "Nutritional optimization for meal planning"
    },
    mathematical_formulation: %{
      present: true,
      quality: :good,
      explanation: "Linear programming with nutritional constraints"
    },
    dsl_syntax: %{
      present: true,
      quality: :excellent,
      explanation: "Clear explanation of variable creation and constraints"
    },
    gotchas: %{
      present: true,
      quality: :good,
      explanation: "Common mistakes with constraint syntax"
    }
  },
  learning_objectives: ["Understand nutritional optimization", "Learn constraint modeling"],
  target_audience: :beginner,
  estimated_learning_time_minutes: 15,
  status: :comprehensive | :adequate | :needs_improvement
}}
```

### `Dantzig.Examples.validate_learning_progression/1`

**Purpose**: Validate that examples provide appropriate learning progression

**Parameters**:
- `opts` (keyword list, optional): Validation options

**Returns**:
```elixir
{:ok, %Dantzig.Examples.LearningProgression{
  progression_valid: true,
  levels: %{
    beginner: %{
      count: 5,
      examples: ["diet_problem.exs", "simple_assignment.exs"],
      learning_objectives: ["Basic LP concepts", "Simple constraints"]
    },
    intermediate: %{
      count: 6,
      examples: ["transportation_problem.exs", "production_planning.exs"],
      learning_objectives: ["Network optimization", "Multi-period planning"]
    },
    advanced: %{
      count: 4,
      examples: ["facility_location.exs", "complex_scheduling.exs"],
      learning_objectives: ["Strategic optimization", "Complex constraints"]
    }
  },
  coverage: %{
    problem_types: 5,
    business_domains: 4,
    mathematical_concepts: 8
  },
  status: :valid | :needs_improvement
}}
```

## Example Execution API

### `Dantzig.Examples.execute/2`

**Purpose**: Execute an example file and capture results

**Parameters**:
- `file_path` (string): Path to example file
- `opts` (keyword list, optional): Execution options
  - `:timeout` (integer, default: 60): Execution timeout
  - `:capture_output` (boolean, default: true): Capture stdout/stderr
  - `:validate_solution` (boolean, default: true): Validate optimization solution

**Returns**:
```elixir
{:ok, %Dantzig.Examples.ExecutionResult{
  file_path: "examples/diet_problem.exs",
  execution_status: :success,
  execution_time_ms: 1500,
  output: "=== Diet Problem ===\nOptimal cost: $12.50\n...",
  solution: %{
    objective_value: 12.50,
    variables: %{"hamburger" => 0.0, "chicken" => 1.2, "salad" => 0.8},
    status: :optimal
  },
  performance_metrics: %{
    memory_usage_mb: 15.2,
    solver_time_ms: 1200,
    constraint_count: 4,
    variable_count: 9
  }
}}
```

**Error Cases**:
- `{:error, :execution_failed, %{error: error, output: output}}` - Execution failed
- `{:error, :timeout_exceeded}` - Execution exceeded timeout
- `{:error, :invalid_solution, details}` - Solution validation failed

## Problem Type Classification API

### `Dantzig.Examples.classify_problem_type/1`

**Purpose**: Automatically classify the type of optimization problem

**Parameters**:
- `file_path` (string): Path to example file

**Returns**:
```elixir
{:ok, %Dantzig.Examples.ProblemClassification{
  file_path: "examples/diet_problem.exs",
  problem_type: :diet,
  business_domain: :nutrition,
  mathematical_category: :linear_programming,
  complexity_level: :beginner,
  key_concepts: ["nutritional constraints", "cost minimization", "linear programming"],
  confidence: 0.95
}}
```

### `Dantzig.Examples.validate_problem_coverage/1`

**Purpose**: Validate that examples cover required problem types

**Parameters**:
- `required_types` (list of atoms): Required problem types

**Returns**:
```elixir
{:ok, %Dantzig.Examples.CoverageValidation{
  required_types: [:diet, :transportation, :assignment, :production, :facility_location],
  covered_types: [:diet, :transportation, :assignment, :production, :facility_location],
  missing_types: [],
  coverage_percentage: 100.0,
  status: :complete | :incomplete
}}
```

## Error Handling

### Common Error Types

```elixir
# Execution Errors
{:error, :execution_failed, %{
  file: "examples/diet_problem.exs",
  error: "undefined function x/1",
  line: 45,
  suggestions: ["Check variable definition", "Verify DSL syntax"]
}}

# Documentation Issues
{:error, :documentation_insufficient, %{
  file: "examples/transportation_problem.exs",
  missing_elements: [:business_context, :mathematical_formulation],
  suggestions: ["Add business context explanation", "Include mathematical model description"]
}}

# Learning Progression Issues
{:error, :progression_invalid, %{
  issue: :insufficient_beginner_examples,
  current_count: 2,
  required_count: 5,
  suggestions: ["Add more beginner examples", "Simplify existing examples"]
}}
```

### Error Recovery

```elixir
# Retry with different options
Dantzig.Examples.validate_file("examples/diet_problem.exs", timeout: 120)

# Focus on specific documentation elements
Dantzig.Examples.analyze_documentation("examples/transportation_problem.exs",
  check_business_context: true,
  check_mathematical_formulation: true
)

# Validate learning progression
Dantzig.Examples.validate_learning_progression()
```

## Usage Examples

### Validate All Examples
```elixir
# Validate all examples
{:ok, report} = Dantzig.Examples.validate_all()

# Check results
IO.puts("Examples: #{report.successful_executions}/#{report.total_examples}")
IO.puts("Documentation: #{report.documentation_quality.comprehensive} comprehensive")
IO.puts("Problem types: #{length(report.problem_types_covered)}")
```

### Analyze Documentation Quality
```elixir
# Analyze specific example
{:ok, analysis} = Dantzig.Examples.analyze_documentation("examples/diet_problem.exs")

# Check quality
IO.puts("Overall quality: #{analysis.overall_quality}")
IO.puts("Learning time: #{analysis.estimated_learning_time_minutes} minutes")
IO.puts("Target audience: #{analysis.target_audience}")
```

### Execute Example
```elixir
# Execute example with validation
{:ok, result} = Dantzig.Examples.execute("examples/diet_problem.exs",
  validate_solution: true,
  capture_output: true
)

# Check results
IO.puts("Status: #{result.execution_status}")
IO.puts("Time: #{result.execution_time_ms}ms")
IO.puts("Solution: #{result.solution.objective_value}")
```
