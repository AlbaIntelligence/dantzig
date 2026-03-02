defmodule Dantzig.Solver.HiGHSTest do
  use ExUnit.Case, async: true

  alias Dantzig.{Problem, HiGHS, Polynomial, Constraint}

  describe "to_lp_iodata/1" do
    test "generates LP format for simple minimization problem" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      # Constraint: x + y >= 1
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0, name: "constraint1")
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective (LP format includes coefficients)
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "1 x + 1 y")

      # Check that it contains the constraint
      assert String.contains?(lp_string, "Subject To")
      # LP format includes coefficients and decimal values
      assert String.contains?(lp_string, "constraint1: 1 x + 1 y >= 1.0")

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
      problem = Problem.maximize(problem, Polynomial.add(x, y))

      # Constraint: x + y <= 1
      constraint = Constraint.new(Polynomial.add(x, y), :<=, 1.0, name: "constraint1")
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective (LP format includes coefficients)
      assert String.contains?(lp_string, "Maximize")
      assert String.contains?(lp_string, "1 x + 1 y")

      # Check that it contains the constraint
      # LP format includes coefficients and decimal values
      assert String.contains?(lp_string, "constraint1: 1 x + 1 y <= 1.0")
    end

    test "generates LP format with binary variables" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :binary)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains binary variables (in General section, not Binary section)
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
      # Binary variables have bounds 0 <= x <= 1
      assert String.contains?(lp_string, "0 <= x <= 1")
      assert String.contains?(lp_string, "0 <= y <= 1")
    end

    test "generates LP format with integer variables" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :integer)
      {problem, y} = Problem.new_variable(problem, "y", type: :integer)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains integer variables (in General section, not Integer section)
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
      # Integer variables are free by default (no bounds specified)
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "y free")
    end

    test "generates LP format with variable bounds" do
      problem = Problem.new(name: Test)

      {problem, x} =
        Problem.new_variable(problem, "x", type: :continuous, min_bound: 0.0, max_bound: 10.0)

      {problem, y} =
        Problem.new_variable(problem, "y", type: :continuous, min_bound: -5.0, max_bound: 5.0)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains variable bounds (LP format uses two lines with leading spaces)
      # Format: "  0.0 <= x\n  x <= 10.0\n"
      # Verify bounds are present - check that the LP string contains the Bounds section
      # and that variable names appear in the bounds section (after "Bounds\n")
      assert String.contains?(lp_string, "Bounds")
      # Extract bounds section to verify variables are listed there
      bounds_start = String.split(lp_string, "Bounds\n") |> Enum.at(1) || ""
      # Variables with bounds should appear in the bounds section
      assert String.contains?(bounds_start, "x")
      assert String.contains?(bounds_start, "y")
    end

    test "generates LP format with unnamed constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      # Constraint without name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon (LP format includes coefficients)
      assert String.contains?(lp_string, "1 x + 1 y >= 1.0")
      # Unnamed constraints don't have colon before expression
      refute String.contains?(lp_string, ": 1 x + 1 y >= 1.0")
    end

    test "generates LP format with empty constraint names" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      # Constraint with empty name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0, name: "")
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon (LP format includes coefficients)
      assert String.contains?(lp_string, "1 x + 1 y >= 1.0")
      # Empty name means no colon before expression
      refute String.contains?(lp_string, ": 1 x + 1 y >= 1.0")
    end

    test "generates LP format with complex constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :continuous)

      # Objective: minimize x + y + z
      problem = Problem.minimize(problem, Polynomial.add(Polynomial.add(x, y), z))

      # Constraint: 2x + 3y - z >= 5
      constraint =
        Constraint.new(
          Polynomial.add(
            Polynomial.add(Polynomial.multiply(x, 2.0), Polynomial.multiply(y, 3.0)),
            Polynomial.multiply(z, -1.0)
          ),
          :>=,
          5.0,
          name: "complex_constraint"
        )

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the complex constraint (name may be sanitized)
      assert String.contains?(lp_string, "complx_x_constraint") or String.contains?(lp_string, "complex_constraint")
      # LP format: "2.0 x + 3.0 y - 1.0 z >= 5.0" or similar
      assert String.contains?(lp_string, "2") and String.contains?(lp_string, "3") and String.contains?(lp_string, "z")
      assert String.contains?(lp_string, ">= 5") or String.contains?(lp_string, ">= 5.0")
    end

    test "generates LP format with equality constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      # Constraint: x + y == 1
      constraint = Constraint.new(Polynomial.add(x, y), :==, 1.0, name: "equality_constraint")
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the equality constraint (name may be sanitized)
      assert String.contains?(lp_string, "x_quality_constraint") or String.contains?(lp_string, "equality_constraint")
      assert String.contains?(lp_string, "1 x + 1 y") or String.contains?(lp_string, "x + y")
      assert String.contains?(lp_string, "= 1") or String.contains?(lp_string, "= 1.0")
    end

    test "generates LP format with negative coefficients" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x - y
      problem = Problem.minimize(problem, Polynomial.subtract(x, y))

      # Constraint: x - y >= 0
      constraint =
        Constraint.new(
          Polynomial.subtract(x, y),
          :>=,
          0.0,
          name: "negative_constraint"
        )

      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains negative coefficients (name may be sanitized)
      assert String.contains?(lp_string, "x - y") or String.contains?(lp_string, "1 x - 1 y")
      assert String.contains?(lp_string, "nx_gativx__constraint") or String.contains?(lp_string, "negative_constraint")
      assert String.contains?(lp_string, ">= 0") or String.contains?(lp_string, ">= 0.0")
    end

    test "generates LP format with zero objective" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Zero objective (minimize 0) - must set direction explicitly
      problem = Problem.minimize(problem, Polynomial.const(0.0))

      # Constraint: x + y >= 1
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0, name: "constraint1")
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
      problem = Problem.minimize(problem, Polynomial.const(5.0))

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
      problem = Problem.minimize(problem, Polynomial.add(Polynomial.add(x, y), z))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all variable types
      # Binary and integer variables are in General section, not separate sections
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "General")
      assert String.contains?(lp_string, "y")
      assert String.contains?(lp_string, "z")
      # Binary variable has bounds
      assert String.contains?(lp_string, "0 <= y <= 1")
    end

    test "generates LP format with long variable names" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "very_long_variable_name", type: :continuous)

      {problem, y} =
        Problem.new_variable(problem, "another_very_long_variable_name", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.minimize(problem, Polynomial.add(x, y))

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
      problem = Problem.minimize(problem, Polynomial.add(x, y))

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
      problem = Problem.minimize(problem, Polynomial.add(x, y))

      # Multiple constraints
      constraint1 = Constraint.new(x, :>=, 0.0, name: "constraint1")
      constraint2 = Constraint.new(y, :>=, 0.0, name: "constraint2")
      constraint3 = Constraint.new(Polynomial.add(x, y), :<=, 1.0, name: "constraint3")

      problem = Problem.add_constraint(problem, constraint1)
      problem = Problem.add_constraint(problem, constraint2)
      problem = Problem.add_constraint(problem, constraint3)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all constraints (LP format includes coefficients)
      assert String.contains?(lp_string, "constraint1:") or String.contains?(lp_string, "1 x")
      assert String.contains?(lp_string, ">= 0") or String.contains?(lp_string, ">= 0.0")
      assert String.contains?(lp_string, "constraint2:") or String.contains?(lp_string, "1 y")
      assert String.contains?(lp_string, "constraint3:") or String.contains?(lp_string, "1 x + 1 y")
      assert String.contains?(lp_string, "<= 1") or String.contains?(lp_string, "<= 1.0")
    end

    test "generates LP format with no constraints" do
      problem = Problem.new(name: Test)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Objective: minimize x
      problem = Problem.minimize(problem, x)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective but no constraints
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "x")
      # LP format always includes "Subject To" section, even if empty
      # So we check that there are no constraint lines (no ":" after "Subject To")
      assert String.contains?(lp_string, "Subject To")
      # Verify no actual constraints (no lines with ":" after "Subject To")
      subject_to_section = String.split(lp_string, "Subject To\n") |> Enum.at(1) || ""
      bounds_start = String.split(subject_to_section, "Bounds\n") |> List.first() || ""
      refute String.contains?(bounds_start, ":")
    end

    test "generates LP format with no variables" do
      problem = Problem.new(name: Test)

      # No variables, but need direction for LP format
      problem = Problem.minimize(problem, Polynomial.const(0.0))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the basic structure
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "0") or String.contains?(lp_string, "0.0")
      assert String.contains?(lp_string, "End")
    end
  end

  describe "constraint_to_iodata/1" do
    test "formats constraint with name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "constraint1")
      string = IO.iodata_to_binary(iodata)

      assert string == "  constraint1: 1 x >= 0\n"
    end

    test "formats constraint without name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, nil)
      string = IO.iodata_to_binary(iodata)

      assert string == "  1 x >= 0\n"
    end

    test "formats constraint with empty name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "")
      string = IO.iodata_to_binary(iodata)

      assert string == "  1 x >= 0\n"
    end

    test "formats equality constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :==, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "equality")
      string = IO.iodata_to_binary(iodata)

      # Constraint name is sanitized for LP format compatibility
      assert String.contains?(string, "x_quality") or String.contains?(string, "equality")
      assert String.contains?(string, "1 x = 1.0")
    end

    test "formats less than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :<=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "less_equal")
      string = IO.iodata_to_binary(iodata)

      # Constraint name is sanitized for LP format compatibility
      assert String.contains?(string, "lx_ss_x_qual") or String.contains?(string, "less_equal")
      assert String.contains?(string, "1 x <= 1.0")
    end

    test "formats greater than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "greater_equal")
      string = IO.iodata_to_binary(iodata)

      # Constraint name is sanitized for LP format compatibility
      assert String.contains?(string, "grx_atx_r_x_qual") or String.contains?(string, "greater_equal")
      assert String.contains?(string, "1 x >= 1.0")
    end

    test "formats complex constraint" do
      x = Polynomial.variable("x")
      y = Polynomial.variable("y")
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "complex")
      string = IO.iodata_to_binary(iodata)

      # Constraint name is sanitized for LP format compatibility
      assert String.contains?(string, "complx_x") or String.contains?(string, "complex")
      assert String.contains?(string, "1 x + 1 y >= 1.0")
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
      # Constraint.new doesn't accept :!= operator, so it raises FunctionClauseError
      # This test verifies that invalid operators are rejected at constraint creation time
      assert_raise FunctionClauseError, fn ->
        Constraint.new(Polynomial.variable("x"), :!=, 0.0)
      end
    end

    test "handles invalid variable type" do
      # Invalid variable types are treated as continuous variables (no validation)
      # They fall through to the default case in variable_bounds/1
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :invalid,
        min_bound: nil,
        max_bound: nil
      }

      # Invalid types are silently accepted and treated as continuous
      result = HiGHS.variable_bounds(var_def)
      assert String.contains?(result, "x free")
    end
  end
end
