# Dantzig DSL Example Structure and Template Design

## 📊 Analysis of Current Examples

Based on examining existing examples, I've identified the structure and patterns that work well:

### **Good Examples Analysis:**

1. **simple_working_example.exs** (290 lines)

   - ✅ Comprehensive header documentation
   - ✅ Business context and real-world applications
   - ✅ Mathematical formulation with proper notation
   - ✅ DSL syntax explanation with examples
   - ✅ Common gotchas section
   - ✅ Multiple problem examples in one file
   - ✅ Variable verification and debugging output
   - ✅ Learning insights section

2. **transportation_problem.exs** (349 lines)

   - ✅ Good problem definition and data setup
   - ✅ Model parameters usage (partial)
   - ✅ Comprehensive validation and error checking
   - ✅ Professional documentation structure
   - ⚠️ Some hardcoded values due to model parameters limitations

3. **knapsack_problem.exs** (150 lines)
   - ✅ Clear business context
   - ✅ Good mathematical formulation
   - ✅ Binary variable demonstration
   - ⚠️ Uses individual variable declaration instead of pattern-based generation
   - ⚠️ Has sum(for ...) syntax issues

## 🎯 Ideal Example Structure Template

```elixir
#!/usr/bin/env elixir

# PROBLEM NAME: [Clear, descriptive title]
# ================================================================
#
# BRIEF DESCRIPTION: [1-2 sentences explaining what the problem does]
#
# BUSINESS CONTEXT:
# [2-3 paragraphs explaining real-world applications and significance]
#
# Real-world applications:
# - [Application 1]
# - [Application 2]
# - [Application 3]
#
# MATHEMATICAL FORMULATION:
# Variables: [Definition of decision variables]
# Parameters: [Definition of problem parameters]
# Constraints: [Mathematical constraints with proper notation]
# Objective: [Objective function definition]
#
# DSL SYNTAX HIGHLIGHTS:
# - [Key DSL feature 1 with example]
# - [Key DSL feature 2 with example]
# - [Key DSL feature 3 with example]
#
# COMMON GOTCHAS:
# 1. [Common mistake 1 and how to avoid it]
# 2. [Common mistake 2 and how to avoid it]
# 3. [Common mistake 3 and how to avoid it]

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# ============================================================================
# Problem Data Definition
# ============================================================================
# [Clear data setup with meaningful variable names]

# ============================================================================
# Problem Creation
# ============================================================================

problem =
  Problem.define [model_parameters: data] do
    new(name: "Problem Name", description: "Problem description", direction: :minimize)

    # Variables section
    # [Clear variable definition with pattern-based generators]

    # Constraints section
    # [Well-documented constraints with meaningful names]

    # Objective section
    # [Clear objective function definition]
  end

# ============================================================================
# Solution and Analysis
# ============================================================================

{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

# [Comprehensive solution display with validation]

# ============================================================================
# Learning Insights
# ============================================================================
# [Key takeaways and educational value]
```

## 📋 Classical LP Problems to Implement (Priority Order)

### **Tier 1: Beginner Level (Fill immediate gaps)**

1. **Two-Variable Linear Programming**

   - **DSL Features**: Basic variables, simple constraints, objective
   - **Variables**: 2 continuous variables (x, y)
   - **Constraints**: 3-4 linear inequalities defining a polygon
   - **Objective**: Simple linear function to maximize/minimize
   - **Value**: Perfect introduction to LP basics, visualizable

2. **Simple Diet Problem** (Fix existing)

   - **Current Status**: Exists but has sum(for ...) syntax issues
   - **Fix Required**: Update to use proper DSL syntax
   - **DSL Features**: Model parameters, simple constraints, cost minimization

3. **Resource Allocation (Simple)**
   - **DSL Features**: Model parameters, pattern-based constraints
   - **Variables**: 2-3 activities
   - **Constraints**: 2-3 resource limits
   - **Value**: Practical business optimization example

### **Tier 2: Intermediate Level (Add missing features)**

4. **Portfolio Optimization**

   - **DSL Features**: Parameter arrays, complex objectives, budget constraints
   - **Variables**: 5-8 investment options
   - **Constraints**: Budget, risk limits, diversification
   - **Value**: Financial application, sophisticated constraints

