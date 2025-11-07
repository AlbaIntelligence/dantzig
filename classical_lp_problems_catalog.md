# Classical Linear Programming Problems for DSL Demonstration

This catalog lists classical LP problems suitable for showcasing the Dantzig DSL capabilities, organized by complexity and feature coverage.

## 📊 Beginner Level (Simple Problems - 2-5 variables)

### 1. **Two-Variable Linear Programming**
- **Problem**: Maximize/minimize a linear function over a polygon
- **Variables**: 2 continuous variables
- **Constraints**: 3-4 linear constraints
- **DSL Features**: Basic variable definition, simple constraints, objective function
- **Educational Value**: Perfect introduction to LP basics

### 2. **Production Planning (Basic)**
- **Problem**: Optimize production mix for 2 products with resource constraints
- **Variables**: 2-3 continuous variables (production quantities)
- **Constraints**: 2-3 resource constraints (labor, materials)
- **DSL Features**: Model parameters, basic constraints, objective maximization
- **Real-world relevance**: Classic business optimization

### 3. **Simple Diet Problem**
- **Problem**: Minimize cost while meeting nutritional requirements
- **Variables**: 3-4 food types
- **Constraints**: 2-3 nutritional requirements
- **DSL Features**: Constant parameters, inequality constraints

### 4. **Resource Allocation (Simple)**
- **Problem**: Allocate limited resources among competing activities
- **Variables**: 2-3 activities
- **Constraints**: 2-3 resource limits
- **DSL Features**: Pattern-based constraints, model parameters

## 🏭 Intermediate Level (Medium Complexity - 5-15 variables)

### 5. **Portfolio Optimization**
- **Problem**: Maximize expected return for given risk tolerance
- **Variables**: 5-8 investment options
- **Constraints**: Budget, risk limits, diversification requirements
- **DSL Features**: Quadratic constraints, parameter arrays, complex objective
- **Complexity**: Portfolio selection with multiple objectives

### 6. **Transportation Problem**
- **Problem**: Minimize shipping costs between suppliers and customers
- **Variables**: 3-4 suppliers × 3-4 customers = 9-16 decision variables
- **Constraints**: Supply capacity, demand requirements
- **DSL Features**: Pattern-based variable creation, sum constraints, matrix-like operations
- **Showcases**: Generator syntax, indexed variables

### 7. **Assignment Problem**
- **Problem**: Assign workers to tasks to minimize total cost
- **Variables**: 4-5 workers × 4-5 tasks = 16-25 binary variables
- **Constraints**: Each worker assigned to exactly one task, each task gets exactly one worker
- **DSL Features**: Binary variables, equality constraints, permutation constraints
- **Showcases**: Integer programming, combinatorial optimization

### 8. **Cutting Stock Problem**
- **Problem**: Minimize waste when cutting raw materials
- **Variables**: 5-7 cutting patterns (binary)
- **Constraints**: Meet demand for different lengths, resource limits
- **DSL Features**: Binary variables, pattern generation, waste minimization

### 9. **Facility Location Problem**
- **Problem**: Determine optimal locations for facilities and assignment
- **Variables**: Binary variables for facility locations (3-5 locations)
- **Variables**: Assignment variables (facilities × customers)
- **Constraints**: Fixed costs, capacity limits, demand satisfaction
- **DSL Features**: Mixed-integer programming, fixed charge constraints

### 10. **Project Selection Problem**
- **Problem**: Select subset of projects to maximize profit within budget
- **Variables**: Binary variables for each project (5-8 projects)
- **Constraints**: Budget limit, dependency relationships
- **DSL Features**: Binary variables, interdependent constraints

## 🔧 Advanced Level (Higher Complexity - 10-30 variables)

### 11. **Production Planning with Multiple Products and Resources**
- **Problem**: Complex production scheduling with time periods
- **Variables**: 4-6 products × 3-4 time periods = 12-24 variables
- **Constraints**: Resource capacity, demand satisfaction, inventory levels
- **DSL Features**: Time-indexed variables, inventory constraints, rolling planning

### 12. **Network Flow Problems**
- **Problem**: Minimize transportation costs in a network
- **Variables**: Edge flow variables (10-15 edges)
- **Constraints**: Flow conservation at nodes, capacity limits
- **DSL Features**: Network structure, node-arc incidence, capacity constraints
- **Showcases**: Graph-based modeling, conservation laws

