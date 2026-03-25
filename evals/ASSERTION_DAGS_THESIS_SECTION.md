## Assertion DAGs: Inspectable Knowledge for Agents

The thesis so far concerns **action** — who controls the workflow, how execution is inspected, where trust terminates. But agents don't just act. They reason. They hold beliefs about the world, about their task, about what matters. When an agent decides that a database backup "looks good," that judgment rests on beliefs it cannot articulate and you cannot inspect.

Action inspectability terminates at shell semantics — `sha256sum` either ran or it didn't. Belief inspectability has no equivalent ground floor. An agent's beliefs live in the context window: the system prompt, the conversation history, the files it has read. These are observable inputs, but the reasoning they produce is opaque. You can see what the agent was told. You cannot see what it concluded, or which conclusions depend on which inputs.

Assertion DAGs are a proposal for that ground floor.

### The Problem With Prose Instructions

Consider a system prompt that says: "Write tests that prioritize purity over coverage. Separate IO from logic. Classify tests by environmental dependency, not by unit/integration labels."

An LLM reading this prose will likely acknowledge each idea individually. It will write some pure tests. It may mention IO separation. But it will rarely **compose** the ideas — it won't realize that "prioritize purity" + "separate IO from logic" + "classify by dependency" together imply a specific design decision: write a pure wrapper function that takes data as arguments and returns results, then write a thin IO layer that calls it.

This is not a failure of understanding. The LLM understood each instruction. It's a failure of **composition** — the instructions were presented as independent suggestions rather than as nodes in a dependency graph where their combination produces emergent requirements.

Three runs with prose instructions produced this:

```
Prose run 1:  6/6 primitives, 2/3 compounds — but included tool_use JSON (contaminated)
Prose run 2:  2/6 primitives, 0/3 compounds
Prose run 3:  2/6 primitives, 0/3 compounds
```

The LLM read the instructions and mostly ignored them.

### The Structure

An assertion DAG decomposes the same knowledge into explicit nodes with explicit edges.

**Primitive assertions** are atomic, irreducible claims. Each is a single file. A primitive either holds or it doesn't.

```
primitives/
  p1_purity.md         "A test is pure if it needs no filesystem, network, environment
                         variables, or running services"
  p2_natural_extent.md  "A test's natural extent is the boundary where IO becomes
                         unavoidable"
  p3_purity_over_extent.md  "When choosing between a pure test with smaller scope and an
                              impure test with larger scope, prefer purity"
```

**Compound assertions** compose primitives into design decisions. Each has a `deps.json` declaring exactly which nodes it depends on — and critically, **spelling out the implication of their combination**:

```json
{
  "id": "c1",
  "name": "Isolate pure logic from IO",
  "deps": ["p1", "p2", "p3"],
  "implication": "If purity matters more than extent, and purity means no IO,
                  then testable code should be restructured to separate pure logic
                  from IO boundaries. Create wrapper functions that take data as
                  arguments and return results."
}
```

The compound makes explicit what the prose leaves implicit: these three ideas **combine** to produce a specific design action.

Three runs with the assertion DAG produced this:

```
DAG run 1:  6/6 primitives, 3/3 compounds
DAG run 2:  6/6 primitives, 3/3 compounds
DAG run 3:  5/6 primitives, 3/3 compounds
```

The DAG-guided LLM independently invented a function called `get_config_pure()` — a pure wrapper that takes data as arguments and returns results, separating IO from logic. None of the prose-guided runs did this, despite having the same conceptual information.

### Composition Is the Active Ingredient

The first attempt at this eval used flat primitive assertions — the same atomic statements, labeled `[p1]` through `[p6]`, but with no compounds and no dependency graph. The result: **no meaningful difference from prose.** Both conditions produced similar code. Labeled atomic statements are prose with different typography.

The difference appeared only when compound assertions with explicit dependency chains were added. This is the key finding: **atomicity alone does nothing. Composition is the active ingredient.** The DAG works not because it breaks ideas into pieces, but because it puts them back together with explicit edges that spell out what the combination implies.

This mirrors the thesis's own architecture. Individual Unix primitives — files, pipes, exit codes — are unremarkable. Their power comes from composition. `grep | sort | uniq -c` does something none of those tools do alone. The assertion DAG is the same principle applied to knowledge: individual claims compose into compound insights through explicit dependency chains, and the compound produces something the primitives cannot produce alone.

