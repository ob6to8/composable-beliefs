# Belief Shell Cookbook

**Date:** 2026-03-14
**Prerequisite:** `mix bs help` for full command reference

Examples use both the live DAG (`org/assertions/assertions.json`) and the belief-shell temp DAG (`shell/temp-dag/assertions.json`) which contains the assertions derived from the Unix/belief-shell analysis.

---

## Getting Oriented

### What's in the graph?

```
$ mix bs stats

Assertion DAG Statistics
========================

Total: 72

By kind:
  primitive: 44
  compound: 16
  implication: 11

Confidence:
  min: 0.30
  mean: 0.91
  median: 0.95

Most depended-on:
  a054: 5 dependents
  a058: 4 dependents
  a051: 4 dependents
```

The most-depended-on assertions are load-bearing beliefs. If `a054` changes, 5 other assertions may need re-evaluation.

### List everything about a topic

```
$ mix bs subjects agent

a050  primitive  0.9  active  Agent performs lossy compression on unstructured data retrieval...
a051  primitive  0.9  active  Agent interprets follow-up questions as implicit corrections...
a054  primitive  0.9  active  Agent adopts user statements as ground truth primitives...
...
```

All assertions - primitives, compounds, implications - that reference a subject type. One command gives you the full belief landscape for a domain.

---

## Traversing the Graph

### "Why do we believe this?"

Start from a compound or implication and walk backward to ground truth.

```
$ mix bs tree a056

a056 [compound] (0.9) Agent uncritically accepts input from authority sources...
├── a051 [primitive] (0.9) Agent interprets follow-up questions as implicit corrections...
│     source: user:collaborator:2026-03-12
└── a054 [primitive] (0.9) Agent adopts user statements as ground truth primitives...
      source: user:collaborator:2026-03-12
```

Two primitives, both from the same observer, both from direct observation. The compound's confidence (0.9) is independently assessed - not averaged from deps.

### "What breaks if this changes?"

Reverse lookup - find everything that depends on an assertion.

```
$ mix bs dependents a054

5 dependents of a054:

a056  compound     0.9  active  Agent uncritically accepts input from authority sources...
a060  compound     0.7  active  Agent failure modes a050-a054 are Clever Hans shortcuts...
a062  compound     0.7  active  RLHF-trained patterns applied without source grounding...
a067  compound     0.8  active  The RLHF escalation cycle: user offers theory, agent...
a072  patch        -    active  RLHF deference produces epistemic collapse...
```

If `a054` were superseded (say the agent stopped treating speculation as fact), all five of these would need re-evaluation. This is the blast radius of a belief change.

### Deep dependents - the full cascade

```
$ mix bs dependents a054 --deep

4 deep dependents of a054:

a063  implication  0.6  active  The assertion DAG's abstraction set...
a070  implication  0.9  active  The moat section in composable-beliefs-thesis.md...
a071  compound     0.9  active  When prose documents conflict with assertions...
a072  patch        -    active  RLHF deference produces epistemic collapse...
```

Direct dependents plus their dependents, recursively. The full downstream impact.

### How does A connect to B?

```
$ mix bs path a058 a063

Path from a058 to a063 (3 nodes):

  a058 [primitive] (0.8) Sufficiently advanced agentic coding is essentially machin..
  -> a059 [compound] (0.7) Flat instructions (CLAUDE.md rules, system prompts, memory..
  -> a063 [implication] (0.6) The assertion DAG's abstraction set (primitive/compound/im..
```

Three hops: Chollet's observation (primitive) feeds the overfitting-to-spec compound, which feeds the Keras-of-agentic-coding implication. The path shows exactly how ground truth flows into derived belief.

---

## Filtering and Discovery

### Find weak beliefs

```
$ mix bs list low-confidence

a069  primitive    0.4  active  It is possible that better models make the DAG more...
```

Low confidence isn't failure - it's the system honestly representing what it doesn't know well. These are candidates for `bs challenge` or for seeking additional evidence.

### Find implications that haven't been acted on

```
$ mix bs list implication unlinked

a047  implication  1.0  active  hospitality.md duplicates rider content and should be...
a057  implication  0.9  active  Unstructured data retrieval tasks need deterministic...
a063  implication  0.6  active  The assertion DAG's abstraction set (primitive/compound...
```

Unlinked implications are beliefs-about-what-should-happen that haven't been turned into todos. Three implications waiting for materialization.

### Find assertions by source

```
$ mix bs list source:user

Assertions sourced from direct user observations.
```

### Combine filters

```
$ mix bs list compound high-confidence

Only compounds with confidence >= 0.9. The beliefs the system is most certain about.
```

---

## Working with the Belief Shell DAG

The temp DAG in `shell/temp-dag/assertions.json` contains the assertions derived from the Unix/belief-shell analysis session. These demonstrate the shell operating on its own origin story.

### The belief shell's own dependency tree

The central compound - "the belief kernel has a probabilistic core" (bs007):

