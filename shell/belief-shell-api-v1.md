# Belief Shell API v1

**Status:** draft spec - for review and discussion
**Date:** 2026-03-14
**Context:** [3-14-26-belief-shell-v1.md](3-14-26-belief-shell-v1.md) (origin transcript and DAG staging)

## Design Principle

The belief shell is a set of operations for interacting with an assertion DAG. Its primary design constraint is making the **deterministic/probabilistic boundary** explicit. Some operations are pure graph traversal - they always produce the same output for the same input. Others require reasoning - they invoke an LLM to interpret, compose, or evaluate. The shell must never blur this line.

This mirrors Unix, where the kernel's syscalls are deterministic and the user's intent is not. The shell sits between them. Here, the graph operations are deterministic and the composition semantics are not. The belief shell sits between them.

## Existing Implementation

v1 builds on what already exists in the current implementation:

| Existing | Maps to |
|---|---|
| `mix bs list [filters]` | `bs list` |
| `mix bs list <id>` | `bs show` |
| `mix bs list tree <id>` | `bs tree` |
| `mix bs list stale` | `bs stale` |
| `/assert` skill | `bs assert`, `bs compose` |
| `/materialize` skill | `bs materialize` |

The shell formalizes these into a coherent interface and adds operations that don't exist yet.

## Command Reference

### Tier 1: Deterministic Operations

These are pure graph traversal. No LLM required. Same input, same output, every time. These are the "syscalls" of the belief shell.

---

#### `bs list [filters]`

List assertions matching filters. Default: active only.

```
bs list                          # all active assertions
bs list primitive                # active primitives only
bs list compound low-confidence  # compounds with confidence < 0.5
bs list subject_type:transport   # assertions about transport entities
bs list --status all             # include superseded and retracted
```

**Filters** (combinable, AND logic):
- Kind: `primitive`, `compound`, `implication`
- Status: `active` (default), `superseded`, `retracted`, `all`
- Confidence: `low-confidence` (< 0.5), `high-confidence` (>= 0.9)
- Subject: `subject_type:<type>`, `subject_ref:<path>`
- Linkage: `unlinked` (implications with no materialized todos)
- Source: `source:<prefix>` (e.g. `source:gmail`, `source:user`)

**Output:** table view (id, kind, confidence, status, claim). Add `-v` for evidence and sources.

---

#### `bs show <id>`

Full detail on a single assertion.

```
bs show a056
```

**Output:** all fields - claim, kind, source, evidence, confidence, subjects, deps, implication, materialized status, supersession chain.

---

#### `bs tree <id>`

Render the full dependency tree rooted at an assertion, walking deps recursively.

```
bs tree a056
```

**Output:** box-drawing tree showing each dep with its confidence (color-coded: green >= 0.9, yellow >= 0.5, red < 0.5), kind, claim, and source. Detects circular references.

---

#### `bs deps <id>`

List direct dependencies of an assertion. Unlike `tree`, does not recurse.

```
bs deps a056          # direct deps of a056
bs deps a056 --deep   # equivalent to tree (recurse all the way down)
```

**Output:** table of dependency assertions.

---

#### `bs dependents <id>`

Reverse lookup - what assertions depend on this one? This is the "what breaks if this changes" query.

```
bs dependents a050    # what compounds/implications use a050 as a dep?
```

**Output:** table of assertions that have `<id>` in their `deps` array. Add `--deep` to recurse upward through the full dependent chain.

**Notes:** This is the inverse of `deps`. Together they give you bidirectional traversal. `deps` walks toward ground truth (primitives). `dependents` walks toward derived meaning (compounds, implications). This operation does not exist in the current implementation.

---

#### `bs stale`

Find assertions whose dependencies have been superseded or retracted.

```
bs stale              # all stale assertions
bs stale --cascade    # include transitively stale (dep of a stale dep)
```

**Output:** stale report showing each stale assertion, which deps are problematic, and why (superseded vs retracted).

**Notes:** `--cascade` is new. Currently staleness is checked one level deep. Cascade walks the full dependent chain - if a054 is retracted, a056 (which depends on a054) is stale, and anything depending on a056 is transitively stale.

---

#### `bs path <id1> <id2>`

Find the dependency path between two assertions, if one exists.

```
bs path a050 a056     # how does a050 connect to a056?
```

**Output:** the chain of assertions connecting id1 to id2 through dependency edges, or "no path" if unconnected.

**Notes:** This is a graph search (BFS/DFS on the DAG). Useful for answering "how does this ground truth relate to that conclusion?" Does not exist in the current implementation.

---

#### `bs history <id>`

Show the supersession chain for an assertion - what it replaced and what replaced it.

```
bs history a012       # full lifecycle of this claim
```

**Output:** chronological chain: original assertion -> superseded by -> superseded by -> current. Shows dates, confidence changes, and claim evolution.

