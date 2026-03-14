defmodule CB.Config do
  @moduledoc """
  Path configuration for the composable beliefs repo.
  """

  def assertions_path, do: Path.join(CB.repo_root(), "org/assertions/assertions.json")
end