5. **Project Selection Problem**
   - **DSL Features**: Binary variables, budget constraints
   - **Variables**: Binary variables for each project (5-8 projects)
   - **Constraints**: Budget limit, dependency relationships
   - **Value**: Shows integer programming capabilities

### **Tier 3: Advanced Level (Showcase advanced features)**

6. **Facility Location Problem**

   - **DSL Features**: Mixed-integer programming, fixed costs
   - **Variables**: Binary facility location + continuous assignment
   - **Constraints**: Fixed costs, capacity limits, demand satisfaction
   - **Value**: Complex mixed-integer formulation

7. **Multi-Objective Linear Programming**
   - **DSL Features**: Multiple objective functions
   - **Variables**: 8-12 decision variables
   - **Objectives**: Multiple conflicting objectives
   - **Value**: Advanced multi-criteria optimization

## 🔧 DSL Feature Coverage Goals

### **Current Coverage (from analysis):**

- ✅ Basic continuous variables
- ✅ Simple constraints (==, <=, >=)
- ✅ Pattern-based variable generation
- ✅ Basic sum expressions
- ✅ Wildcard aggregations (:\_)
- ✅ Model parameters (partial support)
- ✅ Binary variables (knapsack)

### **Missing Coverage to Add:**

- ❌ Integer variables
- ❌ Complex parameter arrays
- ❌ Multi-objective optimization
- ❌ Fixed-charge constraints
- ❌ Logical constraints
- ❌ Advanced sum patterns

## 📏 Quality Standards for Examples

### **Documentation Requirements:**

1. **Header Section** (50-100 lines):

   - Problem name and description
   - Business context (real-world applications)
   - Mathematical formulation (proper notation)
   - DSL syntax highlights
   - Common gotchas section

2. **Data Definition** (20-40 lines):

   - Clear variable names
   - Meaningful comments
   - Well-structured data

3. **Problem Creation** (30-60 lines):

   - Pattern-based variable generation
   - Well-documented constraints
   - Clear objective function
   - Proper use of model parameters

4. **Solution Analysis** (40-80 lines):

   - Solution display with validation
   - Error checking and verification
   - Performance metrics

5. **Learning Insights** (10-20 lines):
   - Key takeaways
   - Educational value
   - Real-world applications

### **Technical Requirements:**

1. **DSL Syntax Compliance**:

   - Use pattern-based variable generation where possible
   - Follow DSL naming conventions
   - Proper use of wildcards and aggregations
   - Model parameters when appropriate

2. **Code Quality**:

   - No compilation warnings
   - Comprehensive error handling
   - Validation of solutions
   - Clear variable naming

3. **Educational Value**:
   - Demonstrate 2-3 DSL features per example
   - Show progressive complexity
   - Include common problem patterns
   - Provide learning insights

## 🚀 Implementation Strategy

### **Phase 1: Fix Existing Issues**

1. Fix diet_problem.exs (sum(for ...) syntax)
2. Fix transportation_problem.exs (Access.get issues)
3. Fix knapsack_problem.exs (pattern-based variables)
4. Fix assignment_problem.exs (objective calculation)

### **Phase 2: Implement New Examples**

1. **Two-Variable LP** (easiest to start with)
2. **Resource Allocation** (pattern-based constraints)
3. **Portfolio Optimization** (complex objectives)
4. **Project Selection** (binary variables)
5. **Multi-Objective LP** (advanced features)

### **Phase 3: Advanced Examples**

1. **Facility Location** (mixed-integer)
2. **Network Flow** (graph-based modeling)
3. **Stochastic Programming** (uncertainty)

## 📊 Success Metrics

1. **Coverage**: All DSL features demonstrated in working examples
2. **Quality**: All examples compile and run without errors
3. **Education**: Clear progression from basic to advanced concepts
4. **Documentation**: Comprehensive documentation in all examples
5. **Validation**: All solutions properly validated and verified

This design provides a clear roadmap for creating rich, educational examples that showcase the full capabilities of the Dantzig DSL.

