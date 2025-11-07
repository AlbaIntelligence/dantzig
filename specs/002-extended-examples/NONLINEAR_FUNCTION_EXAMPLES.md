# Optimization Problems Using Non-Linear Functions (Linearizable)

**Purpose**: Ideas for examples demonstrating `abs()`, `max()`, `min()`, `and()`, `or()` functions in Dantzig DSL

## Problems Using `abs()` (Absolute Value)

### 1. **Minimize Absolute Deviation / L1 Regression**
**Problem**: Fit a line to data points minimizing the sum of absolute deviations (L1 norm) instead of squared deviations (L2 norm).

**Use Case**: Robust regression that is less sensitive to outliers than least squares.

**Mathematical Formulation**:
- Variables: `a`, `b` (line parameters: y = ax + b)
- Objective: Minimize `sum(abs(y_i - (a*x_i + b)))` for all data points i
- Linearization: `abs(y_i - (a*x_i + b))` becomes auxiliary variable with constraints

**Real-world Applications**:
- Robust statistical modeling
- Outlier-resistant curve fitting
- Financial forecasting with noisy data

### 2. **Target Tracking Problem**
**Problem**: Minimize deviation from target values across multiple metrics.

**Use Case**: Production planning where you want to stay close to target inventory levels, production rates, etc.

**Mathematical Formulation**:
- Variables: Production/inventory decisions
- Objective: Minimize `sum(abs(actual[i] - target[i]))` for all metrics i
- Constraints: Resource limits, capacity constraints

**Real-world Applications**:
- Production planning with target metrics
- Inventory management
- Quality control (minimize deviation from specifications)

### 3. **Facility Location with Manhattan Distance**
**Problem**: Locate facilities to minimize total Manhattan distance (L1 norm) to customers.

**Use Case**: Urban planning where travel follows grid streets (Manhattan distance).

**Mathematical Formulation**:
- Variables: Facility locations (x, y coordinates), assignments
- Objective: Minimize `sum(abs(x_f - x_c) + abs(y_f - y_c))` for all facility-customer pairs
- Linearization: Each `abs()` term becomes auxiliary variable

**Real-world Applications**:
- Urban facility location
- Emergency services placement
- Delivery route optimization in grid cities

### 4. **Portfolio Optimization with Absolute Deviation**
**Problem**: Minimize absolute deviation from target portfolio weights.

**Use Case**: Rebalancing portfolio to minimize transaction costs while staying close to target allocation.

**Mathematical Formulation**:
- Variables: Portfolio weights
- Objective: Minimize `sum(abs(weight[i] - target[i]))` for all assets i
- Constraints: Budget, risk limits

**Real-world Applications**:
- Portfolio rebalancing
- Asset allocation with transaction costs
- Index fund tracking

## Problems Using `max()` (Maximum)

### 5. **Minimax / Makespan Minimization**
**Problem**: Minimize the maximum completion time (makespan) in job scheduling.

**Use Case**: Schedule jobs on machines to minimize the time until all jobs are complete.

**Mathematical Formulation**:
- Variables: Job assignments, start times, completion times
- Objective: Minimize `max(completion_time[j])` for all jobs j
- Linearization: `max()` becomes auxiliary variable with constraints

**Real-world Applications**:
- Job shop scheduling
- Project management (minimize project duration)
- Resource allocation with fairness (minimize worst-case)

### 6. **Facility Location - Minimize Maximum Distance**
**Problem**: Locate facilities to minimize the maximum distance any customer must travel.

**Use Case**: Emergency services where worst-case response time matters most.

**Mathematical Formulation**:
- Variables: Facility locations, customer assignments
- Objective: Minimize `max(distance(facility, customer))` for all customer-facility pairs
- Constraints: Each customer served, facility capacity

**Real-world Applications**:
- Emergency services location
- Fire station placement
- Ambulance base location
- Worst-case optimization

### 7. **Robust Optimization - Minimize Maximum Cost**
**Problem**: Optimize under uncertainty by minimizing worst-case cost across scenarios.

