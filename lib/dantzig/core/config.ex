defmodule Dantzig.Config do
  @moduledoc false

  @highs_version_file_basename "highs_version.txt"

  def default_highs_binary_path() do
    :dantzig
    |> :code.priv_dir()
    |> Path.join("bin")
    |> Path.join("highs")
  end

  def read_downloaded_version() do
    bin_path = default_highs_binary_path()
    bin_dir = Path.dirname(bin_path)
    vsn_path = Path.join(bin_dir, @highs_version_file_basename)

    case File.read(vsn_path) do
      {:ok, version} -> version
      {:error, _error} -> nil
    end
  end

  def persist_downloaded_version(version) do
    bin_path = default_highs_binary_path()
    bin_dir = Path.dirname(bin_path)
    vsn_path = Path.join(bin_dir, @highs_version_file_basename)

    File.write!(vsn_path, version)
  end

  def get_highs_version() do
    Application.get_env(:dantzig, :highs_version, "1.9.0")
  end

  def get_highs_binary_path() do
    case Application.fetch_env(:dantzig, :highs_binary_path) do
      {:ok, value} ->
        value

      :error ->
        default_highs_binary_path()
    end
  end

  def put_highs_binary_path(value) do
    Application.put_env(:dantzig, :highs_binary_path, value)
  end

  @doc """
  Compatibility getter used in coverage tests.
  Currently supports a limited set of keys; unknown keys raise ArgumentError.
  """
  def get(key) do
    case key do
      "highs_version" -> get_highs_version()
      "highs_binary_path" -> get_highs_binary_path()
      _ -> raise ArgumentError, "Unknown config key: #{inspect(key)}"
    end
  end
end