## 📊 Analysis of Current Examples

Based on examining existing examples, I've identified the structure and patterns that work well:

### **Good Examples Analysis:**

1. **simple_working_example.exs** (290 lines)

   - ✅ Comprehensive header documentation
   - ✅ Business context and real-world applications
   - ✅ Mathematical formulation with proper notation
   - ✅ DSL syntax explanation with examples
   - ✅ Common gotchas section
   - ✅ Multiple problem examples in one file
   - ✅ Variable verification and debugging output
   - ✅ Learning insights section

2. **transportation_problem.exs** (349 lines)

   - ✅ Good problem definition and data setup
   - ✅ Model parameters usage (partial)
   - ✅ Comprehensive validation and error checking
   - ✅ Professional documentation structure
   - ⚠️ Some hardcoded values due to model parameters limitations

3. **knapsack_problem.exs** (150 lines)
   - ✅ Clear business context
   - ✅ Good mathematical formulation
   - ✅ Binary variable demonstration
   - ⚠️ Uses individual variable declaration instead of pattern-based generation
   - ⚠️ Has sum(for ...) syntax issues

## 🎯 Ideal Example Structure Template

```elixir
#!/usr/bin/env elixir

# PROBLEM NAME: [Clear, descriptive title]
# ================================================================
#
# BRIEF DESCRIPTION: [1-2 sentences explaining what the problem does]
#
# BUSINESS CONTEXT:
# [2-3 paragraphs explaining real-world applications and significance]
#
# Real-world applications:
# - [Application 1]
# - [Application 2]
# - [Application 3]
#
# MATHEMATICAL FORMULATION:
# Variables: [Definition of decision variables]
# Parameters: [Definition of problem parameters]
# Constraints: [Mathematical constraints with proper notation]
# Objective: [Objective function definition]
#
# DSL SYNTAX HIGHLIGHTS:
# - [Key DSL feature 1 with example]
# - [Key DSL feature 2 with example]
# - [Key DSL feature 3 with example]
#
# COMMON GOTCHAS:
# 1. [Common mistake 1 and how to avoid it]
# 2. [Common mistake 2 and how to avoid it]
# 3. [Common mistake 3 and how to avoid it]

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# ============================================================================
# Problem Data Definition
# ============================================================================
# [Clear data setup with meaningful variable names]

# ============================================================================
# Problem Creation
# ============================================================================

problem =
  Problem.define [model_parameters: data] do
    new(name: "Problem Name", description: "Problem description", direction: :minimize)

    # Variables section
    # [Clear variable definition with pattern-based generators]

    # Constraints section
    # [Well-documented constraints with meaningful names]

    # Objective section
    # [Clear objective function definition]
  end

# ============================================================================
# Solution and Analysis
# ============================================================================

{solution, objective_value} = Problem.solve(problem, solver: :highs, print_optimizer_input: true)

# [Comprehensive solution display with validation]

# ============================================================================
# Learning Insights
# ============================================================================
# [Key takeaways and educational value]
```

## 📋 Classical LP Problems to Implement (Priority Order)

### **Tier 1: Beginner Level (Fill immediate gaps)**

1. **Two-Variable Linear Programming**

   - **DSL Features**: Basic variables, simple constraints, objective
   - **Variables**: 2 continuous variables (x, y)
   - **Constraints**: 3-4 linear inequalities defining a polygon
   - **Objective**: Simple linear function to maximize/minimize
   - **Value**: Perfect introduction to LP basics, visualizable

2. **Simple Diet Problem** (Fix existing)

   - **Current Status**: Exists but has sum(for ...) syntax issues
   - **Fix Required**: Update to use proper DSL syntax
   - **DSL Features**: Model parameters, simple constraints, cost minimization

3. **Resource Allocation (Simple)**
   - **DSL Features**: Model parameters, pattern-based constraints
   - **Variables**: 2-3 activities
   - **Constraints**: 2-3 resource limits
   - **Value**: Practical business optimization example

### **Tier 2: Intermediate Level (Add missing features)**

4. **Portfolio Optimization**

   - **DSL Features**: Parameter arrays, complex objectives, budget constraints
   - **Variables**: 5-8 investment options
   - **Constraints**: Budget, risk limits, diversification
   - **Value**: Financial application, sophisticated constraints

