defmodule CB.Assertion.Filter do
  @moduledoc """
  Parses CLI filter arguments and applies them to assertion lists.
  """

  def parse_args(args) do
    {flags, positional} = extract_flags(args)

    {filters, opts} =
      Enum.reduce(positional, {[], []}, fn arg, {filters, opts} ->
        cond do
          arg in ~w(primitive compound implication) ->
            {[&(&1.kind == arg) | filters], opts}

          arg in ~w(active superseded retracted) ->
            {[&(&1.status == arg) | filters], [{:status_override, true} | opts]}

          arg == "all" ->
            {filters, [{:status_override, true} | opts]}

          arg == "stale" ->
            {filters, [{:stale, true} | opts]}

          arg == "low-confidence" ->
            {[&(&1.confidence != nil and &1.confidence < 0.5) | filters], opts}

          arg == "unlinked" ->
            {[&(&1.kind == "implication" and &1.materialized == nil) | filters], opts}

          String.starts_with?(arg, "subject_type:") ->
            st = String.replace_prefix(arg, "subject_type:", "")
            {[&(Enum.any?(&1.subjects || [], fn s -> s["type"] == st end)) | filters], opts}

          String.contains?(arg, "/") ->
            {[&(Enum.any?(&1.subjects || [], fn s -> s["ref"] == arg end)) | filters], opts}

          true ->
            {filters, [{:unknown, arg} | opts]}
        end
      end)

    filters =
      if Keyword.has_key?(opts, :status_override) do
        filters
      else
        [&(&1.status == "active") | filters]
      end

    merged_opts = Keyword.merge(flags, opts)
    {Enum.reverse(filters), merged_opts}
  end

  def apply_filters(assertions, filters) do
    Enum.filter(assertions, fn a ->
      Enum.all?(filters, fn f -> f.(a) end)
    end)
  end

  def sort(assertions) do
    kind_order = %{"primitive" => 0, "compound" => 1, "implication" => 2}

    Enum.sort_by(assertions, fn a ->
      {Map.get(kind_order, a.kind, 3), a.id}
    end)
  end

  defp extract_flags(args) do
    Enum.reduce(args, {[], []}, fn
      arg, {flags, rest} when arg in ~w(-v --verbose) ->
        {[{:verbose, true} | flags], rest}

      arg, {flags, rest} ->
        {flags, rest ++ [arg]}
    end)
  end
end
