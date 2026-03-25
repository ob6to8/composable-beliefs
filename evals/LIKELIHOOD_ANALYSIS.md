# Likelihood Analysis

An honest assessment of the probability these results hold, their potential impact, the testing required, and the best presentation format. Written after the initial N=3 eval showing assertion DAGs outperforming prose on compound adherence (9/9 vs 2/9).

---

## Likelihood the Results Hold

**~65% that the general direction holds. ~40% that it's specifically the DAG structure rather than the additional specificity.**

The biggest threat to validity isn't sample size — it's information asymmetry. Context B doesn't just restructure the prose. It adds c1, which literally says "separate your tests: test the pure logic without IO wherever possible." That's a specific design instruction that doesn't appear in context A's prose. The LLM may have built `get_config_pure()` because it was told to, not because the DAG structure enabled better reasoning.

The honest next test is a four-condition experiment (see NEXT_EXPERIMENT.md) that isolates structure from specificity.

What makes me lean toward "the direction holds" despite this:
- The LLM didn't just follow c1. It also organized tests by purity level (c2) and labeled them with purity metadata (c3). It treated the assertions as a system, not as individual instructions.
- The qualitative consistency across all 3 DAG runs — three different pure-wrapper implementations, all structured the same way — suggests something beyond "following a specific instruction."
- The mechanism is plausible and aligns with established research on LLMs being better at constraint satisfaction than open-ended interpretation.

What makes me cautious:
- N=3 is anecdotal, not evidence
- The scorer is an LLM, introducing circularity
- We haven't run the critical comparison (equally specific prose vs DAG)
- One context A run was contaminated

---

## The Authoring-Time vs Inference-Time Question

A key open question surfaced in discussion: the DAG might not be magic at inference time — the magic might be at *authoring* time.

When you decompose a compound assertion into primitives, you're forced to:

1. **Identify the actual atomic claims** — "purity matters" becomes six specific things you mean by that
2. **Make hidden assumptions explicit** — the recombined claim in test_1 exposed the "visible" gap *because the decomposition forced you to list the deps*
3. **Discover which compositions are sound** — some primitives combine naturally, others don't, and you only find out when you try to write the deps.json

The DAG could be a **thinking tool**, not (or not only) an **inference tool**. The discipline of decomposition produces better instructions regardless of whether the final format is a DAG or prose. The format may be a means to the end of clarity.

If that's the case, then prose written *after* decomposition would perform as well as the DAG itself — because the useful work already happened during decomposition. The DAG structure at inference time would be cosmetic. The value was in the process of building it.

But there's a third possibility: **both matter**. The decomposition surfaces better instructions (authoring-time value), *and* the DAG format helps the LLM execute them more reliably (inference-time value). These aren't mutually exclusive.

The four-condition experiment (see NEXT_EXPERIMENT.md) is designed to isolate these effects.

---

## How Impactful If It Holds

**Useful and publishable, not paradigm-shifting.**

If the DAG structure specifically (not just specificity) drives better adherence, it's a practical technique with immediate applications:

- Replace prose CLAUDE.md files with assertion DAGs for more consistent agent behavior
- Use assertion DAGs as CI-scorable design specifications
- Build agent belief systems as inspectable file structures

It would be a contribution to **context engineering** — a field that barely exists yet but that everyone doing serious agent work is doing implicitly. It would not be a breakthrough in AI alignment, a solution to hallucination generally, or a replacement for model improvements.

The most impactful version of the finding would be: "here's a specific, easy-to-adopt technique that makes LLMs follow your design principles more consistently, and here's the evidence." Practitioners would use it tomorrow. Researchers would cite it as supporting evidence for structured knowledge representation.

The "agent belief system" extension — externalized, inspectable, adversarially testable beliefs — is potentially more impactful than the core finding, but it's further from validated. The eval result is the foot in the door. The epistemological framework is the bigger idea behind it.

---

## How Much Testing to Feel Confident

**A weekend of compute, designed carefully.**

Minimum viable rigor:

| Test | Purpose | LLM calls |
|---|---|---|
| N=10 on current task, 4 contexts (A/B/C/D) | Isolate structure vs specificity | 40 generation + 360 scoring |
| Second task (different domain) | Test generalization | 40 generation + 360 scoring |
| Scorer consistency (re-score 10 outputs) | Measure scorer reliability | 90 scoring |
| Second model (if accessible) | Test model dependence | 40 generation |

That's roughly 900 LLM calls. At `claude -p` speeds, maybe 6-8 hours of wall clock time. All automatable with the scripts we already have.

Context C is the critical condition. Without it, the finding is "more specific instructions produce better results" — true but obvious. With it, the finding is either "structured composition specifically produces better results" (interesting, publishable) or "it was just specificity" (useful learning, changes the direction).

---

## Presentation Format

**The Its Just Shell framing, but with rigorous methodology shown, not hidden.**

A formal academic paper would reach a small audience of NLP researchers who already know about FActScore and neuro-symbolic AI. They'd evaluate it against a standard they define and likely find the sample size insufficient.

The Its Just Shell framing reaches practitioners — the people who write CLAUDE.md files, build agent systems, and would actually use assertion DAGs tomorrow if convinced they work. That audience is larger, more engaged, and more likely to amplify.

But: the framing only works if the methodology is credible. Practitioners are allergic to hand-waving. The matklad article works precisely because it's technically precise while being accessibly written. The thesis already has this quality — it cites papers, shows code, makes falsifiable claims.

The recommended presentation:

1. **Lead with the result**: "We gave an LLM the same design principles two ways. Prose produced 22% compound adherence. An assertion DAG produced 100%. The DAG-guided LLM invented abstractions the prose-guided LLM never attempted."
2. **Show the code**: side-by-side of `get_config_pure()` (DAG) vs straight-to-temp-files (prose). Let people see the difference.
3. **Show the methodology**: the eval is 50 lines of bash. People can reproduce it. This is the Its Just Shell brand — the methodology is shell-inspectable.
4. **Be honest about limitations**: N=3, one task, information asymmetry concern. This is how you build trust with the practitioner audience — show that you know what you don't know.
5. **Frame the bigger picture**: agent belief systems, the deliberation layer, the trust gradient extending to epistemology. This is the "why you should care" beyond the specific result.

The viral potential isn't in the assertion finding alone. It's in the narrative: "the thesis about shell-based agent architecture led to a discovery about how LLMs process knowledge, which was tested using the thesis's own methodology, and the test framework was itself built from the thesis's primitives." That recursive self-validation is the hook.
