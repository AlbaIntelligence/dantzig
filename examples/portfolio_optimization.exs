#!/usr/bin/env elixir

# Portfolio Optimization Problem Example
# ======================================
#
# This example demonstrates Portfolio Optimization using the Dantzig DSL.
# Portfolio optimization is fundamental to modern finance and investment management,
# with applications in asset allocation, risk management, and investment strategy.
#
# BUSINESS CONTEXT:
# An investment manager needs to allocate capital across multiple investment assets
# to maximize expected return while controlling portfolio risk (measured by variance).
# This is a classic mean-variance optimization problem that balances return and risk.
#
# Real-world applications:
# - Mutual fund and ETF management
# - Pension fund asset allocation
# - Individual investment portfolio construction
# - Risk management and hedging strategies
# - Robo-advisor investment algorithms
# - Corporate capital allocation decisions
#
# MATHEMATICAL FORMULATION:
# Variables: x[i] = proportion of portfolio invested in asset i
# Parameters:
#   - return[i] = expected return of asset i
#   - variance[i] = variance of returns for asset i
#   - covariance[i,j] = covariance between returns of assets i and j
#   - budget = total investment budget (usually normalized to 1)
#   - risk_tolerance = maximum acceptable portfolio risk
#   - N = number of assets
#
# Constraints:
#   - Budget constraint: Σi x[i] = 1 (invest all available capital)
#   - Non-negativity: x[i] >= 0 for all i (no short selling)
#   - Risk constraint: Portfolio variance <= risk_tolerance
#
# Objective: Maximize expected return: maximize Σi return[i] * x[i]
# Note: Portfolio variance = Σi Σj covariance[i,j] * x[i] * x[j]
#
# This is a quadratic programming problem due to the variance terms,
# but for this demonstration we'll use a linear approximation.
#
# DSL SYNTAX EXPLANATION:
# - Single set of continuous variables representing portfolio weights
# - Linear constraints for budget and non-negativity
# - Quadratic objective terms approximated by linear constraints
# - Risk-return tradeoff modeling through constraints
#
# COMMON GOTCHAS:
# 1. **Portfolio Weights**: Variables represent proportions (sum to 1.0)
# 2. **Short Selling**: This example assumes no short selling (x[i] >= 0)
# 3. **Risk Modeling**: True portfolio variance is quadratic (Σ Σ covariance * x[i] * x[j])
# 4. **Linear Approximation**: Using linear risk proxy for demonstration
# 5. **Budget Constraint**: Ensure portfolio weights sum to exactly 1.0
# 6. **Return-Risk Tradeoff**: Higher expected returns often require accepting more risk
# 7. **Correlation Effects**: Diversification benefits from low/negative correlations

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the assets in the investment universe
assets = ["US_Stocks", "International_Stocks", "Bonds", "REITs", "Commodities"]

# Expected annual returns (as percentages)
expected_returns = %{
  "US_Stocks" => 10.5,
  "International_Stocks" => 9.2,
  "Bonds" => 4.8,
  "REITs" => 8.7,
  "Commodities" => 6.3
}

# Risk levels (annualized standard deviation as percentage)
risk_levels = %{
  "US_Stocks" => 18.0,
  "International_Stocks" => 20.0,
  "Bonds" => 6.5,
  "REITs" => 22.0,
  "Commodities" => 25.0
}

# Maximum allocation constraints (institutional guidelines)
max_allocation = %{
  # Max 40% US Stocks
  "US_Stocks" => 0.40,
  # Max 25% International
  "International_Stocks" => 0.25,
  # Max 60% Bonds
  "Bonds" => 0.60,
  # Max 15% REITs
  "REITs" => 0.15,
  # Max 20% Commodities
  "Commodities" => 0.20
}

# Risk tolerance (maximum portfolio risk level)
# Maximum 12% portfolio standard deviation
max_portfolio_risk = 12.0

IO.puts("Portfolio Optimization Problem")
IO.puts("================================")
IO.puts("Investment universe: #{Enum.join(assets, ", ")}")
IO.puts("Portfolio budget: $1,000,000")
IO.puts("Maximum acceptable risk: #{max_portfolio_risk}%")
IO.puts("")

