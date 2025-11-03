defmodule Dantzig.ProblemTest do
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
end
