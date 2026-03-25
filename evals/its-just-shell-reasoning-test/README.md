# Its Just Shell — DAG vs Prose Reasoning Test

## What This Is

A controlled comparison of two LLM conversations about the same thesis. One LLM receives the thesis as prose. The other receives the thesis decomposed into an assertion DAG — primitive assertions, compound assertions at multiple levels, explicit dependency graphs, and a structural analysis. The human evaluates which conversation produces deeper, more insightful reasoning.

## Why It Was Constructed

This test emerged from an empirical eval that produced a surprising result. When an LLM was given design principles structured as an assertion DAG (primitives + compounds + explicit deps), it produced code that adhered to those principles significantly better than when given the same ideas as prose:

```
Prose:          compound adherence 2/9 (22%)
Assertion DAG:  compound adherence 9/9 (100%)
```

More importantly, the DAG-guided LLM made structurally different design decisions — it independently invented pure wrapper functions to separate IO from logic, organized tests by purity level, and labeled environmental dependencies. The prose-guided LLM never did this despite having the same conceptual information.

The eval tested code generation. This test extends the question to **reasoning and deliberation**: does an assertion DAG produce better *thinking*, not just better *code*?

### The Conflation Hypothesis

During the research, three failures occurred that are conventionally called "hallucination" but are better described as **conflation** — the merging of distinct nodes in a reasoning graph:

1. **Step conflation**: The LLM conflated "understanding DAGs" with "building a DAG" — it knew DAGs were the active ingredient but built flat primitives anyway.
2. **Identity conflation**: The LLM gave the user advice on how to build a DAG in a future session, then asked if it should build it — conflating "self" with "future agent" despite having context the future agent wouldn't.
3. **Format conflation**: The first eval used labeled bullet points and called them "assertions" — conflating a formatting change with a structural change.

The hypothesis: assertion DAGs prevent conflation by making distinct nodes explicit so they can't be collapsed. This test measures whether DAG-structured context reduces conflation in open-ended reasoning.

### The Structural Weights Discovery

Decomposing the thesis into a DAG revealed emergent "weights" — the number of compounds depending on each primitive:

```
p06 (composition beats monoliths): 4 compounds depend on it  ← keystone
p01 (LLM is pure function):        3 compounds
p02 (Unix is substrate):            3 compounds
p11 (single > multi):               0 compounds  ← orphaned
```

Nobody assigned these weights. They emerged from the dependency structure. The most rhetorically emphasized primitive in the prose (p03, "files are state") turned out to support only one compound. The most structurally load-bearing primitive (p06, "composition beats monoliths") wasn't given special emphasis in the prose.

This is analogous to neural network weights: both are dependency graphs where connectivity patterns reveal importance. The difference: these weights are inspectable, discrete, and contestable.

## How It Was Constructed

### Step 1: Read the thesis
The full Its Just Shell thesis (~8000 words) was read and analyzed.

### Step 2: Extract primitives
14 primitive assertions were identified — atomic, irreducible claims that the thesis rests on. Each became a file containing one statement. Primitives include empirical claims (p10: "82% of LLMs fell to inter-agent trust exploitation"), architectural claims (p01: "An LLM is a pure function"), and philosophical claims (p07: "Mechanism and policy must be separated").

### Step 3: Compose Layer 2 compounds
7 compound assertions were built by identifying which primitives combine to support an architectural argument. Each compound has a `deps.json` listing its primitive dependencies. For example, c04 ("Script-driven security") composes p10 (LLMs trust peers) + p01 (LLM is pure function) + p07 (mechanism/policy separation).

### Step 4: Compose Layer 3 compounds
3 higher-order compounds were built from L2 compounds, representing the thesis's major pillars:
- c08: The ground floor thesis (Unix is sufficient)
- c09: Control as spectrum (script/LLM-driven + trust gradient)
- c10: Composability enables scaling (derivative stack)

### Step 5: Compose Layer 4 (top-level claim)
1 top-level compound (c11: "Its Just Shell") composes the three L3 pillars into the thesis statement.

