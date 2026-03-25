# Stable Marriage Problem — DAG Analysis

## What the decomposition surfaced

### The bridge is the weakest link

The article's rhetorical force comes from the mathematical proof (c01) — it feels like math proves you should ask for what you want. But the math only proves proposer-optimality within the algorithm. The leap to real life passes through c02 (the bridge), which depends on three contestable primitives:

- **p05**: "Proposing" maps to "asking" — intuitive but not formally justified
- **p06**: Preferences are rankable — the algorithm requires strict complete rankings; humans have incomplete, changing, incomparable preferences
- **p07**: Matching is sequential — partly true but real-world matching involves parallelism, incomplete information, and no clear rounds

In the prose, the bridge is nearly invisible. The article moves from "the algorithm proves" to "therefore in life" in a single paragraph. The DAG makes the bridge a first-class structural element that must be examined independently.

### The caveats deserve equal structural weight

The article buries its most important qualifications in footnotes. In the DAG, c04 (real-world friction) has equal structural status to c01 (mathematical advantage). This changes how you evaluate the thesis:

- p13 (stickiness improves outcomes) actually undermines the algorithm's notion of "optimal" — if investing in a match makes it better than the "optimal" match would have been, then the algorithm's ranking is wrong
- p10 (social sanctions) means rejection isn't costless, which violates a core assumption
- p11 (psychological cost) means repeated asking has diminishing returns, which the algorithm doesn't model

The prose presents these as "yes but still." The DAG presents them as dependencies of the qualified conclusion (c06) that the article actually supports.

### The article proves less than it claims

The top-level claim (c07) rhetorically sounds like "math proves asking is optimal." The DAG reveals the actual argument is:

1. Math proves proposer-optimality (airtight, within assumptions)
2. An intuitive but contestable analogy maps proposing to asking (weak)
3. Some anecdotal evidence supports initiative independently (moderate)
4. Real-world friction bounds the advantage (acknowledged)

The honest conclusion is c06 (advantage is real but bounded), not c05 (asking is systematically better). The article's rhetorical emphasis is on c05 but its own evidence better supports c06.

### No primitive reuse — four independent pillars

Unlike the Its Just Shell DAG where p06 appeared in 4 compounds (making it a keystone), every primitive here appears in exactly one L2 compound. The four L2 compounds are completely independent of each other. This means:

- Attacking c01 (math) doesn't affect c03 (empirical) or c04 (caveats)
- Attacking c02 (bridge) doesn't affect c03 (empirical) — there's a weaker case for initiative that doesn't depend on the math at all
- The article has **graceful degradation**: even if the bridge fails entirely, p08 ("initiators select from larger universe") stands on its own as a simple observational truth

### Type structure reveals the argument's architecture

| Type | Primitives | Contestability | Role |
|---|---|---|---|
| Math | p01-p04 | None | Provides rhetorical force |
| Bridge | p05-p07 | High | **Load-bearing but weakest** |
| Empirical | p08-p09 | Medium | Independent backup |
| Caveat | p10-p13 | Low | Bounds the conclusion |

The article leads with math (strongest) and buries caveats (in footnotes). The DAG reveals that the bridge (weakest) determines whether the math even applies. This is the classic rhetorical pattern the DAG is designed to expose: **leading with your strongest evidence while hiding the weakest link in the chain**.

### Potential shared primitives for cross-domain knowledge base

Several primitives here could appear in other domain DAGs:

- **p08** (initiators select from larger universe) → applies to any domain involving agency, negotiation, market dynamics
- **p12** (commitments are sticky due to transaction costs) → economics, organizational theory, relationship psychology
- **p13** (stickiness improves outcomes) → investment theory, skill development, relationship dynamics
- **p11** (rejection has psychological cost) → any domain involving interpersonal risk
- **p06** (preferences are rankable) → decision theory, economics, ethics (preference utilitarianism)

These are candidates for the `knowledge/shared/` directory.

## Structure

```
knowledge/domains/stable-marriage/
  primitives/           13 primitives (p01-p13)
    p01-p04             math (proven theorems)
    p05-p07             bridge (maps math to reality)
    p08-p09             empirical (observable evidence)
    p10-p13             caveats (article's own qualifications)
  compounds_l2/         4 layer-2 compounds (c01-c04) with deps.json
  compounds_l3/         2 layer-3 compounds (c05-c06) with deps.json
  compounds_l4/         1 layer-4 top-level claim (c07) with deps.json
  diagram.txt           ASCII dependency graph with reuse matrix
  ANALYSIS.md           this file
```

4 layers deep. 13 primitives. 7 compounds. 20 total nodes.
