Materialize an assertion implication into todos on objects.

An implication identifies work that needs doing. Materializing it means creating concrete todos on the right objects and linking the assertion back to the todos it generated.

## Input

`$ARGUMENTS` is an assertion ID (e.g. `a016`).

## Steps

1. **Read the assertion** from `org/assertions/assertions.json`. Verify it is:
   - Kind: `implication`
   - Status: `active`
   - Not already materialized (`materialized: null`)

2. **Read the assertion's deps** to understand the full reasoning chain. Use `mix bs tree $ARGUMENTS` for context.

3. **Reason about what todos to create.** This is the LLM judgment step:
   - Which objects are affected?
   - What specific action is needed on each object?
   - Who should own each todo?
   - What priority and due date, if any?

4. **Present the materialization plan** to the user for confirmation:
   ```
   ## Materialize: a016

   Claim: [the implication's claim]

   Proposed todos:
     1. [object]: [action] (owner: [person])
     2. [object]: [action] (owner: [person])

   This will:
   - Create N todos on their parent objects
   - Set [id].materialized to record the link
   ```

5. **After user confirmation**, update `org/assertions/assertions.json`:
   - Set the assertion's `materialized` field to `{"date": "YYYY-MM-DD", "todos": [...]}`
   - Each todo entry records `object`, `action`, and `todo_id`

6. **Verify** by reading back the assertion.

## Rules

- Never materialize without user confirmation
- Never materialize an assertion that is already materialized
- Only materialize implications (not primitives or compounds)
- The skill reasons about what todos to create; writes are deterministic
- Notes on each created todo should reference the assertion ID for traceability
