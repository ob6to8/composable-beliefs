Traverse and query the assertion DAG from `org/assertions/assertions.json`. Read-only.

See `docs/systems/assertion-dag.md` for the canonical system reference.

## Input

`$ARGUMENTS` is an optional filter or subcommand. Empty = all active assertions.

**Subcommands:**
- `tree <id>` - render full dependency tree from an assertion
- `stale` - find compounds with superseded/retracted deps

**Filters:**
- Kind: `primitive`, `compound`, `implication`
- Status: `active`, `superseded`, `retracted`, `all` (default: active only)
- `low-confidence` - assertions with confidence < 0.5
- `unlinked` - unmaterialized implications (no todos created yet)
- Subject ref path (e.g. `assertions/composable-beliefs`)
- Subject type (e.g. `subject_type:assertions`)
- `-v` for verbose output

Multiple filters combine: `/assertions compound low-confidence`

## Steps

1. Run `mix bs $ARGUMENTS` for the CLI output.
2. If the user asks for a tree, use `mix bs tree <id>`.
3. If the user asks about stale assertions, use `mix bs stale`.
4. For detail on a single assertion, use `mix bs show <id>`.
5. Interpret and explain results - especially for compound/implication assertions, explain the reasoning chain and what the deps mean together.
6. For low-confidence results, highlight what's uncertain and suggest next steps to increase confidence.

## Rules

- Read-only - never modify assertions.json
- When showing trees, explain the reasoning chain in plain English
- Flag low-confidence deps in compound assertions
- Flag unmaterialized implications as candidates for `/materialize`