**Notes:** Does not exist in current implementation. Walks `superseded_by` forward and scans for assertions that were superseded by `<id>` backward.

---

#### `bs subjects <ref>`

Find all assertions about a given subject.

```
bs subjects agent/claude
bs subjects --type show    # all assertions about any show
```

**Output:** table of assertions whose `subjects` array matches the ref or type.

---

#### `bs stats`

Graph-level statistics. The "df" of the belief shell.

```
bs stats
```

**Output:**
- Total assertions (by kind, by status)
- Confidence distribution (histogram or quartiles)
- Stale count
- Unlinked implications count
- Source type distribution
- Average dependency depth
- Most-depended-on assertions (highest in-degree)

---

### Tier 2: Probabilistic Operations

These require LLM reasoning. The shell invokes them but the output is non-deterministic - the same input may produce different results. These are marked explicitly so the caller (human or agent) knows they're crossing the boundary.

Each probabilistic operation follows a **propose-confirm** pattern: the shell presents what it would do, the caller approves, then the write happens. No probabilistic operation writes to the DAG without confirmation.

---

#### `bs compose <id1> <id2> [id3...]`

Propose a compound assertion from two or more existing assertions.

```
bs compose a004 a017    # what does combining these mean?
```

**Process:**
1. Read the specified assertions (deterministic)
2. Reason about what their combination means (probabilistic)
3. Propose a compound with: claim, deps, implication text, suggested confidence
4. Present for review
5. On confirmation: write to DAG

**The boundary:** Steps 1, 5 are deterministic. Step 2-3 are probabilistic. The shell makes this visible.

---

#### `bs assert <source>`

Propose a primitive assertion extracted from a source.

```
bs assert file:analyses/some-analysis.md   # extract claims from document
bs assert file:intake/contract.pdf   # extract claims from document
bs assert "observation: ..."         # assert from conversation
```

**Process:**
1. Read the source material (deterministic)
2. Identify atomic claims worth asserting (probabilistic)
3. Propose primitives with: claim, source, evidence, suggested confidence
4. Scan existing assertions for composition opportunities (probabilistic)
5. Present for review
6. On confirmation: write to DAG

---

#### `bs materialize <id>`

Turn an implication into todos on real objects.

```
bs materialize a063
```

**Process:**
1. Validate: must be implication, active, unmaterialized (deterministic)
2. Reason about what todos follow from the implication (probabilistic)
3. Resolve target objects (deterministic)
4. Propose todos with: object, action, owner, priority, due (probabilistic)
5. Present for review
6. On confirmation: write todos to objects, update assertion's materialized field

---

#### `bs challenge <id>`

Evaluate whether an assertion still holds. The inverse of `assert` - instead of creating, it pressure-tests.

```
bs challenge a056     # does "agent defers to authority" still hold?
```

**Process:**
1. Read the assertion and its full dependency tree (deterministic)
2. Evaluate each dep: is the evidence still current? has the source been contradicted? (probabilistic)
3. Check for new information that might supersede (probabilistic)
4. Propose: reaffirm (with updated confidence), supersede (with new assertion), or retract (with reason)
5. Present for review
6. On confirmation: write status change to DAG

**Notes:** This is the most important operation that doesn't exist yet. The DAG currently grows but has no systematic mechanism for self-doubt. `challenge` makes re-evaluation a first-class operation.

---

#### `bs relate <id>`

Find assertions that might compose with a given assertion but haven't been composed yet.

```
bs relate a050        # what might combine with "agent omits fields"?
```

**Process:**
1. Read the assertion and its subjects (deterministic)
2. Find assertions with overlapping subjects, related source types, or thematic proximity (hybrid - subject overlap is deterministic, thematic proximity is probabilistic)
3. For each candidate, briefly reason about whether composition would produce a meaningful compound (probabilistic)
4. Present ranked candidates with one-line rationale for each

**Notes:** This is how the DAG discovers composition opportunities it didn't know it had. The generativity property from the Unix analogy - `relate` is the mechanism for emergent pipelines.

---

### Tier 3: Hybrid Operations

These have a deterministic core with an optional probabilistic layer.

---

#### `bs why <id>`

Walk the dependency chain backward and explain the reasoning.

```
bs why a056                # how did we arrive at this belief?
bs why a056 --structure    # deps only, no explanation (deterministic mode)
```

**Default (hybrid):** walks deps (deterministic), then narrates the reasoning chain in plain English (probabilistic). Explains how each dep contributes to the compound's claim.

**`--structure` flag:** pure deterministic mode. Equivalent to `bs tree` but formatted as a linear chain rather than a tree. No LLM reasoning.

---

#### `bs conflicts [scope]`

Detect potential conflicts in the graph.

```
bs conflicts                        # scan full graph
bs conflicts subject_type:show      # scan show-related assertions only
bs conflicts a004 a017              # check these two specifically
```

