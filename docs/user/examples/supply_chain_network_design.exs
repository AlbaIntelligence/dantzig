#!/usr/bin/env elixir

# Supply Chain Network Design Problem - Ultra Complex Example
# ============================================================
#
# This is the most comprehensive example in the Dantzig library, demonstrating
# a multi-echelon, multi-product supply chain network optimization problem.
#
# BUSINESS CONTEXT:
# A global manufacturing company needs to design an optimal supply chain network
# spanning multiple continents, with suppliers, manufacturers, warehouses, and retailers.
# The company produces multiple products and must satisfy demand while minimizing
# total costs (transportation, facility opening, production, and inventory costs).
#
# SUPPLY CHAIN HIERARCHY:
# Suppliers → Manufacturers → Warehouses → Distribution Centers → Retailers
#
# REAL-WORLD APPLICATIONS:
# - Global manufacturing companies (automotive, electronics, consumer goods)
# - Pharmaceutical supply chains with regulatory requirements
# - Food and beverage distribution networks
# - E-commerce fulfillment networks
# - Humanitarian supply chains for disaster relief
# - Military logistics and defense supply chains
#
# PROBLEM SCALE:
# - 3 regions (North America, Europe, Asia-Pacific)
# - 15 suppliers across regions
# - 8 manufacturing plants
# - 12 regional warehouses
# - 25 distribution centers
# - 50 retail locations
# - 4 product families
# - Multiple transportation modes with different costs and capacities
#
# MATHEMATICAL FORMULATION:
# Variables:
#   - x[i,j,k] = flow from node i to node j for product k
#   - y[i,j,t] = transportation mode t from node i to node j
#   - f[i] = facility opening binary variable for node i
#   - p[i,k] = production quantity of product k at manufacturer i
#   - inv[i,k,t] = inventory of product k at node i in period t
#
# Parameters:
#   - demand[r,k] = demand for product k in region r
#   - supply_cap[s,k] = supply capacity of product k at supplier s
#   - prod_cap[m,k] = production capacity of product k at manufacturer m
#   - trans_cost[i,j,t] = transportation cost via mode t from i to j
#   - fixed_cost[i] = fixed cost to operate facility at node i
#   - prod_cost[m,k] = production cost per unit of product k at manufacturer m
#   - inv_cost[i,k] = inventory holding cost per unit
#
# Constraints:
#   - Flow conservation at each node
#   - Supply capacity constraints
#   - Production capacity constraints
#   - Demand satisfaction constraints
#   - Transportation capacity constraints
#   - Inventory balance constraints
#   - Binary facility opening variables
#
# Objective: Minimize total cost = transportation + facility + production + inventory costs
#
# DSL COMPLEXITY FEATURES DEMONSTRATED:
# 1. Multi-dimensional variable indexing [supplier, manufacturer, product]
# 2. Complex constraint patterns with multiple sum operations
# 3. Binary variables for facility opening decisions
# 4. Coupling constraints between different variable types
# 5. Advanced use of model parameters for large datasets
# 6. Nested comprehensions and generator expressions
# 7. Complex validation and solution analysis

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# ============================================================================
# DATA DEFINITION
# ============================================================================

# Geographic regions
regions = ["North_America", "Europe", "Asia_Pacific"]

# Supply chain nodes by region
suppliers = %{
  "North_America" => ["Supplier_NA_1", "Supplier_NA_2", "Supplier_NA_3", "Supplier_NA_4", "Supplier_NA_5"],
  "Europe" => ["Supplier_EU_1", "Supplier_EU_2", "Supplier_EU_3", "Supplier_EU_4", "Supplier_EU_5"],
  "Asia_Pacific" => ["Supplier_AP_1", "Supplier_AP_2", "Supplier_AP_3", "Supplier_AP_4", "Supplier_AP_5"]
}

