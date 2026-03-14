defmodule CB.Assertion.Formatter do
  import CB.Display
  @moduledoc """
  Terminal output for assertions - table, detail, tree (DAG visualization).

  The tree view renders an assertion's dependency graph using box-drawing
  characters. Recursively walks deps, showing the full reasoning chain
  from implications down to primitives.
  """

  # ANSI color helpers
  defp color(:dim), do: "\e[2m"
  defp color(:reset), do: "\e[0m"
  defp color(:cyan), do: "\e[36m"
  defp color(:yellow), do: "\e[33m"
  defp color(:green), do: "\e[32m"
  defp color(:red), do: "\e[31m"
  defp color(:magenta), do: "\e[35m"

  defp kind_color("primitive"), do: color(:cyan)
  defp kind_color("compound"), do: color(:yellow)
  defp kind_color("implication"), do: color(:magenta)
  defp kind_color(_), do: color(:reset)

  defp confidence_color(c) when c >= 0.9, do: color(:green)
  defp confidence_color(c) when c >= 0.5, do: color(:yellow)
  defp confidence_color(_), do: color(:red)

  defp status_indicator(%{status: "active"}), do: ""
  defp status_indicator(%{status: "superseded"}), do: " #{color(:dim)}[superseded]#{color(:reset)}"
  defp status_indicator(%{status: "retracted"}), do: " #{color(:red)}[retracted]#{color(:reset)}"
  defp status_indicator(_), do: ""

  # --- Table view ---

  def table(assertions, total) do
    if assertions == [] do
      ["No matching assertions.", "", "0 assertions (of #{total} total)"]
    else
      term_width = terminal_width()
      claim_width = max(term_width - 52, 30)

      header = table_row("ID", "KIND", "CONF", "STATUS", "CLAIM", claim_width)
      sep = table_row("----", "----", "----", "------", "-----", claim_width)

      rows =
        Enum.map(assertions, fn a ->
          conf = if a.confidence, do: :erlang.float_to_binary(a.confidence, decimals: 1), else: "-"
          table_row(a.id, a.kind, conf, a.status, trunc(a.claim, claim_width), claim_width)
        end)

      count = length(assertions)
      [header, sep] ++ rows ++ ["", "#{count} assertions (of #{total} total)"]
    end
  end

  defp table_row(id, kind, conf, status, claim, claim_width) do
    :io_lib.format("~-5s ~-12s ~-5s ~-12s ~-*s", [id, kind, conf, status, claim_width, claim])
    |> IO.iodata_to_binary()
  end

  # --- Detail view ---

  def detail(assertion) do
    a = assertion
    lines = [
      "",
      "ID:          #{a.id}",
      "Kind:        #{a.kind}",
      "Claim:       #{a.claim}",
      "Confidence:  #{a.confidence || "-"}",
      "Status:      #{a.status}"
    ]

    lines = lines ++ subjects_lines(a.subjects)

    lines = if a.kind == "primitive" do
      lines ++ ["Source:      #{a.source || "-"}"]
    else
      dep_str = Enum.join(a.deps || [], ", ")
      lines ++ [
        "Deps:        #{dep_str}",
        "Implication: #{a.implication || "-"}"
      ]
    end

    lines = lines ++ evidence_lines(a.evidence)

    lines = if a.kind == "implication" do
      mat = case a.materialized do
        nil -> "-"
        %{"date" => d, "todos" => ts} -> "#{d} (#{length(ts)} todo(s))"
        _ -> inspect(a.materialized)
      end
      lines ++ ["Materialized: #{mat}"]
    else
      lines
    end

    lines = lines ++ [
      "Created:     #{a.created || "-"}"
    ]

    lines = if a.superseded_by do
      lines ++ ["Superseded:  #{a.superseded_by}"]
    else
      lines
    end

    lines ++ [""]
  end

  defp evidence_lines(evidence) when is_list(evidence) and length(evidence) > 0 do
    evidence
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {e, idx} ->
      header = if length(evidence) == 1, do: "Evidence:", else: "Evidence #{idx}:"
      lines = ["#{String.pad_trailing(header, 13)}#{e["detail"] || "-"}"]
      lines = if e["source"], do: lines ++ ["             source: #{e["source"]}"], else: lines
      if e["date"], do: lines ++ ["             date: #{e["date"]}"], else: lines
    end)
  end

  defp evidence_lines(_), do: []

  defp subjects_lines(subjects) when is_list(subjects) and length(subjects) > 0 do
    formatted =
      subjects
      |> Enum.map(fn s -> "#{s["ref"]} (#{s["type"]})" end)
      |> Enum.join(", ")

    ["Subjects:    #{formatted}"]
  end

  defp subjects_lines(_), do: ["Subjects:    -"]

  # --- Tree view (DAG visualizer) ---

  def tree(root, all_assertions) do
    index = Map.new(all_assertions, &{&1.id, &1})
    lines = tree_lines(root, index, :root, true, MapSet.new())
    [""] ++ lines ++ [""]
  end

  defp tree_lines(assertion, index, prefix, is_last, visited) do
    a = assertion
    is_root = prefix == :root

    connector = cond do
      is_root -> ""
      is_last -> "└── "
      true -> "├── "
    end

    display_prefix = if is_root, do: "", else: prefix

    kc = kind_color(a.kind)
    cc = if a.confidence, do: confidence_color(a.confidence), else: color(:dim)
    conf_str = if a.confidence, do: :erlang.float_to_binary(a.confidence, decimals: 1), else: "?"
    rst = color(:reset)
    si = status_indicator(a)

    line = "#{display_prefix}#{connector}#{kc}#{a.id}#{rst} #{color(:dim)}[#{a.kind}]#{rst} (#{cc}#{conf_str}#{rst}) #{a.claim}#{si}"

    meta_prefix = if is_root, do: "", else: child_prefix(prefix, is_last)

    extra = cond do
      a.kind == "primitive" and a.source ->
        src_line = "#{meta_prefix}  #{color(:dim)}source: #{a.source}#{rst}"
        evidence_lines = (a.evidence || [])
        |> Enum.flat_map(fn e ->
          detail = e["detail"]
          if detail do
            wrapped = wrap_text(detail, max(terminal_width() - String.length(meta_prefix) - 4, 40))
            Enum.map(wrapped, fn l -> "#{meta_prefix}  #{color(:dim)}> #{l}#{rst}" end)
          else
            []
          end
        end)
        [src_line] ++ evidence_lines
      a.kind == "implication" and a.materialized ->
        mat = a.materialized
        count = length(mat["todos"] || [])
        ["#{meta_prefix}  #{color(:dim)}materialized: #{mat["date"]} (#{count} todo(s))#{rst}"]
      true ->
        []
    end

    subj = if is_list(a.subjects) and length(a.subjects) > 0 do
      types = a.subjects |> Enum.map(fn s -> s["type"] end) |> Enum.uniq() |> Enum.join(", ")
      ["#{meta_prefix}  #{color(:dim)}subjects: #{types}#{rst}"]
    else
      []
    end

    impl = if a.implication != nil and a.kind != "primitive" do
      wrapped = wrap_text(a.implication, max(terminal_width() - String.length(meta_prefix) - 4, 40))
      Enum.map(wrapped, fn l -> "#{meta_prefix}  #{color(:dim)}> #{l}#{rst}" end)
    else
      []
    end

    deps = a.deps || []

    if a.id in visited do
      ["#{line} #{color(:dim)}(circular ref)#{rst}"]
    else
      new_visited = MapSet.put(visited, a.id)
      child_pref = if is_root, do: "", else: child_prefix(prefix, is_last)

      dep_lines =
        deps
        |> Enum.with_index()
        |> Enum.flat_map(fn {dep_id, idx} ->
          case Map.get(index, dep_id) do
            nil ->
              dep_connector = if idx == length(deps) - 1, do: "└── ", else: "├── "
              ["#{child_pref}#{dep_connector}#{color(:red)}#{dep_id} (missing)#{rst}"]

            dep ->
              tree_lines(dep, index, child_pref, idx == length(deps) - 1, new_visited)
          end
        end)

      [line] ++ subj ++ extra ++ impl ++ dep_lines
    end
  end

  defp child_prefix(prefix, true), do: prefix <> "    "
  defp child_prefix(prefix, false), do: prefix <> "│   "

  # --- Stale report ---

  def stale_report(stale_compounds, all_assertions) do
    if stale_compounds == [] do
      ["No stale assertions found."]
    else
      index = Map.new(all_assertions, &{&1.id, &1})

      lines = ["", "Stale assertions (deps superseded or retracted):", ""]

      detail_lines =
        Enum.flat_map(stale_compounds, fn a ->
          bad_deps =
            (a.deps || [])
            |> Enum.filter(fn dep_id ->
              case Map.get(index, dep_id) do
                nil -> false
                dep -> dep.status in ~w(superseded retracted)
              end
            end)
            |> Enum.map(fn dep_id ->
              dep = Map.get(index, dep_id)
              reason = if dep.superseded_by, do: "superseded by #{dep.superseded_by}", else: dep.status
              "    #{dep_id}: #{reason}"
            end)

          ["  #{a.id} #{a.claim}" | bad_deps] ++ [""]
        end)

      lines ++ detail_lines ++ ["#{length(stale_compounds)} stale assertion(s)"]
    end
  end

  # --- Helpers ---

  defp wrap_text(text, width) do
    words = String.split(text)
    {lines, current} =
      Enum.reduce(words, {[], ""}, fn word, {lines, current} ->
        candidate = if current == "", do: word, else: current <> " " <> word
        if String.length(candidate) > width and current != "" do
          {[current | lines], word}
        else
          {lines, candidate}
        end
      end)

    Enum.reverse(if current == "", do: lines, else: [current | lines])
  end
end
