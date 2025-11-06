#!/usr/bin/env elixir

# Network Flow Problem Example
#
# BUSINESS CONTEXT:
# Network flow problems model the movement of goods, data, or resources through
# interconnected systems. Common applications include transportation logistics,
# telecommunications routing, supply chain optimization, and financial flows.
# The goal is to maximize flow from a source to a sink while respecting capacity
# constraints and flow conservation laws.
#
# MATHEMATICAL FORMULATION:
# Variables: x_{i,j} = flow from node i to node j (0 ≤ x_{i,j} ≤ capacity_{i,j})
# Constraints:
#   x_{i,j} ≤ capacity_{i,j} for all arcs (i,j)
#   Σ_{j} x_{i,j} = Σ_{k} x_{k,i} for all intermediate nodes i (flow conservation)
# Objective: Maximize Σ_{j} x_{source,j} (or equivalently Σ_{i} x_{i,sink})
#
# DSL SYNTAX HIGHLIGHTS:
# - Flow variables represent quantities moving between nodes
# - Capacity constraints use upper bounds on variables
# - Flow conservation requires balancing inflow and outflow at nodes
# - Sum expressions aggregate flows across multiple arcs
#
# GOTCHAS:
# - Tuple destructuring in generators is not currently supported
# - Variable naming must avoid complex data structures
# - Flow conservation constraints require careful inflow/outflow calculation
# - Network topology must be carefully mapped to variable relationships
# - Current implementation uses explicit variable naming due to DSL limitations

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the network structure
# S=source, T=sink
nodes = ["S", "A", "B", "C", "T"]

# Network arcs with capacities
arcs = [
  # Source to A: capacity 5
  {"S", "A", 5},
  # Source to B: capacity 8
  {"S", "B", 8},
  # A to B: capacity 3
  {"A", "B", 3},
  # A to C: capacity 10
  {"A", "C", 10},
  # B to C: capacity 5
  {"B", "C", 5},
  # B to T: capacity 7
  {"B", "T", 7},
  # C to T: capacity 12
  {"C", "T", 12}
]

# Create lookup maps for easier access
arc_capacity = for {from, to, cap} <- arcs, into: %{}, do: {{from, to}, cap}
arc_list = for {from, to, _} <- arcs, do: {from, to}

IO.puts("Network Flow Problem")
IO.puts("====================")
IO.puts("Nodes: #{Enum.join(nodes, ", ")}")
IO.puts("Source: S, Sink: T")
IO.puts("")
IO.puts("Network Arcs (from → to: capacity):")

Enum.each(arcs, fn {from, to, capacity} ->
  IO.puts("  #{from} → #{to}: #{capacity} units")
end)

IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(
      name: "Network Flow Problem",
      description: "Maximize flow from source S to sink T"
    )

    # Flow variables: explicit variables for each arc (tuple destructuring not supported)
    variables("flow_SA", :continuous, min_bound: 0, max_bound: 5, description: "Flow S to A")
    variables("flow_SB", :continuous, min_bound: 0, max_bound: 8, description: "Flow S to B")
    variables("flow_AB", :continuous, min_bound: 0, max_bound: 3, description: "Flow A to B")
    variables("flow_AC", :continuous, min_bound: 0, max_bound: 10, description: "Flow A to C")
    variables("flow_BC", :continuous, min_bound: 0, max_bound: 5, description: "Flow B to C")
    variables("flow_BT", :continuous, min_bound: 0, max_bound: 7, description: "Flow B to T")
    variables("flow_CT", :continuous, min_bound: 0, max_bound: 12, description: "Flow C to T")

    # Capacity constraints (variable bounds not working in LP export)
    constraints(flow_SA <= 5, "Capacity S to A")
    constraints(flow_SB <= 8, "Capacity S to B")
    constraints(flow_AB <= 3, "Capacity A to B")
    constraints(flow_AC <= 10, "Capacity A to C")
    constraints(flow_BC <= 5, "Capacity B to C")
    constraints(flow_BT <= 7, "Capacity B to T")
    constraints(flow_CT <= 12, "Capacity C to T")

    # Non-negativity constraints (variable bounds not working in LP export)
    constraints(flow_SA >= 0, "Non-negative S to A")
    constraints(flow_SB >= 0, "Non-negative S to B")
    constraints(flow_AB >= 0, "Non-negative A to B")
    constraints(flow_AC >= 0, "Non-negative A to C")
    constraints(flow_BC >= 0, "Non-negative B to C")
    constraints(flow_BT >= 0, "Non-negative B to T")
    constraints(flow_CT >= 0, "Non-negative C to T")

    # Flow conservation at intermediate nodes (A, B, C)
    # Node A: inflow from S equals outflow to B and C
    constraints(
    flow_SA == flow_AB + flow_AC,
    "Flow conservation at node A"
    )

    # Node B: inflow from S and A equals outflow to C and T
    constraints(
      flow_SB + flow_AB == flow_BC + flow_BT,
    "Flow conservation at node B"
    )

    # Node C: inflow from A and B equals outflow to T
    constraints(
      flow_AC + flow_BC == flow_CT,
      "Flow conservation at node C"
    )

    # Objective: maximize total flow into sink T
    objective(
    flow_BT + flow_CT,
    direction: :maximize
    )
  end