### 13. **Stochastic Inventory Control**
- **Problem**: Optimize inventory policies under uncertainty
- **Variables**: Order quantities, inventory levels (scenario-dependent)
- **Constraints**: Demand satisfaction, inventory capacity
- **DSL Features**: Scenario-based modeling, expectation objectives

### 14. **Robust Optimization**
- **Problem**: Optimize under uncertainty in parameters
- **Variables**: Decision variables with uncertainty sets
- **Constraints**: Robust constraints (worst-case scenarios)
- **DSL Features**: Uncertainty modeling, robust formulations

### 15. **Multi-Objective Linear Programming**
- **Problem**: Optimize multiple conflicting objectives
- **Variables**: Decision variables (8-12 variables)
- **Constraints**: Multiple constraint sets
- **Objectives**: Multiple objective functions (Pareto frontier)
- **DSL Features**: Multi-objective formulation, Pareto optimization

## 🎯 Specialized Problems (Showcase Specific DSL Features)

### 16. **Quadratic Programming Problem**
- **Problem**: Portfolio optimization with quadratic risk term
- **Variables**: Investment amounts (6-10 variables)
- **Constraints**: Budget, minimum/maximum allocations
- **Objective**: Quadratic utility function
- **DSL Features**: Quadratic terms, risk-return optimization

### 17. **Piecewise Linear Programming**
- **Problem**: Cost functions with breakpoints
- **Variables**: Quantity variables, piecewise linear approximations
- **Constraints**: Piecewise linear constraints
- **DSL Features**: Linearization techniques, breakpoint handling

### 18. **Integer Programming with Logical Constraints**
- **Problem**: Production planning with setup costs and logical conditions
- **Variables**: Continuous production variables, binary setup variables
- **Constraints**: Logical implications, big-M constraints
- **DSL Features**: Logical constraints, indicator variables, big-M formulation

### 19. **Multi-Commodity Flow Problem**
- **Problem**: Flow of multiple commodities through network
- **Variables**: Flow for each commodity on each edge
- **Constraints**: Capacity limits, demand satisfaction for each commodity
- **DSL Features**: Multi-dimensional indexing, commodity separation

### 20. **Robust Timetabling Problem**
- **Problem**: Schedule resources considering uncertainty
- **Variables**: Binary variables for time slots
- **Constraints**: Resource availability, robustness requirements
- **DSL Features**: Binary variables, temporal constraints, robustness

## 📋 DSL Feature Coverage by Problem Type

### Variable Types Demonstrated:
- **Continuous**: Basic production, transportation, portfolio optimization
- **Binary**: Assignment, facility location, timetabling, project selection
- **Integer**: Mixed-integer problems, cutting stock, scheduling

### Constraint Types Demonstrated:
- **Equality**: Assignment problem, flow conservation
- **Inequality**: Resource constraints, capacity limits
- **Bounds**: Variable limits, capacity constraints
- **Logical**: Conditional constraints, implications
- **Network**: Flow conservation, capacity constraints

### Objective Functions Demonstrated:
- **Linear**: Most classic LP problems
- **Quadratic**: Portfolio optimization, risk minimization
- **Multi-objective**: Trade-off optimization, Pareto problems

### DSL Features Showcased:
- **Generator syntax**: `variables("x", [i <- 1..n], :continuous)`
- **Pattern-based constraints**: `[i <- 1..n], sum(x[i]) <= capacity`
- **Model parameters**: Runtime data integration
- **Nested expressions**: Complex mathematical formulations
- **Multiple objectives**: Multi-criteria optimization
- **Integer programming**: Binary and integer variables

## 🎯 Recommended Implementation Order

1. **Start simple**: Two-variable LP, basic production planning
2. **Add complexity**: Transportation, assignment, portfolio optimization
3. **Introduce integers**: Project selection, facility location
4. **Advanced features**: Multi-objective, robust optimization
5. **Specialized applications**: Network flows, stochastic problems

## 💡 Implementation Notes

- **Scalability**: Keep variable counts moderate (5-20) for laptop computation
- **Feature coverage**: Each problem should showcase 2-3 DSL features
- **Real-world relevance**: Focus on practical, recognizable problem types
- **Educational value**: Clear problem statements with expected solutions
- **Complexity progression**: Smooth learning curve from basic to advanced
This catalog lists classical LP problems suitable for showcasing the Dantzig DSL capabilities, organized by complexity and feature coverage.

