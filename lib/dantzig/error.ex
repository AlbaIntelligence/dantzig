defmodule Dantzig.Error do
  @moduledoc """
  Error struct for consistent error reporting across Dantzig.
  """
  defstruct [:type, :message, :suggestions, :code_location]
end
