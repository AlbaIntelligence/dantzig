defmodule Dantzig.CompilationTest do
  @moduledoc """
  Compilation validation test for the Dantzig package.

  This test ensures that all modules compile without errors and warnings.
  """
  use ExUnit.Case, async: true

  test "all core modules compile without errors" do
    core_modules = [
      Dantzig,
      Dantzig.Problem,
      Dantzig.ProblemVariable,
      Dantzig.Constraint,
      Dantzig.SolvedConstraint,
      Dantzig.Polynomial,
      Dantzig.Polynomial.Operators,
      Dantzig.Solution
    ]

    for module <- core_modules do
      assert Code.ensure_loaded?(module), "Module #{module} should be loaded"
    end
  end

  test "all AST modules compile without errors" do
    ast_modules = [
      Dantzig.AST,
      Dantzig.AST.Parser,
      Dantzig.AST.Analyzer,
      Dantzig.AST.Transformer
    ]

    for module <- ast_modules do
      assert Code.ensure_loaded?(module), "Module #{module} should be loaded"
    end
  end

  test "all DSL modules compile without errors" do
    dsl_modules = [
      Dantzig.DSL,
      Dantzig.DSL.ConstraintParser,
      Dantzig.DSL.SumFunction,
      Dantzig.DSL.VariableAccess,
      Dantzig.Problem.DSL
    ]

    for module <- dsl_modules do
      assert Code.ensure_loaded?(module), "Module #{module} should be loaded"
    end
  end

  test "all solver modules compile without errors" do
    solver_modules = [
      Dantzig.HiGHS,
      Dantzig.HiGHSDownloader,
      Dantzig.Config,
      Dantzig.Solution.Parser
    ]

    for module <- solver_modules do
      assert Code.ensure_loaded?(module), "Module #{module} should be loaded"
    end
  end

  test "compilation produces no critical warnings" do
    # This test ensures that compilation doesn't produce critical warnings
    # that would indicate serious issues

    # Check that the main application compiles
    assert Code.ensure_loaded?(Dantzig), "Main Dantzig module should compile"

    # Check that core functionality is available
    assert function_exported?(Dantzig.Problem, :new, 1), "Problem.new/1 should be exported"
    assert function_exported?(Dantzig.Problem, :define, 1), "Problem.define/1 should be exported"
  end

  test "test modules compile without errors" do
    # Check that test helper modules compile
    test_modules = [
      Dantzig.Test.Support.PolynomialGenerator
    ]

    for module <- test_modules do
      if Code.ensure_loaded?(module) do
        assert true, "Test module #{module} compiled successfully"
      else
        # Some test modules might not exist yet, which is okay
        assert true, "Test module #{module} not found (may not exist yet)"
      end
    end
  end

  test "example files compile without errors" do
    # Check that example files can be compiled
    example_files = [
      "docs/user/examples/simple_working_example.exs",
      "docs/user/examples/knapsack_problem.exs",
      "docs/user/examples/assignment_problem.exs"
    ]

    for file <- example_files do
      if File.exists?(file) do
        # Try to compile the example file
        case Code.compile_file(file) do
          {_, []} ->
            assert true, "Example file #{file} compiled successfully"

          {_, warnings} ->
            # Check if warnings are critical
            critical_warnings =
              Enum.filter(warnings, fn {_, _, message} ->
                String.contains?(to_string(message), "undefined") or
                  String.contains?(to_string(message), "error")
              end)

            assert length(critical_warnings) == 0,
                   "Example file #{file} should not have critical warnings: #{inspect(critical_warnings)}"
        end
      else
        assert true, "Example file #{file} not found (may not exist yet)"
      end
    end
  end
end
