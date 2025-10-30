defmodule Dantzig.DSL.EdgeCaseTests do
  use ExUnit.Case

  alias Dantzig.Problem

  describe "Edge Cases and Error Conditions" do
    test "empty generators should raise error" do
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Test")
          # Empty generator list - should work
          variables("x", [], :continuous, "Variable x")
        end
      end
    end

    test "invalid variable type should raise error" do
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Test")
          variables("x", [i <- 1..3], :invalid_type, "Variable x")
        end
      end
    end

    test "invalid constraint operator should raise error" do
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          # Invalid operator
          constraints(x < 5, "Constraint")
        end
      end
    end

    test "undefined variable in constraint should raise error" do
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          # y is not defined
          constraints(y <= 5, "Constraint")
        end
      end
    end

    test "invalid objective direction should raise error" do
      assert_raise ArgumentError, fn ->
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          objective(x, :invalid)
        end
      end
    end

    test "very large problem should handle gracefully" do
      # Test with larger but reasonable problem size
      problem =
        Problem.define do
          new(name: "Large Problem")
          variables("x", [i <- 1..20], :binary, "Binary variable")
          constraints([i <- 1..20], x(i) <= 1, "Constraint #{i}")
          objective(sum(for i <- 1..20, do: x(i)), :maximize)
        end

      # Should not crash during problem creation
      assert problem != nil
      assert map_size(problem.variables) > 0
    end

    test "constraint with no variables should handle gracefully" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          # Constant constraint
          constraints(5 <= 10, "Constant constraint")
          objective(x, :maximize)
        end

      assert problem != nil
    end

    test "problem with no constraints should work" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          objective(x, :maximize)
        end

      assert problem != nil
      assert problem.direction == :maximize
    end
  end

  describe "Boundary Conditions" do
    test "single variable problem" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          constraints(x <= 5, "Constraint")
          objective(x, :maximize)
        end

      assert problem != nil
      assert map_size(problem.variables) == 1
    end

    test "zero bounds" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          constraints(x == 0, "Constraint")
          objective(x, :maximize)
        end

      assert problem != nil
    end

    test "very small coefficients" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          variables("y", [], :continuous, "Variable y")
          constraints(0.0001 * x + 0.0001 * y <= 1, "Constraint")
          objective(x + y, :maximize)
        end

      assert problem != nil
    end
  end

  describe "Complex Expression Handling" do
    test "nested expressions" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x", [], :continuous, "Variable x")
          variables("y", [], :continuous, "Variable y")
          variables("z", [], :continuous, "Variable z")

          # Complex nested constraint
          constraints(2 * (x + y) - 3 * z <= 10, "Complex constraint")
          objective(x + 2 * y + 3 * z, :maximize)
        end

      assert problem != nil
    end

    test "expression with many terms" do
      problem =
        Problem.define do
          new(name: "Test")
          variables("x1", [], :continuous, "Variable x1")
          variables("x2", [], :continuous, "Variable x2")
          variables("x3", [], :continuous, "Variable x3")
          variables("x4", [], :continuous, "Variable x4")
          variables("x5", [], :continuous, "Variable x5")

          # Constraint with many variables
          constraints(x1 + x2 + x3 + x4 + x5 <= 100, "Constraint")
          objective(x1 + x2 + x3 + x4 + x5, :maximize)
        end

      assert problem != nil
    end
  end
end