**Use Case**: Budget planning where costs are uncertain and you want to minimize worst-case outcome.

**Mathematical Formulation**:
- Variables: Decision variables
- Objective: Minimize `max(cost[scenario])` for all scenarios
- Constraints: Feasibility for all scenarios

**Real-world Applications**:
- Robust portfolio optimization
- Supply chain risk management
- Budget planning under uncertainty

### 8. **Load Balancing**
**Problem**: Distribute workload across servers to minimize maximum server load.

**Use Case**: Cloud computing resource allocation.

**Mathematical Formulation**:
- Variables: Task assignments to servers
- Objective: Minimize `max(server_load[s])` for all servers s
- Constraints: All tasks assigned, server capacity

**Real-world Applications**:
- Cloud computing load balancing
- Distributed computing
- Network traffic distribution

## Problems Using `min()` (Minimum)

### 9. **Maximin / Fair Resource Allocation**
**Problem**: Maximize the minimum benefit received by any participant (fairness).

**Use Case**: Allocate resources to maximize the minimum utility, ensuring fairness.

**Mathematical Formulation**:
- Variables: Resource allocations
- Objective: Maximize `min(utility[i])` for all participants i
- Linearization: `min()` becomes auxiliary variable with constraints

**Real-world Applications**:
- Fair resource allocation
- Social welfare optimization
- Equity-focused planning

### 10. **Bottleneck Optimization**
**Problem**: Maximize the minimum capacity or throughput across system components.

**Use Case**: Network design where overall performance is limited by the weakest link.

**Mathematical Formulation**:
- Variables: Component capacities, investments
- Objective: Maximize `min(capacity[component])` for all components
- Constraints: Budget, physical limits

**Real-world Applications**:
- Network design
- Supply chain optimization
- System reliability

## Problems Using `and()` (Logical AND)

### 11. **Conditional Constraints / If-Then Logic**
**Problem**: Model logical dependencies where one constraint depends on another.

**Use Case**: Project selection where selecting project A requires also selecting project B.

**Mathematical Formulation**:
- Variables: Binary project selection variables
- Constraints: `select_A AND select_B` (if A is selected, B must be selected)
- Linearization: `and()` creates binary auxiliary variable with constraints

**Real-world Applications**:
- Project dependencies
- Feature selection with prerequisites
- Conditional resource allocation

### 12. **Multi-Criteria Decision Making**
**Problem**: Select options that satisfy multiple criteria simultaneously.

**Use Case**: Supplier selection where supplier must meet quality AND cost AND delivery criteria.

**Mathematical Formulation**:
- Variables: Binary selection variables
- Constraints: `quality_ok AND cost_ok AND delivery_ok` for each supplier
- Objective: Minimize total cost

**Real-world Applications**:
- Supplier selection
- Vendor evaluation
- Multi-attribute decision making

## Problems Using `or()` (Logical OR)

### 13. **Alternative Constraints / Either-Or**
**Problem**: Model situations where at least one of several options must be chosen.

**Use Case**: Facility location where each customer must be served by at least one of several facility types.

**Mathematical Formulation**:
- Variables: Binary selection variables
- Constraints: `select_option_A OR select_option_B OR select_option_C`
- Linearization: `or()` creates binary auxiliary variable with constraints

**Real-world Applications**:
- Flexible manufacturing (use machine A OR machine B)
- Alternative routing (route 1 OR route 2)
- Backup systems (primary OR backup)

### 14. **Flexible Resource Allocation**
**Problem**: Allocate resources where multiple alternative sources are acceptable.

**Use Case**: Task assignment where each task can be done by worker A OR worker B OR worker C.

**Mathematical Formulation**:
- Variables: Binary assignment variables
- Constraints: `assign_to_A OR assign_to_B OR assign_to_C` for each task
- Objective: Minimize total cost

**Real-world Applications**:
- Flexible workforce scheduling
- Alternative supplier selection
- Backup resource planning

## Combined Non-Linear Functions

### 15. **Robust Portfolio with Min-Max**
**Problem**: Portfolio optimization that maximizes minimum return while minimizing maximum risk.