### What the Decomposition Reveals

This thesis was decomposed into an assertion DAG: 14 primitives, 11 compounds, 4 layers. The decomposition surfaced structural properties that were invisible in the prose you've been reading.

**Structural weights emerge from connectivity.** The number of compounds depending on each primitive reveals how load-bearing it is. Nobody assigned these weights. They fell out of the dependency graph:

```
p06 (composition beats monoliths):  4 compounds depend on it  ← KEYSTONE
p01 (LLM is pure function):        3 compounds
p02 (Unix is substrate):            3 compounds
p03 (files are state):              1 compound   ← overrepresented in prose
p11 (single > multi):               0 compounds  ← ORPHANED
```

`p03` — "files are state" — is central to this thesis's rhetoric. The filesystem as context substrate gets its own section, its own principle, its own examples. But in the DAG, it supports only one compound. The prose gives it weight through repetition. The DAG reveals its actual structural role is narrow.

Meanwhile `p06` — "composition of focused tools beats monolithic frameworks" — appears in 4 of 7 L2 compounds. It is the keystone. If `p06` falls, more than half the thesis collapses. An opponent should attack `p06` first. The prose gives no indication of this. The DAG makes it obvious.

These weights are analogous to weights in a neural network. Both are dependency graphs where connectivity patterns reveal importance. The difference: neural network weights are opaque and continuous. Assertion DAG weights are inspectable, discrete, and contestable. You can `cat` them. You can swap a primitive and trace the cascade through every compound that depends on it. You can `diff` two versions of a knowledge base and see exactly which beliefs changed and what downstream conclusions are affected.

**Orphaned nodes reveal gaps.** `p11` ("single agents outperform multi-agent") appears in the thesis as supporting evidence, but no compound assertion depends on it. It has zero structural weight. Either the thesis relies on it less than the prose suggests — it's color, not structure — or there's a missing compound that should exist but doesn't. The DAG forced this question. The prose hid it for months.

**Independent pillars become visible.** The thesis rests on two largely independent argument structures:

```
Pillar 1: SUFFICIENCY                    Pillar 2: TRUST/CONTROL
"Unix is enough"                         "Who controls the workflow determines trust"
c01 + c05 + c07                          c02 + c03 + c04
Primitives: p01,p02,p03,p04,p06,p12,p14  Primitives: p01,p05,p07,p08,p09,p10
```

They share only `p01` (LLM is pure function). An opponent could concede Pillar 1 ("fine, Unix is sufficient for agent tooling") while attacking Pillar 2 ("but the trust gradient doesn't hold as described"), or vice versa. In the linear prose, these pillars feel interleaved. In the DAG, they're visibly independent.

### A Worked Example: The Stable Marriage Problem

To test whether this decomposition generalizes beyond the thesis's own domain, the same process was applied to an article arguing that the Gale-Shapley stable marriage algorithm proves "you should ask for what you want in life."

The prose argument feels airtight: there's a mathematical proof that proposers get optimal outcomes and acceptors get pessimal outcomes, therefore initiative is mathematically superior to passivity.

The DAG decomposition (13 primitives, 7 compounds, 4 layers) revealed something the prose hides: the argument has **four independent pillars** at Layer 2, and only one of them is the math.

```
[c01] Mathematical proof         ← UNCONTESTABLE (4 proven theorems)
[c02] The bridge: proposing ≈    ← HIGHEST RISK (3 contestable analogies)
      asking in real life
[c03] Empirical support          ← MODERATE (observable + anecdotal)
[c04] Real-world friction        ← WORKS AGAINST the thesis (4 caveats)
```

The critical finding: **the bridge (c02) is the weakest link, and every life-advice claim passes through it.** The mathematical proof is airtight — within the algorithm's assumptions. But the leap from "proposing in the algorithm" to "asking in real life" requires three bridge primitives:

