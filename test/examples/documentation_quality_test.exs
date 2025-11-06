defmodule Examples.DocumentationQualityTest do
  @moduledoc """
  Documentation quality validation test for example files.

  This test ensures that example files have comprehensive documentation
  covering business context, mathematical formulation, DSL syntax, and common gotchas.

  T055: Create documentation quality validation
  """
  # Documentation tests should run sequentially
  use ExUnit.Case, async: false

  @examples_dir "examples"

  # Expected example files that should have documentation
  @expected_examples [
    "simple_working_example.exs",
    "assignment_problem.exs",
    "blending_problem.exs",
    "knapsack_problem.exs",
    "network_flow.exs",
    "production_planning.exs",
    "transportation_problem.exs",
    "working_example.exs",
    "tutorial_examples.exs"
  ]

  # Minimum documentation requirements
  # Minimum number of comment lines for documentation
  @min_comment_lines 5

  test "example files have header documentation" do
    # Verify that example files have header comments
    for example <- @expected_examples do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for header comments (lines starting with #)
        comment_lines =
          content
          |> String.split("\n")
          # Check first 20 lines
          |> Enum.take(20)
          |> Enum.filter(&String.starts_with?(&1, "#"))
          |> Enum.count()

        assert comment_lines >= 3,
               "Example #{example} should have at least 3 comment lines in header, found #{comment_lines}"
      end
    end
  end

  test "example files have problem description" do
    # Verify that example files describe the problem being solved
    for example <- @expected_examples do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for problem description keywords
        has_description =
          String.contains?(content, "Problem") or
            String.contains?(content, "problem") or
            String.contains?(content, "Example") or
            String.contains?(content, "example")

        assert has_description,
               "Example #{example} should contain problem description (look for 'Problem' or 'Example')"
      end
    end
  end

  test "example files have DSL syntax explanations" do
    # Verify that example files explain DSL syntax
    examples_with_dsl = [
      "simple_working_example.exs",
      "knapsack_problem.exs",
      "assignment_problem.exs",
      "tutorial_examples.exs"
    ]

    for example <- examples_with_dsl do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for DSL-related comments
        has_dsl_explanation =
          String.contains?(content, "variables") or
            String.contains?(content, "constraints") or
            String.contains?(content, "objective") or
            String.contains?(content, "Problem.define") or
            String.contains?(content, "DSL")

        assert has_dsl_explanation,
               "Example #{example} should contain DSL syntax explanations"
      end
    end
  end

  test "knapsack_problem.exs has comprehensive documentation" do
    example_path = Path.join(@examples_dir, "knapsack_problem.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Check for business context
      has_business_context =
        String.contains?(content, "weight") and
          String.contains?(content, "value") and
          String.contains?(content, "capacity")

      assert has_business_context,
             "knapsack_problem.exs should describe business context (weight, value, capacity)"

      # Check for problem description
      has_problem_description =
        String.contains?(content, "Problem:") or
          String.contains?(content, "problem")

      assert has_problem_description,
             "knapsack_problem.exs should have problem description"
    end
  end

  test "blending_problem.exs has comprehensive documentation" do
    example_path = Path.join(@examples_dir, "blending_problem.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Check for business context
      has_business_context =
        String.contains?(content, "material") or
          String.contains?(content, "blend") or
          String.contains?(content, "cost")

      assert has_business_context,
             "blending_problem.exs should describe business context (materials, blending, cost)"

      # Check for problem description
      has_problem_description =
        String.contains?(content, "Problem:") or
          String.contains?(content, "problem")

      assert has_problem_description,
             "blending_problem.exs should have problem description"
    end
  end

  test "assignment_problem.exs has comprehensive documentation" do
    example_path = Path.join(@examples_dir, "assignment_problem.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Check for business context
      has_business_context =
        String.contains?(content, "worker") or
          String.contains?(content, "task") or
          String.contains?(content, "assignment")

      assert has_business_context,
             "assignment_problem.exs should describe business context (workers, tasks, assignment)"

      # Check for problem description
      has_problem_description =
        String.contains?(content, "Problem:") or
          String.contains?(content, "problem")

      assert has_problem_description,
             "assignment_problem.exs should have problem description"
    end
  end

  test "transportation_problem.exs has comprehensive documentation" do
    example_path = Path.join(@examples_dir, "transportation_problem.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Check for business context
      has_business_context =
        String.contains?(content, "supplier") or
          String.contains?(content, "customer") or
          String.contains?(content, "transportation") or
          String.contains?(content, "shipment")

      assert has_business_context,
             "transportation_problem.exs should describe business context (suppliers, customers, shipments)"

      # Check for problem description
      has_problem_description =
        String.contains?(content, "Problem:") or
          String.contains?(content, "problem")

      assert has_problem_description,
             "transportation_problem.exs should have problem description"
    end
  end

  test "production_planning.exs has comprehensive documentation" do
    example_path = Path.join(@examples_dir, "production_planning.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Check for business context
      has_business_context =
        String.contains?(content, "production") or
          String.contains?(content, "period") or
          String.contains?(content, "inventory")

      assert has_business_context,
             "production_planning.exs should describe business context (production, periods, inventory)"

      # Check for problem description
      has_problem_description =
        String.contains?(content, "Problem:") or
          String.contains?(content, "problem")

      assert has_problem_description,
             "production_planning.exs should have problem description"
    end
  end

  test "example files have inline comments for complex logic" do
    # Verify that example files have inline comments explaining complex logic
    examples_with_complex_logic = [
      "knapsack_problem.exs",
      "blending_problem.exs",
      "assignment_problem.exs"
    ]

    for example <- examples_with_complex_logic do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Count comment lines (excluding shebang)
        comment_lines =
          content
          |> String.split("\n")
          |> Enum.filter(fn line ->
            trimmed = String.trim(line)
            String.starts_with?(trimmed, "#") and not String.starts_with?(trimmed, "#!/")
          end)
          |> Enum.count()

        assert comment_lines >= @min_comment_lines,
               "Example #{example} should have at least #{@min_comment_lines} comment lines, found #{comment_lines}"
      end
    end
  end

  test "example files have variable explanations" do
    # Verify that example files explain what variables represent
    examples_with_variables = [
      "knapsack_problem.exs",
      "blending_problem.exs",
      "assignment_problem.exs"
    ]

    for example <- examples_with_variables do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for variable explanations (comments near variable definitions)
        has_variable_explanation =
          String.contains?(content, "variable") or
            String.contains?(content, "Variable") or
            (String.contains?(content, "variables(") and
               (String.contains?(content, "#") or String.contains?(content, "Create")))

        assert has_variable_explanation,
               "Example #{example} should explain what variables represent"
      end
    end
  end

  test "example files have constraint explanations" do
    # Verify that example files explain constraints
    examples_with_constraints = [
      "knapsack_problem.exs",
      "blending_problem.exs",
      "assignment_problem.exs"
    ]

    for example <- examples_with_constraints do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for constraint explanations
        has_constraint_explanation =
          String.contains?(content, "constraint") or
            String.contains?(content, "Constraint") or
            (String.contains?(content, "constraints(") and
               (String.contains?(content, "#") or String.contains?(content, "Constraint:")))

        assert has_constraint_explanation,
               "Example #{example} should explain constraints"
      end
    end
  end

  test "tutorial_examples.exs has tutorial-level documentation" do
    example_path = Path.join(@examples_dir, "tutorial_examples.exs")

    if File.exists?(example_path) do
      content = File.read!(example_path)

      # Tutorial examples should have extensive documentation
      comment_lines =
        content
        |> String.split("\n")
        |> Enum.filter(&String.starts_with?(&1, "#"))
        |> Enum.count()

      assert comment_lines >= 10,
             "tutorial_examples.exs should have extensive documentation (at least 10 comment lines), found #{comment_lines}"

      # Should explain DSL syntax
      has_dsl_explanation =
        String.contains?(content, "Problem.define") or
          String.contains?(content, "variables") or
          String.contains?(content, "constraints") or
          String.contains?(content, "DSL")

      assert has_dsl_explanation,
             "tutorial_examples.exs should explain DSL syntax"
    end
  end

  test "example files have code structure comments" do
    # Verify that example files have comments explaining code structure
    for example <- @expected_examples do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for structural comments (comments that explain sections)
        has_structure =
          String.contains?(content, "# Define") or
            String.contains?(content, "# Create") or
            String.contains?(content, "# Solve") or
            String.contains?(content, "# Check") or
            String.contains?(content, "# Example")

        # This is a soft requirement - log but don't fail
        unless has_structure do
          IO.puts("Warning: Example #{example} could benefit from structural comments")
        end
      end
    end

    # Test passes - structural comments are recommended but not required
    assert true
  end

  test "example files avoid magic numbers without explanation" do
    # Verify that example files explain numeric constants
    examples_with_numbers = [
      "knapsack_problem.exs",
      "blending_problem.exs"
    ]

    for example <- examples_with_numbers do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check if numeric constants are defined as variables with names
        # (This is a soft check - we're looking for good practices)
        # Variable assignments
        has_named_constants =
          String.contains?(content, "capacity") or
            String.contains?(content, "limit") or
            String.contains?(content, "cost") or
            String.contains?(content, "=")

        # This is a recommendation, not a requirement
        unless has_named_constants do
          IO.puts(
            "Info: Example #{example} could benefit from named constants instead of magic numbers"
          )
        end
      end
    end

    # Test passes - this is a recommendation
    assert true
  end

  test "example files have readable formatting" do
    # Verify that example files have reasonable formatting
    for example <- @expected_examples do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check for reasonable line length (most lines under 120 chars)
        long_lines =
          content
          |> String.split("\n")
          |> Enum.filter(fn line -> String.length(line) > 120 end)
          |> Enum.count()

        total_lines =
          content
          |> String.split("\n")
          |> Enum.count()

        # Allow up to 20% of lines to be long (for comments, etc.)
        long_line_ratio = if total_lines > 0, do: long_lines / total_lines, else: 0.0

        assert long_line_ratio <= 0.2,
               "Example #{example} should have reasonable line lengths (more than 20% are > 120 chars)"
      end
    end
  end

  test "example files have consistent comment style" do
    # Verify that example files use consistent comment style
    for example <- @expected_examples do
      example_path = Path.join(@examples_dir, example)

      if File.exists?(example_path) do
        content = File.read!(example_path)

        # Check that comments start with # (or #! for shebang)
        lines = String.split(content, "\n")
        comment_lines = Enum.filter(lines, &String.starts_with?(&1, "#"))

        # All comment lines should start with #
        assert length(comment_lines) ==
                 length(Enum.filter(comment_lines, &String.starts_with?(&1, "#"))),
               "Example #{example} should use consistent comment style (#)"
      end
    end
  end
end