**Deterministic layer:** detect structural conflicts - same subject, contradictory confidence trends, supersession chains that create orphans, assertions that depend on both sides of a supersession.

**Probabilistic layer:** detect semantic conflicts - claims that contradict each other in meaning even if structurally unrelated. "Vehicle available April 6-15" vs "show April 12 requires vehicle at venue" - no structural link, but a real conflict.

**Output:** conflicts listed with type (structural vs semantic) and evidence.

---

## Pipes and Composition

Following Unix, shell operations should compose. The output of one operation feeds the input of another.

```
bs list primitive source:gmail | bs relate    # for each gmail primitive, find composition candidates
bs stale --cascade | bs challenge             # challenge every stale assertion
bs dependents a050 | bs conflicts             # check for conflicts in everything that depends on a050
bs list implication unlinked | bs materialize  # materialize all unlinked implications
```

**Implementation note:** pipe composition requires a standard interchange format. The deterministic operations output assertion IDs (one per line) when piped, full formatted output when terminal. This is the same pattern as Unix tools that detect whether stdout is a TTY.

---

## The Deterministic/Probabilistic Contract

Every command is tagged:

| Tag | Meaning |
|---|---|
| `[D]` | Deterministic. Pure graph operation. No LLM. Cacheable. |
| `[P]` | Probabilistic. Requires LLM reasoning. Propose-confirm pattern. Non-cacheable. |
| `[H]` | Hybrid. Deterministic core with optional probabilistic layer. Flag controls which mode. |

The shell displays this tag in help output and command headers so the caller always knows which side of the boundary they're on.

```
$ bs help
DETERMINISTIC [D]
  list        List assertions matching filters
  show        Full detail on a single assertion
  tree        Dependency tree visualization
  deps        Direct dependencies
  dependents  Reverse dependency lookup
  stale       Find assertions with problematic deps
  path        Find connection between two assertions
  history     Supersession chain
  subjects    Find assertions by subject
  stats       Graph-level statistics

PROBABILISTIC [P]
  compose     Propose a compound from multiple assertions
  assert      Propose primitives from a source
  materialize Turn an implication into todos
  challenge   Pressure-test whether an assertion holds
  relate      Find composition candidates

HYBRID [H]
  why         Explain reasoning chain (--structure for deterministic only)
  conflicts   Detect contradictions (structural=deterministic, semantic=probabilistic)
```

---

## Implementation Notes

### Build on existing Elixir modules

The Tier 1 operations map to extensions of existing modules:

| Operation | Module | Status |
|---|---|---|
| `list` | `CB.Assertion.Filter` + `Formatter` | exists |
| `show` | `CB.Assertion.Formatter.detail/1` | exists |
| `tree` | `CB.Assertion.Formatter.tree/2` | exists |
| `deps` | new function on `Filter` or new module | new |
| `dependents` | new - reverse index on `deps` field | new |
| `stale` | `CB.Assertion.Filter` + `Formatter.stale_report/2` | exists, extend for cascade |
| `path` | new - BFS on DAG | new |
| `history` | new - walk `superseded_by` chain | new |
| `subjects` | `CB.Assertion.Filter` (subject filtering exists) | exists, surface as command |
| `stats` | new - aggregate queries | new |

### Entry point

Single mix task: `mix bs <command> [args]`. Alias `bs` in the shell for ergonomics.

Skills (`/assert`, `/assertions`, `/materialize`) remain as the agent-facing interface. The shell is the programmatic interface. Skills may call shell operations internally.

### No infrastructure dependency

The belief shell operates on a local JSON file. No server, no database, no network. This is deliberate - the same design principle as the DAG itself. The shell is a CLI tool, not a service.

---

## Open Questions

1. **Interactive compose.** Should `bs compose` support an interactive mode where it walks you through candidate deps one at a time? Or is batch (`bs relate <id> | bs compose`) sufficient?

2. **Confidence recalculation.** When `bs challenge` re-evaluates a compound, should it mechanically recalculate confidence from dep confidences, or is confidence always a human/LLM judgment? Current system treats it as judgment. A formula might be useful as a suggestion that gets overridden.

3. **Belief scripts.** The staging doc raised this: if the shell enables "belief scripts" (run these checks before acting), how do you prevent them from becoming flat rules? One approach: scripts can only call deterministic operations. The moment you need probabilistic reasoning, you exit the script and enter a propose-confirm flow. Scripts are guardrails, not decision-makers.

4. **Multi-graph.** v1 assumes a single DAG file. If composable beliefs expands to multiple agents or domains, the shell needs to address cross-graph operations. Not in scope for v1 but the command structure shouldn't preclude it.

5. **Undo.** The DAG is immutable - you supersede or retract, never delete. But `bs challenge` could propose multiple status changes in one pass. Should there be a `bs revert <batch-id>` that retract-and-supersedes everything from a challenge session? Or is per-assertion granularity sufficient?
