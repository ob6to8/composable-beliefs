defmodule Mix.Tasks.Bs do
  @moduledoc """
  Belief shell - deterministic interface to the assertion DAG.

  ## Deterministic [D]

      list [filters]       List assertions matching filters
      show <id>            Full detail on a single assertion
      tree <id>            Dependency tree visualization
      deps <id>            Direct dependencies
      dependents <id>      Reverse dependency lookup
      stale                Find assertions with problematic deps
      path <id1> <id2>     Find connection between two assertions
      history <id>         Supersession chain
      subjects <ref|type>  Find assertions by subject
      stats                Graph-level statistics

  ## Filters (for list)

      primitive|compound|implication    Filter by kind
      active|superseded|retracted|all  Filter by status (default: active)
      low-confidence                   Confidence < 0.5
      high-confidence                  Confidence >= 0.9
      unlinked                         Implications with no materialized todos
      subject_type:<type>              By subject type
      source:<prefix>                  By source prefix
      -v / --verbose                   Show full detail

  """
  @shortdoc "Belief shell - query and traverse the assertion DAG"

  use Mix.Task

  import CB.Display

  alias CB.Assertion.{Filter, Formatter, Graph, Store}

  @impl Mix.Task
  def run(args) do
    {flags, positional} = extract_flags(args)

    case positional do
      ["list" | rest] -> cmd_list(rest ++ flag_args(flags))
      ["show", id | _] -> cmd_show(id)
      ["tree", id | _] -> cmd_tree(id)
      ["deps", id | _] -> cmd_deps(id, flags)
      ["dependents", id | _] -> cmd_dependents(id, flags)
      ["stale" | _] -> cmd_stale(flags)
      ["path", id1, id2 | _] -> cmd_path(id1, id2)
      ["history", id | _] -> cmd_history(id)
      ["subjects" | rest] -> cmd_subjects(rest)
      ["stats" | _] -> cmd_stats()
      ["help" | _] -> cmd_help()
      [] -> cmd_help()
      [cmd | _] ->
        if Regex.match?(~r/^a\d+$/, cmd) do
          cmd_show(cmd)
        else
          IO.puts(:stderr, "Unknown command: #{cmd}")
          IO.puts(:stderr, "Run `mix bs help` for usage.")
          System.halt(1)
        end
    end
  end

  # --- Commands ---

  defp cmd_list(args) do
    {filters, opts} = Filter.parse_args(args)

    unknowns = Keyword.get_values(opts, :unknown)
    for arg <- unknowns do
      if String.starts_with?(arg, "source:") do
        :ok
      else
        IO.puts(:stderr, "Unknown filter: #{arg}")
        System.halt(1)
      end
    end

    {:ok, assertions} = Store.read()
    total = length(assertions)

    source_filters =
      unknowns
      |> Enum.filter(&String.starts_with?(&1, "source:"))
      |> Enum.map(fn arg ->
        prefix = String.replace_prefix(arg, "source:", "")
        fn a -> a.source != nil and String.starts_with?(a.source, prefix) end
      end)

    all_filters = filters ++ source_filters
    filtered = assertions |> Filter.apply_filters(all_filters) |> Filter.sort()

    filtered = if "high-confidence" in args do
      Enum.filter(filtered, &(&1.confidence != nil and &1.confidence >= 0.9))
    else
      filtered
    end

    lines =
      if Keyword.get(opts, :verbose) do
        Enum.flat_map(filtered, &Formatter.detail/1) ++
          ["#{length(filtered)} assertions (of #{total} total)"]
      else
        Formatter.table(filtered, total)
      end

    Enum.each(lines, &IO.puts/1)
  end

  defp cmd_show(id) do
    {:ok, assertions} = Store.read()

    case Enum.find(assertions, &(&1.id == id)) do
      nil ->
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      assertion ->
        Formatter.detail(assertion) |> Enum.each(&IO.puts/1)
    end
  end

  defp cmd_tree(id) do
    {:ok, assertions} = Store.read()

    case Enum.find(assertions, &(&1.id == id)) do
      nil ->
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      assertion ->
        Formatter.tree(assertion, assertions) |> Enum.each(&IO.puts/1)
    end
  end

  defp cmd_deps(id, flags) do
    {:ok, assertions} = Store.read()
    idx = Graph.index(assertions)

    case Map.get(idx, id) do
      nil ->
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      assertion ->
        if Keyword.get(flags, :deep) do
          cmd_tree(id)
        else
          resolved = Graph.resolve_deps(assertion, idx)
          if resolved == [] do
            IO.puts("#{id} has no dependencies (primitive).")
          else
            Formatter.table(resolved, length(assertions)) |> Enum.each(&IO.puts/1)
          end
        end
    end
  end

  defp cmd_dependents(id, flags) do
    {:ok, assertions} = Store.read()
    idx = Graph.index(assertions)

    case Map.get(idx, id) do
      nil ->
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      _assertion ->
        deep = Keyword.get(flags, :deep, false)
        results = Graph.dependents(id, assertions, deep: deep)
        if results == [] do
          IO.puts("Nothing depends on #{id}.")
        else
          label = if deep, do: "deep dependents", else: "dependents"
          IO.puts("")
          IO.puts("#{length(results)} #{label} of #{id}:")
          IO.puts("")
          Formatter.table(results, length(assertions)) |> Enum.each(&IO.puts/1)
        end
    end
  end

  defp cmd_stale(flags) do
    {:ok, assertions} = Store.read()
    cascade = Keyword.get(flags, :cascade, false)
    results = Graph.stale(assertions, cascade: cascade)

    if results == [] do
      IO.puts("No stale assertions found.")
    else
      idx = Graph.index(assertions)
      label = if cascade, do: " (with cascade)", else: ""
      IO.puts("")
      IO.puts("Stale assertions#{label}:")
      IO.puts("")

      Enum.each(results, fn {a, bad_deps} ->
        IO.puts("  #{a.id} #{a.claim}")
        Enum.each(bad_deps, fn dep_id ->
          dep = Map.get(idx, dep_id)
          reason = cond do
            dep == nil -> "missing"
            dep.superseded_by -> "superseded by #{dep.superseded_by}"
            dep.status == "retracted" -> "retracted"
            true -> dep.status
          end
          IO.puts("    #{dep_id}: #{reason}")
        end)
        IO.puts("")
      end)

      IO.puts("#{length(results)} stale assertion(s)")
    end
  end

  defp cmd_path(id1, id2) do
    {:ok, assertions} = Store.read()
    idx = Graph.index(assertions)

    for id <- [id1, id2] do
      unless Map.has_key?(idx, id) do
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      end
    end

    case Graph.path(id1, id2, idx, assertions) do
      {:ok, path} ->
        IO.puts("")
        IO.puts("Path from #{id1} to #{id2} (#{length(path)} nodes):")
        IO.puts("")

        path
        |> Enum.with_index()
        |> Enum.each(fn {id, i} ->
          a = Map.get(idx, id)
          connector = if i == 0, do: "  ", else: "  -> "
          conf = if a.confidence, do: "(#{:erlang.float_to_binary(a.confidence, decimals: 1)})", else: ""
          IO.puts("#{connector}#{a.id} [#{a.kind}] #{conf} #{trunc(a.claim, 60)}")
        end)

        IO.puts("")

      :no_path ->
        IO.puts("No path between #{id1} and #{id2}.")
    end
  end

  defp cmd_history(id) do
    {:ok, assertions} = Store.read()
    idx = Graph.index(assertions)

    case Map.get(idx, id) do
      nil ->
        IO.puts(:stderr, "No assertion with id: #{id}")
        System.halt(1)
      target ->
        {predecessors, successors} = Graph.history(id, assertions)
        chain = predecessors ++ [target] ++ successors

        if length(chain) == 1 do
          IO.puts("#{id} has no supersession history (standalone).")
        else
          IO.puts("")
          IO.puts("Supersession chain (#{length(chain)} assertions):")
          IO.puts("")

          chain
          |> Enum.with_index()
          |> Enum.each(fn {a, i} ->
            marker = if a.id == id, do: " <-- current", else: ""
            status = case a.status do
              "active" -> ""
              s -> " [#{s}]"
            end
            arrow = if i > 0, do: "  -> ", else: "  "
            IO.puts("#{arrow}#{a.id}#{status} #{trunc(a.claim, 50)} (#{a.created || "?"})#{marker}")
          end)

          IO.puts("")
        end
    end
  end

  defp cmd_subjects(args) do
    {:ok, assertions} = Store.read()

    results = case args do
      [] ->
        IO.puts(:stderr, "Usage: mix bs subjects <ref|--type TYPE>")
        System.halt(1)
      ["--type", type | _] ->
        Graph.by_subject(assertions, type: type)
      [ref | _] ->
        if String.contains?(ref, "/") do
          Graph.by_subject(assertions, ref: ref)
        else
          Graph.by_subject(assertions, type: ref)
        end
    end

    active = Enum.filter(results, &(&1.status == "active"))

    if active == [] do
      IO.puts("No active assertions found for that subject.")
    else
      Formatter.table(active, length(assertions)) |> Enum.each(&IO.puts/1)
    end
  end

  defp cmd_stats do
    {:ok, assertions} = Store.read()
    s = Graph.stats(assertions)

    IO.puts("")
    IO.puts("Assertion DAG Statistics")
    IO.puts("========================")
    IO.puts("")
    IO.puts("Total: #{s.total}")
    IO.puts("")

    IO.puts("By kind:")
    Enum.each(s.by_kind, fn {k, v} -> IO.puts("  #{k}: #{v}") end)
    IO.puts("")

    IO.puts("By status:")
    Enum.each(s.by_status, fn {k, v} -> IO.puts("  #{k}: #{v}") end)
    IO.puts("")

    if s.confidences != [] do
      min_c = List.first(s.confidences)
      max_c = List.last(s.confidences)
      mean = Enum.sum(s.confidences) / length(s.confidences)
      median = Enum.at(s.confidences, div(length(s.confidences), 2))
      IO.puts("Confidence:")
      IO.puts("  min: #{:erlang.float_to_binary(min_c * 1.0, decimals: 2)}")
      IO.puts("  max: #{:erlang.float_to_binary(max_c * 1.0, decimals: 2)}")
      IO.puts("  mean: #{:erlang.float_to_binary(mean * 1.0, decimals: 2)}")
      IO.puts("  median: #{:erlang.float_to_binary(median * 1.0, decimals: 2)}")
      IO.puts("")
    end

    IO.puts("Stale: #{s.stale_count}")
    IO.puts("Unlinked implications: #{s.unlinked_implications}")
    IO.puts("")

    if s.source_types != %{} do
      IO.puts("Source types:")
      s.source_types
      |> Enum.sort_by(fn {_, v} -> -v end)
      |> Enum.each(fn {k, v} -> IO.puts("  #{k}: #{v}") end)
      IO.puts("")
    end

    if s.dep_depths != [] do
      max_depth = List.last(s.dep_depths)
      mean_depth = Enum.sum(s.dep_depths) / max(length(s.dep_depths), 1)
      IO.puts("Dependency depth:")
      IO.puts("  max: #{max_depth}")
      IO.puts("  mean: #{:erlang.float_to_binary(mean_depth * 1.0, decimals: 1)}")
      IO.puts("")
    end

    if s.most_depended != [] do
      IO.puts("Most depended-on:")
      Enum.each(s.most_depended, fn {id, count} ->
        IO.puts("  #{id}: #{count} dependents")
      end)
      IO.puts("")
    end
  end

  defp cmd_help do
    IO.puts("""

    bs - belief shell

    DETERMINISTIC [D]
      list [filters]       List assertions matching filters
      show <id>            Full detail on a single assertion
      tree <id>            Dependency tree visualization
      deps <id>            Direct dependencies
      dependents <id>      Reverse dependency lookup (--deep for transitive)
      stale                Find assertions with problematic deps (--cascade for transitive)
      path <id1> <id2>     Find connection between two assertions
      history <id>         Supersession chain
      subjects <ref|type>  Find assertions by subject
      stats                Graph-level statistics

    FLAGS
      -v / --verbose       Show full detail in list view
      --deep               Recurse through full chain (deps, dependents)
      --cascade            Include transitively stale (stale)
    """)
  end

  # --- Flag extraction ---

  defp extract_flags(args) do
    Enum.reduce(args, {[], []}, fn
      arg, {flags, rest} when arg in ~w(-v --verbose) ->
        {[{:verbose, true} | flags], rest}
      "--deep", {flags, rest} ->
        {[{:deep, true} | flags], rest}
      "--cascade", {flags, rest} ->
        {[{:cascade, true} | flags], rest}
      arg, {flags, rest} ->
        {flags, rest ++ [arg]}
    end)
  end

  defp flag_args(flags) do
    Enum.flat_map(flags, fn
      {:verbose, true} -> ["-v"]
      _ -> []
    end)
  end
end
