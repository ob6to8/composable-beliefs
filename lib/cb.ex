defmodule CB do
  @moduledoc """
  Composable Beliefs - a paradigm for giving AI agents persistent,
  source-grounded, inspectable reasoning that survives session boundaries
  and composes into understanding the agent never explicitly derived.
  """

  def repo_root do
    Path.expand("../", __DIR__)
  end
end
