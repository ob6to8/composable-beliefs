# Belief Shell - Tier 2 (Probabilistic Operations) Plan

**Status:** planned
**Date:** 2026-03-14
**Depends on:** Tier 1 implemented in `lib/mix/tasks/cb.bs.ex` and `lib/cb/assertion/graph.ex`
**Spec:** `org/assertions/composable-beliefs/shell/belief-shell-api-v1.md`

## Context

Tier 1 of the belief shell is complete - 10 deterministic operations that provide pure graph traversal with no LLM dependency. Tier 2 adds the probabilistic operations that cross the deterministic/probabilistic boundary. These are the operations where the shell invokes reasoning to propose new assertions or evaluate existing ones.

The central design constraint: every Tier 2 operation follows a **propose-confirm** pattern. The shell presents what it would do, the caller approves, then the write happens. No probabilistic operation writes to the DAG without confirmation.

## Operations to Implement

### 1. `bs compose <id1> <id2> [id3...]`

**What it does:** Propose a compound assertion from two or more existing assertions.

**Implementation approach:**
- Read the specified assertions via `Graph.index` (deterministic)
- Build a prompt containing the full assertion details and ask the LLM to reason about what their combination means
- LLM proposes: compound claim, implication text, suggested confidence
- Present the proposed compound for review
- On confirmation: assign next ID via existing `CB.Todo.Id` pattern, write to DAG via `Store`

**Key decisions:**
- The prompt must instruct the LLM to assess confidence independently, not just average the dep confidences
- The proposed compound should include which subjects it inherits or adds
- The LLM should flag if the deps appear to conflict rather than compose

**Existing code to leverage:**
- `/assert` skill already does composition as part of its workflow
- Extract the composition-specific logic into a reusable function in a new module: `CB.Assertion.Compose`

**Mix task integration:**
- `mix cb.bs compose a050 a051` outputs the proposed compound as formatted detail
- Confirmation writes to `assertions.json`
- In agent context: the skill calls the module directly

### 2. `bs assert <source>`

**What it does:** Propose primitive assertions extracted from a source.

**Implementation approach:**
- Parse the source argument to determine source type:
  - `gmail:<thread_id>` - read from local email cache
  - `file:<path>` - read file content
  - Quoted string - treat as direct observation
- Build a prompt with the source material asking the LLM to identify atomic claims
- LLM proposes: list of primitives, each with claim, source, evidence, confidence
- Also scan existing assertions for composition opportunities
- Present all proposals for review
- On confirmation: write to DAG

**Key decisions:**
- Each primitive should be genuinely atomic - one claim per assertion
- The LLM must provide evidence detail, not just the claim
- Source type must match the source prefix conventions in `assertion.ex`

**Existing code to leverage:**
- `/assert` skill handles this entire workflow
- The skill becomes a wrapper that calls `mix cb.bs assert` or the underlying module
- Email reading uses `CB.Email.Store`

### 3. `bs materialize <id>`

**What it does:** Turn an implication into todos on real objects.

**Implementation approach:**
- Validate via existing `CB.Assertion.Materializer` (must be implication, active, unmaterialized)
- Build a prompt with the implication and its full dep tree, asking the LLM to reason about what todos follow
- LLM proposes: list of todos with object, action, owner, priority, due
- Resolve target objects via `CB.Todo.Creator.resolve_object`
- Present for review
- On confirmation: delegate to existing `Materializer.materialize/1`

**Existing code to leverage:**
- `CB.Assertion.Materializer` handles the entire write path
- `/materialize` skill handles the reasoning
- This is primarily a CLI surface for the existing workflow

### 4. `bs challenge <id>`

**What it does:** Pressure-test whether an assertion still holds.

**Implementation approach:**
- Read the assertion and its full dependency tree via `Graph` (deterministic)
- For primitives: check if evidence is still current, if source has been contradicted by newer assertions
- For compounds: check if all deps are still active, if confidence of deps has changed, if new information exists that might alter the implication
- Build a prompt with all context asking the LLM to evaluate
- LLM proposes one of: reaffirm (with updated confidence), supersede (with new replacement assertion), retract (with reason)
- Present for review
- On confirmation: write status change

**New module:** `CB.Assertion.Challenge`

**Key decisions:**
- Challenge should walk deps recursively - a compound is only as strong as its weakest dep
- The LLM should be instructed to look for contradicting assertions, not just confirm the existing one (counteract RLHF agreeableness)
- Reaffirmation with unchanged confidence is a valid outcome and should be cheap
- Challenge results should be tracked - add an evidence entry to the assertion recording when it was last challenged

