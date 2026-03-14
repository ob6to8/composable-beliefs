# Composable Beliefs on the BEAM

**Status:** active
**Date:** 2026-03-14

## Why the BEAM

The BEAM (Erlang VM) isn't just a good runtime for hosting a belief graph service - it's the runtime that makes composable beliefs viable at scale. The primitives align:

| CB requirement | BEAM primitive | Python equivalent |
|---|---|---|
| Many agents, each with own belief state | Processes (~2.5KB each, millions concurrent) | Threads/asyncio (heavyweight, limited) |
| Agent-to-agent belief sharing | Message passing (built-in, location-transparent) | HTTP, MCP, message brokers (bolted on) |
| Agent crashes don't corrupt beliefs | Process crash doesn't affect others | Exception can poison the event loop |
| Restart with beliefs intact | Supervision trees + externalized beliefs | Try/except + manual restart logic |
| Live updates to belief logic | Hot code reloading | Redeploy entire service |
| Distribute belief graphs across machines | Transparent distribution (built-in) | Kubernetes, service mesh, message queues |
| Graph traversal at VM speed | ETS tables (`:digraph` is a VM primitive) | Application-level graph libraries |

These are categorical differences, not marginal improvements.

## The critical coupling: supervision + externalized beliefs

Erlang's "let it crash" philosophy is exactly right for agents - but only if belief state is externalized. Without persistent beliefs, a crashed agent loses everything. With composable beliefs, the restarted process queries the DAG and picks up where it left off.

```elixir
defmodule MyAgent do
  use GenServer

  def init(agent_id) do
    # On start (or restart), load belief state
    {:ok, beliefs} = CB.Assertion.Store.read()
    {:ok, %{agent_id: agent_id, beliefs: beliefs}}
  end

  def handle_cast({:process, task}, state) do
    # Agent does work, forms beliefs
    # Beliefs persist in the DAG, not in process state
    # If this process crashes, supervisor restarts it
    # init/1 reloads beliefs. Nothing lost.
    {:noreply, state}
  end
end
```

This is the deep coupling: composable beliefs is what makes the BEAM's restart semantics viable for agents. The runtime provides fault tolerance. The DAG provides memory.

## What this means for a service

A CB service running on the BEAM gets specific advantages:

- **Process-per-agent-state.** Each agent's belief DAG lives in its own lightweight process. Millions concurrent, fault-isolated. A misbehaving agent's graph operations can't slow down others.
- **ETS for graph operations.** The `bs dependents`, `bs path`, `bs stale --cascade` operations are graph traversals. Erlang's `:digraph` module runs on ETS tables - graph traversal is a VM-level primitive, not an application-level library.
- **Built-in distribution.** Belief states can migrate between nodes. For multi-agent systems sharing a belief store, this is free infrastructure.
- **Per-process GC.** No global pauses when serving belief queries. Soft real-time guarantees.
- **LiveView dashboard.** Real-time graph visualization as a natural byproduct of the BEAM runtime - no separate frontend.

## Polyglot access, BEAM-native premium

The service is polyglot. Python and TypeScript agents call an HTTP/gRPC API. But Elixir agents get a premium experience:

- **Zero-latency belief access** via ETS (no network hop, no serialization)
- **Supervision** for automatic crash recovery with belief reloading
- **In-process composition** - `bs compose` and `bs relate` run at VM speed
- **Hot code reloading** - update belief logic without restarting agents

This is the upgrade path, not the entry point. Start with the Python SDK. When you need fault tolerance, real concurrency, and sub-millisecond belief access - here's what it looks like on the BEAM.

## Example: client integration

Consider an Elixir application that already runs composable beliefs on local JSON files. Deploying both the client app and CB on the BEAM makes interop trivial:

**Today (local, JSON-file):**
```
client_app -> reads/writes org/assertions/assertions.json directly
```

**Phase 1 (in-process, same BEAM node):**
```
client_app (GenServer) -> CB.Assertion.Store (ETS) -> assertions.json
```
The client's skills (`/assert`, `/assertions`, `/materialize`) call CB modules directly. No network hop. The store moves from file I/O to ETS with file persistence. The belief shell (`mix bs`) works unchanged.

**Phase 2 (service, separate node):**
```
client_app (BEAM node A) -> CB service (BEAM node B, ETS + Postgres)
```
The client connects via BEAM distribution or HTTP API. Same module interface, different transport. The BEAM's location-transparent messaging means the code barely changes.

This progression is invisible to the agent - beliefs are accessed through the same `CB.Assertion.Store` interface at every phase. The infrastructure evolves underneath.
