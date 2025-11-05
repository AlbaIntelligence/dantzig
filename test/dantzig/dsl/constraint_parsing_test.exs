defmodule Dantzig.DSL.ConstraintParsingTest do
  @moduledoc """
  Tests for constraint parsing functionality using the DSL parser.

  These tests verify that constraint expressions are properly parsed
  and integrated with the parentheses-based variable naming system.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  alias Dantzig.DSL.ConstraintParser

  setup do
    # Create a test problem with variables using the DSL
    problem =
      Problem.define do
        new(name: "test")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        variables("qty", [food <- ["apple", "banana"]], :continuous, "Food quantity")
      end

    %{problem: problem}
  end

  describe "simple constraint parsing" do
    test "queen2d(i, :_) == 1", %{problem: problem} do
      # Test queen2d(i, :_) == 1
      constraint_ast = quote do: queen2d(i, :_) == 1
      bindings = %{i: 1}

      result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 1
      # Should match variables with first index = 1
      assert String.contains?(inspect(result.left_hand_side), "queen2d")
    end

    test "queen2d(i, j) == 1 with specific binding", %{problem: problem} do
      # Test queen2d(i, j) == 1 with specific bindings
      constraint_ast = quote do: queen2d(i, j) == 1
      bindings = %{i: 1, j: 2}

      result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 1
    end
  end

  describe "sum constraint parsing" do
    test "sum(queen2d(:_, :_)) == 4", %{problem: problem} do
      # Test sum(queen2d(:_, :_)) == 4
      constraint_ast = quote do: sum(queen2d(:_, :_)) == 4

      result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 4
    end

    test "sum(qty(food)) <= 10", %{problem: problem} do
      # Test sum(qty(food)) <= 10
      constraint_ast = quote do: sum(qty(food)) <= 10

      result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :<=
      assert result.right_hand_side == 10
    end

    test "sum(qty(food)) >= 5", %{problem: problem} do
      # Test sum(qty(food)) >= 5
      constraint_ast = quote do: sum(qty(food)) >= 5

      result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :>=
      assert result.right_hand_side == 5
    end
  end

  describe "constraint with variable bindings" do
    test "queen2d(i, :_) == 1 with i = 1", %{problem: problem} do
      # Test queen2d(i, :_) == 1 with i = 1
      constraint_ast = quote do: queen2d(i, :_) == 1
      bindings = %{i: 1}

      result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 1
    end

    test "sum(queen2d(i, :_)) == 1 with i = 1", %{problem: problem} do
      # Test sum(queen2d(i, :_)) == 1 with i = 1
      constraint_ast = quote do: sum(queen2d(i, :_)) == 1
      bindings = %{i: 1}

      result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 1
    end
  end

  describe "constraint with variable right hand side" do
    test "sum(queen2d(:_, :_)) == n with n = 4", %{problem: problem} do
      # Test sum(queen2d(:_, :_)) == n with n = 4
      constraint_ast = quote do: sum(queen2d(:_, :_)) == n
      bindings = %{n: 4}

      result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :==
      assert result.right_hand_side == 4
    end
  end

  describe "error handling" do
    test "error handling for invalid constraint", %{problem: problem} do
      # Test invalid constraint expression
      constraint_ast = quote do: invalid_expression

      assert_raise ArgumentError, fn ->
        ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)
      end
    end

    test "error handling for unsupported constraint operator", %{problem: problem} do
      # Test unsupported constraint operator
      constraint_ast = quote do: queen2d(1, 1) !== 1

      assert_raise ArgumentError, fn ->
        ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)
      end
    end
  end

  describe "inequality constraints" do
    test "non-strict inequality <=", %{problem: problem} do
      constraint_ast = quote do: queen2d(1, 1) <= 1

      result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :<=
    end

    test "non-strict inequality >=", %{problem: problem} do
      constraint_ast = quote do: queen2d(1, 1) >= 0

      result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

      assert is_struct(result, Dantzig.Constraint)
      assert result.operator == :>=
    end
  end
end