manufacturers = %{
  "North_America" => ["Manufacturer_NA_1", "Manufacturer_NA_2"],
  "Europe" => ["Manufacturer_EU_1", "Manufacturer_EU_2", "Manufacturer_EU_3"],
  "Asia_Pacific" => ["Manufacturer_AP_1", "Manufacturer_AP_2", "Manufacturer_AP_3"]
}

warehouses = %{
  "North_America" => ["Warehouse_NA_1", "Warehouse_NA_2", "Warehouse_NA_3", "Warehouse_NA_4"],
  "Europe" => ["Warehouse_EU_1", "Warehouse_EU_2", "Warehouse_EU_3", "Warehouse_EU_4"],
  "Asia_Pacific" => ["Warehouse_AP_1", "Warehouse_AP_2", "Warehouse_AP_3", "Warehouse_AP_4"]
}

distribution_centers = %{
  "North_America" => ["DC_NA_1", "DC_NA_2", "DC_NA_3", "DC_NA_4", "DC_NA_5", "DC_NA_6", "DC_NA_7", "DC_NA_8", "DC_NA_9"],
  "Europe" => ["DC_EU_1", "DC_EU_2", "DC_EU_3", "DC_EU_4", "DC_EU_5", "DC_EU_6", "DC_EU_7"],
  "Asia_Pacific" => ["DC_AP_1", "DC_AP_2", "DC_AP_3", "DC_AP_4", "DC_AP_5", "DC_AP_6", "DC_AP_7", "DC_AP_8", "DC_AP_9"]
}

retailers = %{
  "North_America" => Enum.map(1..20, &"Retailer_NA_#{&1}"),
  "Europe" => Enum.map(1..18, &"Retailer_EU_#{&1}"),
  "Asia_Pacific" => Enum.map(1..12, &"Retailer_AP_#{&1}")
}

# Product families
products = ["Electronics", "Automotive", "Consumer_Goods", "Industrial"]

# Transportation modes
transport_modes = ["Sea", "Air", "Ground", "Rail"]

# ============================================================================
# PARAMETER DATA
# ============================================================================

# All nodes for easier iteration
all_suppliers = Enum.flat_map(suppliers, fn {_region, nodes} -> nodes end)
all_manufacturers = Enum.flat_map(manufacturers, fn {_region, nodes} -> nodes end)
all_warehouses = Enum.flat_map(warehouses, fn {_region, nodes} -> nodes end)
all_dcs = Enum.flat_map(distribution_centers, fn {_region, nodes} -> nodes end)
all_retailers = Enum.flat_map(retailers, fn {_region, nodes} -> nodes end)
all_nodes = all_suppliers ++ all_manufacturers ++ all_warehouses ++ all_dcs ++ all_retailers

# Demands by region and product (simplified for demo)
demand_data = %{
  "North_America" => %{
    "Electronics" => 1000,
    "Automotive" => 800,
    "Consumer_Goods" => 1500,
    "Industrial" => 600
  },
  "Europe" => %{
    "Electronics" => 1200,
    "Automotive" => 700,
    "Consumer_Goods" => 1800,
    "Industrial" => 500
  },
  "Asia_Pacific" => %{
    "Electronics" => 900,
    "Automotive" => 600,
    "Consumer_Goods" => 1200,
    "Industrial" => 400
  }
}

# Supply capacities by supplier and product
supply_capacities = %{
  "Supplier_NA_1" => %{"Electronics" => 300, "Automotive" => 200, "Consumer_Goods" => 400, "Industrial" => 150},
  "Supplier_NA_2" => %{"Electronics" => 250, "Automotive" => 300, "Consumer_Goods" => 350, "Industrial" => 200},
  "Supplier_NA_3" => %{"Electronics" => 200, "Automotive" => 250, "Consumer_Goods" => 300, "Industrial" => 180},
  "Supplier_NA_4" => %{"Electronics" => 280, "Automotive" => 180, "Consumer_Goods" => 380, "Industrial" => 160},
