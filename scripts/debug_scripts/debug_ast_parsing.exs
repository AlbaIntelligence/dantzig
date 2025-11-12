defmodule DebugASTParsing do
  require Dantzig.Problem.DSL, as: DSL

  def main do
    IO.puts("=== Debugging Variable Bounds AST Generation ===")

    # Test simple syntax
    ast1 =
      quote do
        variables("x", :continuous, "X variable", min_bound: 0, max_bound: 100)
      end

    IO.inspect(ast1, label: "Simple syntax AST")

    # Test generator syntax
    ast2 =
      quote do
        variables("qty", [food <- ["bread", "milk"]], :continuous, "Quantity",
          min_bound: 0,
          max_bound: 100
        )
      end

    IO.inspect(ast2, label: "Generator syntax AST")
  end
end

DebugASTParsing.main()