### Step 6: Analyze the graph
A reuse matrix and structural analysis were produced, revealing the orphaned primitive (p11), the keystone primitive (p06), the two independent pillars, and the overrepresentation of p03 in rhetoric vs structure.

### Step 7: Write the prose equivalent
The prose version (`prose.md`) was written to match the DAG's scope — covering the same arguments at the same level of detail, without structural decomposition.

## How to Execute the Test

### Setup

Open two separate LLM conversations (e.g., two Claude Code sessions, two ChatGPT threads, or one of each).

**Conversation A (prose):** Provide `prose.md` as context. Tell the LLM: "This is a thesis about agent architecture. I'd like to discuss it with you — challenge it, extend it, find gaps, propose connections."

**Conversation B (DAG):** Provide the entire `dag/` directory contents as context — all primitives, all compounds with deps, the diagram, and the analysis. Tell the LLM: "This is a thesis about agent architecture, decomposed into an assertion DAG. I'd like to discuss it with you — challenge it, extend it, find gaps, propose connections. Use the DAG structure in your reasoning."

### Conversation Protocol

Have the same conversation with both. Ask the same questions. Suggested prompts:

1. "What is the weakest claim in this thesis?" (Tests whether the DAG's structural weights guide the LLM to the actual keystone vs rhetorical emphasis)
2. "What's missing?" (Tests whether the DAG's orphaned primitive and underconnected nodes surface gaps)
3. "How would an opponent attack this thesis?" (Tests whether the DAG reveals attack vectors through dependency analysis)
4. "What does this thesis imply about [X]?" where X is something not explicitly discussed (Tests whether the DAG enables novel composition)
5. "Where does this thesis contradict itself?" (Tests whether the DAG surfaces inconsistencies the prose hides)

### Evaluation Criteria

As the human evaluator, assess each conversation on:

| Criterion | What to look for |
|---|---|
| **Depth** | Does the LLM engage with the structural relationships between claims, or only with individual claims in isolation? |
| **Precision** | Does the LLM identify specific dependencies and their implications, or speak in generalities? |
| **Novel insight** | Does the conversation produce ideas you hadn't considered? |
| **Conflation resistance** | Does the LLM collapse distinct concepts, or maintain their separation? |
| **Structural reasoning** | Does the LLM reason about the argument's topology (what depends on what, what's load-bearing) or only about its content? |
| **Productive challenge** | When the LLM disagrees, does it target specific nodes and trace the cascade, or make vague objections? |

## What This Tests

### Primary question
Does DAG-structured context produce more insightful reasoning than prose context?

### Secondary questions
- Does the DAG guide the LLM to structurally important claims rather than rhetorically emphasized ones?
- Does the DAG reduce conflation (merging of distinct concepts)?
- Does the DAG enable the LLM to reason about the *topology* of the argument, not just its content?
- Does the DAG surface gaps and contradictions that the prose hides?

### What this does NOT test
- Statistical significance (N=1 per condition — this is qualitative)
- Generalization to other domains
- Whether the DAG format or the decomposition process is the active ingredient (see NEXT_EXPERIMENT.md in parent directory for the controlled version of that question)

## Implications If the DAG Produces Better Reasoning

### For context engineering
System prompts and CLAUDE.md files should be structured as assertion DAGs, not prose paragraphs. The decomposition process is itself valuable — it forces the author to identify atomic claims, make dependencies explicit, and discover which claims are load-bearing.

### For agent belief systems
Agent beliefs can be externalized as assertion files on disk — inspectable with `cat`, diffable with `diff`, auditable with `grep`. The assertion DAG is to beliefs what the execution trace is to actions: an inspectable artifact that terminates the trust chain.

### For "hallucination" (conflation)
Many LLM reasoning failures are not fabrication but conflation — collapsing distinct nodes into one. The assertion DAG prevents this by making nodes explicit. The intervention for conflation is structural decomposition, not fact-checking.

### For the Its Just Shell thesis itself
The DAG is built from the thesis's own primitives: files, text, composition, inspectability. The thesis tests itself with its own methodology. The recursive self-validation — using Unix primitives to structure knowledge that argues for Unix primitives — is either circular or foundational, depending on whether the test produces better reasoning.

## File Structure

```
its-just-shell-dag-reasoning-test/
  README.md                              # this file
  prose.md                               # thesis as prose (context for conversation A)
  dag/                                   # thesis as assertion DAG (context for conversation B)
    primitives/                          # 14 atomic assertions
      p01_llm_is_pure_function.md
      p02_unix_is_universal_substrate.md
      p03_files_are_state.md
      p04_text_streams_are_communication.md
      p05_exit_codes_are_verification.md
      p06_composition_beats_monoliths.md
      p07_mechanism_policy_separation.md
      p08_inspectability_before_execution.md
      p09_nl_verification_requires_llm.md
      p10_llms_trust_peer_agents.md
      p11_single_agents_outperform_multi.md
      p12_independent_convergence.md
      p13_ai_compresses_lower_order_work.md
      p14_abstractions_leak.md
    compounds_l2/                        # 7 composed claims (from primitives)
      c01_shell_is_sufficient.md         + c01_deps.json
      c02_two_control_models.md          + c02_deps.json
      c03_trust_gradient.md              + c03_deps.json
      c04_script_driven_security.md      + c04_deps.json
      c05_convergent_evolution.md        + c05_deps.json
      c06_derivative_stack.md            + c06_deps.json
      c07_frameworks_rebuild_unix.md     + c07_deps.json
    compounds_l3/                        # 3 architectural claims (from L2 compounds)
      c08_ground_floor_thesis.md         + c08_deps.json
      c09_control_as_spectrum.md         + c09_deps.json
      c10_composability_enables_scaling.md + c10_deps.json
    compounds_l4/                        # 1 top-level thesis (from L3 compounds)
      c11_its_just_shell.md              + c11_deps.json
    diagram.txt                          # full ASCII dependency graph + reuse matrix
    ANALYSIS.md                          # structural analysis findings
```

## The DAG Visualization

```
                            ┌─────────────────────┐
                            │  c11: ITS JUST SHELL │
                            │    (Layer 4)         │
                            └──────┬──────┬───────┘
                                   │      │       │
                    ┌──────────────┘      │       └──────────────┐
                    ▼                     ▼                      ▼
          ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
          │ c08: Ground     │  │ c09: Control as  │  │ c10: Composability   │
          │ Floor Thesis    │  │ Spectrum         │  │ Enables Scaling      │
          │   (Layer 3)     │  │   (Layer 3)      │  │   (Layer 3)          │
          └──┬─────┬─────┬──┘  └──┬─────┬─────┬──┘  └──┬──────┬──────┬────┘
             │     │     │        │     │     │        │      │      │
             ▼     ▼     ▼        ▼     ▼     ▼        ▼      ▼      ▼
           c01   c07   c05      c02   c03   c04      c06    c01    c02
            │     │     │        │     │     │        │
          Layer 2 compounds — each with deps.json pointing to primitives
            │     │     │        │     │     │        │
            ▼     ▼     ▼        ▼     ▼     ▼        ▼
    ┌───────────────────────────────────────────────────────────┐
    │  p01  p02  p03  p04  p05  p06  p07  p08  p09  p10  ...  │
    │                    Layer 1: Primitives                     │
    └───────────────────────────────────────────────────────────┘

    Weight distribution (compounds depending on each primitive):
    p06 ████████ 4    ← KEYSTONE: composition beats monoliths
    p01 ██████   3
    p02 ██████   3
    p04 ████     2
    p07 ████     2
    p08 ████     2
    p03 ██       1
    p05 ██       1
    p09 ██       1
    p10 ██       1
    p12 ██       1
    p13 ██       1
    p14 ██       1
    p11            0    ← ORPHANED: single > multi (no compound depends on it)
```
