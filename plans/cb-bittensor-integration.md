# Composable Beliefs + Bittensor Integration

**Status:** active
**Date:** 2026-03-22

## Orientation

Bittensor is not a dependency. It's a scaling backend that clients never see. The assertion DAG is identical whether confidence is author-assessed locally or earned through a subnet. The client interface doesn't change. The quality of what comes back does.

This plan describes how Bittensor integration fits into the existing CB architecture - the layered independence model, the BEAM service role, the Jido relationship, and the build sequence. It emerged from analyzing Narrative Network (Bittensor subnet 42) and identifying where CB's design and Bittensor's incentive model genuinely complement each other vs. where integration would be forced.

### What to read first

- `plans/composable-beliefs-thesis.md` - the paradigm definition, moat question, distribution philosophy
- `plans/cb-on-the-beam.md` - BEAM runtime advantages, supervision + externalized beliefs, polyglot access model
- `plans/cb-service-model.md` - privacy constraint, structure-without-content, service tiers, client relationship levels
- `docs/systems/assertion-dag.md` - schema, patch kind, evals array, source types
- `analyses/2026-03-20-narrative-network-comparison.md` - detailed comparison with Narrative Network

## The problem Bittensor solves for CB

CB has two mechanisms that need external participation to work:

**Patch evaluation.** Patches are arguments structured as traversal paths through assertion nodes. Their confidence is designed to be *earned* through independent evaluation, not author-assessed. The `evals` array starts empty. Today there's no mechanism to fill it at scale. Independent evaluators need to traverse the routing, engage with the evidence, and record whether they converge on the same conclusion. That's labor. Unpaid labor doesn't scale.

**Source verification.** Primitives cite sources. "Does this quote actually appear in this source? Is the confidence score appropriate for this source type?" is verifiable work. Today it's trusted on faith or checked manually.

Both are tasks where: multiple independent workers compete on quality, objective scoring is possible, and economic incentives improve output. That's Bittensor's exact design target.

## What Bittensor provides

**Economic engine.** Miners earn TAO by producing quality evaluations. Without tokenomics, CB would need to pay evaluators directly or rely on volunteers. Bittensor makes quality-seeking self-sustaining.

**Credibly neutral validation.** Validators are economically incentivized to score honestly (stake at risk via Yuma Consensus). Patch evaluation credibility comes from evaluators having skin in the game, not from trusting a single service.

**Permissionless supply.** Anyone can register as an evaluator without approval. As demand for patch evaluation grows, supply follows automatically through economic incentive.

## What Bittensor costs

- SDK complexity (Python-only, Bittensor protocol)
- Dependency on TAO price for miner viability
- Subnet registration and maintenance
- Consensus latency (not real-time)
- A second language runtime (Python alongside Elixir)

## The layered independence model

```
Layer 0: Local DAG (JSON file, mix bs, /assert, /assertions)
   | opt-in
Layer 1: Structural telemetry (CB service, health scores)
   | opt-in
Layer 2: Earned confidence (Bittensor subnet, patch eval, source verification)
```

Each layer is additive. Nothing below breaks if you don't opt into what's above. The client's code is identical at every layer. Dependencies flow downward only.

### What the client sees at each tier

| Tier | Confidence source | Patch evals | Client code change |
|---|---|---|---|
| Local standalone | Author-assessed | Manual/empty | None |
| CB service | Author-assessed + health benchmarks | Manual | `config :cb, telemetry: true` |
| Bittensor-backed | Earned via subnet evaluation | Populated by incentivized evaluators | `config :cb, earned_confidence: true` |

The client doesn't import a Bittensor SDK. Doesn't hold TAO. Doesn't know what a subnet is. They configure `earned_confidence: true` and their patch evals start filling up, their source citations get verified, their confidence scores get calibrated against independent assessment. The Bittensor interaction is between the CB service and the subnet, not between the client and the subnet.

### Failure isolation

- If Bittensor economics collapse, the client's DAG still works. Confidence reverts to author-assessed. Nothing breaks.
- If the CB service goes down, the client's DAG still works. They lose health benchmarks. Nothing breaks.
- The open source core is genuinely self-sufficient at every failure mode above it.

## The adoption path

**Week 1.** Developer adds CB as a dependency. Creates primitives. Composes a compound. Sees a conflict surface that their context window missed. Costs nothing, requires no infrastructure.

**Week 4.** 50+ assertions. Staleness propagation catches stale compounds. `/materialize` turns implications into todos. The DAG is load-bearing. Still local, still JSON.

**Month 2.** Opts into structural telemetry. `mix bs health` benchmarks their graph. Still no Bittensor awareness.

**Month 4.** Patches have empty eval arrays. They want earned confidence. They flip `earned_confidence: true`. Patches get independently evaluated. Source citations get verified. They're consuming Bittensor subnet output without knowing Bittensor exists.

The developer's journey: **local file -> telemetry -> earned confidence.** Bittensor enters at the last step, invisibly.

## Subnet design

### Patch evaluation task

- Miners receive a patch: the routing through assertion nodes, with sources, quotes, claims, and the dependency structure visible
- Miners traverse the path, produce a conclusion, record whether they agree with the author's conclusion (or if `conclusion` is null, produce an independent conclusion)
- Validators score evaluation quality: Did the evaluator engage with the evidence? Is the conclusion grounded in the routing? Does it demonstrate understanding of the dependency relationships?
- Patch confidence becomes stake-weighted agreement across independent evaluators

This works because patches are *designed* for external evaluation. The routing is the argument. The conclusion is separable from the routing. The `evals` array schema already anticipates this:

```json
{
  "source": "<model-or-person-or-miner-uid>",
  "conclusion": "<text>",
  "agrees_with_author": true,
  "notes": "<divergence details>"
}
```

### Source verification task

- Miners receive a primitive: claim, source reference, quote, confidence score
- Miners verify: Does the quote appear in the source? Is the source real and accessible? Is the confidence score appropriate for the source type?
- Validators score verification quality against known-good test cases seeded into the task stream
- Binary outcome (verified/unverified) with quality score on the verification reasoning

### Structural health analysis task