IO.puts("Asset Analysis:")
IO.puts("================")

Enum.each(assets, fn asset ->
  return_rate = expected_returns[asset]
  risk = risk_levels[asset]
  max_alloc = max_allocation[asset] * 100

  IO.puts("  #{asset}:")
  IO.puts("    Expected Return: #{return_rate}%")
  IO.puts("    Risk Level: #{risk}%")
  IO.puts("    Maximum Allocation: #{max_alloc}%")
  IO.puts("")
end)

IO.puts("Investment Guidelines:")

Enum.each(assets, fn asset ->
  max_alloc = max_allocation[asset] * 100
  IO.puts("  #{asset}: Max #{max_alloc}% due to diversification requirements")
end)

IO.puts("")

# Create the optimization problem
# Note: This is a simplified linear approximation of the true quadratic problem
problem =
  Problem.define model_parameters: %{
                   assets: assets,
                   expected_returns: expected_returns,
                   risk_levels: risk_levels,
                   max_allocation: max_allocation,
                   max_portfolio_risk: max_portfolio_risk
                 } do
    new(
      name: "Portfolio Optimization",
      description: "Maximize expected return subject to risk and allocation constraints"
    )

    # Decision variables: x[i] = proportion of portfolio invested in asset i
    variables(
      "weight",
      [asset <- assets],
      :continuous,
      min: 0.0,
      max: max_allocation[asset],
      description: "Portfolio weight for each asset"
    )

    # Constraint 1: Budget constraint - all money must be invested
    constraints(
      sum(for asset <- assets, do: weight(asset)) == 1.0,
      "Total allocation equals 100%"
    )

    # Constraint 2: Risk constraint - portfolio risk cannot exceed tolerance
    # Simplified linear approximation of portfolio variance
    # (True variance requires quadratic terms: Σ Σ covariance * x[i] * x[j])
    constraints(
      sum(
        for asset <- assets do
          weight(asset) * risk_levels[asset] / 100.0
        end
      ) <= max_portfolio_risk / 100.0,
      "Portfolio risk within tolerance"
    )

    # Objective: Maximize expected portfolio return
    objective(
      sum(
        for asset <- assets do
          weight(asset) * expected_returns[asset] / 100.0
        end
      ),
      direction: :maximize
    )
  end

IO.puts("Solving the portfolio optimization problem...")
result = Problem.solve(problem, print_optimizer_input: false)