**Use Case**: Conservative investment strategy focusing on worst-case scenarios.

**Mathematical Formulation**:
- Variables: Portfolio weights
- Objective: Maximize `min(return[scenario]) - max(risk[scenario])` across scenarios
- Constraints: Budget, diversification

**Real-world Applications**:
- Conservative portfolio management
- Risk-averse investment
- Robust financial planning

### 16. **Scheduling with Absolute Deviation from Target**
**Problem**: Schedule jobs to minimize absolute deviation from target completion times.

**Use Case**: Just-in-time manufacturing where early/late completion both have costs.

**Mathematical Formulation**:
- Variables: Job start times, completion times
- Objective: Minimize `sum(abs(completion_time[j] - target[j]))` for all jobs j
- Constraints: Precedence, resource capacity

**Real-world Applications**:
- Just-in-time manufacturing
- Project scheduling with deadlines
- Time-sensitive operations

## Recommended Priority Examples

Based on educational value and real-world applicability:

### High Priority (Should Create):
1. **Minimax Scheduling** (max function) - Clear, visualizable, common problem
2. **Target Tracking** (abs function) - Simple, intuitive, widely applicable
3. **Facility Location - Minimize Maximum Distance** (max function) - Practical, easy to understand

### Medium Priority:
4. **Minimize Absolute Deviation** (abs function) - Statistical application
5. **Fair Resource Allocation** (min function) - Social/ethical applications
6. **Conditional Constraints** (and function) - Logical modeling

### Lower Priority (Can Demonstrate in Tutorial):
7. **Alternative Constraints** (or function) - Similar to conditional
8. **Combined Functions** - Advanced, can be in tutorial

## Implementation Notes

- All these problems can be linearized using Dantzig's automatic linearization
- `abs(x)` requires 1 auxiliary variable + 2 constraints
- `max(x1, x2, ..., xn)` requires 1 auxiliary variable + n constraints
- `min(x1, x2, ..., xn)` requires 1 auxiliary variable + n constraints
- `and(x1, x2, ..., xn)` requires 1 binary auxiliary variable + (n+1) constraints
- `or(x1, x2, ..., xn)` requires 1 binary auxiliary variable + (n+1) constraints

## Additional Ideas from JuMP Tutorials

### From JuMP Linear Programming Tutorials:

#### 17. **Factory Schedule with Fixed Costs** (max/and function)
**Source**: `factory_schedule.jl` from JuMP tutorials
**Problem**: Schedule factory production with fixed costs that are incurred only when factory runs.

**Use Case**: Production planning where opening a factory has a fixed cost, but production has variable costs.

**Mathematical Formulation**:
- Variables: `produce[m,f]` = production in month m at factory f, `run[m,f]` = 1 if factory runs
- Constraints: `produce[m,f] <= capacity[f] * run[m,f]` (can use max or and logic)
- Objective: Minimize `sum(fixed_cost[f] * run[m,f] + variable_cost[f] * produce[m,f])`

**DSL Application**: Could use `and()` or `max()` to model the fixed cost logic, or demonstrate conditional constraints.

#### 18. **Short-Term Financing** (abs function potential)
**Source**: `finance.jl` from JuMP tutorials
**Problem**: Manage cash flow over time with borrowing, investing, and commercial paper options.

**Use Case**: Corporate cash flow management with multiple financing sources.

**Mathematical Formulation**:
- Variables: Line of credit draws, commercial paper issues, excess funds invested
- Constraints: Cash balance equations over time periods
- Objective: Maximize final wealth

**DSL Application**: Could use `abs()` to minimize deviation from target cash levels or model absolute borrowing amounts.

#### 19. **Combinatorial Auctions** (and/or functions)
**Source**: `finance.jl` from JuMP tutorials
**Problem**: Auctioneer selects winning bids on item combinations to maximize revenue.

**Use Case**: Auctions where bidders value combinations of items (not just individual items).

**Mathematical Formulation**:
- Variables: Binary variables for accepting each bid
- Constraints: Each item sold at most once: `sum(bids containing item i) <= 1`
- Objective: Maximize total revenue from accepted bids