## 📊 Beginner Level (Simple Problems - 2-5 variables)

### 1. **Two-Variable Linear Programming**
- **Problem**: Maximize/minimize a linear function over a polygon
- **Variables**: 2 continuous variables
- **Constraints**: 3-4 linear constraints
- **DSL Features**: Basic variable definition, simple constraints, objective function
- **Educational Value**: Perfect introduction to LP basics

### 2. **Production Planning (Basic)**
- **Problem**: Optimize production mix for 2 products with resource constraints
- **Variables**: 2-3 continuous variables (production quantities)
- **Constraints**: 2-3 resource constraints (labor, materials)
- **DSL Features**: Model parameters, basic constraints, objective maximization
- **Real-world relevance**: Classic business optimization

### 3. **Simple Diet Problem**
- **Problem**: Minimize cost while meeting nutritional requirements
- **Variables**: 3-4 food types
- **Constraints**: 2-3 nutritional requirements
- **DSL Features**: Constant parameters, inequality constraints

### 4. **Resource Allocation (Simple)**
- **Problem**: Allocate limited resources among competing activities
- **Variables**: 2-3 activities
- **Constraints**: 2-3 resource limits
- **DSL Features**: Pattern-based constraints, model parameters

## 🏭 Intermediate Level (Medium Complexity - 5-15 variables)

### 5. **Portfolio Optimization**
- **Problem**: Maximize expected return for given risk tolerance
- **Variables**: 5-8 investment options
- **Constraints**: Budget, risk limits, diversification requirements
- **DSL Features**: Quadratic constraints, parameter arrays, complex objective
- **Complexity**: Portfolio selection with multiple objectives

### 6. **Transportation Problem**
- **Problem**: Minimize shipping costs between suppliers and customers
- **Variables**: 3-4 suppliers × 3-4 customers = 9-16 decision variables
- **Constraints**: Supply capacity, demand requirements
- **DSL Features**: Pattern-based variable creation, sum constraints, matrix-like operations
- **Showcases**: Generator syntax, indexed variables

### 7. **Assignment Problem**
- **Problem**: Assign workers to tasks to minimize total cost
- **Variables**: 4-5 workers × 4-5 tasks = 16-25 binary variables
- **Constraints**: Each worker assigned to exactly one task, each task gets exactly one worker
- **DSL Features**: Binary variables, equality constraints, permutation constraints
- **Showcases**: Integer programming, combinatorial optimization

### 8. **Cutting Stock Problem**
- **Problem**: Minimize waste when cutting raw materials
- **Variables**: 5-7 cutting patterns (binary)
- **Constraints**: Meet demand for different lengths, resource limits
- **DSL Features**: Binary variables, pattern generation, waste minimization

### 9. **Facility Location Problem**
- **Problem**: Determine optimal locations for facilities and assignment
- **Variables**: Binary variables for facility locations (3-5 locations)
- **Variables**: Assignment variables (facilities × customers)
- **Constraints**: Fixed costs, capacity limits, demand satisfaction
- **DSL Features**: Mixed-integer programming, fixed charge constraints

### 10. **Project Selection Problem**
- **Problem**: Select subset of projects to maximize profit within budget
- **Variables**: Binary variables for each project (5-8 projects)
- **Constraints**: Budget limit, dependency relationships
- **DSL Features**: Binary variables, interdependent constraints

## 🔧 Advanced Level (Higher Complexity - 10-30 variables)

### 11. **Production Planning with Multiple Products and Resources**
- **Problem**: Complex production scheduling with time periods
- **Variables**: 4-6 products × 3-4 time periods = 12-24 variables
- **Constraints**: Resource capacity, demand satisfaction, inventory levels
- **DSL Features**: Time-indexed variables, inventory constraints, rolling planning

### 12. **Network Flow Problems**
- **Problem**: Minimize transportation costs in a network
- **Variables**: Edge flow variables (10-15 edges)
- **Constraints**: Flow conservation at nodes, capacity limits
- **DSL Features**: Network structure, node-arc incidence, capacity constraints
- **Showcases**: Graph-based modeling, conservation laws

