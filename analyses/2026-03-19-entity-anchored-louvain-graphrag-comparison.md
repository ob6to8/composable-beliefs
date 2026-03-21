# Entity-Anchored vec0 KNN Salient-Weighted Louvain Graph vs. Composable Beliefs

Date: 2026-03-19

## Decomposing the Term

"Entity anchored vec0 KNN salient weighted Louvain graph" is not a named system or paper. It's a description of a specific GraphRAG pipeline architecture - a stack of techniques composed together:

| Term | What it means |
|---|---|
| **Entity anchored** | Graph organized around extracted entities (people, places, concepts) as primary nodes, not documents or chunks |
| **vec0** | sqlite-vec - a SQLite extension for vector embeddings. The whole thing runs locally in SQLite, no external vector DB |
| **KNN** | K-Nearest Neighbors search over those embeddings to find semantically similar nodes |
| **Salient weighted** | Edge weights based on salience (relevance/importance) rather than raw co-occurrence counts |
| **Louvain** | The Louvain community detection algorithm - clusters the graph into communities of densely connected nodes |
| **graph** | The knowledge graph itself |

Read together: a knowledge graph where entities are the anchor nodes, vector similarity (via sqlite-vec KNN) finds related nodes, edges are weighted by salience, and Louvain clustering identifies community structure. This is essentially the LightRAG / Microsoft GraphRAG architecture pattern with a local SQLite backend.

## What This Stack Does

Ingests documents -> extracts entities -> embeds them as vectors -> links them by semantic similarity (KNN) and salience -> clusters them (Louvain) -> retrieves relevant clusters at query time.

It is an **information retrieval** pipeline. The goal: given a question, find the right context.

## What Composable Beliefs Does

Captures grounded claims with provenance -> composes them into derived beliefs -> tracks confidence and staleness -> drives action through implications -> observes itself.

It is an **epistemological architecture**. The goal: maintain persistent, inspectable, composable reasoning.

## Key Differences

**No confidence.** The Louvain graph has edge weights for retrieval ranking, not epistemic uncertainty. A salient-weighted edge says "these are related" not "I'm 70% sure this is true."

**No immutability or belief evolution.** Re-indexing replaces the graph. There's no supersession chain, no history of what was believed when.

**No composition semantics.** Louvain communities are statistical clusters - "these entities co-occur." CB compounds are logical derivations - "these facts together mean X." The community has no `claim`, no `implication`, no `deps`.

**No action feedback loop.** The Louvain graph is read-only infrastructure for retrieval. It doesn't generate implications, materialize todos, or ingest results.

**No self-reference.** It can't represent beliefs about the knower.

**Retrieval vs. reasoning.** KNN asks "what's near this query?" CB asks "what follows from what I know?"

## Where It's Relevant

This stack would be useful as a discovery layer feeding into CB. Entity-anchored KNN could surface documents that might contain primitives worth asserting. Louvain communities could suggest clusters of related assertions that might compose into compounds nobody's written yet.

It's a telescope - it helps you find things to look at. CB is the notebook where you record what you saw, what it means, and what to do about it.

## Sources

- sqlite-vec (vec0): https://github.com/asg017/sqlite-vec
- Louvain method: https://en.wikipedia.org/wiki/Louvain_method
- LightRAG (EMNLP2025): https://github.com/hkuds/lightrag
- GraphAnchor - Graph-Anchored Knowledge Indexing: https://arxiv.org/abs/2601.16462
- How to Implement Graph RAG Using Knowledge Graphs: https://medium.com/data-science/how-to-implement-graph-rag-using-knowledge-graphs-and-vector-databases-60bb69a22759
