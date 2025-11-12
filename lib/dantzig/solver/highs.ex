defmodule Dantzig.HiGHS do
  @moduledoc """
  HiGHS solver integration for Dantzig.

  This module provides integration with the HiGHS (High-performance
  Interior-Point Solver) for linear and quadratic programming problems.

  ## Key Functions

  - `solve/1`: Solves an optimization problem and returns a solution
  - `to_lp_iodata/1`: Serializes a problem to LP/QP format

  ## Problem Serialization

  Problems are serialized to LP/QP format with the following structure:

  - **Direction**: `Maximize` or `Minimize`
  - **Objective**: Linear and quadratic terms
  - **Constraints**: Subject To section with all constraints
  - **Bounds**: Variable bounds
  - **General/Binary**: Integer and binary variable declarations

  ## Solver Execution

  The solver is executed via system command:

  1. Write problem to temporary LP file
  2. Execute `highs` binary with model file
  3. Parse solution from output file
  4. Clean up temporary files

  ## Solution Format

  Solutions are parsed from HiGHS output format:

  - Status (optimal, infeasible, unbounded, etc.)
  - Objective value
  - Variable values
  - Constraint dual values

  ## Configuration

  Solver binary path is configured via `Dantzig.Config`:

      config :dantzig, :highs_binary_path, "/path/to/highs"

  Or use the default path from `priv/bin/highs`.

  ## See Also

  - `Dantzig.solve/1` - Main solving interface
  - `Dantzig.Solution` - Solution representation
  - `Dantzig.Config` - Configuration management
  """

  require Dantzig.Problem, as: Problem
  alias Dantzig.Config
  alias Dantzig.Constraint
  alias Dantzig.ProblemVariable
  alias Dantzig.Solution
  alias Dantzig.Polynomial

  @max_random_prefix 2 ** 32

  def solve(%Problem{} = problem) do
    iodata = to_lp_iodata(problem)
    iodata_bin = IO.iodata_to_binary(iodata)

    command = Config.default_highs_binary_path()

    with_temporary_files(["model.lp", "solution.lp"], fn [model_path, solution_path] ->
      File.write!(model_path, iodata_bin)

      {output, _error_code} =
        System.cmd(command, [
          model_path,
          "--solution_file",
          solution_path
        ])

      solution_contents =
        case File.read(solution_path) do
          {:ok, contents} ->
            contents

          {:error, :enoent} ->
            raise RuntimeError, """
            Couldn't generate a solution for the given problem.

            Input problem/model file:

            #{indent(iodata_bin, 4)}
            Output from the HiGHS solver:

            #{indent(output, 4)}
            """
        end

      Solution.from_file_contents(solution_contents)
    end)
  end

  defp indent(iodata, indent_level) do
    binary = to_string(iodata)
    spaces = String.duplicate(" ", indent_level)

    binary
    |> String.split("\n")
    |> Enum.map(fn line -> [spaces, line, "\n"] end)
  end

  defp with_temporary_files(basenames, fun) do
    dir = System.tmp_dir!()
    prefix = :rand.uniform(@max_random_prefix) |> Integer.to_string(32)

    paths =
      for basename <- basenames do
        Path.join(dir, "#{prefix}_#{basename}")
      end

    try do
      fun.(paths)
    after
      for path <- paths do
        try do
          File.rm!(path)
        rescue
          _ -> :ok
        end
      end
    end
  end

  def constraint_to_iodata(constraint = %Constraint{}, name \\ nil) do
    # Polynomial.to_lp_constraint returns [linear_terms, quadratic_terms]
    # We need to flatten this into a single iodata
    [linear_terms, quadratic_terms] = Polynomial.to_lp_constraint(constraint.left_hand_side)

    # Flatten the iodata to ensure proper string conversion
    polynomial_iodata = [linear_terms, quadratic_terms]

    base = [
      "  ",
      polynomial_iodata,
      " ",
      operator_to_iodata(constraint.operator),
      " ",
      format_lp_value(constraint.right_hand_side),
      "\n"
    ]

    # Use passed name if provided, otherwise use constraint.name
    display_name = name || constraint.name

    case display_name do
      nil ->
        base

      "" ->
        base

      name ->
        sanitized_name = sanitize_name(name)

        [
          "  ",
          sanitized_name,
          ": ",
          polynomial_iodata,
          " ",
          operator_to_iodata(constraint.operator),
          " ",
          format_lp_value(constraint.right_hand_side),
          "\n"
        ]
    end
  end

  defp operator_to_iodata(operator) do
    case operator do
      :== -> "="
      other -> to_string(other)
    end
  end

  # Sanitize variable/constraint names for LP format (CPLEX-compatible)
  defp sanitize_name(name) when is_binary(name) do
    # Apply LP format constraints: alphanumeric + ! " # $ % & ( ) , . ; ? @ _ ' ~
    # Cannot start with number or period, avoid 'E'/'e' (exponential notation)
    sanitized =
      name
      # Replace prohibited characters (exponential notation 'E', '+', '-', '*', '^', '[', ']')
      # Only replace 'e' or 'E' when followed by a digit (scientific notation) or at start of name
      # Pattern: 'e' or 'E' at start OR 'e'/'E' followed by digit (scientific notation)
      |> String.replace(~r/^[e]|[e](?=\d)/, "var_e")
      |> String.replace(~r/^[E]|[E](?=\d)/, "var_E")
      |> String.replace(~r/[\+\-\*\^\[\]]/, "_")
      # Replace prohibited characters with underscore
      |> String.replace(~r/[^A-Za-z0-9_!"#\$%&()\,\.\;\?@_'~]/, "_")
      # Trim leading/trailing underscores
      |> String.trim("_")

    # Enforce length limit
    sanitized =
      if String.length(sanitized) > 255 do
        String.slice(sanitized, 0, 255)
      else
        sanitized
      end

    case sanitized do
      <<_first::binary-size(1), _rest::binary>> ->
        sanitized

      _ ->
        # Create a new random name
        "var_" <> generate_random_var_name()
    end
  end

  defp generate_random_var_name() do
    alphabet = Enum.concat(?A..?Z)
    length = 8

    Stream.repeatedly(fn -> Enum.random(alphabet) end)
    |> Enum.take(length)
    |> List.to_string()
  end

  defp direction_to_iodata(:maximize), do: "Maximize"
  defp direction_to_iodata(:maximise), do: "Maximize"
  defp direction_to_iodata(:minimize), do: "Minimize"
  defp direction_to_iodata(:minimise), do: "Minimize"

  def to_lp_iodata(%Problem{} = problem) do
    constraints = Enum.sort(problem.constraints)

    constraints_iodata =
      Enum.map(constraints, fn {_id, constraint} ->
        constraint_to_iodata(constraint)
      end)

    bounds = all_variable_bounds(Map.values(problem.variable_defs))
    general_vars = all_general_variables(Map.values(problem.variable_defs))

    [
      direction_to_iodata(problem.direction),
      "\n  ",
      Polynomial.to_lp_iodata_objective(problem.objective),
      "\n",
      "Subject To\n",
      constraints_iodata,
      "Bounds\n",
      bounds,
      "General\n",
      general_vars,
      "End\n"
    ]
  end

  def variable_bounds(%ProblemVariable{} = v) do
    # For binary variables, set bounds to 0 <= variable <= 1
    case v.type do
      :binary ->
        "  0 <= #{v.name} <= 1\n"

      _ ->
        case {v.min_bound, v.max_bound} do
          {nil, nil} ->
            "  #{v.name} free\n"

          {nil, max} ->
            "  #{v.name} <= #{format_lp_value(max)}\n"

          {min, nil} ->
            min_str =
              if is_struct(min, Polynomial),
                do: Polynomial.serialize(min),
                else: format_lp_value(min)

            "  #{min_str} <= #{v.name}\n"

          {min, max} ->
            min_str =
              if is_struct(min, Polynomial),
                do: Polynomial.serialize(min),
                else: format_lp_value(min)

            max_str =
              if is_struct(max, Polynomial),
                do: Polynomial.serialize(max),
                else: format_lp_value(max)

            "  #{min_str} <= #{v.name}\n  #{v.name} <= #{max_str}\n"
        end
    end
  end

  defp all_variable_bounds(variables) do
    Enum.map(variables, &variable_bounds/1)
  end

  defp all_general_variables(variables) do
    general_vars =
      variables
      |> Enum.filter(fn v -> v.type == :binary or v.type == :integer end)
      |> Enum.map(fn v -> "  #{v.name}\n" end)

    if general_vars == [] do
      ""
    else
      general_vars
    end
  end

  # Format :infinity for LP export - convert to large finite number
  # LP solvers don't understand the atom :infinity, so we use 1e+30
  defp format_lp_value(:infinity), do: "1e+30"

  # Handle Polynomial structs specially
  defp format_lp_value(%Polynomial{} = poly), do: Polynomial.serialize(poly)

  # Convert all other values to string
  defp format_lp_value(value), do: to_string(value)
end