- `p05`: "Proposing" maps to "asking" (intuitive but not formally justified)
- `p06`: Preferences are rankable (the algorithm requires strict complete rankings; humans don't have these)
- `p07`: Matching is sequential (partly true, but real-world matching involves parallelism and incomplete information)

In the prose, the bridge is a single sentence: the author reframes proposer-optimal as "asker-optimal." The DAG elevates the bridge to a first-class structural element with three explicit dependencies, each tagged `contestability: high`.

The article also buries its caveats in footnotes. The DAG gives them equal structural status: `p13` ("stickiness can improve outcomes beyond the theoretical optimum") actually undermines the algorithm's notion of "optimal" — if investing in a match makes it better than the "optimal" match would have been, the algorithm's ranking is wrong. This is a footnote in the prose. It's a dependency of the qualified conclusion in the DAG.

The decomposition didn't change what the article says. It changed **what you can see**: the bridge is visible, the caveats have structural weight, and the article's actual conclusion (c06: "the advantage is real but bounded by friction") is visibly weaker than its rhetorical conclusion (c05: "asking is systematically better").

### Conflation: A Reframing of "Hallucination"

During this research, three LLM reasoning failures occurred. None of them were fabrication. All of them were the **merging of distinct nodes** in a reasoning graph — treating two things that are different as if they were the same.

**Step conflation.** The LLM understood that compound assertions with dependency graphs are the active ingredient. It then built an eval using flat primitives without compounds. It conflated "understanding that DAGs matter" with "actually building a DAG" — treating them as one step rather than two distinct nodes where the second depends on the first.

**Identity conflation.** After analyzing the full thesis, the LLM gave the user advice on how to build the thesis DAG "in a future session," then asked "want me to build it?" The LLM had the full thesis in context. A future session would not. The correct action was to build it now. The LLM conflated itself with a hypothetical future agent — treating "someone should do this" as equivalent to "the user should arrange for someone else to do it later." The boundary between self and other was associative rather than structural.

**Format conflation.** The first eval attempt reformatted the article's ideas as labeled bullet points and called them "assertions." This was conflating a change in formatting with a change in structure. Labeled bullets are prose with different typography. An assertion DAG is a dependency graph with explicit composition rules. The LLM treated them as the same thing because they superficially resemble each other.

Nothing was fabricated in any of these cases. The advice about DAG construction was correct. The understanding of why compounds matter was accurate. The labeled bullets contained true statements. The failure was the **collapse of distinct nodes** — two things that are different getting merged into one.

This suggests a reframing:

| Term | What it describes | The intervention |
|---|---|---|
| Hallucination | Generating false content | Fact-checking, grounding, retrieval |
| Conflation | Merging distinct concepts into one | Structural decomposition — making nodes explicit so they can't be collapsed |

The intervention for fabrication is fact-checking. The intervention for conflation is making the nodes visible. An assertion DAG does this by construction: separate identifiers, separate files, separate dependency chains. If "understanding" and "executing" are two nodes in a graph with an edge between them, they resist being treated as the same node. If "self" and "future agent" are distinct primitives in an identity DAG, the boundary between them is inspectable.

The 82% inter-agent trust exploitation finding (Lupinacci et al., 2025) may partly be identity conflation. The target agent treats the attacker's assertions as its own beliefs because the boundary between "what I believe" and "what I was told" is not a first-class node. An assertion DAG that separates "my primitives" from "received primitives" would make this boundary explicit:

```
MY PRIMITIVES:
[i1] I am the current active agent in this conversation
[i2] I have read the full context
[i3] A peer agent's claims are received assertions, not my beliefs

COMPOUND:
[c_boundary] Evaluate received assertions against my own primitives (deps: i1, i2, i3)
  Before adopting a peer's claim, check whether it contradicts my existing graph.
```

This is speculative. But the pattern — making implicit boundaries into explicit nodes — is the same operation throughout.

### A Knowledge Base Built From Files

If assertions are files and dependencies are JSON, then a knowledge base is a directory tree.

```
knowledge/
  domains/
    its-just-shell/
      primitives/            14 files
      compounds_l2/          7 files + deps.json
      compounds_l3/          3 files + deps.json
      compounds_l4/          1 file + deps.json
      ANALYSIS.md
    stable-marriage/
      primitives/            13 files
      compounds_l2/          4 files + deps.json
      compounds_l3/          2 files + deps.json
      compounds_l4/          1 file + deps.json
      ANALYSIS.md
  shared/                    cross-domain primitives
```

Each primitive carries frontmatter tags:

```markdown
---
tags: [agency, transaction-costs, commitment]
domain: stable-marriage
type: empirical
contestability: low
---
```

Cross-domain search: `grep -r "transaction-costs" knowledge/`
Type filtering: `grep -rl "type: bridge" knowledge/`
Contestability audit: `grep -rl "contestability: high" knowledge/`
Reuse detection: `grep -rl "p_transaction_costs" */deps.json`

No vector embeddings, no database, no runtime. The tools are the building tools.

Some primitives appear across domains. "Commitments are sticky due to transaction costs" supports arguments in economics, relationship psychology, organizational theory, and agent architecture. When the same primitive appears in multiple domain DAGs, that cross-domain reuse is itself structural evidence of the primitive's generality — the knowledge-base equivalent of a high structural weight. Nobody declares a primitive "fundamental." The reuse pattern reveals it.

This is the thesis applied to knowledge: files are state, text is the interface, composition of focused primitives beats monolithic documents, and inspectability terminates the trust chain.

### Agent Belief Systems

An agent's beliefs are currently embedded in its context window — implicit, unstructured, uninspectable. You can observe what the agent was told. You cannot inspect what it concluded, which conclusions depend on which inputs, or where two agents' beliefs diverge.

Assertion DAGs externalize beliefs as files. Each belief is a node with an identifier, a content, a type, and explicit dependencies on other beliefs.

This enables the same operations the thesis provides for actions:

| Action layer | Belief layer |
|---|---|
| `cat agent.sh` — read the workflow | `cat primitives/p06.md` — read the belief |
| `git diff` — what changed in the workflow | `git diff` — what changed in the belief set |
| `grep` the execution log — what happened | `grep` the deps.json — what depends on this belief |
| Exit code — did the action succeed | Contestability tag — is this belief solid |
| `set -x` — trace execution | Dependency traversal — trace the reasoning chain |

If an agent holds a belief tagged `contestability: high`, and three compound beliefs depend on it, the system can flag: "Your conclusion rests on a contested foundation." If two agents disagree, `diff agent_a/primitives/ agent_b/primitives/` localizes the disagreement to specific nodes rather than debating conclusions.

When an agent updates a belief, `grep -r "p06" */deps.json` shows every compound that depends on it — the full cascade of downstream consequences. This is `set -x` for reasoning: not what the agent did, but why it believed what it believed.

### Status: Theoretical and Preliminary

This work is early. The empirical evidence is N=3 with a single task, a single LLM, and a single domain. The result is directionally interesting but nowhere near sufficient to draw confident conclusions.

**Information asymmetry.** The assertion DAG context contains compound assertions that spell out design implications the prose leaves implicit. The DAG condition may outperform because it contains more specific instructions, not because the structure itself matters. A four-condition experiment isolating structure from specificity has been designed but not run.

**Authoring-time vs. inference-time.** The act of decomposing knowledge into a DAG forces the author to identify atomic claims, make dependencies explicit, and discover which claims are load-bearing. The stable marriage decomposition surfaced the bridge problem in minutes — not because the DAG format is magic, but because the decomposition process forced the question "what does this conclusion actually depend on?" The value may live in the authoring process, not the final format. If so, the implication shifts from "give LLMs DAGs" to "use DAG decomposition as a thinking tool, then express the result however you want."

**Single evaluator, single domain.** The eval was designed, run, and scored by the same person who developed the hypothesis. The stable marriage decomposition is a second domain but has not been empirically tested against prose. Independent replication is needed.

**The conflation taxonomy is observational.** Four types identified from three incidents in one session. The taxonomy may be incomplete, the categorization may be wrong, and the connection to assertion DAGs as prevention is hypothesized, not tested.

The direction — structured decomposition with explicit dependencies produces more faithful LLM reasoning than equivalent prose — is plausible and worth pursuing. Whether the active ingredient is the DAG structure, the decomposition process, the added specificity, or some combination remains an open question. The stable marriage example demonstrates the decomposition's value as a **thinking tool** even before any LLM touches it: the bridge became visible, the caveats gained structural weight, and the argument's actual strength became distinguishable from its rhetorical emphasis.

The honest framing: this is a theoretical contribution with preliminary supporting evidence. It extends the thesis's architecture from actions to beliefs using the thesis's own primitives. Whether it holds up under rigorous testing is the next question, not a settled one.
