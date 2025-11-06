defmodule Dantzig.LPExamplesTest do
  @moduledoc """
  Tests for Linear Programming examples transcribed from OR-Notes by J.E. Beasley

  Source: https://people.brunel.ac.uk/~mastjjb/jeb/or/morelp.html

  These tests verify that our DSL correctly solves the LP problems
  and matches the solutions provided in the original source.
  """

  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  @moduletag :lp_examples

  describe "1997 UG Exam - Stock Maximization" do
    test "solves correctly" do
      # Problem data from the exam
      initial_stock_x = 30
      initial_stock_y = 90
      demand_x = 75
      demand_y = 95
      time_a_minutes = 40 * 60
      time_b_minutes = 35 * 60

      problem =
        Problem.define do
          new(name: "1997 UG Exam - Stock Maximization")

          variables("x", :continuous, min: 0)
          variables("y", :continuous, min: 0)

          constraints(50 * x + 24 * y <= time_a_minutes)
          constraints(30 * x + 33 * y <= time_b_minutes)
          constraints(x >= demand_x - initial_stock_x)
          constraints(y >= demand_y - initial_stock_y)

          objective(x + y - 50, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: x=45, y=6.25, objective=1.25
      assert_in_delta solution.variables["x"], 45.0, 0.01
      assert_in_delta solution.variables["y"], 6.25, 0.01
      assert_in_delta objective_value, 1.25, 0.01
    end
  end

  describe "1995 UG Exam - Production with Penalties" do
    test "forecasting works correctly" do
      # Test the forecasting function
      product1_demand = [23, 27, 34, 40]
      product2_demand = [11, 13, 15, 14]
      alpha = 0.7

      forecast_p1 = forecast_demand(product1_demand, alpha)
      forecast_p2 = forecast_demand(product2_demand, alpha)

      # Expected forecasts from source
      assert forecast_p1 == 37
      assert forecast_p2 == 14
    end

    test "optimization solves correctly" do
      # Using the forecasted demands
      forecast_p1 = 37
      forecast_p2 = 14

      problem =
        Problem.define do
          new(name: "1995 UG Exam - Production with Penalties")

          variables("x1", :continuous, min: 0, max: forecast_p1)
          variables("x2", :continuous, min: 0, max: forecast_p2)

          constraints(15 * x1 + 7 * x2 <= 20 * 60)
          constraints(25 * x1 + 45 * x2 <= 15 * 60)

          objective(13 * x1 + 5 * x2 - 125, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: x1=36, x2=0, profit=343
      assert_in_delta solution.variables["x1"], 36.0, 0.01
      assert_in_delta solution.variables["x2"], 0.0, 0.01
      assert_in_delta objective_value, 343.0, 0.01
    end

    # Helper function for exponential smoothing
    defp forecast_demand(demand_history, alpha) do
      smoothed = Enum.reduce(demand_history, [], fn demand, acc ->
        case acc do
          [] -> [demand]
          [last | _] -> [alpha * demand + (1 - alpha) * last | acc]
        end
      end)
      |> Enum.reverse()

      trunc(List.last(smoothed))
    end
  end

  describe "1994 UG Exam - Cost Optimization" do
    test "solves correctly" do
      problem =
        Problem.define do
          new(name: "1994 UG Exam - Cost Optimization")

          variables("x", :continuous, min: 10)
          variables("y", :continuous, min: 0)

          constraints(13 * x + 19 * y <= 2400)
          constraints(20 * x + 29 * y <= 2100)

          objective(17.1667 * x + 25.8667 * y, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: x=10, y=65.52, profit=1866.50
      assert_in_delta solution.variables["x"], 10.0, 0.01
      assert_in_delta solution.variables["y"], 65.52, 0.01
      assert_in_delta objective_value, 1866.50, 0.1  # Allow some tolerance for floating point
    end
  end

  describe "1992 UG Exam - Technological Constraints" do
    test "solves correctly" do
      problem =
        Problem.define do
          new(name: "1992 UG Exam - Technological Constraints")

          variables("xA", :continuous, min: 0)
          variables("xB", :continuous, min: 0)

          constraints(12 * xA + 25 * xB <= 1800)
          constraints(2 * xB <= 5 * xA)

          objective(3 * xA + 5 * xB, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: xA=81.8, xB=32.7, profit=408.9
      assert_in_delta solution.variables["xA"], 81.8, 0.1
      assert_in_delta solution.variables["xB"], 32.7, 0.1
      assert_in_delta objective_value, 408.9, 0.1
    end
  end

  describe "1988 UG Exam - Minimization with Equality" do
    test "solves correctly" do
      # Using substitution c = a + b
      problem =
        Problem.define do
          new(name: "1988 UG Exam - Minimization")

          variables("a", :continuous, min: 0)
          variables("b", :continuous, min: 0)

          constraints(a + b >= 11)
          constraints(a - b <= 5)
          constraints(7 * a + 12 * b >= 35)

          objective(10 * a + 11 * b, direction: :minimize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: a=8, b=3, objective=113
      assert_in_delta solution.variables["a"], 8.0, 0.01
      assert_in_delta solution.variables["b"], 3.0, 0.01
      assert_in_delta objective_value, 113.0, 0.01
    end
  end

  describe "1987 UG Exam - Standard Maximization" do
    test "solves correctly" do
      problem =
        Problem.define do
          new(name: "1987 UG Exam - Maximization")

          variables("x1", :continuous, min: 0)
          variables("x2", :continuous, min: 0)

          constraints(x1 + x2 <= 10)
          constraints(x1 - x2 >= 3)
          constraints(5 * x1 + 4 * x2 <= 35)

          objective(5 * x1 + 6 * x2, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: x1=47/9≈5.222, x2=20/9≈2.222, objective=355/9≈39.444
      assert_in_delta solution.variables["x1"], 47/9, 0.01
      assert_in_delta solution.variables["x2"], 20/9, 0.01
      assert_in_delta objective_value, 355/9, 0.01
    end
  end

  describe "1986 UG Exam - Carpenter Production" do
    test "solves correctly" do
      problem =
        Problem.define do
          new(name: "1986 UG Exam - Carpenter Production")

          variables("xT", :continuous, min: 0, max: 4)
          variables("xC", :continuous, min: 0)

          constraints(6 * xT + 3 * xC <= 40)
          constraints(xC >= 3 * xT)
          constraints(xT + 0.25 * xC <= 4)

          objective(30 * xT + 10 * xC, direction: :maximize)
        end

      {solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

      # Expected solution from source: xT=1.333, xC=10.667, profit=146.667
      assert_in_delta solution.variables["xT"], 4/3, 0.01
      assert_in_delta solution.variables["xC"], 32/3, 0.01  # 10.667 = 32/3
      assert_in_delta objective_value, 440/3, 0.01  # 146.667 = 440/3
    end
  end
end
