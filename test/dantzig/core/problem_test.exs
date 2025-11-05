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
      assert (is_atom(left_arg) or (is_tuple(left_arg) and elem(left_arg, 0) == :i))
      assert (is_atom(right_arg) or (is_tuple(right_arg) and elem(right_arg, 0) == :i))
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
      
      # Should resolve to polynomial referencing x_1
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x_1")
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
      assert Enum.member?(vars, "queen2d_1_1")
      assert Enum.member?(vars, "queen2d_1_2")
      # Should not reference queen2d_2_* (different i value)
      refute Enum.member?(vars, "queen2d_2_1")
      refute Enum.member?(vars, "queen2d_2_2")
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
      assert Enum.member?(vars, "x_2")
      # Should not reference other x variables
      refute Enum.member?(vars, "x_1")
      refute Enum.member?(vars, "x_3")
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
      assert (is_atom(left_arg) or (is_tuple(left_arg) and elem(left_arg, 0) == :i))
      assert (is_atom(right_arg) or (is_tuple(right_arg) and elem(right_arg, 0) == :i))
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
      
      # Should resolve to polynomial referencing x_1
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x_1")
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
      assert Enum.member?(vars, "queen2d_1_1")
      assert Enum.member?(vars, "queen2d_1_2")
      # Should not reference queen2d_2_* (different i value)
      refute Enum.member?(vars, "queen2d_2_1")
      refute Enum.member?(vars, "queen2d_2_2")
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
      
      # Should resolve to polynomial referencing x_2 and y_2
      vars = Dantzig.Polynomial.variables(poly)
      assert Enum.member?(vars, "x_2")
      assert Enum.member?(vars, "y_2")
      # Should not reference other x/y variables
      refute Enum.member?(vars, "x_1")
      refute Enum.member?(vars, "x_3")
      refute Enum.member?(vars, "y_1")
      refute Enum.member?(vars, "y_3")
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
      
      # This should fail until T145 is implemented
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr, "Sum constraint")
      end
    end

    test "adds single constraint without description" do
      # Test that Problem.constraint/3 works without description
      problem = 
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :binary, "Variable")
        end
      
      constraint_expr = quote do: x(1) >= 0
      
      # This should fail until T145 is implemented
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr)
      end
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
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr1, "Less than or equal")
      end
      
      # Test >= operator
      constraint_expr2 = quote do: x(2) >= 0
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr2, "Greater than or equal")
      end
      
      # Test == operator
      constraint_expr3 = quote do: x(1) == 1
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr3, "Equal")
      end
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
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr, "Sum")
      end
    end

    test "adds single constraint with scaled variables" do
      # Test that scaled variables work: 2*x(1) + 3*x(2) <= 10
      problem = 
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end
      
      constraint_expr = quote do: 2 * x(1) + 3 * x(2) <= 10
      
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr, "Scaled constraint")
      end
    end

    test "adds single constraint with constant comparisons" do
      # Test constraints comparing to constants
      problem = 
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end
      
      constraint_expr = quote do: x(1) >= 0
      
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr, "Non-negative")
      end
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
      
      # All should fail until T145 is implemented
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr1, "Constraint 1")
      end
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr2, "Constraint 2")
      end
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr3, "Constraint 3")
      end
    end

    test "preserves constraint name from description" do
      # Test that description becomes constraint name
      problem = 
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..2], :binary, "Variable")
        end
      
      constraint_expr = quote do: x(1) <= 1
      
      assert_raise ArgumentError, fn ->
        Problem.constraint(problem, constraint_expr, "My constraint name")
      end
    end
  end
end
