# Composable Beliefs

A paradigm for giving AI agents persistent, source-grounded, inspectable reasoning that survives session boundaries and composes into understanding the agent never explicitly derived.

## Quick Start

1. Read this file for orientation
2. Read `plans/composable-beliefs-thesis.md` for the full thesis
3. `mix deps.get && mix compile` to build
4. `mix bs help` for the belief shell CLI
5. `mix bs stats` to see the graph

## Architecture

The mechanism is a directed acyclic graph of assertions. Three kinds: primitive (what a source said), compound (what combining sources means), implication (what needs to happen). Confidence scores make uncertainty visible. Immutability makes change traceable. Composition makes the whole greater than the parts.

### Belief Shell

The CLI interface to the DAG. See `shell/belief-shell-api-v1.md` for the full spec.

**Tier 1 (Deterministic)** - pure graph traversal, no LLM:

    mix bs list [filters]       List assertions
    mix bs show <id>            Full detail
    mix bs tree <id>            Dependency tree
    mix bs deps <id>            Direct dependencies
    mix bs dependents <id>      Reverse lookup (--deep for transitive)
    mix bs stale                Find stale assertions (--cascade for transitive)
    mix bs path <id1> <id2>     Find connection between assertions
    mix bs history <id>         Supersession chain
    mix bs subjects <ref|type>  Find by subject
    mix bs stats                Graph statistics

**Tier 2 (Probabilistic)** - require LLM reasoning, propose-confirm pattern. See `plans/belief-shell-tier2.md`.

### Schema

**SSOT: `lib/cb/assertion.ex`** - read that module for field definitions, types, assertion kinds, confidence scoring guide, source type prefixes, and immutability rules.

### System Design

- `docs/systems/assertion-dag.md` - full design rationale, DAG structure, query patterns
- `docs/systems/assertion-dag-operations.md` - operational learnings
- `docs/systems/actualization-via-assertion-dag.md` - self-referential assertions, RLHF counterweight

## Skills

| Skill | Notes |
|---|---|
| `/assert` | Add assertions from artifacts, entities, or conversation reasoning |
| `/assertions` | Query and traverse the DAG (list, filter, tree, stale) |
| `/materialize` | Turn implications into todos on objects |

## Data

- `org/assertions/assertions.json` - the assertion graph (example assertions demonstrating the paradigm)
- `shell/temp-dag/assertions.json` - belief shell analysis assertions

## Plans

- `plans/composable-beliefs-thesis.md` - the paradigm definition
- `plans/composable-beliefs-plans.md` - plan briefs for DAG spec, architecture, privacy, distribution
- `plans/belief-shell-tier2.md` - implementation plan for probabilistic shell operations
- `plans/cb-on-the-beam.md` - why the BEAM is the right runtime, supervision + beliefs coupling, client integration path example
- `plans/cb-service-model.md` - open source core + paid service model, structure-without-content privacy, tiers, client integration, tiers
- `plans/historical/` - (gitignored) original Stratta plans from startup-framing era, mined for useful content

## Formatting

**Never use emdashes.** Use hyphens (-) instead.

## Git Policy

Never commit or push unless explicitly instructed.

## Data Protection

**Never modify files under `org/` unless the user explicitly requests and authorizes the change.** Reading and querying is always allowed.

## Origin

Extracted from a live operational system where the assertion DAG was built and battle-tested. This repo is the framework.