5. **Project Selection Problem**
   - **DSL Features**: Binary variables, budget constraints
   - **Variables**: Binary variables for each project (5-8 projects)
   - **Constraints**: Budget limit, dependency relationships
   - **Value**: Shows integer programming capabilities

### **Tier 3: Advanced Level (Showcase advanced features)**

6. **Facility Location Problem**

   - **DSL Features**: Mixed-integer programming, fixed costs
   - **Variables**: Binary facility location + continuous assignment
   - **Constraints**: Fixed costs, capacity limits, demand satisfaction
   - **Value**: Complex mixed-integer formulation

7. **Multi-Objective Linear Programming**
   - **DSL Features**: Multiple objective functions
   - **Variables**: 8-12 decision variables
   - **Objectives**: Multiple conflicting objectives
   - **Value**: Advanced multi-criteria optimization

## 🔧 DSL Feature Coverage Goals

### **Current Coverage (from analysis):**

- ✅ Basic continuous variables
- ✅ Simple constraints (==, <=, >=)
- ✅ Pattern-based variable generation
- ✅ Basic sum expressions
- ✅ Wildcard aggregations (:\_)
- ✅ Model parameters (partial support)
- ✅ Binary variables (knapsack)

### **Missing Coverage to Add:**

- ❌ Integer variables
- ❌ Complex parameter arrays
- ❌ Multi-objective optimization
- ❌ Fixed-charge constraints
- ❌ Logical constraints
- ❌ Advanced sum patterns

## 📏 Quality Standards for Examples

### **Documentation Requirements:**

1. **Header Section** (50-100 lines):

   - Problem name and description
   - Business context (real-world applications)
   - Mathematical formulation (proper notation)
   - DSL syntax highlights
   - Common gotchas section

2. **Data Definition** (20-40 lines):

   - Clear variable names
   - Meaningful comments
   - Well-structured data

3. **Problem Creation** (30-60 lines):

   - Pattern-based variable generation
   - Well-documented constraints
   - Clear objective function
   - Proper use of model parameters

4. **Solution Analysis** (40-80 lines):

   - Solution display with validation
   - Error checking and verification
   - Performance metrics

5. **Learning Insights** (10-20 lines):
   - Key takeaways
   - Educational value
   - Real-world applications

### **Technical Requirements:**

1. **DSL Syntax Compliance**:

   - Use pattern-based variable generation where possible
   - Follow DSL naming conventions
   - Proper use of wildcards and aggregations
   - Model parameters when appropriate

2. **Code Quality**:

   - No compilation warnings
   - Comprehensive error handling
   - Validation of solutions
   - Clear variable naming

3. **Educational Value**:
   - Demonstrate 2-3 DSL features per example
   - Show progressive complexity
   - Include common problem patterns
   - Provide learning insights

## 🚀 Implementation Strategy

### **Phase 1: Fix Existing Issues**

1. Fix diet_problem.exs (sum(for ...) syntax)
2. Fix transportation_problem.exs (Access.get issues)
3. Fix knapsack_problem.exs (pattern-based variables)
4. Fix assignment_problem.exs (objective calculation)

### **Phase 2: Implement New Examples**

1. **Two-Variable LP** (easiest to start with)
2. **Resource Allocation** (pattern-based constraints)
3. **Portfolio Optimization** (complex objectives)
4. **Project Selection** (binary variables)
5. **Multi-Objective LP** (advanced features)

### **Phase 3: Advanced Examples**

1. **Facility Location** (mixed-integer)
2. **Network Flow** (graph-based modeling)
3. **Stochastic Programming** (uncertainty)

## 📊 Success Metrics

1. **Coverage**: All DSL features demonstrated in working examples
2. **Quality**: All examples compile and run without errors
3. **Education**: Clear progression from basic to advanced concepts
4. **Documentation**: Comprehensive documentation in all examples
5. **Validation**: All solutions properly validated and verified

This design provides a clear roadmap for creating rich, educational examples that showcase the full capabilities of the Dantzig DSL.