**DSL Application**: Could use `and()` to model bid requirements (all items in bid must be available) or `or()` for alternative bid acceptance.

#### 20. **Geographic Clustering** (min/max functions)
**Source**: `geographic_clustering.jl` from JuMP tutorials
**Problem**: Cluster cities into groups minimizing total pairwise distance while balancing population.

**Use Case**: Regional planning, sales territory design, service area allocation.

**Mathematical Formulation**:
- Variables: Binary assignment of cities to clusters
- Objective: Minimize `sum(distance[i,j] * same_cluster[i,j])` for all city pairs
- Constraints: Population balance, each city in exactly one cluster

**DSL Application**: Could use `max()` to minimize maximum cluster diameter or `min()` to maximize minimum inter-cluster distance.

#### 21. **Multi-Objective Optimization** (Multiple objectives)
**Source**: `multi_objective_examples.jl`, `multi_objective_knapsack.jl` from JuMP tutorials
**Problem**: Optimize multiple conflicting objectives simultaneously.

**Use Case**: Knapsack with profit AND desirability, assignment with cost AND time.

**Mathematical Formulation**:
- Variables: Decision variables
- Objectives: Multiple objectives (e.g., maximize profit AND maximize desirability)
- Solution: Pareto frontier of non-dominated solutions

**DSL Application**: Demonstrates `objective()` with multiple criteria, could use `max()` or `min()` to create composite objectives.

#### 22. **Cannery Problem (Transshipment)** (Standard LP, but good example)
**Source**: `cannery.jl` from JuMP tutorials
**Problem**: Ship cases from production plants to markets minimizing transportation distance.

**Use Case**: Distribution network optimization.

**Mathematical Formulation**:
- Variables: Shipment quantities from plants to markets
- Constraints: Plant capacity, market demand
- Objective: Minimize total transportation distance

**DSL Application**: Good example for pattern-based constraints and model parameters with nested data structures.

#### 23. **Piecewise Linear Approximation** (Advanced, demonstrates linearization)
**Source**: `piecewise_linear.jl` from JuMP tutorials
**Problem**: Approximate non-linear functions using piecewise linear segments.

**Use Case**: When you need to model non-linear relationships in a linear program.

**Mathematical Formulation**:
- Variables: Convex combination weights for breakpoints
- Constraints: SOS2 constraints (special ordered sets)
- Objective: Approximate non-linear function value

**DSL Application**: Advanced example showing how Dantzig's automatic linearization works internally (educational).

## Updated Priority Recommendations

### High Priority (Should Create):
1. **Minimax Scheduling** (max function) - Clear, visualizable, common problem
2. **Target Tracking** (abs function) - Simple, intuitive, widely applicable
3. **Multi-Objective Knapsack** (multiple objectives) - From JuMP, well-documented
4. **Factory Schedule with Fixed Costs** (max/and function) - From JuMP, practical

### Medium Priority:
5. **Minimize Absolute Deviation** (abs function) - Statistical application
6. **Facility Location - Minimize Maximum Distance** (max function) - Practical
7. **Fair Resource Allocation** (min function) - Social/ethical applications
8. **Short-Term Financing** (abs function potential) - From JuMP, financial

### Lower Priority (Can Demonstrate in Tutorial):
9. **Geographic Clustering** (min/max functions) - From JuMP, interesting but complex
10. **Combinatorial Auctions** (and/or function) - From JuMP, specialized
11. **Conditional Constraints** (and function) - Logical modeling
12. **Alternative Constraints** (or function) - Similar to conditional
13. **Combined Functions** - Advanced, can be in tutorial

## References

These problem types are standard in optimization literature:
- Operations Research textbooks (Hillier & Lieberman, Taha)
- Linear Programming textbooks (Vanderbei, Chvatal)
- Optimization modeling books (Williams, Fourer et al.)
- Robust optimization literature (Ben-Tal & Nemirovski)
- **JuMP Tutorials** (docs/JuMP_tutorials/linear/) - Additional examples and formulations
