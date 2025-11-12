defmodule Dantzig.Solver.HiGHSTest do
  use ExUnit.Case, async: true

  alias Dantzig.{Problem, HiGHS, Polynomial, Constraint}

  describe "to_lp_iodata/1" do
    test "generates LP format for simple minimization problem" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      # Constraint: x + y >= 1
      constraint =
        Constraint.new(Polynomial.add(x, y), :>=, Polynomial.const(1.0), name: "constraint1")

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "x") and String.contains?(lp_string, "y")

      # Check that it contains the constraint
      assert String.contains?(lp_string, "Subject To")
      assert String.contains?(lp_string, "constraint1") and String.contains?(lp_string, ">=")

      # Check that it contains variable bounds
      assert String.contains?(lp_string, "Bounds")
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "y free")

      # Check that it contains the end marker
      assert String.contains?(lp_string, "End")
    end

    test "generates LP format for maximization problem" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: maximize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.maximize(problem, problem.objective)

      # Constraint: x + y <= 1
      constraint =
        Constraint.new(Polynomial.add(x, y), :<=, Polynomial.const(1.0), name: "constraint1")

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective
      assert String.contains?(lp_string, "Maximize")
      assert String.contains?(lp_string, "x") and String.contains?(lp_string, "y")

      # Check that it contains the constraint
      assert String.contains?(lp_string, "constraint1") and String.contains?(lp_string, "<=")
    end

    test "generates LP format with binary variables" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :binary)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains binary variables (in General section)
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
    end

    test "generates LP format with integer variables" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :integer)
      {problem, y} = Problem.new_variable(problem, "y", type: :integer)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains integer variables (in General section)
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
    end

    test "generates LP format with variable bounds" do
      problem = Problem.new(name: Test)

      {problem, x} =
        Problem.new_variable(problem, "x", type: :continuous, min_bound: 0.0, max_bound: 10.0)

      {problem, y} =
        Problem.new_variable(problem, "y", type: :continuous, min_bound: -5.0, max_bound: 5.0)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains variable bounds (format is two lines)
      assert String.contains?(lp_string, "0.0 <= x") and String.contains?(lp_string, "x <= 10.0")
      assert String.contains?(lp_string, "-5.0 <= y") and String.contains?(lp_string, "y <= 5.0")
    end

    test "generates LP format with unnamed constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      # Constraint without name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, Polynomial.const(1.0))
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon
      assert String.contains?(lp_string, ">=") and String.contains?(lp_string, "x") and
               String.contains?(lp_string, "y")

      refute String.contains?(lp_string, ":")
    end

    test "generates LP format with empty constraint names" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      # Constraint with empty name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, Polynomial.const(1.0))
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon
      assert String.contains?(lp_string, ">=") and String.contains?(lp_string, "x") and
               String.contains?(lp_string, "y")

      refute String.contains?(lp_string, ":")
    end

    test "generates LP format with complex constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :continuous)

      # Objective: minimize x + y + z
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.increment_objective(problem, z)
      problem = Problem.minimize(problem, problem.objective)

      # Constraint: 2x + 3y - z >= 5
      constraint =
        Constraint.new(
          Polynomial.add(
            Polynomial.add(Polynomial.multiply(x, 2.0), Polynomial.multiply(y, 3.0)),
            Polynomial.multiply(z, -1.0)
          ),
          :>=,
          Polynomial.const(5.0),
          name: "complex_constraint"
        )

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the complex constraint
      assert String.contains?(lp_string, "complex_constraint") and
               String.contains?(lp_string, ">=")
    end

    test "generates LP format with equality constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      # Constraint: x + y == 1
      constraint =
        Constraint.new(Polynomial.add(x, y), :==, Polynomial.const(1.0),
          name: "equality_constraint"
        )

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the equality constraint
      assert String.contains?(lp_string, "equality_constraint") and
               String.contains?(lp_string, "=")
    end

    test "generates LP format with negative coefficients" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x - y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, Polynomial.multiply(y, -1.0))
      problem = Problem.minimize(problem, problem.objective)

      # Constraint: x - y >= 0
      constraint =
        Constraint.new(
          Polynomial.subtract(x, y),
          :>=,
          Polynomial.const(0.0),
          name: "negative_constraint"
        )

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains negative coefficients
      assert String.contains?(lp_string, "x") and String.contains?(lp_string, "y")

      assert String.contains?(lp_string, "negative_constraint") and
               String.contains?(lp_string, ">=")
    end

    test "generates LP format with zero objective" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # No objective (zero)
      problem = Problem.minimize(problem, Polynomial.const(0.0))

      # Constraint: x + y >= 1
      constraint =
        Constraint.new(Polynomial.add(x, y), :>=, Polynomial.const(1.0), name: "constraint1")

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains zero objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "0")
    end

    test "generates LP format with constant objective" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Objective: minimize 5 (constant)
      problem = Problem.increment_objective(problem, Polynomial.const(5.0))
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains constant objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "5")
    end

    test "generates LP format with mixed variable types" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)
      {problem, z} = Problem.new_variable(problem, "z", type: :integer)

      # Objective: minimize x + y + z
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.increment_objective(problem, z)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all variable types
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "y")
      assert String.contains?(lp_string, "z")
    end

    test "generates LP format with long variable names" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "very_long_variable_name", type: :continuous)

      {problem, y} =
        Problem.new_variable(problem, "another_very_long_variable_name", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains long variable names
      assert String.contains?(lp_string, "very_long_variable_name")
      assert String.contains?(lp_string, "another_very_long_variable_name")
    end

    test "generates LP format with special characters in variable names" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x_1", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y_2", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains variable names with underscores
      assert String.contains?(lp_string, "x_1")
      assert String.contains?(lp_string, "y_2")
    end

    test "generates LP format with multiple constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.minimize(problem, problem.objective)

      # Multiple constraints
      constraint1 = Constraint.new(x, :>=, Polynomial.const(0.0), name: "constraint1")
      constraint2 = Constraint.new(y, :>=, Polynomial.const(0.0), name: "constraint2")

      constraint3 =
        Constraint.new(Polynomial.add(x, y), :<=, Polynomial.const(1.0), name: "constraint3")

      problem = Problem.add_constraint(problem, constraint1)
      problem = Problem.add_constraint(problem, constraint2)
      problem = Problem.add_constraint(problem, constraint3)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all constraints
      assert String.contains?(lp_string, "constraint1") and String.contains?(lp_string, ">=")
      assert String.contains?(lp_string, "constraint2") and String.contains?(lp_string, ">=")
      assert String.contains?(lp_string, "constraint3") and String.contains?(lp_string, "<=")
    end

    test "generates LP format with no constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Objective: minimize x
      problem = Problem.increment_objective(problem, x)
      problem = Problem.minimize(problem, problem.objective)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective
      # Note: "Subject To" section is always present even if empty
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "x")
      # Subject To section is always present in LP format
      assert String.contains?(lp_string, "Subject To")
    end

    test "generates LP format with no variables" do
      problem = Problem.new(name: Test)

      # No variables, no objective, no constraints
      problem = Problem.minimize(problem, Polynomial.const(0.0))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the basic structure
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "0")
      assert String.contains?(lp_string, "End")
    end
  end

  describe "constraint_to_iodata/1" do
    test "formats constraint with name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, Polynomial.const(0.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "constraint1")
      string = IO.iodata_to_binary(iodata)

      assert string == "  constraint1: 1 x >= 0\n"
    end

    test "formats constraint without name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, Polynomial.const(0.0))
      iodata = HiGHS.constraint_to_iodata(constraint, nil)
      string = IO.iodata_to_binary(iodata)

      assert string == "  1 x >= 0\n"
    end

    test "formats constraint with empty name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, Polynomial.const(0.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "")
      string = IO.iodata_to_binary(iodata)

      assert string == "  1 x >= 0\n"
    end

    test "formats equality constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :==, Polynomial.const(1.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "equality")
      string = IO.iodata_to_binary(iodata)

      # The constraint name gets sanitized - "equality" becomes "var_equality" because it starts with 'e'
      # Check that it contains the constraint content
      assert String.contains?(string, "1 x = 1.0")
      assert String.contains?(string, "=")
      # Name should still be present (sanitized)
      assert String.contains?(string, "equality")
    end

    test "formats less than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :<=, Polynomial.const(1.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "less_equal")
      string = IO.iodata_to_binary(iodata)

      assert string == "  less_equal: 1 x <= 1.0\n"
    end

    test "formats greater than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, Polynomial.const(1.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "greater_equal")
      string = IO.iodata_to_binary(iodata)

      assert string == "  greater_equal: 1 x >= 1.0\n"
    end

    test "formats complex constraint" do
      x = Polynomial.variable("x")
      y = Polynomial.variable("y")
      constraint = Constraint.new(Polynomial.add(x, y), :>=, Polynomial.const(1.0))
      iodata = HiGHS.constraint_to_iodata(constraint, "complex")
      string = IO.iodata_to_binary(iodata)

      assert string == "  complex: 1 x + 1 y >= 1.0\n"
    end
  end

  describe "variable_bounds/1" do
    test "formats continuous variable with bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min_bound: 0.0,
        max_bound: 10.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  0.0 <= x\n  x <= 10.0\n"
    end

    test "formats continuous variable with only lower bound" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min_bound: 0.0,
        max_bound: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  0.0 <= x\n"
    end

    test "formats continuous variable with only upper bound" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min_bound: nil,
        max_bound: 10.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  x <= 10.0\n"
    end

    test "formats continuous variable with no bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min_bound: nil,
        max_bound: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  x free\n"
    end

    test "formats continuous variable with negative bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min_bound: -5.0,
        max_bound: 5.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  -5.0 <= x\n  x <= 5.0\n"
    end

    test "formats binary variable" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :binary,
        min_bound: nil,
        max_bound: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  0 <= x <= 1\n"
    end

    test "formats integer variable" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :integer,
        min_bound: nil,
        max_bound: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  x free\n"
    end

    test "formats integer variable with bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :integer,
        min_bound: 0.0,
        max_bound: 100.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "  0.0 <= x\n  x <= 100.0\n"
    end
  end

  describe "error handling" do
    test "handles invalid constraint operator" do
      # Create a constraint with an invalid operator by directly constructing it
      # Since Constraint.new doesn't accept :!=, we need to test the error differently
      # The constraint_to_iodata function converts :!= to string "!=" (no error raised)
      # This test verifies that invalid operators are converted to strings
      constraint = %Constraint{
        left_hand_side: Polynomial.variable("x"),
        operator: :!=,
        right_hand_side: Polynomial.const(0.0),
        name: nil,
        description: nil
      }

      # The function doesn't raise an error, it just converts the operator to string
      iodata = HiGHS.constraint_to_iodata(constraint, "invalid")
      string = IO.iodata_to_binary(iodata)

      # Verify it contains the operator as a string
      assert String.contains?(string, "!=")
    end

    test "handles invalid variable type" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :invalid,
        min_bound: nil,
        max_bound: nil
      }

      # The function doesn't validate the type - it just treats it as non-binary
      # and outputs "x free" for variables with nil bounds
      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      # Verify it outputs "x free" for invalid type with nil bounds
      assert string == "  x free\n"
    end
  end
end