IO.puts("Solving the network flow problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Maximum flow: #{Float.round(objective_value * 1.0, 2)} units")
IO.puts("")

IO.puts("Flow on each arc:")

# Map arc tuples to variable names
arc_to_var = %{
 {"S", "A"} => "flow_SA",
{"S", "B"} => "flow_SB",
{"A", "B"} => "flow_AB",
{"A", "C"} => "flow_AC",
{"B", "C"} => "flow_BC",
{"B", "T"} => "flow_BT",
{"C", "T"} => "flow_CT"
}

# Calculate total flow and display arcs
total_flow = Enum.reduce(arcs, 0.0, fn {from, to, capacity}, acc ->
 var_name = arc_to_var[{from, to}]
 flow_amount = Map.get(solution.variables, var_name, 0.0)

 if flow_amount > 0.001 do
    utilization = flow_amount / capacity * 100

  IO.puts(
     "  #{from} → #{to}: #{Float.round(flow_amount * 1.0, 2)}/#{capacity} units (#{Float.round(utilization * 1.0, 1)}% utilized)"
    )
  else
    IO.puts("  #{from} → #{to}: 0.0/#{capacity} units (0.0% utilized)")
  end

# Only add flows entering the sink to total_flow
if to == "T" do
acc + flow_amount
else
    acc
  end
end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total flow calculated: #{Float.round(total_flow * 1.0, 2)}")
IO.puts("  Reported maximum flow: #{Float.round(objective_value * 1.0, 2)}")
IO.puts("  Flow values match: #{abs(total_flow - objective_value) < 0.001}")

# Validation
if abs(total_flow - objective_value) > 0.001 do
  IO.puts("ERROR: Flow value mismatch!")
  System.halt(1)
end

# Validate capacity constraints
IO.puts("")
IO.puts("Capacity Constraint Validation:")

capacity_violations =
  Enum.filter(arcs, fn {from, to, capacity} ->
    var_name = arc_to_var[{from, to}]
    flow_amount = solution.variables[var_name]
    flow_amount > capacity + 0.001
  end)

if capacity_violations == [] do
  IO.puts("  ✅ All capacity constraints satisfied")
else
  IO.puts("  ❌ Capacity violations found: #{inspect(capacity_violations)}")
  System.halt(1)
end

# Validate flow conservation for intermediate nodes
IO.puts("")
IO.puts("Flow Conservation Validation:")

# Define node inflows and outflows explicitly
node_flows = %{
  "A" => %{in: ["flow_SA"], out: ["flow_AB", "flow_AC"]},
  "B" => %{in: ["flow_SB", "flow_AB"], out: ["flow_BC", "flow_BT"]},
  "C" => %{in: ["flow_AC", "flow_BC"], out: ["flow_CT"]}
}

conservation_violations =
  Enum.filter(["A", "B", "C"], fn node ->
    flows = node_flows[node]
    flow_in = Enum.reduce(flows.in, 0, fn var, acc -> acc + solution.variables[var] end)
    flow_out = Enum.reduce(flows.out, 0, fn var, acc -> acc + solution.variables[var] end)
    abs(flow_in - flow_out) >= 0.001
  end)

if conservation_violations == [] do
  IO.puts("  ✅ Flow conservation satisfied at all intermediate nodes")
else
  IO.puts("  ❌ Flow conservation violations at nodes: #{inspect(conservation_violations)}")
  System.halt(1)
end

# Check source and sink net flow
source_outflow = solution.variables["flow_SA"] + solution.variables["flow_SB"]
sink_inflow = solution.variables["flow_BT"] + solution.variables["flow_CT"]

IO.puts("")
IO.puts("Network Flow Summary:")
IO.puts("  Source total outflow: #{Float.round(source_outflow * 1.0, 2)}")
IO.puts("  Sink total inflow: #{Float.round(sink_inflow * 1.0, 2)}")
IO.puts("  Maximum flow achieved: #{Float.round(objective_value * 1.0, 2)}")

IO.puts("")
IO.puts("LEARNING INSIGHTS:")
IO.puts("==================")
IO.puts("• Network flow problems balance supply and demand across interconnected systems")
IO.puts("• Flow conservation ensures no loss or creation of flow at intermediate nodes")
IO.puts("• Maximum flow algorithms find optimal routing through capacity-constrained networks")
IO.puts("• Linear programming naturally handles capacity and conservation constraints")
IO.puts("• Real-world applications: transportation, telecommunications, supply chains")
IO.puts("• Current DSL limitations require explicit variable naming for complex structures")

IO.puts("")
IO.puts("✅ Network flow problem solved successfully!")
