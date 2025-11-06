IO.puts("=== Debugging AST Patterns ===")

# Let's see what AST patterns are actually generated
ex1 =
  quote do
    variables("x", [i <- 1..2], :continuous, "X variable")
  end

ex2 =
  quote do
    variables("y", [i <- 1..2], :continuous, "Y variable", min_bound: 0, max_bound: 100)
  end

IO.puts("\n--- AST for variables WITHOUT bounds ---")
IO.inspect(ex1)

IO.puts("\n--- AST for variables WITH bounds ---")
IO.inspect(ex2)

# Now let's manually trace what the reducer should be matching
IO.puts("\n=== Pattern Matching Analysis ===")

# Test pattern 1: Full generator with bounds - should match 5-element pattern
# Manually construct the AST that our DSL macro would generate
ast1 =
  {:variables, [],
   [
     "y",
     [{:->, [], [[i], {:in, [], [i, {:.., [], [1, 2]}]}]}],
     :continuous,
     "Y variable",
     [min_bound: 0, max_bound: 100]
   ]}

IO.puts("Testing 5-element bounds pattern:")
IO.inspect(ast1)

case ast1 do
  {:variables, _, [name, generators, type, description, bounds_opts]} when is_list(bounds_opts) ->
    IO.puts("✅ Matched 5-element bounds pattern")

    {desc, bounds_list} =
      Dantzig.Problem.DSL.ConstraintManager.extract_description_and_bounds([
        description | bounds_opts
      ])

    IO.inspect(desc)
    IO.inspect(bounds_list)
    min_bound = Keyword.get(bounds_list, :min_bound)
    max_bound = Keyword.get(bounds_list, :max_bound)
    IO.inspect(min_bound)
    IO.inspect(max_bound)

  _ ->
    IO.puts("❌ Did not match 5-element bounds pattern")
end

# Test pattern 2: See if it matches the 4-element generator pattern instead
ast2 =
  {:variables, [],
   [
     "y",
     [{:->, [], [[i], {:in, [], [i, {:.., [], [1, 2]}]}]}],
     :continuous,
     [min_bound: 0, max_bound: 100]
   ]}

IO.puts("\nTesting 4-element generator pattern:")
IO.inspect(ast2)

case ast2 do
  {:variables, _, [name, generators, type, opts_or_desc]} ->
    IO.puts("✅ Matched 4-element generator pattern")
    IO.puts("This would be processed by the wrong pattern!")

  _ ->
    IO.puts("❌ Did not match 4-element generator pattern")
end

# Test pattern 3: Check what the cons pattern would match
IO.puts("\n=== Cons Pattern Analysis ===")
remaining = ["Y variable", [min_bound: 0, max_bound: 100]]

case remaining do
  [description | opts] when is_list(opts) ->
    IO.puts("Cons pattern matched!")

    {desc, bounds_list} =
      Dantzig.Problem.DSL.ConstraintManager.extract_description_and_bounds([description | opts])

    IO.inspect(desc)
    IO.inspect(bounds_list)

  _ ->
    IO.puts("Cons pattern did not match")
end
