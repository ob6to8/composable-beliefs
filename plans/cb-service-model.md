# Composable Beliefs - Service Model

**Status:** active
**Date:** 2026-03-14

## Orientation

The goal is proving that composable beliefs works and achieving distribution through open source. A paid service exists to sustain the work and demonstrate that the paradigm has commercial value - not to gate the paradigm itself.

The framework is the contribution. The service sells intelligence about how belief graphs behave, without ever seeing what agents believe.

## The privacy constraint

Agent belief graphs contain some of the most sensitive data in any system - business deal terms, private communications, strategic reasoning, confidence scores that expose where an organization is uncertain. Self-referential beliefs (an agent's model of its own behavior) are the most sensitive of all.

No enterprise security team will approve sending this to a third party. This isn't a feature gap - it's a hard constraint that shapes the entire model.

**The solution: structure without content.** The service never sees claims, quotes, sources, or subject references. Only graph topology and statistical properties.

## Open source core

The complete framework is open source and self-sufficient:

- Assert primitives, compounds, implications
- Track provenance and source references
- Propagate staleness through dependency chains
- Query by subject, confidence, kind, status
- The full belief shell CLI (`mix bs`)
- Materialize implications into actions

No service dependency. Works offline, air-gapped, completely standalone. This is the entry point - anyone can use composable beliefs without paying anything.

## What a service adds

From structural telemetry across many belief graphs, a service can provide intelligence that a local installation cannot:

**Health scoring.** "Your graph has 40% of compounds resting on primitives with confidence below 0.5. That's worse than 90% of similar-sized graphs."

**Staleness prediction.** "Compounds with this dependency pattern (3+ deps, mixed source types, oldest dep > 14 days) go stale 80% of the time within a week."

**Anomaly detection.** "This agent retracted 12 beliefs in the last hour. That's 10x its baseline."

**Composition gap detection.** "You have 28 primitives but only 15 compounds. Similar domains average a 1.5:1 ratio. Your agent may be under-composing."

**Growth modeling.** "Graphs that reach 200+ nodes without pruning superseded chains show degraded query performance."

None of these require seeing content. All of them require seeing many graphs.

## What the service sees

Structural telemetry only:

```json
{
  "graph_id": "hashed-opaque-id",
  "snapshot_ts": "2026-03-14T14:00:00Z",
  "node_count": 23,
  "by_kind": {"primitive": 11, "compound": 8, "implication": 3, "patch": 1},
  "by_status": {"active": 23},
  "confidence_distribution": {
    "p10": 0.4, "p25": 0.65, "p50": 0.85, "p75": 0.9, "p90": 0.9
  },
  "stale_compound_count": 0,
  "max_dep_depth": 3,
  "avg_deps_per_compound": 2.8,
  "supersession_rate_7d": 0.0,
  "unmaterialized_implications": 2,
  "source_type_distribution": {"user": 10, "policy": 1}
}
```

No claims, no quotes, no sources, no subject references. Just the shape.

### Hashed reference mode (optional, higher tier)

For customers who want more than structural telemetry but less than full content exposure:

- Claims, quotes, and source content stay local
- Subject references and source IDs are SHA-256 hashed before transmission
- Dependency edges use hashed node IDs

The service can detect patterns like "these three compounds all depend on the same source" without knowing what any of them contain. The customer resolves hashes locally.

## Tiers

| Tier | Beliefs live | Service sees | Service provides |
|---|---|---|---|
| Open source | Local | Nothing | Full framework, self-sufficient |
| Pro | Local | Structural telemetry (opt-in) | Health scores, anomaly alerts, benchmarks |
| Team | Local or customer cloud | Structural + hashed references | Above + dependency analysis, staleness prediction, per-source patterns |
| Enterprise | Customer cloud | Structural + hashed + on-prem dashboard | Above + custom models, SLA, dedicated support |

No tier requires sending belief content.

## Client Relationship

A CB client is any application that uses the composable beliefs framework to manage an assertion DAG. The relationship has three levels, each additive.

### Level 1: Library (OSS tier)

The client adds CB as a dependency and uses the framework locally. No service, no telemetry, fully self-sufficient.

```elixir
# client_app/mix.exs
defp deps do
  [{:cb, path: "../composable-beliefs"}]  # or {:cb, "~> 0.1"} from hex
end
```

**What the client gets:**
- `CB.Assertion` struct, serialization, schema validation
- `CB.Assertion.Store` for reading/writing the DAG (JSON file, atomic writes)
- `CB.Assertion.Graph` for deterministic traversal (deps, dependents, path, stale, stats)
- `CB.Assertion.Filter` and `Formatter` for querying and display
- The belief shell CLI (`mix bs`) available in the client's project
- Skills (`/assert`, `/assertions`, `/materialize`) if using Claude Code

**What the client provides:**
- Nothing. The library is self-contained.

**Integration pattern:** The client either uses CB modules directly (`CB.Assertion.Store.read()`) or wraps them in domain-specific modules. The client's existing assertion data migrates to `org/assertions/assertions.json` or any path configured via `CB.Config`.

### Level 2: Telemetry (Pro/Team tier)

The client opts into structural telemetry. CB emits graph snapshots on each write. No content leaves the machine.

```elixir
# client_app/config/config.exs
config :cb,
  telemetry: true,
  service_url: "https://api.composablebeliefs.dev",
  graph_id: "my-app-prod"
```

**What the client sends:**
```json
{
  "graph_id": "hashed-opaque-id",
  "node_count": 23,
  "by_kind": {"primitive": 11, "compound": 8, "implication": 3},
  "confidence_distribution": {"p10": 0.4, "p50": 0.85, "p90": 0.9},
  "stale_compound_count": 0,
  "max_dep_depth": 3,
  "source_type_distribution": {"user": 10, "policy": 1}
}
```

No claims, no quotes, no sources, no subject references. Just the shape.

**What the client gets back:**
- Health scores benchmarked against other graphs of similar size
- Anomaly detection (sudden spikes in retractions, staleness)
- Composition gap analysis (under-composing, over-reliance on single sources)
- Staleness prediction (dependency patterns that historically go stale)

Accessible via `mix bs health` or the service API.

### Level 3: Hashed References (Team/Enterprise tier)

The client enables hashed reference mode. Subject refs and source IDs are SHA-256 hashed before transmission.

```elixir
config :cb,
  telemetry: true,
  hashed_refs: true,
  service_url: "https://api.composablebeliefs.dev",
  graph_id: "my-app-prod"
```

**What the service sees additionally:**
- Dependency topology with hashed node IDs
- Per-source patterns ("source abc123 has triggered 4 supersessions")
- Single-point-of-failure detection ("node def456 has 8 transitive dependents")

**What the service still cannot see:**
- What any assertion claims
- What any source contains
- What any subject refers to
- Any domain-specific content

The client resolves hashes locally. The service never can.

### What the service cannot know

At any tier, the service knows graph shape: "this graph has 11 primitives, 8 compounds, 3 implications, median confidence 0.85, max dep depth 3, no stale assertions."

It cannot know: what domain the graph operates in, what any assertion claims, what sources the assertions trace to, or what entities are referenced.

## Build sequence

1. **Open source core (done).** The CB repo exists with the full framework.
2. **Structural telemetry module.** Add `CB.Telemetry` that computes and emits graph snapshots. Off by default. clients opt in.
3. **Minimal service.** BEAM app that ingests telemetry snapshots, stores them, computes health scores. Deployed on Fly.io.
4. **`mix bs health` command.** The client-side command that calls the service and renders intelligence.
5. **Benchmark baselines.** early adopter graphs provide initial baselines. As more graphs register, benchmarks become meaningful.
6. **Dashboard (LiveView).** Visual surface for graph health, confidence heatmaps, staleness trends. The human-readable layer.

## The flywheel

The library being good makes more people use it. More users means more structural telemetry (opt-in). More telemetry means better benchmarks and predictions. Better predictions make the service more valuable. The service being valuable funds continued development of the library.

The library is never degraded to drive service adoption. The open source core is always self-sufficient.

## Open questions

1. **Is structural telemetry sufficient for meaningful intelligence?** The hypothesis is that graph shape (size, depth, confidence distribution, staleness rate) is predictive of graph health. The first graph is the initial data point - can you predict which beliefs will go stale from structure alone?

2. **Cold start.** Early customers get less value from benchmarks because there aren't enough graphs to benchmark against. Options: early adopter graphs provide initial baselines, publish synthetic benchmarks, early adopter pricing that reflects cold-start reality.

3. **Telemetry trust.** Even structural data requires review. `source_type_distribution: {email: 14}` tells you the customer processes email. Telemetry fields need careful design to avoid information leakage. Principle: if you can infer business context from the telemetry, it's too detailed.

4. **Pricing.** Not yet quantified. Need to understand typical belief graph sizes across different agent use cases. The free tier (open source) is the entire framework. Paid tiers sell intelligence, not capability.
