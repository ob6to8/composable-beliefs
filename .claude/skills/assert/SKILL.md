Add assertions to the DAG after examining a source artifact, entity, or reasoning direction.

See `docs/systems/assertion-dag.md` for the canonical system reference - especially the design principles and confidence scoring guide.

## Input

`$ARGUMENTS` describes what to assert on. Examples:
- Entity path: `agent/claude` - read the entity and build assertions
- Reasoning direction: `crew capacity for spring 2026` - compose assertions about a topic
- Conversation: `persist our discussion about break 2 logistics` - formalize prior reasoning

## Steps

1. **Read** the referenced artifact, entity, or conversation context.

2. **Load existing assertions** from `org/assertions/assertions.json`. Note the last ID to generate sequential new IDs.

3. **Identify primitives.** Extract non-reducible facts worth asserting. Each primitive:
   - Has `type: "assertion"` and `kind: "primitive"`
   - Has a single source (document, user, policy)
   - Has an `evidence` array with at least one entry. Each entry has `date`, `source`, and `detail`. The `detail` is a specific, detailed description of what happened - not a generalization (that's `claim`) but the full narrative of the event that constitutes evidence. More detail resists conflation.
   - Has `subjects` array linking to referenced entities
   - Gets a confidence score (see scoring guide in `docs/systems/assertion-dag.md`)
   - Only include facts that participate in compound reasoning - skip self-evident data
   - **For self-referential assertions** (subject type "agent"): distinguish between user observations (encode as primitives) and user theories (encode as compounds with lower confidence). Do not treat user speculation as ground truth.

4. **Scan for composition.** Compare new primitives against existing assertions:
   - Do any new primitives interact with existing primitives from other entities?
   - Do date ranges overlap? Do capacity numbers conflict? Do schedules collide?
   - This is where cross-entity findings emerge. Be thorough.

5. **Build compounds.** For each composition found:
   - List the dep IDs explicitly
   - Write the implication - what does the combination of deps mean?
   - Score confidence independently from deps

6. **Build implications.** For compounds that surface actions, gaps, or requirements:
   - Set `kind: "implication"` (all assertions have `type: "assertion"`)
   - Set `materialized: null` (materialization is done separately via `/materialize`)
   - Set `subjects` to the relevant entity references
   - The implication text should describe the action needed
   - **An implication must trace its sources through real composition.** If it restates a single primitive, it's redundant - not an implication. Every implication requires deps representing genuinely distinct inputs whose combination produces a novel conclusion.

7. **Present** the proposed assertions to the user before writing. Show each one with its deps, confidence, and reasoning.

8. **Write** to `org/assertions/assertions.json` after user approval.

## Rules

- Never edit existing assertions. Only append new ones or change status (supersede/retract).
- Extraction-time only - assert what you're actively reading, not retroactive guesses.
- Primitives are ground truth as stated by the source. We take sources at their word.
- Confidence scoring: 1.0 = confirmed/specific, 0.9 = strong but could change, 0.7 = some ambiguity, 0.5 = unconfirmed, 0.3 = weak signal, 0.0 = placeholder.
- Compound confidence is independent of dep confidence - assess the reasoning quality.
- If superseding an assertion, mark the old one `superseded` with `superseded_by` pointing to the new one. Flag any compounds that depend on the old one as potentially stale.

## Data protection

Writing to `org/assertions/assertions.json` requires explicit user authorization. Always present proposed assertions and get confirmation before writing.
