# Contracts as the Intermediary Layer Between Domain Expertise and Code

**Date:** 2026-03-22
**Context:** Conversation about what abstraction layer replaces code when a human operates as architect/auditor rather than developer, using Louder Agent as test case.

---

## The Problem

Code and file trees are the wrong abstraction layer for a person straddling domain expertise and agentic coding supervision. Literal code/file structure is too low-level. Plain English does not have guarantees. There should be something in between.

## The Gap

Louder Agent already has implicit contracts scattered across multiple representations:

- A struct defines shape but not behavioral invariants.
- A skill defines a workflow but not its guarantees to callers.
- CLAUDE.md defines policy but can't be mechanically verified.

The gap is that these contracts are implicit and scattered. What's needed is an explicit layer where a domain expert can author commitments and a machine can enforce them.

## What Contracts Look Like

```
contract SyncFlight {
  input: email thread with flight-* label
  guarantees:
    - flight object created or updated in org/flights/
    - sheet columns F-K reflect current model state
    - no data deleted, only added or updated
  requires:
    - gmail.modify scope
    - sheet write access
  violates_if:
    - flight exists in sheet but not in model
    - model has fields not traceable to a source
}
```

This isn't code and isn't prose. It's a composable unit of system behavior that a domain expert can write, an architect agent can verify, and a coding agent can implement against. The domain expert doesn't need to know how sync works internally. The coding agent doesn't need to understand why these guarantees matter. The architect agent checks that implementations satisfy contracts and that contracts cover the domain.

## Contracts and Assertions: Two Sides of the Same Coin

Right now assertions encode beliefs about the world - "this show has a guarantee of $X", "this flight is confirmed", traceable to source evidence. Contracts would encode promises about system behavior - "sync-flights will never delete a flight", "a Flight struct always has a passenger".

These are two sides of the same coin. An assertion says "this is true." A contract says "this will remain true." Together they form a complete system: assertions are the state, contracts are the invariants over that state.

Here's where it gets powerful: contracts can be assertions, and assertions can generate contracts.

A contract like "every show with status confirmed must have a source contract document" is both a system invariant and a domain belief. It lives in both worlds. You could express it as an assertion with an implication that materializes into a todo when violated - which is exactly what `/materialize` already does.

Going the other direction: when you assert something enough times with enough consistency, that pattern is a candidate contract. If every flight sync for six months has preserved the invariant "no flight deleted without explicit user action," that's an emergent contract worth codifying.

## Three Layers of the DAG

The assertion DAG evolves from two layers (assertions + implications) into three:

### Layer 1: Assertions
Beliefs about current state, sourced from evidence.
- "Show 0521 guarantee is $2500, per contract"
- "Flight 05-21-26-david-sartore-den-bos is confirmed"
- Grounded in source documents, email threads, manual input
- Can become stale, can be superseded

### Layer 2: Contracts
Invariants that must hold across state transitions.
- "Sync never deletes, only adds or updates"
- "Every confirmed show has a source contract document"
- "A Flight struct always has a passenger and a date"
- Can apply to code (struct shape), skills (workflow guarantees), or domain rules (business logic)
- Verifiable mechanically - an architect agent can check them

### Layer 3: Implications
The edges connecting assertions and contracts, defining what happens when state changes or invariants are violated.
- "If this contract is violated, materialize a todo"
- "If this assertion changes, re-verify these contracts"
- "If this pattern holds for N iterations, propose it as a contract"

## Contracts Span Both Code and Skills

A key insight: contracts work as the abstraction layer for both implementation code and agent skills. A contract over an Elixir module (`Louder.Flight` must always have `passenger` and `date`) and a contract over a skill (`/sync-flights` guarantees no data deletion) use the same representation. This means a single system can express guarantees across the entire stack - from struct definitions to multi-step agent workflows - without requiring the domain expert to understand either layer's internals.

## Contracts as New Node Type vs. Assertion Subtype

Lean: new node type in the DAG, not `type: invariant` on existing assertions. Reason: assertions are claims about the world that can become stale and get superseded. Contracts are structural commitments that get violated or upheld - they have a fundamentally different lifecycle. An assertion that "show 0521 has a $2500 guarantee" can be superseded by new information. A contract that "sync never deletes data" isn't superseded - it's either enforced or intentionally relaxed. Mixing them would muddy the semantics of both. But they should be first-class participants in the same graph, connected by implications, queryable by the same tools.
