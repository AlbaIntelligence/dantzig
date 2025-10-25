# Test Coverage API Contract

**Feature**: 001-robustify
**Date**: 2024-12-19
**Purpose**: Define API contract for test coverage functionality

## Coverage Analysis API

### `Dantzig.TestCoverage.analyze/1`

**Purpose**: Analyze test coverage for the entire codebase

**Parameters**:
- `opts` (keyword list, optional): Analysis options
  - `:threshold` (float, default: 0.8): Minimum coverage threshold (0.0-1.0)
  - `:core_modules` (list of atoms): Modules requiring higher coverage
  - `:core_threshold` (float, default: 0.85): Core module coverage threshold

**Returns**:
```elixir
{:ok, %Dantzig.TestCoverage.Report{
  overall_coverage: 0.85,
  core_modules: %{
    "Dantzig.Problem" => 0.90,
    "Dantzig.DSL" => 0.88,
    "Dantzig.AST" => 0.87,
    "Dantzig.Solver" => 0.89
  },
  test_files: %{
    "test/dantzig/problem_test.exs" => 0.92,
    "test/dantzig/dsl_test.exs" => 0.85
  },
  status: :passed | :failed,
  violations: [%{module: "Module.Name", coverage: 0.75, threshold: 0.85}]
}}
```

**Error Cases**:
- `{:error, :compilation_failed, details}` - Test compilation errors
- `{:error, :coverage_insufficient, violations}` - Coverage below thresholds

### `Dantzig.TestCoverage.analyze_module/2`

**Purpose**: Analyze coverage for a specific module

**Parameters**:
- `module` (atom): Module name to analyze
- `opts` (keyword list, optional): Analysis options

**Returns**:
```elixir
{:ok, %Dantzig.TestCoverage.ModuleReport{
  module: "Dantzig.Problem",
  coverage: 0.90,
  lines_covered: 45,
  lines_total: 50,
  functions: %{
    "new/1" => 1.0,
    "variables/3" => 0.8,
    "constraints/3" => 0.9
  },
  status: :passed | :failed
}}
```

## Test Execution API

### `Dantzig.TestRunner.run_all/1`

**Purpose**: Execute all tests and return comprehensive results

**Parameters**:
- `opts` (keyword list, optional): Execution options
  - `:include_performance` (boolean, default: false): Include performance tests
  - `:timeout` (integer, default: 300): Test timeout in seconds

**Returns**:
```elixir
{:ok, %Dantzig.TestRunner.Results{
  compilation_status: :success,
  tests_run: 150,
  tests_passed: 148,
  tests_failed: 2,
  execution_time_ms: 45000,
  coverage_report: %Dantzig.TestCoverage.Report{...},
  performance_metrics: %Dantzig.Performance.Metrics{...}
}}
```

**Error Cases**:
- `{:error, :compilation_failed, errors}` - Test compilation errors
- `{:error, :timeout_exceeded}` - Tests exceeded timeout limit

### `Dantzig.TestRunner.run_category/2`

**Purpose**: Execute tests for a specific category

**Parameters**:
- `category` (atom): Test category (:unit, :integration, :performance, :examples)
- `opts` (keyword list, optional): Execution options

**Returns**:
```elixir
{:ok, %Dantzig.TestRunner.CategoryResults{
  category: :unit,
  tests_run: 50,
  tests_passed: 50,
  tests_failed: 0,
  execution_time_ms: 15000,
  status: :passed
}}
```

## Coverage Validation API

### `Dantzig.TestCoverage.validate_thresholds/1`

**Purpose**: Validate that coverage meets required thresholds

**Parameters**:
- `report` (%Dantzig.TestCoverage.Report{}): Coverage report to validate

**Returns**:
```elixir
{:ok, :thresholds_met} | {:error, :thresholds_not_met, violations}
```

**Violations Format**:
```elixir
[%{
  type: :overall_coverage | :core_module_coverage,
  module: "Module.Name" | nil,
  actual: 0.75,
  required: 0.85,
  message: "Coverage 75% below required 85%"
}]
```

## Performance Testing API

### `Dantzig.Performance.benchmark/2`

**Purpose**: Run performance benchmarks for optimization problems

**Parameters**:
- `problem_sizes` (list of integers): Problem sizes to benchmark
- `opts` (keyword list, optional): Benchmark options
  - `:problem_types` (list of atoms): Types of problems to benchmark
  - `:iterations` (integer, default: 3): Number of benchmark iterations

**Returns**:
```elixir
{:ok, %Dantzig.Performance.BenchmarkResults{
  problem_sizes: [100, 500, 1000],
  results: %{
    100 => %{execution_time_ms: 150, memory_mb: 10},
    500 => %{execution_time_ms: 2000, memory_mb: 45},
    1000 => %{execution_time_ms: 15000, memory_mb: 85}
  },
  scalability_analysis: %{
    time_complexity: "O(n^2)",
    memory_complexity: "O(n)",
    recommendations: ["Consider problem size limits for production"]
  }
}}
```

## Error Handling

### Common Error Types

```elixir
# Compilation Errors
{:error, :compilation_failed, %{
  file: "test/dantzig/dsl_test.exs",
  line: 45,
  error: "undefined function x/1",
  suggestions: ["Check variable definition", "Verify DSL syntax"]
}}

# Coverage Violations
{:error, :coverage_insufficient, %{
  module: "Dantzig.Problem",
  actual: 0.75,
  required: 0.85,
  uncovered_functions: ["private_function/1", "edge_case/2"]
}}

# Performance Issues
{:error, :performance_degraded, %{
  metric: :execution_time,
  actual: 45000,
  threshold: 30000,
  problem_size: 1000,
  recommendations: ["Optimize constraint generation", "Consider problem size limits"]
}}
```

### Error Recovery

```elixir
# Retry with different options
Dantzig.TestRunner.run_all(timeout: 600, include_performance: false)

# Focus on specific modules
Dantzig.TestCoverage.analyze_module(Dantzig.Problem, threshold: 0.9)

# Run incremental tests
Dantzig.TestRunner.run_category(:unit, incremental: true)
```

## Usage Examples

### Basic Coverage Analysis
```elixir
# Analyze overall coverage
{:ok, report} = Dantzig.TestCoverage.analyze()

# Check if thresholds are met
case Dantzig.TestCoverage.validate_thresholds(report) do
  {:ok, :thresholds_met} -> IO.puts("Coverage requirements satisfied")
  {:error, :thresholds_not_met, violations} ->
    IO.puts("Coverage violations: #{inspect(violations)}")
end
```

### Comprehensive Testing
```elixir
# Run all tests with coverage
{:ok, results} = Dantzig.TestRunner.run_all(include_performance: true)

# Analyze results
IO.puts("Tests: #{results.tests_passed}/#{results.tests_run}")
IO.puts("Coverage: #{results.coverage_report.overall_coverage}")
IO.puts("Performance: #{results.performance_metrics.execution_time_ms}ms")
```

### Performance Benchmarking
```elixir
# Benchmark different problem sizes
{:ok, benchmark} = Dantzig.Performance.benchmark([100, 500, 1000])

# Analyze scalability
IO.puts("Scalability: #{benchmark.scalability_analysis.time_complexity}")
IO.puts("Recommendations: #{inspect(benchmark.scalability_analysis.recommendations)}")
```