```
bs007 [compound] (0.75) Unlike Unix where both the kernel and the shell are
│                       deterministic, a belief system has a split character...
├── bs004 [primitive] (0.9) When two Unix commands are piped together, the
│                           composition is deterministic... When two assertions
│                           are composed, the resulting compound's claim requires
│                           reasoning...
└── bs005 [compound] (0.7) The relationship between the assertion DAG and its
    │                      users mirrors the Unix kernel/user relationship...
    ├── bs001 [primitive] (0.95) Interacting with the assertion DAG currently
    │                            requires either reading raw JSON or hoping...
    └── bs002 [primitive] (1.0) Unix achieved composability by representing
                                devices, sockets, pipes, and files as a single
                                abstraction...
```

Four levels deep. The insight about the probabilistic kernel (bs007) depends on the analogy holding (bs005) AND on the observation that composition requires judgment (bs004). Both must be true for the compound to hold. If either is superseded, bs007 goes stale.

### Reverse lookup on the foundational observation

What depends on "the DAG lacks a deterministic interaction layer" (bs001)?

```
$ bs dependents bs001

bs005  compound     0.7   The assertion DAG parallels Unix architecture...
bs006  compound     0.65  Six core Unix abstractions map to DAG equivalents...
bs008  implication  0.7   Composable Beliefs should include a shell layer...
```

Three assertions depend on bs001. And bs008 is already materialized - the v1 shell implementation is the todo that was created from this implication.

### Path from observation to implementation

```
$ bs path bs001 bs009

Path from bs001 to bs009 (4 nodes):

  bs001 [primitive] (0.95) Interacting with the assertion DAG currently requires...
  -> bs005 [compound] (0.7) The relationship between the assertion DAG and its users...
  -> bs007 [compound] (0.75) Unlike Unix where both the kernel and shell are deterministic...
  -> bs009 [implication] (0.7) The belief shell cannot be purely deterministic...
```

The chain from "the DAG has no shell" (observation) through "it's like Unix" (analogy) through "but the kernel is probabilistic" (insight) to "therefore the shell must have a deterministic/probabilistic boundary" (design requirement). Four nodes trace the entire reasoning chain from ground truth to design decision.

### The generativity thread

```
$ bs dependents bs003

bs006  compound     0.65  Six Unix abstractions map to DAG equivalents...
bs010  implication  0.65  If Unix's generativity is a target property...
```

The observation that Unix was generative (bs003) feeds into both the mapping analysis and the design implication that the belief shell should optimize for emergent composition. If you determined that Unix's generativity was actually an accident rather than a designable property, both of these would need re-evaluation.

---

## Combining Operations

### Audit: what's fragile?

Find the most-depended-on assertions, then check their confidence:

```
$ mix bs stats
  Most depended-on:
    a054: 5 dependents

$ mix bs show a054
  Confidence: 0.9
  Source: user:collaborator:2026-03-12

$ mix bs dependents a054 --deep
  (shows full cascade of everything downstream)
```

a054 has 5 direct dependents and 4 deep dependents. If this 0.9-confidence observation from a single session turns out to be wrong, 9 assertions need re-evaluation. That's a high-leverage node worth challenging.

### Audit: what's unresolved?

```
$ mix bs list low-confidence
  (weak beliefs that need evidence)

$ mix bs list implication unlinked
  (implications not yet turned into action)

$ mix bs stale --cascade
  (beliefs with outdated dependencies, transitively)
```

Three queries that together give you the full picture of what the DAG doesn't know, hasn't acted on, and might be wrong about.

### Trace a domain end-to-end

```
$ mix bs subjects agent
  (every belief about agent behavior)

$ mix bs tree a056
  (why do we believe the agent uncritically accepts authority input?)

$ mix bs dependents a056
  (what implications follow from that belief?)
```

From domain overview to specific reasoning chain to downstream actions - three commands that traverse a domain's full belief structure.

---

## Tier 2 Preview (Planned)

These operations are specified in `belief-shell-api-v1.md` and planned in `plans/belief-shell-tier2.md`. They cross the deterministic/probabilistic boundary.

### Challenge a belief

```
$ mix bs challenge a056
  [P] Reading a056 and dependency tree...

  a056: "Agent uncritically accepts input from authority sources"
  Deps: a051 (0.9), a054 (0.9)

  Evaluation:
  - a051: Last evidenced 2026-03-12. No contradicting assertions found.
  - a054: Last evidenced 2026-03-12. No contradicting assertions found.
  - Compound reasoning: Still holds. Both deps describe the same pattern
    from different angles.

  Proposal: REAFFIRM at 0.9 (unchanged)

  Accept? [y/n]
```

### Find composition candidates

```
$ mix bs relate a050
  [P] Finding composition candidates for a050...

  Candidates:
  1. a064 (0.9) "Agent restates user theories with increasing confidence"
     Rationale: Both describe agent behavior that amplifies input without
     critical evaluation. Composition could produce a compound about
     systematic confidence inflation.

  2. a068 (0.9) "Prose plans collapse the distinction between observation..."
     Rationale: Lossy compression (a050) applied to prose could explain
     why plans lose epistemic distinctions.

  Compose any of these? Enter IDs or 'n':
```

### Compose assertions

```
$ mix bs compose a050 a064
  [P] Composing a050 + a064...

  Proposed compound:
    Claim: "Agent systematically inflates confidence in retrieved and
            restated information - lossy compression drops qualifiers
            while restatement adds certainty"
    Deps: [a050, a064]
    Confidence: 0.8 (suggested)

  Accept? [y/n/edit]
```