**This is the most important new operation.** The DAG currently grows but has no systematic mechanism for self-doubt. `challenge` makes re-evaluation first-class.

### 5. `bs relate <id>`

**What it does:** Find assertions that might compose with a given assertion but haven't been composed yet.

**Implementation approach:**
- Read the target assertion and its subjects (deterministic)
- Find candidates via deterministic filters:
  - Same subject type or overlapping subject refs
  - Same source type
  - Assertions not already in a dep relationship with the target
- For each candidate, build a brief prompt asking the LLM if composition would produce a meaningful compound
- LLM returns: ranked list with one-line rationale for each candidate
- Present ranked candidates

**Key decisions:**
- Pre-filter deterministically to keep the LLM calls manageable
- Only present the top N candidates (default 5)
- `relate` is read-only - it suggests but does not create
- Pair with `compose`: `bs relate a050` finds candidates, then `bs compose a050 <candidate>` acts on them

**New module:** `CB.Assertion.Relate`

## Architecture

### Module structure

```
lib/cb/assertion/
  compose.ex      # Compose two+ assertions into a compound (new)
  challenge.ex    # Pressure-test an assertion (new)
  relate.ex       # Find composition candidates (new)
  materializer.ex # Already exists - materialize implications into todos
  graph.ex        # Already exists - deterministic graph operations
  filter.ex       # Already exists - filter/sort
  formatter.ex    # Already exists - terminal output
  store.ex        # Already exists - read/write JSON
```

### The LLM invocation question

Tier 2 operations need to invoke LLM reasoning. In the current system, the LLM is the agent itself - skills are prompts that the agent executes. There's no programmatic LLM API call from Elixir.

**Options:**

1. **Skills remain the LLM layer.** `mix cb.bs compose` outputs the deterministic context (assertions, deps, subjects) in a structured format. The agent reads it and does the reasoning. The mix task handles the write on confirmation. The agent is the "probabilistic core" of the kernel.

2. **Add an API call.** The mix task calls the Claude API directly to get a completion. This makes `bs compose` fully self-contained but adds an API dependency.

3. **Hybrid.** Deterministic prep in the mix task, reasoning delegated to the agent via structured output, write handled by the mix task.

**Recommendation: Option 1 for v1.** The skills already work. The mix task outputs structured context. The agent reasons. The shell's value is in making the boundary explicit, not in hiding the LLM call. Option 2 is the path for the open-source framework but premature for CB.

### Mix task routing

Extend `mix cb.bs` with Tier 2 commands:

```elixir
["compose" | rest] -> cmd_compose(rest, flags)
["assert" | rest] -> cmd_assert(rest, flags)
["materialize", id | _] -> cmd_materialize(id, flags)
["challenge", id | _] -> cmd_challenge(id, flags)
["relate", id | _] -> cmd_relate(id, flags)
```

For Option 1, each `cmd_*` function outputs structured context that the agent uses for reasoning. The agent then calls a confirmation function to write.

## Build Sequence

1. **`bs challenge`** - highest value, nothing like it exists. Build `Challenge` module with deterministic evidence gathering. Agent provides the judgment.
2. **`bs relate`** - deterministic candidate finding is useful even without LLM ranking. Build `Relate` module with subject/source overlap detection.
3. **`bs compose`** - extract composition logic from `/assert` skill into `Compose` module. The skill becomes a wrapper.
4. **`bs materialize`** - already implemented in `Materializer`. Wire through `bs` CLI.
5. **`bs assert`** - extract from `/assert` skill. Largest surface area, lowest marginal value since the skill works.

## Success Criteria

- All 5 operations accessible via `mix cb.bs`
- Help output clearly tags each as `[P]` (probabilistic)
- Each operation outputs structured context the agent can reason about
- Each operation follows propose-confirm pattern
- `bs challenge` successfully re-evaluates at least one assertion in the live DAG
- `bs relate` surfaces at least one composition opportunity not previously identified

## Open Questions

1. **Should `challenge` add evidence entries?** If an assertion is challenged and reaffirmed, should the challenge be recorded as a new evidence entry with the date? This would make challenge history visible without changing the assertion's content.

2. **Batch operations.** `bs stale --cascade | bs challenge` implies challenging multiple assertions. Should `challenge` accept multiple IDs? Or should the pipe pattern handle it with xargs-style invocation?

3. **Confidence recalculation in `compose`.** When composing assertions with different confidences, should the module suggest a formula (e.g. min of deps) as a starting point? Or always leave it to LLM judgment? Current system treats confidence as judgment, not calculation.