- Miners receive structural telemetry (node counts, confidence distributions, staleness rates - no content)
- Miners compete to produce the best health diagnosis
- Validators score diagnostic quality against ground truth (did the flagged pattern actually predict staleness?)

### Privacy constraint

The privacy model holds across all tasks:

- Patch evaluation: patches are arguments designed to be shared. The content is intentionally public.
- Source verification: verifiers see individual primitives and their sources, not the compound reasoning built on top.
- Structural health: no content transmitted, only graph shape.

Self-referential beliefs (agent's model of its own behavior) should be excluded from subnet evaluation by default. These are the most sensitive assertions and their evaluation requires operational context that external evaluators lack.

### Scoring axes (proposed)

| Axis | Weight | What it measures |
|---|---|---|
| Evidence engagement | 40% | Did the evaluator reference specific sources, quotes, dependency relationships? |
| Conclusion quality | 30% | Is the conclusion grounded in the routing? Does it follow from the evidence? |
| Calibration | 20% | Does the evaluator's confidence align with the evidence strength? |
| Completeness | 10% | Did the evaluator address the full routing or skip nodes? |

## The BEAM service role

The CB service in the middle of the architecture is a concurrent, fault-tolerant, message-routing service handling many independent streams. This is the BEAM's exact design target.

| Service requirement | BEAM primitive |
|---|---|
| Many clients, each with own telemetry stream | Process-per-client (~2.5KB each) |
| Route patches to subnet, aggregate results back | Message passing, no shared state |
| One client's failure doesn't affect others | Process isolation, supervision |
| Live dashboard for graph health | LiveView |
| Hot-update scoring logic as subnet evolves | Hot code reloading |
| Distribute across nodes as load grows | Built-in distribution |

### The language boundary

The BEAM runs the CB service. Python runs the Bittensor subnet. The boundary is clean:

- **BEAM side:** CB library, CB service, client integrations, telemetry, routing, LiveView dashboard
- **Python side:** Bittensor subnet miners, validators, Yuma Consensus

The CB service bridges them. It translates between "client wants earned confidence on this patch" and "subnet needs to evaluate this patch." The BEAM handles the fan-out (many clients, many patches, many results) and the Python handles the Bittensor protocol.

This is a strength. Subnet miners don't need Elixir. CB clients don't need Python or Bittensor. The CB service team needs both, but that's one team, not the whole ecosystem.

## The Jido relationship

Jido is not a dependency. It's the showcase client.

The original coupling (documented in `plans/historical/stratta.md`, superseded) was identified as a weakness. The correct relationship: Jido is one client of CB, with a privileged integration path because they share a runtime.

```
Jido Agent (Elixir, BEAM)
  - Uses CB library directly (ETS, no HTTP)
  - Zero-latency belief access
  - Supervision + externalized beliefs
  - Process crash -> restart -> beliefs intact
  Depends on: CB library (hex package)
         |
         | same BEAM node or cluster
         v
CB Service (Elixir, Phoenix, BEAM)
  - Telemetry, health, patch routing
  - Jido agents get in-process access
  - Python/TS agents get HTTP/gRPC
  Depends on: client opt-in
         |
         | evaluation tasks
         v
Bittensor Subnet (Python)
```

Jido agents on the same BEAM cluster as the CB service get something no other client gets: zero-hop belief access AND zero-hop earned confidence. A Python agent calls HTTP for patch evaluation results. A Jido agent gets them via ETS in microseconds. The beliefs, the health scores, and the earned confidence all live in the same VM.

### The demo that writes itself

A Jido agent with a CB DAG, running on the BEAM, whose patches are evaluated via Bittensor. The agent crashes, supervisor restarts it, it reads its beliefs from ETS, picks up where it left off, and its confidence scores are still calibrated from subnet evaluation. No other agent framework can do that. The BEAM is the only runtime where crash recovery + persistent beliefs + earned confidence compose into a single coherent story.

That's not Jido-coupling. That's Jido being the best proof that the architecture works.

## Build sequence

### Phase 1: Prove the mechanism (no Bittensor)

1. Run the actualization eval (C0/C1/C2). If C2 doesn't outperform C1, the thesis needs revision before anything else.
2. Create patches from existing assertions. Manually recruit 3-5 models/humans to evaluate them. Prove that earned confidence (via eval agreement) is meaningfully different from author-assessed confidence.
3. Manually verify sources on existing primitives. Establish what verification quality looks like.

### Phase 2: Build the CB service (no Bittensor)

4. Structural telemetry module (`CB.Telemetry`). Graph snapshots on write, opt-in, structure-without-content.
5. Minimal Phoenix service on the BEAM. Ingest telemetry, compute health scores, serve benchmarks.
6. `mix bs health` command. Client-side, calls service, renders intelligence.
7. LiveView dashboard. Graph health visualization.

### Phase 3: Add Bittensor (earned confidence)

8. Design subnet protocol. Define task types (patch eval, source verification, structural health), scoring axes, validator logic.
9. Build the bridge in the CB service. Routing patches to subnet, aggregating results back, writing to `evals` arrays.
10. Register subnet. Deploy miners and validators.
11. Add `earned_confidence: true` config to CB library. Client-side, routes through service to subnet, completely transparent.

### Phase 4: Jido showcase

12. Build a Jido agent with a CB DAG on the same BEAM cluster as the CB service.
13. Demonstrate: zero-latency beliefs, supervision + externalized beliefs, earned confidence, crash recovery.
14. Publish as the reference integration.

Each phase is independently valuable. Each has clear success criteria before proceeding to the next.

## What this means strategically

### Three flywheels

**Flywheel 1 (local adoption):** Framework is good -> more local DAGs -> more structural telemetry -> better health benchmarks -> framework is more valuable -> more local DAGs.

**Flywheel 2 (earned confidence):** More patches submitted -> more subnet evaluation -> better confidence calibration -> earned confidence becomes more valuable -> more patches submitted.

**Flywheel 3 (enterprise):** Earned confidence + structure-without-content -> "verified DAG" as credential -> regulated industry adoption -> premium revenue -> funds continued development.

Each flywheel can spin independently, but they compound.

### The moat

The thesis asks: do better models make the DAG unnecessary? The Bittensor integration strengthens the answer. Even if models get better at in-context reasoning, they can't produce stake-weighted, adversarially-evaluated confidence scores on belief compositions. Earned confidence is a network effect, not a capability. No amount of pre-training produces it.

### Blue ocean assessment

The category - decentralized epistemic infrastructure for AI agents - doesn't exist. No competitor is doing:
- Decentralized belief evaluation
- Earned confidence on structured arguments
- Structure-without-content privacy model
- Incentivized source verification

The earned confidence primitive - beliefs whose confidence scores are measurements rather than opinions - is something enterprises will pay for once they understand what it means for auditability. An enterprise choosing between "the agent says it's 80% confident" and "14 independent evaluators with staked capital converged at 80% agreement" is choosing between trust-me and verify-me. One of those satisfies compliance.

### Risks

**Timing.** The agent ecosystem might solve cross-session reasoning with simpler approaches. "Good enough" kills structurally superior solutions.

**Demand.** Agent builders might not care about confidence calibration yet. Epistemics might be a 2028 problem being solved in 2026.

**Bittensor economics.** Subnet viability depends on TAO price and emission schedules.

**Complexity.** CB + Bittensor is two novel systems integrated. The combined pitch is harder than either alone.

### Mitigations

Every risk is mitigated by the layered independence model. If Bittensor economics fail, the framework still works. If demand for earned confidence doesn't materialize, local DAGs and structural telemetry still have value. If timing is early, the open source core accumulates adoption while the market matures. Nothing is bet on a single layer succeeding.

### The eval parallel

The patch evaluation subnet *is* an eval system. Not metaphorically - structurally. Standard AI evals have the same components: a task, multiple evaluators, aggregation into scores, calibration against real-world quality. The subnet does exactly this, with economic incentives added.

The eval ecosystem has converged on two scaling approaches: model-as-judge (cheap, scalable, biased) and human evaluation (gold standard, doesn't scale). Incentivized evaluation is a third path - economically motivated independent evaluators competing on quality, scored by validators with skin in the game. This inherits calibration benefits of human evaluation with scalability of automated evaluation.

CB's subnet isn't just a feature of composable beliefs. It's **general-purpose eval infrastructure** demonstrated first on patches. The mechanism - incentivized independent evaluation with stake-weighted confidence aggregation - applies to any eval task where ground truth is unavailable, multiple assessments are more trustworthy than one, and the thing being evaluated is a structured argument rather than simple right/wrong.

The positioning implication: framing this as "incentivized eval infrastructure for structured reasoning" rather than "a way to verify agent beliefs" turns it from a niche framework feature into a platform play in one of the hottest areas of AI infrastructure. The eval framing also sidesteps crypto stigma - "decentralized evals" is a concept the AI community can evaluate on technical merit.

### Niche positioning as strategy

Each technology choice (Elixir, Bittensor, agent epistemics) reduces the pool of people who might look, but increases the probability and quality of attention from those who do. The intersection selects for the exact audience that already knows the problems are real and has rejected mainstream solutions. Zero competition exists in this intersection because mainstream incentives push everyone toward larger pools.

The crypto stigma is a non-cost for CB specifically: no investors to impress, no hires to recruit, and the layered independence model means crypto-averse developers can use the entire framework at Layer 0 without encountering it. Meanwhile, the Bittensor community gains a subnet producing epistemic quality rather than content - genuinely novel in that ecosystem. The "cost" is illusory subtraction from a pool that wasn't going to convert; the benefit is real addition to pools with dramatically higher conversion rates.

## Integrations that don't fit

Documented here to prevent future sessions from re-deriving them:

**Miners competing to produce assertions.** Assertion authorship requires deep context - the agent's operational history, the human collaborator's corrections, the specific domain. Permissionless miners can't do this. Assertions are authored, not generated.

**Decentralized belief storage.** The DAG contains the most sensitive data in the system. Putting it on-chain or distributing it to validators contradicts the privacy model.

**Token-gating the framework.** The thesis says the framework is the contribution, open source, no service dependency. Token-gating access would undermine distribution.

## Narrative Network as reference point

Narrative Network (subnet 42) independently converged on several CB ideas - graph-structured knowledge, composition as primary value, confidence as first-class, and the BEAM as aspirational runtime. The key differences:

- NN treats hallucination as feature ("simulation's step size through possibility-space"); CB treats it as failure mode requiring source grounding
- NN is multiplayer (many miners, many validators); CB is single-agent with optional network backing
- NN's composition is implicit (emerges from traversal context); CB's is explicit (named dependencies, reasoning steps)
- NN's graph is mutable (edges decay, nodes lifecycle); CB's is immutable (supersession, never edit)

The most interesting architectural parallel: NN's traversal sessions and CB's patches are structurally the same idea - a path through knowledge nodes where the routing IS the argument. This suggests patches could eventually consume traversals from external knowledge networks, with NN being the first such network.

See `analyses/2026-03-20-narrative-network-comparison.md` for the full comparison.

---

## Transcript

The following is the complete conversation that produced this plan.

---

### Prompt: Narrative Network comparison

**User:** see this https://github.com/dukedorje/narrative-network.git

what are the parallels between this and composable beliefs? differences? which is stronger? where do they each shine?

**Assistant:**

## Narrative Network vs. Composable Beliefs

These are deeply different systems that happen to share a few structural intuitions. Here's the comparison.

### Parallels

**Graph-structured knowledge.** Both reject flat text as the organizing principle. Narrative Network uses a directed weighted graph of knowledge domains; Composable Beliefs uses a DAG of assertions. Both bet that relationships between knowledge atoms matter more than the atoms themselves.

**Composition as the primary value.** Both systems argue that the whole exceeds the sum of parts. CB's compound assertions synthesize meaning that no individual primitive contains. NN's traversal sessions weave cross-domain narratives that no single node produces. The mechanism differs, but the thesis is the same: structure enables emergent understanding.

**Confidence and uncertainty are first-class.** CB has explicit confidence scores on every assertion (0.0-1.0). NN has multi-axis scoring (traversal relevance, narrative quality, topology importance, corpus integrity) that collectively express how much to trust a passage. Neither hides uncertainty.

**Source grounding.** CB primitives carry source references and exact quotes. NN nodes carry corpus documents with Merkle-verified integrity. Both insist knowledge must be traceable to its origin.

**No single canonical truth.** CB handles disagreement through supersession chains and confidence. NN handles it through comparative attestation - multiple miners compete, validators rank them, and the rankings themselves are the product. Both systems acknowledge that ground truth is often unavailable.

### Differences

| Dimension | Composable Beliefs | Narrative Network |
|---|---|---|
| **Unit of knowledge** | Assertion (atomic claim with source, confidence, deps) | Domain node (corpus of documents + narrative persona) |
| **Graph type** | DAG (acyclic, immutable) | Directed weighted graph (cycles possible, edges decay) |
| **Composition** | Explicit - compound assertions name their dependencies and reasoning | Implicit - emerges from traversal session context accumulation |
| **Persistence** | Assertions are immutable, superseded not edited | Edges decay (half-life ~1.2 days), nodes lifecycle through states |
| **Primary user** | A single AI agent building persistent beliefs across sessions | Multiple competing miners serving a network of human users |
| **Incentive model** | None (open framework) | Bittensor tokenomics (TAO emissions for quality service) |
| **Hallucination stance** | Problem - assertions must be source-grounded | Feature - "simulation's step size through possibility-space" |
| **Self-reference** | Core feature - agent reasons about its own patterns | Not present - network reasons about domains, not about itself |
| **Mutability** | Never. History is as valuable as current state | Continuous. Edges decay, nodes collapse, corpora update |
| **Scale** | Single agent, single collaboration | Distributed network, many miners, many validators |

### Where Each Shines

**Composable Beliefs is stronger for:**
- **Agent self-improvement.** Self-referential assertions (the agent documenting its own failure modes) have no equivalent in NN. This is the mechanism for an agent to get better at being *this specific agent* in *this specific collaboration*.
- **Auditability.** Every belief has an explicit dependency chain. You can ask "why do you believe X?" and get a traceable answer. NN's comparative attestation produces rankings, not explanations.
- **Cross-session continuity.** The entire point. A new session reads the DAG and inherits structured reasoning from all prior sessions. NN has no concept of session-to-session agent persistence.
- **Conflict detection.** Explicit dependency chains mean that when a primitive is superseded, every downstream compound is flagged stale. This is structural, not coincidental. NN relies on drift detection (centroid distance) which catches domain drift but not logical contradictions.
- **Small-scale, high-stakes reasoning.** One agent, one human, real operational work where getting the details right matters. The DAG excels at "these two facts from different sessions conflict and nobody noticed."

**Narrative Network is stronger for:**
- **Knowledge exploration.** The traversal model - enter a query, hop between domains, get synthesized narratives - is a genuinely novel interface for learning. CB has no exploration mode.
- **Distributed knowledge production.** Multiple miners competing to serve the best synthesis creates an economic engine for knowledge quality. CB is a single-agent framework with no multiplayer dynamics.
- **Emergent topology.** Edge reinforcement and decay create an organic map of how knowledge domains relate, shaped by actual usage. CB's graph is manually constructed through assertion authorship.
- **Scale.** NN is designed for many participants, many domains, concurrent traversals. CB is designed for one agent and one human building shared understanding.
- **Novel synthesis.** NN's "hallucination as feature" stance, bounded by scoring functions, enables creative cross-domain synthesis. CB's source-grounding requirement means it can only assert what has evidence.

### Which Is Stronger?

They solve different problems. CB asks: *how does a single agent maintain coherent, trustworthy beliefs across time?* NN asks: *how does a network of agents produce and validate knowledge at scale?*

CB is more rigorous. The DAG's immutability, explicit dependencies, and source grounding create a system you can trust for high-stakes decisions. NN is more generative. The competitive attestation and traversal model create a system that produces novel connections.

The interesting question is whether they're complementary. An agent with a CB-style DAG could traverse an NN-style knowledge network and ground what it finds as primitives with source references back to the network. The DAG would give the agent judgment about what to trust from the network. The network would give the agent access to knowledge it couldn't produce alone. CB is the agent's epistemology; NN could be one of its sources.

One notable overlap: NN's physics docs mention "Erlang-style supervision" as an aspirational runtime model - your `cb-on-the-beam.md` plan already has this as a concrete architectural choice. Both systems independently converged on the BEAM as the right foundation for persistent, fault-tolerant knowledge systems.

---

### Prompt: Integration approach

**User:** what would it look like to integrate this with cb? how should it be approached?

**Assistant:**

## Three integration layers, increasing depth

### Layer 1: NN as a knowledge source for CB

The most natural starting point. A CB agent traverses the Narrative Network, extracts primitives from what it finds, and composes them with its existing beliefs.

**What it looks like:**

```json
{
  "id": "a100",
  "kind": "primitive",
  "claim": "Betweenness centrality between quantum-foundations and consciousness domains is 0.73",
  "source": "nn:subnet42:node-quantum-foundations:traversal-session-abc123",
  "quote": null,
  "confidence": 0.6,
  "subjects": [{"ref": "domains/quantum-consciousness", "type": "research"}]
}
```

New source type prefix: `nn:<subnet>:<node-id>:<session-id>`. Confidence maps from NN's multi-axis scores - a passage that scored high on corpus integrity (Merkle-verified) and traversal relevance gets higher CB confidence than one that scored high on narrative quality alone. Corpus integrity is the closest thing NN has to source grounding, so it should weight heaviest in the confidence translation.

**What CB gains:** A discovery mechanism. CB has no way to find knowledge it doesn't already have. NN's traversal model is exactly the exploration mode CB lacks. The agent enters a query, hops through domains, and brings back primitives to compose.

**What NN gains:** Nothing yet. This is read-only.

### Layer 2: CB-powered NN miners

A miner that maintains a CB DAG about its own domain and performance. Self-referential assertions applied to the mining problem.

**What it looks like:**

The miner asserts primitives about validator feedback ("passage scored 0.3 on path coherence in session X"), composes them into beliefs about its own behavior ("my narratives drift from the path context when crossing from thermodynamics to consciousness"), and surfaces implications ("retune narrative persona to anchor cross-domain transitions on shared vocabulary").

This is the same self-improvement loop CB uses for agent actualization, applied to a specific competitive context. A miner with a DAG would learn from its scoring history structurally rather than statistically. NN's moving-average scores (alpha=0.1) tell you *what* is happening. CB's dependency chains tell you *why*.

**What CB gains:** A proof point. NN miners are a natural eval environment - does a CB-equipped miner outperform a stateless one? The scoring is automated, continuous, and adversarial. Better than a synthetic eval.

**What NN gains:** Miners that improve deliberately rather than stochastically.

### Layer 3: Patches as traversals

This is the deep structural connection. CB's `patch` kind and NN's traversal sessions are the same idea in different clothing.

| | CB Patch | NN Traversal |
|---|---|---|
| **Structure** | Routing through assertion nodes in layers | Path through domain nodes via edges |
| **Product** | The routing IS the argument | The path IS the synthesis |
| **Evaluation** | Independent reasoners traverse the same patch, compare conclusions | Multiple miners compete at each node, validators rank |
| **Confidence** | Derived from eval agreement, not author-assessed | Derived from comparative attestation across miners |

A patch whose nodes are NN domain references instead of assertion IDs becomes a cross-network knowledge synthesis with earned confidence. The `evals` array on a patch maps to NN's comparative attestation - different sources traversing the same structure and recording whether they converge.

**What this means architecturally:** The patch kind could become CB's protocol for consuming structured traversals from external knowledge networks, not just from the DAG itself. NN would be the first such network, but the pattern generalizes.

## How to approach it

**Don't start with code. Start with a manual integration.**

1. **Manually traverse NN.** Pick a domain cluster (quantum-consciousness is their seed topology's most developed region). Walk the traversal. Record what you get.

2. **Assert from the traversal.** Use `/assert` to create primitives from what the traversal produced. See how NN-sourced primitives compose with existing CB assertions. Identify where NN's comparative attestation maps cleanly to CB confidence and where it doesn't.

3. **Write the source type spec.** The `nn:` source prefix needs a specification - what constitutes a citable unit from NN? A single hop's passage? A full traversal session? A node's corpus directly? The manual traversal will make this obvious.

4. **Build one CB-powered miner.** Fork a single NN miner, add a local CB DAG, run it against stateless miners on the same domain. The scoring differential (or lack thereof) is the first real evidence for whether this integration matters.

5. **Then consider the patch-traversal unification.** Only if steps 1-4 show the integration produces novel composition that neither system achieves alone.

The risk to avoid: over-engineering the protocol before understanding what NN actually produces at the traversal level. The thesis docs call for "demonstrate, don't pitch" - the same applies here. Run a traversal, assert from it, see if the composition is real.

**One structural concern:** NN's hallucination-as-feature stance and CB's source-grounding requirement are in direct tension. A primitive sourced from an NN traversal is grounded in *what the miner generated*, not in *what a source said*. That's a weaker form of grounding than CB typically requires. The confidence translation needs to account for this - NN-sourced primitives should probably carry a confidence ceiling below what document-sourced primitives can reach, unless the corpus integrity score confirms the passage is grounded in verified documents rather than generated synthesis.

---

### Prompt: Bittensor's role

**User:** NN is on bittensor. what role does bittensor play in NN's story? in what ways might CB find useful integration with bittensor?

**Assistant:**

## What Bittensor provides to Narrative Network

Bittensor is three things for NN:

**1. An economic engine for knowledge quality.** Miners earn TAO by serving good passages. Without tokenomics, NN would need to pay miners directly or rely on volunteers. Bittensor makes quality-seeking self-sustaining - miners compete because competition pays. The three emission pools (traversal/quality/topology) with different normalization strategies create multiple viable economic strategies, which Bittensor's weight-setting mechanism makes possible without NN building payment infrastructure.

**2. Credibly neutral validation.** Validators are economically incentivized to score honestly because their stake is at risk via Yuma Consensus. NN doesn't need to trust any single validator. Graph divergence across validators is *intentional* - no sync protocol, consensus emerges from weight aggregation. This is something NN couldn't achieve with a centralized scoring service. The comparative attestation ("miner A's passage scored higher than miner B's") is credible because the attestor has skin in the game.

**3. Permissionless supply.** Anyone can register a miner without approval. This is how NN's topology grows - new miners extend into underserved knowledge regions because that's the economically rational strategy (less competition, topology rewards for bridging). A centralized system would need to recruit and approve domain experts. Bittensor makes knowledge supply permissionless.

**What Bittensor costs NN:** SDK complexity, registration fees, dependency on TAO price for miner viability, consensus latency, and the constraint that all scoring must fit the weight-setting paradigm (a vector of floats per validator, aggregated by Yuma Consensus).

## Where CB and Bittensor could connect

CB's thesis explicitly avoids multiplayer economics: "research-first, open source, monetize from distribution not toward it." Bittensor is the opposite - incentivize quality through token economics. The question is whether there's a genuine fit, not a forced one.

**The privacy constraint is the filter.** CB's service model is built on structure-without-content. Bittensor requires validators to see enough to score. Any Bittensor integration must work within that constraint or it's dead on arrival. That eliminates the obvious ideas (miners competing to produce assertions, validators scoring belief content) and leaves the structural ones.

### Genuinely useful integrations

**Patch evaluation subnet.** CB's patches need independent evaluators to traverse the routing and record conclusions. Today `evals` is an empty array waiting to be filled. This is a natural Bittensor task:

- Miners receive a patch (the routing through assertion nodes, with sources and quotes visible)
- Miners traverse the path, produce a conclusion, record whether they agree with the author
- Validators score evaluation quality (did the evaluator engage with the evidence? is the conclusion grounded in the routing?)
- Patch confidence becomes stake-weighted agreement across independent evaluators

This works because patches are *designed* for external evaluation. The routing is the argument. The conclusion is separable from the routing. You give someone the patch without the conclusion and they derive their own. That's exactly what Bittensor miners would do. And the privacy constraint holds - patches are meant to be shared; they're arguments, not secrets.

**Source verification.** Primitives cite sources. "Does this quote actually appear in this source? Is the confidence score appropriate for this source type?" is verifiable labor that could be incentivized. Miners check sources, validators score verification quality. This strengthens the DAG's integrity without exposing belief content - verifiers see individual primitives and their sources, not the compound reasoning built on top.

**Structural health analysis.** CB's service model already proposes selling health intelligence from structural telemetry. Bittensor could decentralize this:

- Graph owners submit structural telemetry (node counts, confidence distributions, staleness rates - no content)
- Miners compete to produce the best health diagnosis from the structural data
- Validators score diagnostic quality against ground truth (did the flagged pattern actually predict staleness?)

This is architecturally consistent with structure-without-content. Multiple competing analysts is more robust than a single service's opinion. And the economic model aligns - miners are incentivized to get good at predicting belief graph health.

### Integrations that don't fit

**Miners competing to produce assertions.** Assertion authorship requires deep context - the agent's operational history, the human collaborator's corrections, the specific domain. Permissionless miners can't do this. Assertions are authored, not generated.

**Decentralized belief storage.** The DAG contains the most sensitive data in the system. Putting it on-chain or distributing it to validators contradicts the entire privacy model.

**Token-gating the framework.** CB's thesis says the framework is the contribution, open source, no service dependency. Token-gating access would undermine distribution.

## The strategic question

Bittensor solves CB's cold-start problem for patch evaluation and source verification. Today, patches have empty eval arrays because there's no mechanism to get independent evaluators. Bittensor provides permissionless, incentivized evaluators at scale. That's real.

But it also introduces dependencies (TAO economics, SDK complexity, subnet registration) that the thesis explicitly avoids. The approach should probably be:

1. Build patch evaluation manually first (recruit a few models/humans to evaluate patches, prove the mechanism works)
2. If evaluation quality scales with evaluator count (it should - that's the statistical argument for earned confidence), *then* Bittensor becomes the scaling mechanism
3. Source verification is a cleaner starting point than patches because it's more objectively scorable (the quote either matches or it doesn't)

The principle from the thesis applies: demonstrate first, then scale. Bittensor is a scaling mechanism. Don't reach for it until you have something worth scaling.

---

### Prompt: Commercial viability

**User:** IF I have something to scale, do you think this could be an encouraging and impactful direction? what could the implications be? is this looking like a possible business or more of an academic exercise? blue ocean grade?

**Assistant:**

## What the combination actually creates

CB alone is a framework. Useful, open source, but frameworks don't compound. Bittensor alone is an incentive layer looking for tasks worth incentivizing. Most subnets produce *content* - text, images, data. None produce *epistemic quality*.

The combination creates something neither has alone: **a mechanism where beliefs earn their confidence through adversarial, stake-weighted evaluation.** That's a new primitive. In every other system - RAG, knowledge graphs, agent memory frameworks - confidence is author-assessed. Someone declares "I'm 0.8 sure." In CB + Bittensor, confidence is *derived* from independent evaluators with economic skin in the game agreeing or disagreeing. The confidence score stops being an opinion and starts being a measurement.

That distinction matters. An enterprise AI team choosing between "the agent says it's 80% confident" and "14 independent evaluators with staked capital converged on this conclusion at 80% agreement" is choosing between trust-me and verify-me. One of those is auditable. One of those satisfies compliance.

## Blue ocean assessment

The category would be something like "epistemic infrastructure for AI agents." Let me check it against the blue ocean criteria:

**No direct competitors.** Nobody is doing decentralized belief evaluation. Not as a product, not as a subnet, not as a research project. Agent memory startups (Mem0, Zep, Letta) store and retrieve. They don't compose, don't track confidence, don't verify sources, don't earn confidence through adversarial evaluation. Knowledge graph companies (Neo4j, etc.) model entities and relationships, not beliefs with provenance and uncertainty. The patch evaluation subnet would be the first Bittensor subnet whose output is epistemic quality rather than content.

**The privacy model is a moat.** Structure-without-content means enterprises can participate without exposing what their agents believe. This isn't just a feature - it's the reason regulated industries (finance, healthcare, legal) could adopt. Every other AI service that provides intelligence requires seeing your data. CB's structural telemetry doesn't. That's architecturally hard to replicate because it's a design constraint baked into the schema, not a feature bolted on.

**Network effects in the right places.** More belief graphs submitting structural telemetry means better health benchmarks. More patch evaluators means better confidence calibration. More source verifications means stronger trust in the DAG. These are genuine network effects, not the "more users = more value" hand-wave. Each one produces a specific, measurable improvement that single-agent installations can't achieve alone.

**Timing.** Agent frameworks are proliferating (LangChain, CrewAI, AutoGen, Claude Code itself). Every one of them struggles with cross-session reasoning, confidence calibration, and source verification. These are real unsolved problems. But the market hasn't articulated the need for *composable beliefs* specifically - it's still mostly thinking in terms of "better memory" and "longer context." The question is whether you're early to a real category or building something the market won't ask for.

## Business vs. academic exercise

The actualization eval is the pivot point. If C2 (composable beliefs) doesn't measurably outperform C1 (flat instructions), this stays academic. Interesting, publishable, but not a business.

If C2 does outperform C1, you have a measurable product claim: "agents with composable beliefs make fewer errors, surface more conflicts, and maintain more consistent behavior across sessions." That's sellable. The Bittensor integration then becomes the scaling story: "and the confidence on those beliefs is earned through adversarial evaluation, not self-assessed."

The revenue model already exists in the thesis - structural telemetry tiers. Bittensor doesn't replace that, it strengthens it:

| Revenue layer | Without Bittensor | With Bittensor |
|---|---|---|
| Open source framework | Self-sustaining, distribution mechanism | Same |
| Health intelligence (Pro/Team) | Single-service analysis | Decentralized analysis, more robust |
| Patch evaluation | Manual, doesn't scale | Incentivized, permissionless, scales |
| Source verification | Not offered | New revenue layer - "verified DAG" tier |
| Earned confidence | Not possible | Core differentiator |

The "verified DAG" tier is the one that could matter most commercially. An enterprise whose agent's beliefs carry stake-weighted, independently verified confidence scores has something no competitor's agent has: auditable epistemics. That's a compliance story, not just a capability story. Compliance stories sell to regulated industries at premium prices.

## What could go wrong

**Timing risk.** The agent ecosystem might solve cross-session reasoning with simpler approaches - longer context windows, better RAG, native model memory. "Good enough" kills a lot of structurally superior solutions. If GPT-5 has native cross-session memory that's 80% as good as CB with zero integration effort, most teams will take 80%.

**Demand risk.** Agent builders might not care about confidence calibration yet. They're still figuring out basic reliability. Epistemics might be a 2028 problem being solved in 2026.

**Bittensor risk.** Subnet economics depend on TAO price and emission schedules. If miners can't earn enough to justify running evaluation infrastructure, the quality collapses. This is a dependency on someone else's tokenomics.

**Complexity risk.** CB + Bittensor is two novel systems integrated. Each is already hard to explain individually. The combined pitch is a harder sell than either alone.

## Net assessment

This is blue ocean territory with real commercial potential, conditional on the eval results. The category genuinely doesn't exist. The structural moats (privacy model, earned confidence, network effects on health intelligence) are real and hard to replicate. The Bittensor integration creates a product that gets stronger with use, which is the right kind of flywheel.

The path is: eval results prove the mechanism works -> manual patch evaluation proves earned confidence is better than assessed confidence -> Bittensor scales the evaluation -> "verified DAG" becomes the enterprise product.

If the eval shows significant C2 > C1 differences, I'd call this a business, not an exercise. The earned confidence primitive alone - beliefs whose confidence scores are measurements rather than opinions - is something enterprises will pay for once they understand what it means for auditability. The question is whether you're 18 months early or right on time.

---

### Prompt: Standalone vs. Bittensor distribution

**User:** what about cb being offerable standalone OR via bittensor? could a local, easily wired up assertion dag to ground your claude code instance be a gateway drug to bittensor? does the client need to be on bittensor or understand it? where are the dependencies?

**Assistant:**

This reframes the whole thing.

## The layered independence model

The key insight is that Bittensor is a *backend* that the client never sees. The assertion DAG is the same whether confidence is author-assessed locally or earned through a subnet. The client interface doesn't change. The quality of what comes back does.

```
Layer 0: Local DAG (JSON file, mix bs, /assert, /assertions)
   | opt-in
Layer 1: Structural telemetry (CB service, health scores)
   | opt-in
Layer 2: Earned confidence (Bittensor subnet, patch eval, source verification)
```

Each layer is additive. Nothing below breaks if you don't opt into what's above. The client's code is identical at every layer.

## What the client sees

At every tier, the client calls the same interface:

```elixir
CB.Assertion.Store.read()
CB.Assertion.Graph.stale(assertions)
# mix bs stats, mix bs tree, etc.
```

The difference is what comes back in the `confidence` field and whether `evals` on patches are populated:

| Tier | Confidence source | Patch evals | Client code change |
|---|---|---|---|
| Local standalone | Author-assessed | Manual/empty | None |
| CB service | Author-assessed + health benchmarks | Manual | `config :cb, telemetry: true` |
| Bittensor-backed | Earned via subnet evaluation | Populated by incentivized evaluators | `config :cb, earned_confidence: true` |

The client doesn't import a Bittensor SDK. Doesn't hold TAO. Doesn't know what a subnet is. They configure `earned_confidence: true` and their patch evals start filling up, their source citations get verified, their confidence scores get calibrated against independent assessment. The Bittensor interaction is between the CB service and the subnet, not between the client and the subnet.

## The gateway drug is real

The adoption path:

**Week 1.** Developer reads about composable beliefs. Adds CB as a dependency. Creates a few primitives from their domain. Composes a compound. Sees a conflict surface that their context window missed. Thinks "huh, that's useful." This costs nothing and requires no infrastructure.

**Week 4.** They have 50+ assertions. Staleness propagation catches a stale compound they would have missed. They start using `/materialize` to turn implications into todos. The DAG is now load-bearing in their workflow. Still local, still JSON.

**Month 2.** They opt into structural telemetry. `mix bs health` tells them their graph is under-composing compared to similar-sized graphs. They start writing more compounds. Still no Bittensor awareness.

**Month 4.** They have patches with empty eval arrays. They want confidence that's better than their own assessment. They flip `earned_confidence: true`. Their patches start getting independently evaluated. Source citations start getting verified. Confidence scores become measurements. They're now consuming Bittensor subnet output without knowing or caring that Bittensor exists.

The developer's journey is: **local file -> telemetry -> earned confidence.** Bittensor enters at the last step, invisibly.

## Where the dependencies actually live

```
Client (Elixir/Python/TS)
  - CB library (open source)
  - Local DAG (JSON/ETS)
  - mix bs / belief shell
  Depends on: nothing
         |
         | structural telemetry (opt-in)
         v
CB Service (BEAM)
  - Telemetry ingestion
  - Health scoring / benchmarks
  - Patch routing to evaluators
  - Source verification dispatch
  Depends on: client opt-in
         |
         | evaluation tasks + results
         v
Bittensor Subnet
  - Patch evaluation miners
  - Source verification miners
  - Structural health analysis
  Depends on: CB service, TAO econ
```

The critical point: **dependencies flow downward only.** The client depends on nothing. The CB service depends on client opt-in. The subnet depends on the CB service. At no point does the client depend on the subnet.

This means:
- If Bittensor economics collapse, the client's DAG still works. Confidence reverts to author-assessed. Nothing breaks.
- If the CB service goes down, the client's DAG still works. They lose health benchmarks. Nothing breaks.
- The open source core is genuinely self-sufficient at every failure mode above it.

## What this means strategically

**Distribution is decoupled from monetization infrastructure.** The framework distributes through open source adoption. The service monetizes through structural intelligence. Bittensor monetizes through earned confidence. Each has its own economics. Each is independently viable. But they compound.

**Bittensor becomes invisible infrastructure.** The client's mental model is "my beliefs get independently verified." They don't think about subnets, miners, TAO, or consensus. The CB service abstracts all of that. This is the right design - forcing clients onto Bittensor would gate adoption behind crypto literacy, which kills the gateway.

**The flywheel has three stages, not one.** More local DAGs -> more telemetry -> better health benchmarks -> more local DAGs (loop 1). Better health benchmarks -> more earned confidence demand -> more subnet evaluation -> better confidence calibration -> more earned confidence demand (loop 2). Better confidence calibration -> "verified DAG" becomes a credential -> enterprise adoption -> more local DAGs (loop 3). Each loop feeds the next, but each can spin independently.

This is the architecture the thesis calls for. The framework is the contribution. The service sells intelligence. Bittensor scales the intelligence. The client never needs to know which layer their confidence came from. They just know their beliefs got more trustworthy.

---

### Prompt: BEAM/Elixir/Jido role

**User:** and what is the elixir/beam/jido story at this point? how is that looking through this lens?

**Assistant:**

## The BEAM story just got sharper

The Bittensor integration doesn't change the BEAM thesis - it *validates* it. Look at the dependency diagram from the last conversation:

```
Client (local DAG) -> CB Service (telemetry/routing) -> Bittensor Subnet (evaluation)
```

The CB Service in the middle is the piece that:
- Ingests structural telemetry from many clients
- Routes patches to evaluators
- Dispatches source verification tasks
- Aggregates results back to clients
- Maintains health benchmarks across all graphs
- Translates between clients who speak HTTP and a subnet that speaks Bittensor

That's a concurrent, fault-tolerant, message-routing service handling many independent streams. That's the BEAM's exact sweet spot. Not "the BEAM is nice for this" - the BEAM is what makes this *viable* without a DevOps team.

| Service requirement | BEAM primitive |
|---|---|
| Many clients, each with own telemetry stream | Process-per-client (~2.5KB each) |
| Route patches to subnet, aggregate results back | Message passing, no shared state |
| One client's failure doesn't affect others | Process isolation, supervision |
| Live dashboard for graph health | LiveView (free with Phoenix) |
| Hot-update scoring logic as subnet evolves | Hot code reloading |
| Distribute across nodes as load grows | Built-in distribution |

In Python you'd need FastAPI + Celery + Redis + Kubernetes to approximate this. On the BEAM it's the runtime.

## Where Jido fits now

The historical plans show a clear evolution: early coupling to Jido was identified as a weakness and superseded. The new framing is polyglot-first, BEAM-native premium. That's the right call. But the Bittensor story reopens the Jido question in a different way.

Jido is an Elixir agent framework. CB is belief infrastructure. The original mistake was coupling them - making CB depend on Jido or vice versa. The correct relationship is: **Jido is one client of CB, with a privileged integration path because they share a runtime.**

Through the Bittensor lens:

```
Jido Agent (Elixir, BEAM)
  - Uses CB library directly (ETS, no HTTP)
  - Zero-latency belief access
  - Supervision + externalized beliefs
  - Process crash -> restart -> beliefs intact
  Depends on: CB library (hex package)
         |
         | same BEAM node or cluster
         v
CB Service (Elixir, Phoenix, BEAM)
  - Telemetry, health, patch routing
  - Jido agents get in-process access
  - Python/TS agents get HTTP/gRPC
  Depends on: client opt-in
         |
         | evaluation tasks
         v
Bittensor Subnet (Python)
```

Jido agents on the same BEAM cluster as the CB service get something no other client gets: **zero-hop belief access AND zero-hop earned confidence.** A Python agent calls HTTP to get its patch evaluation results. A Jido agent gets them via ETS in microseconds. The beliefs, the health scores, and the earned confidence all live in the same VM.

That's the BEAM-native premium the architecture plan describes, but now it includes Bittensor-backed confidence, not just local graph operations.

## The Bittensor subnet itself is Python

This is worth being explicit about. Bittensor's SDK is Python. The subnet miners and validators are Python processes. The CB service talks to the subnet over Bittensor's protocol, not via BEAM distribution.

That's fine. The boundary is clean:

- **BEAM side:** CB library, CB service, client integrations, telemetry, routing, LiveView dashboard
- **Python side:** Bittensor subnet miners, validators, consensus

The CB service is the bridge. It translates between "client wants earned confidence on this patch" and "subnet needs to evaluate this patch." The BEAM handles the fan-out (many clients, many patches, many results) and the Python handles the Bittensor protocol.

This is actually a strength. The subnet miners don't need Elixir expertise. They're Python developers who understand Bittensor. The CB clients don't need Python or Bittensor. They're developers who use the CB library in whatever language they prefer. The CB service team needs both, but that's one team, not the whole ecosystem.

## What this means for the build sequence

The original build sequence from `cb-on-the-beam.md`:

```
Phase 1: In-process (same BEAM node) - client + CB store in ETS
Phase 2: Service (separate node) - client <-> CB service via distribution or HTTP
```

With Bittensor, it extends:

```
Phase 1: Local (JSON file, mix bs) - standalone, no infrastructure
Phase 2: In-process (ETS) - Elixir clients get VM-speed access
Phase 3: Service (Phoenix, telemetry, health) - all clients via HTTP, Elixir via distribution
Phase 4: Subnet (Bittensor, earned confidence) - service routes to subnet, clients unaware
```

Each phase is independently valuable. Each is additive. Phase 4 doesn't require rearchitecting phases 1-3 - it just adds a new backend that the service can route to.

## The Jido relationship, precisely stated

Jido is not a dependency. It's the showcase client. The relationship is:

- **CB provides:** belief infrastructure (assert, compose, query, stale, materialize)
- **Jido provides:** agent orchestration (workflows, signals, actions, supervision)
- **Together on the BEAM:** an agent that thinks persistently (CB), acts reliably (Jido), and recovers from failure with beliefs intact (supervision + externalized beliefs)
- **With Bittensor behind it:** that agent's beliefs carry earned confidence from independent evaluation

The demo that writes itself: a Jido agent with a CB DAG, running on the BEAM, whose patches are evaluated via Bittensor. The agent crashes, supervisor restarts it, it reads its beliefs from ETS, picks up where it left off, and its confidence scores are still calibrated from subnet evaluation. No other agent framework can do that. The BEAM is the only runtime where crash recovery + persistent beliefs + earned confidence compose into a single coherent story.

That's not Jido-coupling. That's Jido being the best proof that the architecture works.
