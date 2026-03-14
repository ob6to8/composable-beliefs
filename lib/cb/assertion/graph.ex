defmodule CB.Assertion.Graph do
  @moduledoc """
  Graph operations on the assertion DAG. Pure deterministic traversal -
  no LLM reasoning, same input always produces same output.

  All functions take an index (map of id => assertion) built from the
  full assertion list. Build once with `index/1`, pass to all operations.
  """

  @doc "Build an id => assertion lookup map."
  def index(assertions), do: Map.new(assertions, &{&1.id, &1})

  @doc "Direct dependencies of an assertion."
  def deps(%{deps: deps}, _index) when is_list(deps), do: deps
  def deps(_, _), do: []

  @doc "Resolve dep IDs to assertion structs."
  def resolve_deps(assertion, index) do
    assertion
    |> deps(index)
    |> Enum.map(&Map.get(index, &1))
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  All assertions that depend on the given ID (reverse lookup).
  Returns direct dependents only unless `deep: true`.
  """
  def dependents(id, assertions, opts \\ []) do
    direct =
      Enum.filter(assertions, fn a ->
        is_list(a.deps) and id in a.deps
      end)

    if Keyword.get(opts, :deep, false) do
      deep_dependents(Enum.map(direct, & &1.id), assertions, MapSet.new([id]))
    else
      direct
    end
  end

  defp deep_dependents([], _assertions, _visited), do: []

  defp deep_dependents(ids, assertions, visited) do
    new_visited = MapSet.union(visited, MapSet.new(ids))

    direct =
      Enum.filter(assertions, fn a ->
        is_list(a.deps) and Enum.any?(a.deps, &(&1 in ids)) and
          a.id not in visited
      end)

    next_ids =
      direct
      |> Enum.map(& &1.id)
      |> Enum.reject(&MapSet.member?(new_visited, &1))

    direct ++ deep_dependents(next_ids, assertions, new_visited)
  end

  @doc """
  Find a dependency path from `from_id` to `to_id`.
  Returns `{:ok, [id1, id2, ...]}` or `:no_path`.
  Searches both downstream (deps) and upstream (dependents).
  """
  def path(from_id, to_id, index, assertions) do
    case bfs_path(from_id, to_id, index, :down, assertions) do
      {:ok, p} -> {:ok, p}
      :no_path ->
        case bfs_path(from_id, to_id, index, :up, assertions) do
          {:ok, p} -> {:ok, p}
          :no_path -> :no_path
        end
    end
  end

  defp bfs_path(from, to, _index, _dir, _assertions) when from == to, do: {:ok, [from]}

  defp bfs_path(from, to, index, dir, assertions) do
    queue = :queue.in({from, [from]}, :queue.new())
    bfs_step(queue, to, index, dir, assertions, MapSet.new([from]))
  end

  defp bfs_step(queue, to, index, dir, assertions, visited) do
    case :queue.out(queue) do
      {:empty, _} ->
        :no_path

      {{:value, {current, path}}, rest} ->
        neighbors = case dir do
          :down ->
            case Map.get(index, current) do
              nil -> []
              a -> a.deps || []
            end
          :up ->
            assertions
            |> Enum.filter(fn a -> is_list(a.deps) and current in a.deps end)
            |> Enum.map(& &1.id)
        end

        case Enum.find(neighbors, &(&1 == to)) do
          nil ->
            {new_queue, new_visited} =
              Enum.reduce(neighbors, {rest, visited}, fn n, {q, v} ->
                if MapSet.member?(v, n) do
                  {q, v}
                else
                  {:queue.in({n, path ++ [n]}, q), MapSet.put(v, n)}
                end
              end)
            bfs_step(new_queue, to, index, dir, assertions, new_visited)

          _ ->
            {:ok, path ++ [to]}
        end
    end
  end

  @doc """
  Supersession history for an assertion.
  Returns `{predecessors, successors}` where each is a list of assertions
  in chronological order.
  """
  def history(id, assertions) do
    idx = index(assertions)
    successors = walk_successors(id, idx)
    predecessors = walk_predecessors(id, assertions)
    {Enum.reverse(predecessors), successors}
  end

  defp walk_successors(id, index, visited \\ MapSet.new()) do
    if MapSet.member?(visited, id) do
      []
    else
      case Map.get(index, id) do
        nil -> []
        a ->
          case a.superseded_by do
            nil -> []
            next_id ->
              case Map.get(index, next_id) do
                nil -> []
                next -> [next | walk_successors(next_id, index, MapSet.put(visited, id))]
              end
          end
      end
    end
  end

  defp walk_predecessors(id, assertions, visited \\ MapSet.new()) do
    if MapSet.member?(visited, id) do
      []
    else
      case Enum.find(assertions, &(&1.superseded_by == id)) do
        nil -> []
        pred -> [pred | walk_predecessors(pred.id, assertions, MapSet.put(visited, id))]
      end
    end
  end

  @doc """
  Find stale assertions with optional cascade detection.
  Returns list of `{assertion, stale_deps}` tuples.
  """
  def stale(assertions, opts \\ []) do
    cascade = Keyword.get(opts, :cascade, false)

    superseded_ids =
      assertions
      |> Enum.filter(&(&1.status in ~w(superseded retracted)))
      |> Enum.map(& &1.id)
      |> MapSet.new()

    direct_stale =
      assertions
      |> Enum.filter(fn a ->
        a.kind != "primitive" and a.status == "active" and
          Enum.any?(a.deps || [], &MapSet.member?(superseded_ids, &1))
      end)
      |> Enum.map(fn a ->
        bad = Enum.filter(a.deps || [], &MapSet.member?(superseded_ids, &1))
        {a, bad}
      end)

    if cascade do
      direct_ids = MapSet.new(Enum.map(direct_stale, fn {a, _} -> a.id end))
      cascade_stale(assertions, direct_stale, direct_ids, superseded_ids)
    else
      direct_stale
    end
  end

  defp cascade_stale(assertions, found, found_ids, problem_ids) do
    all_problem = MapSet.union(problem_ids, found_ids)

    next =
      assertions
      |> Enum.filter(fn a ->
        a.kind != "primitive" and a.status == "active" and
          not MapSet.member?(found_ids, a.id) and
          Enum.any?(a.deps || [], &MapSet.member?(found_ids, &1))
      end)
      |> Enum.map(fn a ->
        bad = Enum.filter(a.deps || [], &MapSet.member?(all_problem, &1))
        {a, bad}
      end)

    if next == [] do
      found
    else
      next_ids = MapSet.new(Enum.map(next, fn {a, _} -> a.id end))
      cascade_stale(assertions, found ++ next, MapSet.union(found_ids, next_ids), all_problem)
    end
  end

  @doc "Find all assertions about a given subject ref or type."
  def by_subject(assertions, ref: ref) do
    Enum.filter(assertions, fn a ->
      Enum.any?(a.subjects || [], fn s -> s["ref"] == ref end)
    end)
  end

  def by_subject(assertions, type: type) do
    Enum.filter(assertions, fn a ->
      Enum.any?(a.subjects || [], fn s -> s["type"] == type end)
    end)
  end

  @doc "Aggregate statistics across the graph."
  def stats(assertions) do
    active = Enum.filter(assertions, &(&1.status == "active"))

    by_kind = Enum.frequencies_by(assertions, & &1.kind)
    by_status = Enum.frequencies_by(assertions, & &1.status)

    confidences =
      assertions
      |> Enum.map(& &1.confidence)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    stale_count = length(stale(assertions))

    unlinked =
      active
      |> Enum.count(&(&1.kind == "implication" and &1.materialized == nil))

    source_types =
      assertions
      |> Enum.filter(&(&1.kind == "primitive" and &1.source != nil))
      |> Enum.map(fn a ->
        case String.split(a.source, ":", parts: 2) do
          [prefix, _] -> prefix
          [single] -> single
        end
      end)
      |> Enum.frequencies()

    dep_depths =
      active
      |> Enum.filter(&(&1.kind != "primitive"))
      |> Enum.map(&max_depth(&1.id, index(assertions), MapSet.new()))
      |> Enum.sort()

    dep_counts =
      assertions
      |> Enum.filter(&(&1.status == "active"))
      |> Enum.flat_map(&(&1.deps || []))
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_id, count} -> -count end)
      |> Enum.take(5)

    %{
      total: length(assertions),
      by_kind: by_kind,
      by_status: by_status,
      confidences: confidences,
      stale_count: stale_count,
      unlinked_implications: unlinked,
      source_types: source_types,
      dep_depths: dep_depths,
      most_depended: dep_counts
    }
  end

  defp max_depth(id, index, visited) do
    if MapSet.member?(visited, id) do
      0
    else
      case Map.get(index, id) do
        nil -> 0
        a ->
          deps = a.deps || []
          if deps == [] do
            0
          else
            new_visited = MapSet.put(visited, id)
            1 + (deps |> Enum.map(&max_depth(&1, index, new_visited)) |> Enum.max(fn -> 0 end))
          end
      end
    end
  end
end
