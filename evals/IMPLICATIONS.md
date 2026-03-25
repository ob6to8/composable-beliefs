# Implications and Future Directions

## If These Results Hold

The eval results (N=3, one task, one model) suggest that assertion DAGs produce measurably better and more consistent LLM adherence to design principles than equivalent prose. If this holds across larger samples, multiple tasks, and multiple models, the implications are significant.

---

## Implication 1: The Bottleneck Is Knowledge Representation, Not Model Capability

The prose and the DAG contained the same ideas. The model was the same. The only variable was how the knowledge was structured. If the structure produces the difference, then improving LLM reliability is a knowledge representation problem — not a scaling problem, not a fine-tuning problem, not a prompting problem.

This means: instead of writing better prose instructions, write better assertion graphs. Instead of hoping the model "understands" your philosophy, give it the composition explicitly. The fix is structural.

## Implication 2: CLAUDE.md Files and System Prompts Are Fundamentally Limited

The dominant pattern for configuring agent behavior today is prose instructions in system prompts and CLAUDE.md files. If assertion DAGs outperform prose, then the entire ecosystem of "write good system prompts" is operating at a suboptimal representation layer.

The actionable change: replace prose design principles in system prompts with assertion DAGs. Instead of "write clean, well-tested code," provide:
- Primitive assertions defining what "clean" and "well-tested" mean concretely
- Compound assertions showing how those primitives compose into design decisions
- The dependency graph showing which primitives support which compounds

## Implication 3: Design Principles Become Testable

Currently, "does this code follow our testing philosophy?" is a vibes check in code review. With compound assertions, it becomes a scoring function. You can:
- Run it in CI: score every PR against the assertion DAG
- Track adherence over time: monitor scores across commits
- Detect regression: alert when a compound drops from YES to NO
- Diff principles: compare two teams' assertion DAGs structurally

Design principles move from tribal knowledge to executable specification.

## Implication 4: The Eval and the Guidance Are the Same Artifact

The assertion DAG serves triple duty:
1. **Context**: guides the LLM during generation
2. **Rubric**: scores the LLM's output after generation
3. **Documentation**: records the design principles for humans

This is not a coincidence. It's a property of the structure. If your guidance is precise enough to score against, it's precise enough to follow. If it's too vague to score against, it's too vague to follow. The assertion DAG enforces this precision by construction.

## Implication 5: LLMs Are Better at Constraint Satisfaction Than Philosophy Adoption

The prose asked the LLM to "understand and embody a testing philosophy." The DAG asked it to "satisfy these specific constraints in combination." These are fundamentally different cognitive tasks. The results suggest LLMs are better at the second.

This aligns with what we know about LLMs: they're good at following concrete instructions and bad at maintaining abstract principles across long generations. The assertion DAG converts abstract principles into concrete constraints — it compiles philosophy into a checkable specification.

## Implication 6: Composition Is a Form of Reasoning LLMs Can Execute But Don't Spontaneously Perform

The LLM "knew" about purity from the prose. It had the concept in its training data. But it didn't *compose* that knowledge into a design decision (separate pure logic from IO) unless the composition was made explicit via compound assertions.

This suggests: LLMs have the components of reasoning available but don't reliably perform the synthesis step. The compound assertion performs that synthesis externally and hands the result to the LLM. The LLM executes the pre-composed reasoning rather than composing it from scratch.

If true, this means the role of the assertion DAG is not "telling the LLM what to think" but "performing the reasoning step the LLM is unreliable at, and giving it the result." The human (or a separate LLM) does the composition. The generating LLM executes it.

---

## Future Directions

### More Rigorous Testing

- **Scale N**: Run N=10 or N=30 to establish statistical significance
- **Multiple tasks**: Test across different coding tasks with varying design spaces
- **Multiple models**: Compare Claude, GPT-4, Gemini, open-source models
- **Scorer validation**: Score the same output multiple times to measure scorer consistency
- **Fairer comparison**: Test prose that includes compound ideas (without DAG structure) to isolate whether the structure or the additional specificity is the active ingredient

