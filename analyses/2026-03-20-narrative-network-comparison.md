# Composable Beliefs vs. Narrative Network (Bittensor Knowledge Network)

Date: 2026-03-20
Source: https://github.com/dukedorje/narrative-network.git

## What Narrative Network Is

A Bittensor subnet (subnet 42) where knowledge is structured as a directed weighted graph of domains, and traversal is the mechanism of cognition. Miners own knowledge domain nodes (each with a corpus, centroid embedding, and narrative persona), compete to produce synthesized narrative passages as users traverse the graph, and earn TAO cryptocurrency based on multi-axis quality scoring.

The foundational reframe: LLM hallucination is not a defect but "the simulation's step size through possibility-space." Scoring functions bound the exploration rather than suppress it. The product is not the narratives themselves but comparative attestation at scale - a continuously-generated, stake-weighted record of which knowledge mutations were judged most valuable.

Tech stack: Python 3.12, Bittensor SDK v10, FastAPI, sentence-transformers, KuzuDB, SvelteKit 5 frontend. 223 Python tests.

### Key Mechanisms

- **Nodes** represent knowledge domains with corpus documents, centroid embeddings (768-dim), narrative personas, and lifecycle states (Incubating -> Live -> Warning -> Decaying -> Collapsed)
- **Edges** are weighted by traversal history, decay multiplicatively each epoch (half-life ~1.2 days), never reach zero (floor at 0.01)
- **Traversal sessions** carry context across hops - path history, accumulated embeddings, narrative continuity
- **Four scoring axes**: traversal relevance (40%), narrative quality (30%), topology importance (15%), corpus integrity (15%)
- **Corpus integrity** is a binary gate via Merkle proofs - zero proof score collapses all other scores, primary anti-fraud mechanism
- **Three emission pools** with different normalization: traversal (linear), quality (softmax), topology (rank) - creating multiple viable strategies for miners
- **Graph divergence across validators is intentional** - no synchronization protocol, consensus emerges through Yuma Consensus on weight vectors
- **Gradual lifecycle** for everything - nodes fade in (FORESHADOW -> BRIDGE -> LIVE) and out, no abrupt topology changes

## Parallels

**Graph-structured knowledge.** Both reject flat text as the organizing principle. Narrative Network uses a directed weighted graph of knowledge domains; Composable Beliefs uses a DAG of assertions. Both bet that relationships between knowledge atoms matter more than the atoms themselves.

**Composition as the primary value.** Both argue the whole exceeds the sum of parts. CB's compound assertions synthesize meaning no individual primitive contains. NN's traversal sessions weave cross-domain narratives no single node produces. Different mechanisms, same thesis: structure enables emergent understanding.

**Confidence and uncertainty are first-class.** CB has explicit confidence scores on every assertion (0.0-1.0). NN has multi-axis scoring (traversal relevance, narrative quality, topology importance, corpus integrity) that collectively express trustworthiness. Neither hides uncertainty.

**Source grounding.** CB primitives carry source references and exact quotes. NN nodes carry corpus documents with Merkle-verified integrity. Both insist knowledge must be traceable to its origin.

**No single canonical truth.** CB handles disagreement through supersession chains and confidence. NN handles it through comparative attestation - multiple miners compete, validators rank them, rankings are the product. Both acknowledge that ground truth is often unavailable.

**Independent convergence on the BEAM.** NN's physics docs describe "Erlang-style supervision" as an aspirational runtime model (agents as isolated processes with mailboxes, preemptive scheduling, supervisor trees). CB's `cb-on-the-beam.md` already has this as a concrete architectural choice. Both independently identified the BEAM as the right foundation for persistent, fault-tolerant knowledge systems.

## Differences

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
| **Conflict detection** | Structural - dependency chains flag stale compounds when primitives change | Statistical - centroid drift detection catches domain drift, not logical contradictions |

## Where Each Shines

### Composable Beliefs

- **Agent self-improvement.** Self-referential assertions (the agent documenting its own failure modes) have no equivalent in NN. This is the mechanism for an agent to get better at being this specific agent in this specific collaboration.
- **Auditability.** Every belief has an explicit dependency chain. You can ask "why do you believe X?" and get a traceable answer. NN's comparative attestation produces rankings, not explanations.
- **Cross-session continuity.** The entire point. A new session reads the DAG and inherits structured reasoning from all prior sessions. NN has no concept of session-to-session agent persistence.
- **Conflict detection.** When a primitive is superseded, every downstream compound is flagged stale. This is structural, not coincidental. NN relies on drift detection (centroid distance) which catches domain drift but not logical contradictions.
- **Small-scale, high-stakes reasoning.** One agent, one human, real operational work where getting details right matters. The DAG excels at "these two facts from different sessions conflict and nobody noticed."

### Narrative Network

- **Knowledge exploration.** The traversal model - enter a query, hop between domains, get synthesized narratives - is a genuinely novel interface for learning. CB has no exploration mode.
- **Distributed knowledge production.** Multiple miners competing to serve the best synthesis creates an economic engine for knowledge quality. CB is a single-agent framework with no multiplayer dynamics.
- **Emergent topology.** Edge reinforcement and decay create an organic map of how knowledge domains relate, shaped by actual usage. CB's graph is manually constructed through assertion authorship.
- **Scale.** NN is designed for many participants, many domains, concurrent traversals. CB is designed for one agent and one human building shared understanding.
- **Novel synthesis.** NN's "hallucination as feature" stance, bounded by scoring functions, enables creative cross-domain synthesis. CB's source-grounding requirement means it can only assert what has evidence.

## Complementarity

They solve different problems. CB asks: how does a single agent maintain coherent, trustworthy beliefs across time? NN asks: how does a network of agents produce and validate knowledge at scale?

CB is more rigorous. The DAG's immutability, explicit dependencies, and source grounding create a system you can trust for high-stakes decisions. NN is more generative. Competitive attestation and the traversal model produce novel connections.

The interesting question is whether they're complementary. An agent with a CB-style DAG could traverse an NN-style knowledge network and ground what it finds as primitives with source references back to the network. The DAG would give the agent judgment about what to trust from the network. The network would give the agent access to knowledge it couldn't produce alone. CB is the agent's epistemology; NN could be one of its sources.

## Assessment

Neither is "stronger" in absolute terms. CB is stronger for persistent, auditable, single-agent reasoning. NN is stronger for distributed, generative, multi-participant knowledge production. The hallucination stance is the sharpest philosophical divide - CB treats unsourced claims as a failure mode to prevent; NN treats them as exploration to score and bound. Both positions are defensible for their respective use cases.
