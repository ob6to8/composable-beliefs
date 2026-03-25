# Thesis DAG Analysis

## What the decomposition surfaced

### p11 is orphaned

Primitive p11 ("Single agents outperform multi-agent in most cases") is not a dependency of any compound assertion. It appears in the thesis as supporting evidence but no architectural claim depends on it. This means either:

1. It's not actually load-bearing for the thesis — it's color, not structure
2. There's a missing compound that should depend on it (perhaps something about why simplicity works, or why multi-agent coordination is the wrong default)
3. It's doing implicit work that the decomposition didn't capture

This is exactly the kind of gap the DAG is designed to surface. In the prose thesis, p11 feels important. In the DAG, it's visibly disconnected. Either the prose is giving it false weight, or the DAG is missing a connection.

### p06 is the most load-bearing primitive

"Composition of focused tools beats monolithic frameworks" appears in 4 of 7 L2 compounds. It's the foundational claim. If p06 falls, c01 (shell is sufficient), c05 (convergent evolution), c06 (derivative stack), and c07 (frameworks rebuild Unix) all lose a dependency. That's more than half the thesis.

This makes p06 the highest-value target for adversarial testing. An opponent contesting the thesis should attack p06 first.

### The thesis has two independent pillars

The dependency graph reveals that the thesis rests on two largely independent argument structures:

**Pillar 1: Sufficiency** (c08 "ground floor")
- c01 (shell is sufficient) + c05 (convergent evolution) + c07 (frameworks leak)
- Primitives: p01, p02, p03, p04, p06, p12, p14
- Argument: Unix is enough, frameworks add unnecessary abstraction, independent practitioners agree

**Pillar 2: Trust/Control** (c09 "control as spectrum")
- c02 (two control models) + c03 (trust gradient) + c04 (script-driven security)
- Primitives: p01, p05, p07, p08, p09, p10
- Argument: who controls the workflow determines trust, security, and inspectability

These pillars share only p01 (LLM is pure function). They are otherwise independent. The thesis stands on both but each could be argued independently. An opponent could concede Pillar 1 (yes, Unix is sufficient) while attacking Pillar 2 (no, the trust gradient doesn't hold as described) or vice versa.

### p03 (files are state) is underused

Despite being central to the thesis's rhetoric ("the filesystem is the context substrate"), p03 only appears in c01. It doesn't support the trust gradient, the security argument, or the derivative stack claims — even though the thesis text argues that files are essential for all of these. Either the decomposition missed connections, or the thesis relies on p03 less than its prose suggests.

### The "conflation" observation applies here

This decomposition may itself be exhibiting conflation — treating the thesis's rhetorical emphasis as a proxy for logical dependency. p03 feels important because the thesis mentions it repeatedly, but its actual role in the argument structure may be narrower than the prose implies. The DAG forces honesty about this.

## Structure

```
thesis_dag/
  primitives/          14 primitive assertions (p01-p14)
  compounds_l2/        7 layer-2 compounds (c01-c07) with deps.json
  compounds_l3/        3 layer-3 compounds (c08-c10) with deps.json
  compounds_l4/        1 layer-4 top-level claim (c11) with deps.json
  diagram.txt          ASCII dependency graph with reuse matrix
  ANALYSIS.md          this file
```

4 layers deep. 14 primitives. 11 compounds. 25 total nodes.