case result do
  {solution, objective_value} ->
    IO.puts("\nSolution:")
    IO.puts("=========")
    IO.puts("Expected Portfolio Return: #{Float.round(objective_value * 100, 2)}%")
    IO.puts("")

    IO.puts("Optimal Portfolio Allocation:")
    total_value = 1_000_000
    total_return_value = 0
    portfolio_risk = 0

    Enum.each(assets, fn asset ->
      var_name = "weight_#{asset}"
      weight = solution.variables[var_name] || 0
      asset_value = total_value * weight
      return_rate = expected_returns[asset]

      total_return_value = total_return_value + asset_value * (return_rate / 100.0)
      portfolio_risk = portfolio_risk + weight * (risk_levels[asset] / 100.0)

      if weight > 0.001 do
        IO.puts(
          "  #{asset}: #{Float.round(weight * 100, 1)}% ($#{Float.round(asset_value, 0)}) - Expected Return: #{return_rate}%"
        )
      end
    end)

    IO.puts("")
    IO.puts("Portfolio Analysis:")
    IO.puts("  Total Value: $#{Float.round(total_value, 0)}")
    IO.puts("  Expected Annual Return: $#{Float.round(total_return_value, 0)}")
    IO.puts("  Portfolio Risk Level: #{Float.round(portfolio_risk * 100, 2)}%")

    IO.puts(
      "  Return per Dollar Risk: #{Float.round(total_return_value / total_value / portfolio_risk, 2)}"
    )

    # Validation
    IO.puts("")
    IO.puts("Constraint Validation:")

    # Check budget constraint
    total_weight =
      Enum.reduce(assets, 0, fn asset, acc ->
        var_name = "weight_#{asset}"
        weight = solution.variables[var_name] || 0
        acc + weight
      end)

    budget_ok = abs(total_weight - 1.0) < 0.001

    IO.puts(
      "  ✅ Budget constraint: #{Float.round(total_weight * 100, 2)}% allocated #{if budget_ok, do: "✅ OK", else: "❌ VIOLATED"}"
    )

    # Check risk constraint
    risk_ok = portfolio_risk <= max_portfolio_risk / 100.0 + 0.001

    IO.puts(
      "  ✅ Risk constraint: #{Float.round(portfolio_risk * 100, 2)}% <= #{max_portfolio_risk}% #{if risk_ok, do: "✅ OK", else: "❌ VIOLATED"}"
    )

    # Check maximum allocation constraints
    allocation_ok =
      Enum.all?(assets, fn asset ->
        var_name = "weight_#{asset}"
        weight = solution.variables[var_name] || 0
        max_weight = max_allocation[asset]
        weight <= max_weight + 0.001
      end)

    IO.puts(
      "  ✅ Allocation constraints: All within maximum limits #{if allocation_ok, do: "✅ OK", else: "❌ VIOLATED"}"
    )

    # Portfolio diversification analysis
    IO.puts("")
    IO.puts("Diversification Analysis:")

    num_assets =
      Enum.count(assets, fn asset ->
        var_name = "weight_#{asset}"
        weight = solution.variables[var_name] || 0
        # Consider asset included if >5% of portfolio
        weight > 0.05
      end)

    top_3_weight =
      Enum.reduce(assets, 0, fn asset, acc ->
        var_name = "weight_#{asset}"
        weight = solution.variables[var_name] || 0
        weight + acc
      end)
      |> Enum.sort(:desc)
      |> Enum.take(3)
      |> Enum.sum()

    IO.puts(
      "  ✅ Number of significant assets: #{num_assets} (#{if num_assets >= 3, do: "Well diversified", else: "Concentrated"})"
    )

    IO.puts(
      "  ✅ Top 3 assets concentration: #{Float.round(top_3_weight * 100, 1)}% #{if top_3_weight <= 0.80, do: "(Good diversification)", else: "(High concentration)"}"
    )

    IO.puts("")
    IO.puts("Investment Strategy Summary:")

    if portfolio_risk <= 0.08 do
      IO.puts("  🎯 Conservative Strategy: Low risk, steady returns")
    else
      IO.puts("  🎯 Growth Strategy: Higher risk for potentially higher returns")
    end

    if num_assets >= 4 do
      IO.puts("  ✅ Well Diversified: Good risk spreading across multiple asset classes")
    else
      IO.puts("  ⚠️ Concentrated: Consider adding more asset classes for better diversification")
    end

    if allocation_ok and risk_ok and budget_ok do
      IO.puts("  ✅ All constraints satisfied - feasible and optimal solution")
    else
      IO.puts("  ❌ Constraint violations detected")
    end

    IO.puts("")
    IO.puts("LEARNING INSIGHTS:")
    IO.puts("==================")
    IO.puts("• Portfolio optimization balances return expectations against risk tolerance")
    IO.puts("• Linear constraints naturally model budget and allocation limits")
    IO.puts("• Risk-return tradeoff illustrates fundamental investment principle")
    IO.puts("• Diversification reduces portfolio risk through correlation effects")
    IO.puts("• Real-world applications: fund management, retirement planning, robo-advisors")

    IO.puts(
      "• The DSL demonstrates financial optimization with multiple constraints and objectives"
    )

    IO.puts(
      "• Note: True portfolio variance is quadratic - this uses linear approximation for demo"
    )

    IO.puts("")
    IO.puts("✅ Portfolio optimization problem solved successfully!")

  :error ->
    IO.puts("ERROR: Portfolio optimization problem could not be solved.")
    IO.puts("This may be due to infeasible constraints (risk tolerance too low, etc.).")
    IO.puts("Try adjusting risk tolerance or allocation constraints.")
    System.halt(1)
end