### Adversarial Assertion Testing

Two LLM agents operating over the same assertion DAG:

- **Proponent**: Constructs compound assertions from primitives, defends them
- **Opponent**: Attacks compounds by contesting primitives, finding composition gaps, constructing counter-assertions

The adversarial setup would:
1. **Contest primitives**: "I reject p2, here's why" (itself a compound assertion)
2. **Attack composition**: "p1+p2+p3 doesn't entail c1 because..." (the "visible fruit" problem from test_1)
3. **Construct counter-assertions**: Alternative compounds from the same primitives
4. **Force decomposition**: Demand finer-grained primitives, exposing hidden assumptions

### Agent Belief Systems

Use assertion DAGs as externalized agent belief systems:
- An agent's beliefs are the assertion files in its directory
- Belief composition is deps.json
- Belief verification is the scoring function
- Belief change is a `git diff` on the assertion files

This enables:
- **Observability**: `cat` what an agent believes
- **Security**: trace contaminated beliefs through the dependency graph
- **Self-correction**: agent runs consistency checks on its own assertion DAG
- **Auditability**: version-controlled belief history

### The Deliberation Layer

The Its Just Shell thesis identifies three layers: deliberation (unconstrained NL), execution (shell-semantic), verification (shell-inspectable). The deliberation layer is currently the weak link — it's unconstrained.

The assertion DAG constrains the deliberation layer without restricting natural language. Agents can chat freely, but beliefs resulting from deliberation must be deposited as structured assertions. The deliberation is unconstrained; the *output* of deliberation is structured.

### Self-Referential Testing

The Its Just Shell thesis itself makes testable claims that decompose into primitive and compound assertions. An eval could:
1. Decompose the thesis into an assertion DAG
2. Give an LLM the thesis-as-DAG and ask it to build an agent system
3. Give another LLM the thesis-as-prose
4. Score both outputs against the thesis's own primitives

The thesis testing itself with its own methodology.

### Formal Connections

The assertion DAG relates to several established formalisms:
- **Dung's argumentation frameworks** (1995): arguments as nodes that attack each other. The DAG adds internal structure to arguments.
- **FActScore** (EMNLP 2023): atomic fact decomposition for factuality scoring. The DAG adds composition.
- **FoVer** (TACL 2025): first-order logic verification with Z3. The DAG provides the claims to verify.
- **SAFE** (Google DeepMind, 2024): search-augmented factuality evaluation. The DAG provides the rubric.
- **Neuro-symbolic AI**: LLM as generator, symbolic structure as verifier. The DAG is the symbolic structure.

No existing system fully implements epistemic dependency graphs where claims are organized by their logical dependencies and verified in topological order. This appears to be an open research opportunity.

---

## Open Questions

1. **Is composition the active ingredient, or is it specificity?** The compounds are more specific than the primitives. A fairer test would compare DAG compounds against equally specific prose paragraphs.

2. **Does this scale to complex domains?** Testing philosophy decomposes cleanly into 6 primitives. Would a real-world domain (e.g., security policy, API design principles) decompose as cleanly?

3. **Who writes the assertions?** Human-authored assertions are expensive. LLM-authored assertions might inherit the same reasoning gaps they're meant to prevent. The decomposition step is where interpretation happens — it's the compilation from prose to structured form.

4. **How do you validate the DAG itself?** The recombined claim in test_1 showed that a DAG can be internally consistent but logically flawed. Who checks the composition?

5. **Does the scorer agree with itself?** We have not tested scorer consistency. The same output scored twice might produce different results, especially on philosophical assertions like "purity implies stability."

6. **What's the minimum effective structure?** Is the full DAG necessary, or would just the compounds (without explicit deps) work? What about compounds with deps but without the primitives spelled out?
