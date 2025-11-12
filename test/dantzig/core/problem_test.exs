defmodule Dantzig.Core.ProblemTest do
  @moduledoc """
  Tests for Problem module core functionality.

  This module tests the core Problem functionality and AST transformations.
  """
  use ExUnit.Case
  require Dantzig.Problem, as: Problem
  alias Dantzig.Problem.AST

  describe "constraint expression variable references" do
    test "variable references work in constraints with generators" do
      food_names = ["bread", "milk"]

      # This test checks that qty(food) where food comes from model parameters
      # is properly handled in constraint expressions
      problem =
        Problem.define model_parameters: %{food_names: food_names} do
          new(name: "Test", description: "Test var ref in constraints")
          variables("qty", [food <- food_names], :continuous, "Amount")

          # Variable reference qty(food) should work when food is from generator
          constraints([food <- food_names], qty(food) >= 0, "Non-negativity")
        end

      assert map_size(problem.constraints) == 2
    end
  end

  # T141c: Tests for transform_constraint_expression_to_ast/1 variable refs
  # These tests are expected to FAIL until implementation is complete

  describe "transform_constraint_expression_to_ast/1" do
    test "transforms variable reference with single generator variable" do
      # Test that x(i) where i is from generator gets transformed correctly
      # Input: AST for x(i) where i comes from generator context
      # Expected: AST that can resolve to concrete variable names x_1, x_2, etc.

      # Create AST for x(i) expression
      expr = quote do: x(i)

      # Transform it
      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should still be a function call AST, but normalized
      # Format should be {:x, meta, [i]} where i is the generator variable
      assert match?({:x, _, [_]}, transformed)

      # The argument should be preserved as generator variable 'i'
      # This will be resolved later when bindings are provided
      {_, _, [arg]} = transformed
      # Should be atom 'i' or tuple {:i, _, _} - generator variable preserved
      assert is_atom(arg) or (is_tuple(arg) and elem(arg, 0) == :i)
    end

    test "transforms variable reference with 2D pattern matching" do
      # Test that queen2d(i, :_) gets transformed correctly
      expr = quote do: queen2d(i, :_)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be normalized function call preserving generator variable and wildcard
      assert match?({:queen2d, _, [_, :_]}, transformed)

      {_, _, [arg1, arg2]} = transformed
      # First arg should be generator variable 'i' (preserved for later resolution)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
    end

    test "transforms variable reference with multiple generator variables" do
      # Test that queen3d(i, :_, k) gets transformed correctly
      expr = quote do: queen3d(i, :_, k)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be normalized function call with 3 args
      assert match?({:queen3d, _, [_, :_, _]}, transformed)

      {_, _, [arg1, arg2, arg3]} = transformed
      # First arg should be generator variable 'i' (preserved)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
      # Third arg should be generator variable 'k' (preserved)
      assert is_atom(arg3) or (is_tuple(arg3) and elem(arg3, 0) == :k)
    end

    test "transforms variable reference in constraint expression" do
      # Test that constraint expression like x(i) >= 0 gets transformed
      expr = quote do: x(i) >= 0

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be comparison operation with transformed variable reference on left
      assert match?({:>=, _, [_, _]}, transformed)

      {_, _, [left, right]} = transformed
      # Left side should be transformed variable reference {:x, _, [i]}
      assert match?({:x, _, [_]}, left)

      # Verify the variable reference preserves generator variable
      {_, _, [arg]} = left
      assert is_atom(arg) or (is_tuple(arg) and elem(arg, 0) == :i)

      # Right side should be constant
      assert right == 0
    end

    test "transforms variable reference with sum pattern" do
      # Test that sum(queen2d(i, :_)) gets transformed correctly
      expr = quote do: sum(queen2d(i, :_))

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be sum call with transformed variable reference
      assert match?({:sum, _, [{:queen2d, _, [_, :_]}]}, transformed)

      {_, _, [{:queen2d, _, [arg1, arg2]}]} = transformed
      # First arg should be generator variable 'i' (preserved for resolution)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
    end

    test "transforms nested variable references in complex expression" do
      # Test that complex expression like x(i) + y(i) gets transformed
      expr = quote do: x(i) + y(i)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be addition operation
      assert match?({:+, _, [_, _]}, transformed)

      {_, _, [left, right]} = transformed
      # Both sides should be transformed variable references preserving 'i'
      assert match?({:x, _, [_]}, left)
      assert match?({:y, _, [_]}, right)

      # Verify both preserve generator variable
      {_, _, [left_arg]} = left
      {_, _, [right_arg]} = right
      assert is_atom(left_arg) or (is_tuple(left_arg) and elem(left_arg, 0) == :i)
      assert is_atom(right_arg) or (is_tuple(right_arg) and elem(right_arg, 0) == :i)
    end

    test "preserves wildcard pattern in variable reference" do
      # Test that queen2d(:_, j) preserves wildcard correctly
      expr = quote do: queen2d(:_, j)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should preserve wildcard and generator variable
      assert match?({:queen2d, _, [:_, _]}, transformed)

      {_, _, [arg1, arg2]} = transformed
      # First arg should be wildcard
      assert arg1 == :_
      # Second arg should be generator variable 'j' (preserved)
      assert is_atom(arg2) or (is_tuple(arg2) and elem(arg2, 0) == :j)
    end

    test "transforms variable reference with numeric index" do
      # Test that x(1) (numeric index) gets transformed correctly
      expr = quote do: x(1)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be normalized function call
      assert match?({:x, _, [_]}, transformed)

      {_, _, [arg]} = transformed
      # Argument should be numeric literal (no transformation needed)
      assert arg == 1
    end

    test "transforms variable reference to format compatible with parse_expression_to_polynomial" do
      # Test that transformed AST can be processed by parse_expression_to_polynomial
      # This verifies the transformation produces the expected format
      expr = quote do: x(i)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Should be in format {:var_name, meta, [indices]} where indices can contain generator vars
      assert match?({:x, _, [_]}, transformed)

      # The format should be compatible with ExpressionParser.parse_expression_to_polynomial/3
      # which expects {var_name, meta, indices} where indices can be resolved with bindings
      {var_name, _meta, indices} = transformed
      assert var_name == :x
      assert is_list(indices)
      assert length(indices) == 1

      # The index should preserve generator variable for later resolution
      [index] = indices
      assert is_atom(index) or (is_tuple(index) and elem(index, 0) == :i)
    end

    test "transformed variable reference resolves correctly with bindings" do
      # Integration test: Verify that transformed AST can be resolved with bindings
      # This test should FAIL until variable reference resolution is fully implemented
      expr = quote do: x(i)

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Create a problem with variables using Problem.define to get generator context
      problem =
        Problem.define do
          new()
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      # Create bindings for generator variable i=1
      bindings = %{i: 1}

      # Parse the transformed expression with bindings
      # This should resolve x(i) to x_1 when i=1
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(transformed, bindings, problem)

      # Should resolve to polynomial referencing x(1) (new format)
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x(1)")
    end

    test "transformed 2D variable reference resolves correctly with bindings" do
      # Integration test: Verify that queen2d(i, :_) resolves correctly
      expr = quote do: sum(queen2d(i, :_))

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Create a problem with 2D variables using Problem.define
      problem =
        Problem.define do
          new()
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen")
        end

      # Create bindings for generator variable i=1
      bindings = %{i: 1}

      # Parse the transformed expression with bindings
      # This should resolve sum(queen2d(1, :_)) to queen2d_1_1 + queen2d_1_2
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(transformed, bindings, problem)

      # Should resolve to polynomial referencing queen2d_1_1 and queen2d_1_2
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "queen2d(1,1)")
      assert Enum.member?(vars, "queen2d(1,2)")
      # Should not reference queen2d(2,*) (different i value)
      refute Enum.member?(vars, "queen2d(2,1)")
      refute Enum.member?(vars, "queen2d(2,2)")
    end

    test "transformed variable reference resolves in constraint expression with bindings" do
      # Integration test: Verify that constraint expression x(i) >= 0 resolves correctly
      expr = quote do: x(i) >= 0

      transformed = AST.transform_constraint_expression_to_ast(expr)

      # Create a problem with variables using Problem.define
      problem =
        Problem.define do
          new()
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      # Create bindings for generator variable i=2
      bindings = %{i: 2}

      # Parse constraint expression - should extract left side
      {_, _, [left_expr, _right]} = transformed

      # Parse the left side with bindings
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(left_expr, bindings, problem)

      # Should resolve to polynomial referencing x_2
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x(2)")
      # Should not reference other x variables
      refute Enum.member?(vars, "x(1)")
      refute Enum.member?(vars, "x(3)")
    end
  end

  # T141d: Tests for transform_objective_expression_to_ast/1 variable refs
  # These tests are expected to FAIL until implementation is complete

  describe "transform_objective_expression_to_ast/1" do
    test "transforms variable reference with single generator variable" do
      # Test that x(i) where i is from generator gets transformed correctly
      expr = quote do: x(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should still be a function call AST, but normalized
      assert match?({:x, _, [_]}, transformed)

      # The argument should be preserved as generator variable 'i'
      {_, _, [arg]} = transformed
      # Should be atom 'i' or tuple {:i, _, _} - generator variable preserved
      assert is_atom(arg) or (is_tuple(arg) and elem(arg, 0) == :i)
    end

    test "transforms variable reference with 2D pattern matching" do
      # Test that queen2d(i, :_) gets transformed correctly
      expr = quote do: queen2d(i, :_)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be normalized function call preserving generator variable and wildcard
      assert match?({:queen2d, _, [_, :_]}, transformed)

      {_, _, [arg1, arg2]} = transformed
      # First arg should be generator variable 'i' (preserved for later resolution)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
    end

    test "transforms variable reference with multiple generator variables" do
      # Test that queen3d(i, :_, k) gets transformed correctly
      expr = quote do: queen3d(i, :_, k)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be normalized function call with 3 args
      assert match?({:queen3d, _, [_, :_, _]}, transformed)

      {_, _, [arg1, arg2, arg3]} = transformed
      # First arg should be generator variable 'i' (preserved)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
      # Third arg should be generator variable 'k' (preserved)
      assert is_atom(arg3) or (is_tuple(arg3) and elem(arg3, 0) == :k)
    end

    test "transforms variable reference in arithmetic expression" do
      # Test that objective expression like x(i) + y(i) gets transformed
      expr = quote do: x(i) + y(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be addition operation with transformed variable references
      assert match?({:+, _, [_, _]}, transformed)

      {_, _, [left, right]} = transformed
      # Both sides should be transformed variable references preserving 'i'
      assert match?({:x, _, [_]}, left)
      assert match?({:y, _, [_]}, right)

      # Verify both preserve generator variable
      {_, _, [left_arg]} = left
      {_, _, [right_arg]} = right
      assert is_atom(left_arg) or (is_tuple(left_arg) and elem(left_arg, 0) == :i)
      assert is_atom(right_arg) or (is_tuple(right_arg) and elem(right_arg, 0) == :i)
    end

    test "transforms variable reference with sum pattern" do
      # Test that sum(queen2d(i, :_)) gets transformed correctly
      expr = quote do: sum(queen2d(i, :_))

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be sum call with transformed variable reference
      assert match?({:sum, _, [{:queen2d, _, [_, :_]}]}, transformed)

      {_, _, [{:queen2d, _, [arg1, arg2]}]} = transformed
      # First arg should be generator variable 'i' (preserved for resolution)
      assert is_atom(arg1) or (is_tuple(arg1) and elem(arg1, 0) == :i)
      # Second arg should be wildcard
      assert arg2 == :_
    end

    test "transforms nested variable references in complex expression" do
      # Test that complex expression like x(i) + 2 * y(i) gets transformed
      expr = quote do: x(i) + 2 * y(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be addition operation
      assert match?({:+, _, [_, _]}, transformed)

      {_, _, [left, right]} = transformed
      # Left side should be transformed variable reference
      assert match?({:x, _, [_]}, left)
      # Right side should be multiplication
      assert match?({:*, _, [_, _]}, right)

      {_, _, [_, right_var]} = right
      assert match?({:y, _, [_]}, right_var)
    end

    test "preserves wildcard pattern in variable reference" do
      # Test that queen2d(:_, j) preserves wildcard correctly
      expr = quote do: queen2d(:_, j)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should preserve wildcard and generator variable
      assert match?({:queen2d, _, [:_, _]}, transformed)

      {_, _, [arg1, arg2]} = transformed
      # First arg should be wildcard
      assert arg1 == :_
      # Second arg should be generator variable 'j' (preserved)
      assert is_atom(arg2) or (is_tuple(arg2) and elem(arg2, 0) == :j)
    end

    test "transforms variable reference with numeric index" do
      # Test that x(1) (numeric index) gets transformed correctly
      expr = quote do: x(1)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be normalized function call
      assert match?({:x, _, [_]}, transformed)

      {_, _, [arg]} = transformed
      # Argument should be numeric literal (no transformation needed)
      assert arg == 1
    end

    test "transforms variable reference to format compatible with parse_expression_to_polynomial" do
      # Test that transformed AST can be processed by parse_expression_to_polynomial
      expr = quote do: x(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Should be in format {:var_name, meta, [indices]} where indices can contain generator vars
      assert match?({:x, _, [_]}, transformed)

      {var_name, _meta, indices} = transformed
      assert var_name == :x
      assert is_list(indices)
      assert length(indices) == 1

      # The index should preserve generator variable for later resolution
      [index] = indices
      assert is_atom(index) or (is_tuple(index) and elem(index, 0) == :i)
    end

    test "transformed variable reference resolves correctly with bindings" do
      # Integration test: Verify that transformed AST can be resolved with bindings
      # This test should FAIL until variable reference resolution is fully implemented
      expr = quote do: x(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Create a problem with variables using Problem.define to get generator context
      problem =
        Problem.define do
          new()
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      # Create bindings for generator variable i=1
      bindings = %{i: 1}

      # Parse the transformed expression with bindings
      # This should resolve x(i) to x_1 when i=1
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(transformed, bindings, problem)

      # Should resolve to polynomial referencing x(1) (new format)
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x(1)")
    end

    test "transformed 2D variable reference resolves correctly with bindings" do
      # Integration test: Verify that queen2d(i, :_) resolves correctly
      expr = quote do: sum(queen2d(i, :_))

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Create a problem with 2D variables using Problem.define
      problem =
        Problem.define do
          new()
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen")
        end

      # Create bindings for generator variable i=1
      bindings = %{i: 1}

      # Parse the transformed expression with bindings
      # This should resolve sum(queen2d(1, :_)) to queen2d_1_1 + queen2d_1_2
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(transformed, bindings, problem)

      # Should resolve to polynomial referencing queen2d_1_1 and queen2d_1_2
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "queen2d(1,1)")
      assert Enum.member?(vars, "queen2d(1,2)")
      # Should not reference queen2d(2,*) (different i value)
      refute Enum.member?(vars, "queen2d(2,1)")
      refute Enum.member?(vars, "queen2d(2,2)")
    end

    test "transformed variable reference resolves in objective expression with bindings" do
      # Integration test: Verify that objective expression x(i) + y(i) resolves correctly
      expr = quote do: x(i) + y(i)

      transformed = AST.transform_objective_expression_to_ast(expr)

      # Create a problem with variables using Problem.define
      problem =
        Problem.define do
          new()
          variables("x", [i <- 1..3], :binary, "Variable")
          variables("y", [i <- 1..3], :binary, "Variable")
        end

      # Create bindings for generator variable i=2
      bindings = %{i: 2}

      # Parse objective expression with bindings
      alias Dantzig.Problem.DSL.ExpressionParser
      poly = ExpressionParser.parse_expression_to_polynomial(transformed, bindings, problem)

      # Should resolve to polynomial referencing x(2) and y(2)
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x(2)")
      assert Enum.member?(vars, "y(2)")
      # Should not reference other x/y variables
      refute Enum.member?(vars, "x(1)")
      refute Enum.member?(vars, "x(3)")
      refute Enum.member?(vars, "y(1)")
      refute Enum.member?(vars, "y(3)")
    end
  end

  # T141e: Tests for transform_description_to_ast/1 interpolation
  # These tests are expected to FAIL until implementation is complete

  describe "transform_description_to_ast/1" do
    test "transforms description with single variable interpolation" do
      # Test that "Variable #{i}" gets transformed correctly
      desc = quote do: "Variable #{i}"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _}, transformed)

      # The variable reference should be normalized for later resolution
      # We'll verify this by checking the structure contains the variable reference
      {_, _, parts} = transformed
      # Should have at least 2 parts: string and interpolation
      assert length(parts) >= 2
    end

    test "transforms description with multiple variable interpolation" do
      # Test that "Variable #{i}_#{j}" gets transformed correctly
      desc = quote do: "Variable #{i}_#{j}"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _}, transformed)

      {_, _, parts} = transformed
      # Should have multiple parts including interpolations
      assert length(parts) >= 3
    end

    test "transforms description with no interpolation" do
      # Test that plain string descriptions are preserved
      desc = "Plain description"

      transformed = AST.transform_description_to_ast(desc)

      # Should remain unchanged
      assert transformed == desc
    end

    test "transforms description with numeric interpolation" do
      # Test that numeric interpolation works
      desc = quote do: "Value #{42}"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _}, transformed)
    end

    test "transforms description with expression interpolation" do
      # Test that expression interpolation works
      desc = quote do: "Sum #{i + j}"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _}, transformed)
    end

    test "transformed description resolves correctly with bindings" do
      # Integration test: Verify that transformed AST can be resolved with bindings
      # This test should FAIL until variable reference resolution is fully implemented
      desc = quote do: "Variable #{i}"

      transformed = AST.transform_description_to_ast(desc)

      # Create bindings for generator variable i=1
      bindings = %{i: 1}

      # The transformed AST should be evaluable with bindings to produce the final string
      # We need to evaluate the AST with bindings
      # This will require implementing the resolution logic
      result = evaluate_interpolated_description(transformed, bindings)

      # Should resolve to "Variable 1"
      assert result == "Variable 1"
    end

    test "transformed description with multiple variables resolves correctly with bindings" do
      # Integration test: Verify that multi-variable interpolation resolves correctly
      desc = quote do: "Position (#{i}, #{j})"

      transformed = AST.transform_description_to_ast(desc)

      # Create bindings for generator variables
      bindings = %{i: 2, j: 3}

      # Evaluate the transformed AST with bindings
      result = evaluate_interpolated_description(transformed, bindings)

      # Should resolve to "Position (2, 3)"
      assert result == "Position (2, 3)"
    end

    test "transformed description preserves string parts correctly" do
      # Test that string parts are preserved during transformation
      desc = quote do: "Prefix #{i} suffix"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _parts}, transformed)

      {_, _, parts} = transformed
      # First part should be "Prefix "
      assert List.first(parts) == "Prefix "
      # Last part should be " suffix"
      assert List.last(parts) == " suffix"
    end

    test "transformed description handles empty string parts" do
      # Test that empty string parts are handled correctly
      desc = quote do: "#{i}#{j}"

      transformed = AST.transform_description_to_ast(desc)

      # Should be a string interpolation AST
      assert match?({:<<>>, _, _}, transformed)
    end

    # Helper function to evaluate interpolated description AST with bindings
    # This simulates what the implementation should do
    defp evaluate_interpolated_description(ast, bindings) do
      # The transformed AST should have normalized generator variables to atoms
      # We need to evaluate it with bindings
      # Code.eval_quoted expects variables to be unbound, but our normalized AST
      # has atoms. We need to reconstruct the AST with variables that can be resolved

      # Walk the AST and replace normalized atoms with variable references that Code.eval_quoted can resolve
      evaluable_ast = reconstruct_evaluable_ast(ast, bindings)

      # Convert bindings to keyword list for Code.eval_quoted
      env = Enum.map(bindings, fn {k, v} -> {k, v} end)

      try do
        {result, _} = Code.eval_quoted(evaluable_ast, env)
        result
      rescue
        _ ->
          # If evaluation fails, it means the AST wasn't properly transformed
          # This is expected until T144 is implemented
          raise "Description AST not properly transformed for evaluation with bindings"
      end
    end

    # Reconstruct AST with variable references that Code.eval_quoted can resolve
    defp reconstruct_evaluable_ast(ast, bindings) do
      Macro.prewalk(ast, fn
        # Normalized atom that's in bindings - convert back to variable reference
        atom when is_atom(atom) ->
          if Map.has_key?(bindings, atom) do
            # Create a variable reference that Code.eval_quoted can resolve
            {atom, [], nil}
          else
            atom
          end

        other ->
          other
      end)
    end
  end

  # T141f: Tests for Problem.constraint/3 no-generator single constraints
  # These tests are expected to FAIL until implementation is complete

  describe "Problem.constraint/3" do
    test "adds single constraint without generators" do
      # Test that Problem.constraint/3 can add a single constraint
      # Note: Variable access macros are only available inside Problem.define blocks
      # So we need to test this differently - the actual usage would be inside define blocks
      # For now, we test that the function exists and can be called
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      # Problem.constraint should exist and accept constraint expression
      # In actual usage, this would be: Problem.constraint(problem, x(1) + x(2) + x(3) == 1, "Sum constraint")
      # But since we're outside the define block, we'll test with a quoted expression
      constraint_expr = quote do: x(1) + x(2) + x(3) == 1

      # Problem.constraint/3 now works - it can add constraints
      result = Problem.constraint(problem, constraint_expr, "Sum constraint")
      assert result != problem  # Should return a new problem
      assert map_size(result.constraints) > 0
    end

    test "adds single constraint without description" do
      # Test that Problem.constraint/3 works without description
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) >= 0

      # Problem.constraint/3 now works without description
      result = Problem.constraint(problem, constraint_expr)
      assert result != problem  # Should return a new problem
      assert map_size(result.constraints) > 0
    end

    test "adds single constraint with comparison operators" do
      # Test various comparison operators
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      # Test <= operator
      constraint_expr1 = quote do: x(1) <= 1

      # Problem.constraint/3 now works with comparison operators
      result1 = Problem.constraint(problem, constraint_expr1, "Less than or equal")
      assert result1 != problem
      assert map_size(result1.constraints) > 0

      # Test >= operator
      constraint_expr2 = quote do: x(2) >= 0

      result2 = Problem.constraint(problem, constraint_expr2, "Greater than or equal")
      assert result2 != problem
      assert map_size(result2.constraints) > 0

      # Test == operator
      constraint_expr3 = quote do: x(1) == 1

      result3 = Problem.constraint(problem, constraint_expr3, "Equal")
      assert result3 != problem
      assert map_size(result3.constraints) > 0
    end

    test "adds single constraint with arithmetic expressions" do
      # Test that arithmetic expressions work in constraints
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) + x(2) == 1

      # This should fail until T145 is implemented
      # Problem.constraint/3 now works with arithmetic expressions
      result = Problem.constraint(problem, constraint_expr, "Sum")
      assert result != problem
      assert map_size(result.constraints) > 0
    end

    test "adds single constraint with scaled variables" do
      # Test that scaled variables work: 2*x(1) + 3*x(2) <= 10
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: 2 * x(1) + 3 * x(2) <= 10

      # Problem.constraint/3 now works with scaled variables
      result = Problem.constraint(problem, constraint_expr, "Scaled constraint")
      assert result != problem
      assert map_size(result.constraints) > 0
    end

    test "adds single constraint with constant comparisons" do
      # Test constraints comparing to constants
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) >= 0

      # Problem.constraint/3 now works with constant comparisons
      result = Problem.constraint(problem, constraint_expr, "Non-negative")
      assert result != problem  # Should return a new problem
      assert map_size(result.constraints) > 0
    end

    test "adds multiple single constraints sequentially" do
      # Test that multiple constraints can be added sequentially
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end

      constraint_expr1 = quote do: x(1) >= 0
      constraint_expr2 = quote do: x(2) >= 0
      constraint_expr3 = quote do: x(3) >= 0

      # Problem.constraint/3 now works - can add multiple constraints sequentially
      result1 = Problem.constraint(problem, constraint_expr1, "Constraint 1")
      assert result1 != problem
      assert map_size(result1.constraints) > 0
      
      result2 = Problem.constraint(result1, constraint_expr2, "Constraint 2")
      assert result2 != result1
      assert map_size(result2.constraints) > map_size(result1.constraints)
      
      result3 = Problem.constraint(result2, constraint_expr3, "Constraint 3")
      assert result3 != result2
      assert map_size(result3.constraints) > map_size(result2.constraints)
    end

    test "preserves constraint name from description" do
      # Test that description becomes constraint name
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end

      constraint_expr = quote do: x(1) <= 1

      # Problem.constraint/3 now works and preserves constraint name from description
      result = Problem.constraint(problem, constraint_expr, "My constraint name")
      assert result != problem  # Should return a new problem
      assert map_size(result.constraints) > 0
      # Verify constraint name is preserved
      constraint = result.constraints |> Map.values() |> List.first()
      assert constraint.name == "My constraint name"
    end
  end

  # T039: Unit tests for Dantzig.Problem module core functionality

  describe "Problem.new/1" do
    test "creates a new problem with default values" do
      problem = Dantzig.Problem.new()

      assert problem.name == nil
      assert problem.description == nil
      assert problem.objective == Dantzig.Polynomial.const(0.0)
      assert problem.direction == nil
      assert problem.variable_defs == %{}
      assert problem.variables == %{}
      assert problem.constraints == %{}
      assert problem.variable_counter == 0
      assert problem.constraint_counter == 0
    end

    test "creates a new problem with name" do
      problem = Dantzig.Problem.new(name: "Test Problem")

      assert problem.name == "Test Problem"
      assert problem.description == nil
    end

    test "creates a new problem with description" do
      problem = Dantzig.Problem.new(description: "Test description")

      assert problem.name == nil
      assert problem.description == "Test description"
    end

    test "creates a new problem with both name and description" do
      problem = Dantzig.Problem.new(name: "Test", description: "Description")

      assert problem.name == "Test"
      assert problem.description == "Description"
    end
  end

  describe "Problem.new_variable/3" do
    test "creates a continuous variable with default bounds" do
      problem = Dantzig.Problem.new()
      {updated_problem, poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      assert Dantzig.Polynomial.variables(poly) == ["x"]
      assert Map.has_key?(updated_problem.variable_defs, "x")
      var_def = updated_problem.variable_defs["x"]
      assert var_def.name == "x"
      assert var_def.type == :continuous
      assert var_def.min_bound == nil
      assert var_def.max_bound == nil
    end

    test "creates a binary variable with default bounds [0, 1]" do
      problem = Dantzig.Problem.new()
      {updated_problem, poly} = Dantzig.Problem.new_variable(problem, "x", type: :binary)

      assert Dantzig.Polynomial.variables(poly) == ["x"]
      var_def = updated_problem.variable_defs["x"]
      assert var_def.type == :binary
      assert var_def.min_bound == 0
      assert var_def.max_bound == 1
    end

    test "creates a variable with custom bounds" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :continuous,
          min_bound: 5.0,
          max_bound: 10.0
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min_bound == 5.0
      assert var_def.max_bound == 10.0
    end

    test "creates a variable with description" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :continuous,
          description: "Amount of x"
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.description == "Amount of x"
    end

    test "creates binary variable with custom max bound" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :binary,
          max_bound: 2
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min_bound == 0
      assert var_def.max_bound == 2
    end

    test "creates binary variable with custom min bound" do
      problem = Dantzig.Problem.new()

      {updated_problem, _poly} =
        Dantzig.Problem.new_variable(problem, "x",
          type: :binary,
          min_bound: -1
        )

      var_def = updated_problem.variable_defs["x"]
      assert var_def.min_bound == -1
      assert var_def.max_bound == 1
    end
  end

  describe "Problem.add_constraint/2" do
    test "adds a constraint to the problem" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      updated_problem = Dantzig.Problem.add_constraint(problem, constraint)

      assert map_size(updated_problem.constraints) == 1
      assert updated_problem.constraint_counter == 1
    end

    test "generates unique constraint IDs" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint1 = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      constraint2 = Dantzig.Constraint.new_linear(x_poly, :>=, Dantzig.Polynomial.const(0.0))

      problem = Dantzig.Problem.add_constraint(problem, constraint1)
      problem = Dantzig.Problem.add_constraint(problem, constraint2)

      assert map_size(problem.constraints) == 2
      assert problem.constraint_counter == 2

      # Constraint IDs should be unique
      ids = Map.keys(problem.constraints)
      assert length(Enum.uniq(ids)) == 2
    end
  end

  describe "Problem.minimize/2 and Problem.maximize/2" do
    test "sets minimization objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      updated_problem = Dantzig.Problem.minimize(problem, x_poly)

      assert updated_problem.direction == :minimize
      assert updated_problem.objective == x_poly
    end

    test "sets maximization objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      updated_problem = Dantzig.Problem.maximize(problem, x_poly)

      assert updated_problem.direction == :maximize
      assert updated_problem.objective == x_poly
    end

    test "can change from minimize to maximize" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      assert problem.direction == :minimize

      problem = Dantzig.Problem.maximize(problem, x_poly)
      assert problem.direction == :maximize
    end
  end

  describe "Problem.set_objective/2" do
    test "sets objective without changing direction" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      assert problem.direction == :minimize

      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)
      problem = Dantzig.Problem.set_objective(problem, y_poly)

      # Direction unchanged
      assert problem.direction == :minimize
      assert problem.objective == y_poly
    end
  end

  describe "Problem.increment_objective/2" do
    test "adds to existing objective" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)

      problem = Dantzig.Problem.minimize(problem, x_poly)
      initial_objective = problem.objective

      problem = Dantzig.Problem.increment_objective(problem, y_poly)

      expected = Dantzig.Polynomial.add(initial_objective, y_poly)
      assert problem.objective == expected
    end
  end

  describe "Problem.get_variable/2" do
    test "retrieves existing variable definition" do
      problem = Dantzig.Problem.new()
      {problem, _poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      var_def = Dantzig.Problem.get_variable(problem, "x")

      assert var_def != nil
      assert var_def.name == "x"
      assert var_def.type == :continuous
    end

    test "returns nil for non-existent variable" do
      problem = Dantzig.Problem.new()

      var_def = Dantzig.Problem.get_variable(problem, "nonexistent")

      assert var_def == nil
    end
  end

  describe "Problem.get_constraint/2" do
    test "retrieves existing constraint" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      constraint = Dantzig.Constraint.new_linear(x_poly, :<=, Dantzig.Polynomial.const(10.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint)

      constraint_id = List.first(Map.keys(problem.constraints))
      retrieved = Dantzig.Problem.get_constraint(problem, constraint_id)

      assert retrieved != nil
      assert retrieved == constraint
    end

    test "returns nil for non-existent constraint" do
      problem = Dantzig.Problem.new()

      constraint = Dantzig.Problem.get_constraint(problem, "nonexistent")

      assert constraint == nil
    end
  end

  describe "Problem.get_variables_nd/2 and Problem.put_variables_nd/3" do
    test "stores and retrieves N-dimensional variable sets" do
      problem = Dantzig.Problem.new()
      {problem, x1_poly} = Dantzig.Problem.new_variable(problem, "x_1", type: :continuous)
      {problem, x2_poly} = Dantzig.Problem.new_variable(problem, "x_2", type: :continuous)

      var_map = %{1 => x1_poly, 2 => x2_poly}
      problem = Dantzig.Problem.put_variables_nd(problem, "x", var_map)

      retrieved = Dantzig.Problem.get_variables_nd(problem, "x")

      assert retrieved == var_map
    end

    test "returns nil for non-existent variable set" do
      problem = Dantzig.Problem.new()

      result = Dantzig.Problem.get_variables_nd(problem, "nonexistent")

      assert result == nil
    end
  end

  describe "Problem.new_variables/3" do
    test "creates multiple variables at once" do
      problem = Dantzig.Problem.new()

      {updated_problem, polys} =
        Dantzig.Problem.new_variables(problem, ["x", "y", "z"], type: :continuous)

      assert length(polys) == 3
      assert Map.has_key?(updated_problem.variable_defs, "x")
      assert Map.has_key?(updated_problem.variable_defs, "y")
      assert Map.has_key?(updated_problem.variable_defs, "z")
    end

    test "applies same options to all variables" do
      problem = Dantzig.Problem.new()

      {updated_problem, _polys} =
        Dantzig.Problem.new_variables(problem, ["x", "y"],
          type: :binary,
          min_bound: 0,
          max_bound: 1
        )

      x_def = updated_problem.variable_defs["x"]
      y_def = updated_problem.variable_defs["y"]

      assert x_def.type == :binary
      assert y_def.type == :binary
      assert x_def.min_bound == 0
      assert y_def.min_bound == 0
    end
  end

  describe "Problem.solve_for_all_variables/1" do
    test "solves constraints for all variables" do
      problem = Dantzig.Problem.new()
      {problem, x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)
      {problem, y_poly} = Dantzig.Problem.new_variable(problem, "y", type: :continuous)

      # Add constraint: x + y == 10
      sum_poly = Dantzig.Polynomial.add(x_poly, y_poly)
      constraint = Dantzig.Constraint.new_linear(sum_poly, :==, Dantzig.Polynomial.const(10.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint)

      # Add constraint: x - y == 0
      diff_poly = Dantzig.Polynomial.subtract(x_poly, y_poly)
      constraint2 = Dantzig.Constraint.new_linear(diff_poly, :==, Dantzig.Polynomial.const(0.0))
      problem = Dantzig.Problem.add_constraint(problem, constraint2)

      solved = Dantzig.Problem.solve_for_all_variables(problem)

      # Should have solutions for both x and y
      assert Map.has_key?(solved, "x")
      assert Map.has_key?(solved, "y")
    end

    test "returns empty map when no constraints" do
      problem = Dantzig.Problem.new()
      {problem, _x_poly} = Dantzig.Problem.new_variable(problem, "x", type: :continuous)

      solved = Dantzig.Problem.solve_for_all_variables(problem)

      assert solved == %{}
    end
  end
end
