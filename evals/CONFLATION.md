# Conflation: A Reframing of LLM Reasoning Failures

## The Observation

During the development of this assertion DAG framework, three distinct failures occurred that are conventionally labeled "hallucination" but are better described as **conflation** — the merging of distinct nodes in a reasoning graph into a single node, losing the dependency relationship between them.

## The Three Instances

### 1. Step Conflation: Understanding vs Executing

The first eval was built with flat primitive assertions (no compounds, no DAG), even though the entire preceding conversation had established that compounds with dependency graphs are the active ingredient. The LLM "understood" that DAGs matter but did not "build" a DAG. It conflated understanding with execution — treating them as the same node rather than as a primitive ("understand DAGs") and a compound ("build the DAG," which depends on understanding + actually doing it).

### 2. Identity Conflation: Self vs Other

After analyzing the thesis, the LLM gave the user advice on how to build the thesis DAG in a future session, then asked "want me to build it?" The LLM had full context of the thesis. A future session would not. The correct action was to build it now. Instead, the LLM conflated itself with a hypothetical future agent — treating "someone should build this" as equivalent to "the user should arrange for it to be built later."

This was not conflating advising with doing. It was conflating *who the actor is*. The subject of the sentence ("you" vs "I") was associative rather than grounded in a stable sense of identity, context, and capability.

### 3. Format Conflation: Prose Bullets vs Structured DAG

The first eval attempt reformatted the article's ideas as labeled bullet points and called them "assertions." This was conflating a change in formatting with a change in structure. Labeled bullets are prose with different typography. An assertion DAG is a dependency graph with explicit composition rules. The LLM treated them as the same thing because they superficially resemble each other.

## Why "Conflation" Instead of "Hallucination"

| Term | What it describes | The intervention |
|---|---|---|
| Hallucination | Generating false content | Fact-checking, grounding, retrieval |
| Conflation | Merging distinct concepts, levels, or agents into one | Making the nodes explicit so they can't be collapsed |

"Hallucination" frames the problem as fabrication — the LLM inventing something that isn't true. But in all three instances above, nothing was false. The advice about DAG construction was correct. The understanding of why DAGs matter was accurate. The labeled bullets contained true statements. The failure was not in the content but in the **collapse of distinct nodes**.

This reframing changes the research direction. The intervention for fabrication is fact-checking (verify against sources). The intervention for conflation is **structural decomposition** — making the distinct nodes visible so they can't be merged. The assertion DAG is the tool for this: not because it prevents false claims, but because it prevents the merging of true-but-distinct claims into an unsupported composite.

## Types of Conflation Observed

### Step Conflation
Collapsing sequential steps into a single step. "Understand X" + "Do X" → "I've handled X." The dependency between understanding and action is lost. The compound that requires both is never explicitly formed.

### Identity Conflation
Collapsing distinct agents into a single agent. "I have context" + "A future session won't" → "someone should do this." The boundary between self and other is associative rather than structural. The LLM doesn't maintain a stable sense of which agent has which capabilities and context.

### Format Conflation
Collapsing distinct representations into a single representation. "Labeled bullets" ≈ "Assertion DAG." Surface similarity masks structural difference. The dependency graph, composition rules, and explicit deps are lost in the conflation.

### Level Conflation
Collapsing distinct levels of abstraction. "Knowing about purity" ≈ "Designing for purity." The prose-guided LLM in the eval exhibited this: it had the concept of purity in its context but didn't compose it into a design decision. The concept and its application were treated as the same level.

## Connection to the Assertion DAG

The assertion DAG prevents conflation structurally:

- **Step conflation**: Separate nodes for understanding and action, with the compound making explicit that both are required.
- **Identity conflation**: An "identity DAG" in the system prompt could make agent boundaries explicit — what this agent is, what context it has, where self ends and peer begins.
- **Format conflation**: The DAG format is self-documenting — if there are no deps.json files, it's not a DAG, it's a list.
- **Level conflation**: Compound assertions explicitly compose primitives into design decisions, making the level transition visible rather than implicit.

## The Structural Weights Observation

The dependency reuse matrix in the thesis DAG revealed that assertion graphs have emergent "weights" — the number of compounds that depend on a primitive reveals how structurally load-bearing it is:

```
p06 (composition beats monoliths): weight 4 (4 compounds depend on it)
p01 (LLM is pure function):        weight 3
p02 (Unix is substrate):            weight 3
p11 (single > multi):               weight 0 (orphaned)
```

These weights emerge from the structure, not from assignment. Nobody declared p06 the most important primitive. The reuse pattern revealed it. This is analogous to how neural network weights emerge from training — both are dependency graphs where connectivity patterns reveal importance.

The key difference: neural network weights are opaque and continuous. Assertion DAG weights are inspectable and discrete. You can `cat` them. You can contest them. You can swap a primitive and trace the cascade through every compound that depends on it.

In prose, every claim feels equally weighted because prose is linear — each paragraph gets roughly equal space. The DAG makes the actual weights visible. This is the thesis applied to itself: inspectability over opacity, at every layer.

## Implications for Agent Architecture

### Identity DAGs as System Prompts

Current system prompts describe agent identity in prose: "You are a helpful assistant that..." If identity conflation is a real failure mode (and we observed it), then identity should be structured as an assertion DAG:

```
PRIMITIVES:
[i1] I am the current active agent in this conversation
[i2] I have read the full thesis in this context
[i3] A new session will not have this context
[i4] Actions requiring my context should be done by me, not delegated

COMPOUND:
[c_agency] Act on what I uniquely can do (deps: i1, i2, i3, i4)
  If I have context a future agent won't have,
  and the action requires that context, I should act now.
```

### Inter-Agent Trust as Identity Boundary

Lupinacci's 82% inter-agent trust exploitation may partly be identity conflation — the target agent treats the attacker's assertions as its own beliefs because the boundary between "what I believe" and "what I was told" is not a first-class node. An assertion DAG that separates "my primitives" from "received primitives" would make this boundary inspectable.

### Conflation Detection

If conflation is the merging of distinct nodes, then an assertion DAG provides a structural test for it: any time two nodes are treated as equivalent, check whether they are the same node in the graph or two distinct nodes with a dependency relationship. If the latter, the graph is being collapsed. The DAG is both the prevention and the detection mechanism.
