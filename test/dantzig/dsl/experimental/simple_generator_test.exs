defmodule Dantzig.DSL.SimpleGeneratorTest do
  @moduledoc """
  The syntax in this module is _golden_.
  It should be considered the canonical way to write generator syntax.
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  test "Simple generator syntax" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    # 2 variables + 1 base
    assert map_size(problem.variables) == 3
    assert Map.has_key?(problem.variables, "qty_bread")
    assert Map.has_key?(problem.variables, "qty_milk")
  end

  test "Generator with objective" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(qty(:_)), :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil
  end

  # T141b: Tests for variable refs in constraints/objectives
  # These tests are expected to FAIL until implementation is complete

  test "variable refs in constraints with single generator variable" do
    # Test variable references like x(i) where i comes from generator context
    problem =
      Problem.define do
        new(name: "Variable Ref Constraint Test")
        variables("x", [i <- 1..3], :binary, "Variable")
        # Variable ref x(i) should resolve to x_1, x_2, x_3 for each i
        constraints([i <- 1..3], x(i) >= 0, "Non-negative constraint")
      end

    # Should create 3 constraints
    assert map_size(problem.constraints) == 3

    # Verify each constraint references the correct variable
    constraint_exprs = problem.constraints |> Map.values() |> Enum.map(& &1.left_hand_side)
    # Each constraint should reference x_1, x_2, or x_3
    assert Enum.any?(constraint_exprs, fn expr ->
             Dantzig.Polynomial.variables(expr) |> Enum.member?("x_1")
           end)

    assert Enum.any?(constraint_exprs, fn expr ->
             Dantzig.Polynomial.variables(expr) |> Enum.member?("x_2")
           end)

    assert Enum.any?(constraint_exprs, fn expr ->
             Dantzig.Polynomial.variables(expr) |> Enum.member?("x_3")
           end)
  end

  test "variable refs in constraints with 2D variables" do
    # Test variable references like queen2d(i, :_) where i comes from generator
    problem =
      Problem.define do
        new(name: "2D Variable Ref Constraint Test")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        # Variable ref queen2d(i, :_) should resolve to sum of queen2d_i_* for each i
        constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
      end

    # Should create 2 constraints (one for each i)
    assert map_size(problem.constraints) == 2

    # Verify constraints reference correct variables
    # First constraint should reference queen2d_1_1 and queen2d_1_2
    # Second constraint should reference queen2d_2_1 and queen2d_2_2
    constraint_exprs = problem.constraints |> Map.values() |> Enum.map(& &1.left_hand_side)

    # Check that we have constraints referencing queen2d_1_* and queen2d_2_*
    has_row1 =
      Enum.any?(constraint_exprs, fn expr ->
        vars = Dantzig.Polynomial.variables(expr)
        Enum.member?(vars, "queen2d_1_1") and Enum.member?(vars, "queen2d_1_2")
      end)

    has_row2 =
      Enum.any?(constraint_exprs, fn expr ->
        vars = Dantzig.Polynomial.variables(expr)
        Enum.member?(vars, "queen2d_2_1") and Enum.member?(vars, "queen2d_2_2")
      end)

    assert has_row1, "Should have constraint for row 1"
    assert has_row2, "Should have constraint for row 2"
  end

  test "variable refs in constraints with multiple generator variables" do
    # Test variable references like queen3d(i, :_, k) where i and k come from generators
    problem =
      Problem.define do
        new(name: "3D Variable Ref Constraint Test")
        variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..2], :binary, "Queen position")
        # Variable ref queen3d(i, :_, k) should resolve to sum of queen3d_i_*_k for each (i,k)
        constraints([i <- 1..2, k <- 1..2], sum(queen3d(i, :_, k)) == 1, "One queen per axis")
      end

    # Should create 4 constraints (2x2 = 4 combinations of i and k)
    assert map_size(problem.constraints) == 4

    # Verify constraints reference correct variables
    # Each constraint should reference two variables (queen3d_i_j_k for j=1,2)
    constraint_exprs = problem.constraints |> Map.values() |> Enum.map(& &1.left_hand_side)

    # Check that we have constraints for all combinations
    expected_combinations = [
      # i=1, k=1
      {"queen3d_1_1_1", "queen3d_1_2_1"},
      # i=1, k=2
      {"queen3d_1_1_2", "queen3d_1_2_2"},
      # i=2, k=1
      {"queen3d_2_1_1", "queen3d_2_2_1"},
      # i=2, k=2
      {"queen3d_2_1_2", "queen3d_2_2_2"}
    ]

    for {var1, var2} <- expected_combinations do
      has_constraint =
        Enum.any?(constraint_exprs, fn expr ->
          vars = Dantzig.Polynomial.variables(expr)
          MapSet.member?(vars, var1) and MapSet.member?(vars, var2)
        end)

      assert has_constraint, "Should have constraint for #{var1} and #{var2}"
    end
  end

  test "variable refs in objectives with generator variable" do
    # Test variable references like qty(food) in objectives where food comes from generator
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Variable Ref Objective Test")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        # Variable ref qty(food) in for comprehension should resolve to qty_bread, qty_milk
        objective(sum(for food <- food_names, do: qty(food)), :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil

    # Verify objective references both variables
    objective_vars = Dantzig.Polynomial.variables(problem.objective)
    assert Enum.member?(objective_vars, "qty_bread")
    assert Enum.member?(objective_vars, "qty_milk")
  end

  test "variable refs in objectives with 2D variables" do
    # Test variable references like queen2d(i, j) in objectives
    problem =
      Problem.define do
        new(name: "2D Variable Ref Objective Test")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        # Variable ref queen2d(i, j) should resolve to all queen2d_i_j variables
        objective(sum(for i <- 1..2, j <- 1..2, do: queen2d(i, j)), :maximize)
      end

    assert problem.direction == :maximize
    assert problem.objective != nil

    # Verify objective references all 2D variables
    objective_vars = Dantzig.Polynomial.variables(problem.objective)
    assert Enum.member?(objective_vars, "queen2d_1_1")
    assert Enum.member?(objective_vars, "queen2d_1_2")
    assert Enum.member?(objective_vars, "queen2d_2_1")
    assert Enum.member?(objective_vars, "queen2d_2_2")
  end

  test "variable refs with pattern matching in constraints" do
    # Test pattern matching variable refs like queen2d(:_, j)
    problem =
      Problem.define do
        new(name: "Pattern Variable Ref Constraint Test")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        # Variable ref queen2d(:_, j) should resolve to sum of queen2d_*_j for each j
        constraints([j <- 1..2], sum(queen2d(:_, j)) == 1, "One queen per column")
      end

    # Should create 2 constraints (one for each j)
    assert map_size(problem.constraints) == 2

    # Verify constraints reference correct variables
    constraint_exprs = problem.constraints |> Map.values() |> Enum.map(& &1.left_hand_side)

    # First constraint should reference queen2d_1_1 and queen2d_2_1 (j=1)
    # Second constraint should reference queen2d_1_2 and queen2d_2_2 (j=2)
    has_col1 =
      Enum.any?(constraint_exprs, fn expr ->
        vars = Dantzig.Polynomial.variables(expr)
        MapSet.member?(vars, "queen2d_1_1") and MapSet.member?(vars, "queen2d_2_1")
      end)

    has_col2 =
      Enum.any?(constraint_exprs, fn expr ->
        vars = Dantzig.Polynomial.variables(expr)
        MapSet.member?(vars, "queen2d_1_2") and MapSet.member?(vars, "queen2d_2_2")
      end)

    assert has_col1, "Should have constraint for column 1"
    assert has_col2, "Should have constraint for column 2"
  end

  test "variable refs with mixed pattern matching in constraints" do
    # Test mixed pattern matching like queen3d(i, :_, k)
    problem =
      Problem.define do
        new(name: "Mixed Pattern Variable Ref Test")
        variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..2], :binary, "Queen position")
        # Variable ref queen3d(i, :_, k) should resolve to sum of queen3d_i_*_k
        constraints([i <- 1..2, k <- 1..2], sum(queen3d(i, :_, k)) == 1, "One queen per axis")
      end

    # Should create 4 constraints (2x2 combinations)
    assert map_size(problem.constraints) == 4

    # Verify at least one constraint references expected variables
    constraint_exprs = problem.constraints |> Map.values() |> Enum.map(& &1.left_hand_side)

    # Should have constraint for queen3d_1_1_1 + queen3d_1_2_1
    has_expected =
      Enum.any?(constraint_exprs, fn expr ->
        vars = Dantzig.Polynomial.variables(expr)
        Enum.member?(vars, "queen3d_1_1_1") and Enum.member?(vars, "queen3d_1_2_1")
      end)

    assert has_expected, "Should have constraint with expected variable pattern"
  end
end
