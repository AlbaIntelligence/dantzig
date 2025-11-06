defmodule Dantzig.ProblemVariable do
  @moduledoc false
  defstruct name: nil,
            min_bound: nil,
            max_bound: nil,
            type: :real,
            description: nil

  @type variable_name :: binary()

  @doc """
  Compatibility constructor used in legacy tests.
  Accepts a keyword list with at least :name and :type.
  """
  def new(opts) when is_list(opts) do
    name = Keyword.get(opts, :name)
    type = Keyword.get(opts, :type, :real)
    description = Keyword.get(opts, :description)
    min = Keyword.get(opts, :min)
    max = Keyword.get(opts, :max)

    %__MODULE__{name: name, type: type, description: description, min_bound: min, max_bound: max}
  end
end