### 13. **Stochastic Inventory Control**
- **Problem**: Optimize inventory policies under uncertainty
- **Variables**: Order quantities, inventory levels (scenario-dependent)
- **Constraints**: Demand satisfaction, inventory capacity
- **DSL Features**: Scenario-based modeling, expectation objectives

### 14. **Robust Optimization**
- **Problem**: Optimize under uncertainty in parameters
- **Variables**: Decision variables with uncertainty sets
- **Constraints**: Robust constraints (worst-case scenarios)
- **DSL Features**: Uncertainty modeling, robust formulations

### 15. **Multi-Objective Linear Programming**
- **Problem**: Optimize multiple conflicting objectives
- **Variables**: Decision variables (8-12 variables)
- **Constraints**: Multiple constraint sets
- **Objectives**: Multiple objective functions (Pareto frontier)
- **DSL Features**: Multi-objective formulation, Pareto optimization

## 🎯 Specialized Problems (Showcase Specific DSL Features)

### 16. **Quadratic Programming Problem**
- **Problem**: Portfolio optimization with quadratic risk term
- **Variables**: Investment amounts (6-10 variables)
- **Constraints**: Budget, minimum/maximum allocations
- **Objective**: Quadratic utility function
- **DSL Features**: Quadratic terms, risk-return optimization

### 17. **Piecewise Linear Programming**
- **Problem**: Cost functions with breakpoints
- **Variables**: Quantity variables, piecewise linear approximations
- **Constraints**: Piecewise linear constraints
- **DSL Features**: Linearization techniques, breakpoint handling

### 18. **Integer Programming with Logical Constraints**
- **Problem**: Production planning with setup costs and logical conditions
- **Variables**: Continuous production variables, binary setup variables
- **Constraints**: Logical implications, big-M constraints
- **DSL Features**: Logical constraints, indicator variables, big-M formulation

### 19. **Multi-Commodity Flow Problem**
- **Problem**: Flow of multiple commodities through network
- **Variables**: Flow for each commodity on each edge
- **Constraints**: Capacity limits, demand satisfaction for each commodity
- **DSL Features**: Multi-dimensional indexing, commodity separation

### 20. **Robust Timetabling Problem**
- **Problem**: Schedule resources considering uncertainty
- **Variables**: Binary variables for time slots
- **Constraints**: Resource availability, robustness requirements
- **DSL Features**: Binary variables, temporal constraints, robustness

## 📋 DSL Feature Coverage by Problem Type

### Variable Types Demonstrated:
- **Continuous**: Basic production, transportation, portfolio optimization
- **Binary**: Assignment, facility location, timetabling, project selection
- **Integer**: Mixed-integer problems, cutting stock, scheduling

### Constraint Types Demonstrated:
- **Equality**: Assignment problem, flow conservation
- **Inequality**: Resource constraints, capacity limits
- **Bounds**: Variable limits, capacity constraints
- **Logical**: Conditional constraints, implications
- **Network**: Flow conservation, capacity constraints

### Objective Functions Demonstrated:
- **Linear**: Most classic LP problems
- **Quadratic**: Portfolio optimization, risk minimization
- **Multi-objective**: Trade-off optimization, Pareto problems

### DSL Features Showcased:
- **Generator syntax**: `variables("x", [i <- 1..n], :continuous)`
- **Pattern-based constraints**: `[i <- 1..n], sum(x[i]) <= capacity`
- **Model parameters**: Runtime data integration
- **Nested expressions**: Complex mathematical formulations
- **Multiple objectives**: Multi-criteria optimization
- **Integer programming**: Binary and integer variables

## 🎯 Recommended Implementation Order

1. **Start simple**: Two-variable LP, basic production planning
2. **Add complexity**: Transportation, assignment, portfolio optimization
3. **Introduce integers**: Project selection, facility location
4. **Advanced features**: Multi-objective, robust optimization
5. **Specialized applications**: Network flows, stochastic problems

## 💡 Implementation Notes

- **Scalability**: Keep variable counts moderate (5-20) for laptop computation
- **Feature coverage**: Each problem should showcase 2-3 DSL features
- **Real-world relevance**: Focus on practical, recognizable problem types
- **Educational value**: Clear problem statements with expected solutions
- **Complexity progression**: Smooth learning curve from basic to advanced
