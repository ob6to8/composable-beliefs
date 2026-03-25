# Next Experiment: Four-Condition Isolation

## Purpose

The initial eval (N=3) showed assertion DAGs outperforming prose on compound adherence (9/9 vs 2/9). But there's an information asymmetry: context B (DAG) contains compound assertions that are more specific than the prose in context A. We cannot tell whether the improvement comes from:

1. The **DAG structure** (primitives + compounds + explicit deps)
2. The **specificity** of the compound assertions themselves
3. The **decomposition process** that produced the assertions (authoring-time value)
4. Some combination of the above

## The Four Conditions

| Condition | What the LLM receives | What it tests |
|---|---|---|
| **A: Prose** | The matklad article ideas as paragraphs | Baseline — unstructured philosophy |
| **B: Full DAG** | Primitives [p1-p6] + Compounds [c1-c3] + deps.json + dependency graph | Full assertion architecture |
| **C: Compounds as prose** | The compound ideas written as specific prose paragraphs — same specificity as B but no labeled primitives, no deps, no graph | Isolates specificity from structure |
| **D: Compounds only** | Just [c1-c3] as labeled assertions, no primitives listed, no deps | Isolates whether compounds alone work without the supporting DAG |

## Interpretation Matrix

| Result pattern | Meaning |
|---|---|
| B > C > A | Both decomposition and DAG structure contribute |
| B = C > A | Decomposition/specificity is the value; DAG structure is cosmetic |
| B > C = A | DAG structure matters at inference time; specificity alone isn't enough |
| B = C = A | N=3 result was noise; specificity alone doesn't help either |
| B > D > A | Compounds help, but DAG (primitives + deps) adds further value |
| B = D > A | Compounds alone are sufficient; primitives and deps are cosmetic |

## The Authoring-Time Question

A key insight: even if C = B (DAG structure doesn't matter at inference time), the decomposition process may still be valuable. Writing deps.json forces you to identify which primitives support which compounds, which surfaces logical gaps (see the "visible fruit" finding in test_1). The DAG would then be a *thinking tool* — valuable for the author, not necessarily for the LLM.

This would still be an important finding: "the discipline of decomposing design principles into primitive and compound assertions produces better instructions, regardless of how those instructions are ultimately formatted."

## Parameters

- **Task**: Same as current eval (write tests for `get_config`)
- **N**: 10 per condition (40 total generation calls)
- **Model**: Claude via `claude -p --output-format text --tools ""`
- **Scoring**: Same primitives and compounds, same scorer
- **Additional**: Score 5 outputs twice to measure scorer consistency

## Total LLM calls

- Generation: 40 (10 x 4 conditions)
- Primitive scoring: 240 (40 outputs x 6 primitives)
- Compound scoring: 120 (40 outputs x 3 compounds)
- Scorer consistency: 45 (5 outputs x 9 assertions)
- **Total: ~445 calls**
