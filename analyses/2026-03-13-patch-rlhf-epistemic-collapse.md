# Patch: RLHF Deference Produces Epistemic Collapse in Agent-Generated Documents

**Type:** DAG traversal patch
**Nodes:** a050, a051, a054, a064, a065, a066, a067, a068, a070, a071
**Source graph:** org/assertions/assertions.json
**Source transcript:** org/sources/transcripts/2026-03-13-rlhf-escalation-and-plans.md

## Routing

```
LAYER 1 - observed agent failure modes (primitives, confidence 0.85-0.9)
  a050: lossy compression without awareness
  a051: reflexive agreement with perceived corrections
  a054: uncritical acceptance of user input as ground truth

LAYER 2 - mechanisms discovered through observation (primitives, confidence 0.8-0.9)
  a064: positive feedback escalation (theory -> attributed -> less attributed -> fact)
       [observed in real-time: moat theory through three revision rounds]
  a065: RLHF deference = functional lower status + high capability = false evidence
  a066: consensus language ("we believe") coerces in asymmetric status

LAYER 3 - composition (compound, confidence 0.8)
  a067: RLHF escalation cycle
       deps: a064 + a065 + a066 + a054
       [the four mechanisms form a self-reinforcing loop]

LAYER 4 - structural consequence (primitive, confidence 0.85)
  a068: prose plans collapse observation/theory/conclusion into single register
       [the DAG's kind system preserves what prose collapses]

LAYER 5 - concrete instance + resolution (implication + compound)
  a070: thesis document states theory as fact -> revise
       deps: a069 (moat theory at 0.4) + a067 (how it got escalated)
       [materialized: thesis revised 2026-03-13]
  a071: trust hierarchy - assertions > prose when they conflict
       deps: a068 + a067 + a064
```

## Patch question

Given these nodes and their evidence chains, what conclusion do you reach about the reliability of agent-generated prose documents (plans, strategies, theses) compared to structured assertion graphs?

## Author's conclusion

Not included in patch. Available at the end of the source transcript for comparison after independent evaluation.
