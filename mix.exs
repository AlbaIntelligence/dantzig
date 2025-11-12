defmodule Dantzig.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :dantzig,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:download_solver_binary],
      aliases: [
        "compile.download_solver_binary": &download_solver_binary/1
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "Dantzig",
      description: "Linear programming solver for Elixir",
      source_url: "https://github.com/tmbb/dantzig",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "docs/README.md",
          # User Documentation
          "docs/user/README.md",
          "docs/user/quickstart.md",
          "docs/user/tutorial/basics.md",
          "docs/user/tutorial/comprehensive.md",
          "docs/user/reference/dsl-syntax.md",
          "docs/user/reference/DSL_SYNTAX_ADVANCED.md",
          "docs/user/reference/advanced/wildcards-and-nested-maps.md",
          "docs/user/reference/advanced/error-handling.md",
          "docs/user/reference/advanced/best-practices.md",
          "docs/user/reference/DSL_SYNTAX_EXAMPLES.md",
          "docs/user/reference/pattern-operations.md",
          "docs/user/reference/variadic-operations.md",
          "docs/user/reference/expressions.md",
          "docs/user/reference/model-parameters.md",
          "docs/user/guides/modeling-patterns.md",
          "docs/user/guides/troubleshooting.md",
          "docs/user/guides/DEPRECATION_NOTICE.md",
          # Developer Documentation
          "docs/developer/README.md",
          "docs/developer/architecture/overview.md",
          "docs/developer/architecture/ast-transformation.md",
          "docs/developer/contributing/style-guide.md"
        ],
        groups_for_modules: [
          Core: [
            Dantzig,
            Dantzig.Problem,
            Dantzig.ProblemVariable,
            Dantzig.Constraint,
            Dantzig.SolvedConstraint,
            Dantzig.Polynomial,
            Dantzig.Polynomial.Operators,
            Dantzig.Solution
          ],
          "AST & Macros": [
            Dantzig.AST,
            Dantzig.AST.Parser,
            Dantzig.AST.Analyzer,
            Dantzig.AST.Transformer,
            Dantzig.DSL
          ],
          Solver: [
            Dantzig.HiGHS,
            Dantzig.HiGHSDownloader,
            Dantzig.Config,
            Dantzig.Solution.Parser
          ]
        ]
      ]
    ]
  end

  defp download_solver_binary(_) do
    Dantzig.HiGHSDownloader.maybe_download_for_target()
  end

  def elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test"]
  def elixirc_paths(:prod), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :public_key,
        :crypto,
        inets: :optional,
        ssl: :optional
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:stream_data, "~> 1.1", only: [:test, :dev]},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/dantzig"}
    ]
  end
end
