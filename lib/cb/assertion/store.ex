defmodule CB.Assertion.Store do
  @moduledoc """
  Reads and writes `assertions.json`. Atomic writes via tmp + rename.
  """

  alias CB.Assertion
  alias CB.Config

  def read do
    path = Config.assertions_path()

    if File.exists?(path) do
      with {:ok, content} <- File.read(path),
           {:ok, data} <- Jason.decode(content) do
        {:ok, Enum.map(data, &Assertion.from_map/1)}
      end
    else
      {:ok, []}
    end
  end

  def write(assertions, path \\ nil) do
    path = path || Config.assertions_path()
    ordered = Enum.map(assertions, &Assertion.to_map/1)
    json = Jason.encode!(ordered, pretty: true)
    content = json <> "\n"

    tmp_path = path <> ".tmp"

    with :ok <- File.write(tmp_path, content),
         :ok <- File.rename(tmp_path, path) do
      :ok
    else
      {:error, reason} ->
        File.rm(tmp_path)
        {:error, reason}
    end
  end
end
