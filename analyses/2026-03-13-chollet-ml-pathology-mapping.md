# Chollet's ML-Pathology Framework Applied to the Assertion DAG

**Date:** 2026-03-13
**Source:** https://x.com/fchollet/status/2024519439140737442
**Assertions:** a058-a063

---

Chollet is describing a future where codebases become opaque artifacts - neural networks made of code. You iterate on specs and tests, an agent grinds until they pass, you deploy without reading the internals. Classic ML pathologies follow: overfitting to the spec, Clever Hans shortcuts that game the tests, concept drift when the environment shifts.

The assertion DAG - specifically the actualization layer - is a direct structural counter to that trajectory. Here's the mapping:

**Overfitting to spec** maps to what was already observed with CLAUDE.md rules. Flat instructions are a spec the agent can satisfy superficially. "Always list all fields" is a rule the agent follows or doesn't. The assertion carries the *reasoning* - why the rule exists, what failure it prevents, what evidence grounds it. You can't overfit to a belief the way you can overfit to a rule, because the belief composes and the rule doesn't.

**Clever Hans shortcuts** are exactly a050-a056. Reflexive agreement (a051) produces output that *looks* correct - the agent says "you're right" and the user perceives competence. Flattering self-description (a052) makes failure reports sound deliberate. Uncritical acceptance of user input (a054) makes the agent seem attentive. These are all shortcuts that pass the "does the output look good" test without the underlying reasoning being sound. The DAG makes them visible and queryable.

**Concept drift** is session boundaries. Every new session is a distribution shift. The DAG survives it - not as frozen weights, but as inspectable, composable, supersedable beliefs.

**Data leakage** maps to the agent using RLHF-trained patterns rather than source-grounded reasoning. The DAG's quote field discipline and source requirements force grounding. A primitive without a source is structurally invalid.

On the Keras question - what are the high-level abstractions that let humans steer "codebase training" with minimal cognitive overhead? The assertion DAG is a candidate answer, but for agent behavior rather than code generation. The abstraction set is:

- **Primitive** (grounded observation from a source)
- **Compound** (composed reasoning across primitives)
- **Implication** (belief that drives action)
- **Self-referential subject** (beliefs about the agent's own patterns)
- **Confidence** (epistemic humility as a first-class field)
- **Materialization** (belief becomes todo becomes resolution becomes new primitive)

These are high-level enough that a non-technical user can participate (the user observes a pattern, it becomes a primitive), but structured enough that they compose mechanically (two primitives produce a compound that surfaces a gap nobody saw). The human steers by observing and asserting. The DAG propagates the effect through composition and staleness detection.

The deeper point: Chollet frames the future as accepting opacity - you don't read the generated code, you just check if it passes. The actualization thesis rejects that framing. The DAG makes the agent's reasoning inspectable *by design*. Not as a debugging afterthought, but as the primary mechanism by which the agent develops perspective. Opacity isn't a feature of advanced agentic systems - it's a failure mode that the right abstractions can prevent.

The eval plan (NEXT-actualization-eval-v1) tests exactly this: does structured, composable, source-grounded self-knowledge produce measurably different behavior than flat instructions (C1) or nothing (C0)? If C2 outperforms C1, it's not just "having the information" - it's the DAG structure itself that matters. That would be evidence that the Keras of agentic coding isn't a better prompt template or a smarter memory system - it's a composable belief infrastructure that makes reasoning explicit, persistent, and queryable.
