# Composable Beliefs vs. Mirofish/GraphRAG

Date: 2026-03-17
Source: https://dev.to/arshtechpro/mirofish-the-open-source-ai-engine-that-builds-digital-worlds-to-predict-the-future-ki8

## What Mirofish Is

An open-source AI prediction engine that ingests real-world data (news, reports, novels), uses GraphRAG to build a knowledge graph, spawns thousands of AI agents with unique personalities and memories, simulates their interactions across social platforms (Twitter-like, Reddit-like via OASIS engine), and produces prediction reports from emergent behavior.

Five-step pipeline: knowledge graph construction -> environment setup & agent creation -> dual-platform parallel simulation -> report generation -> deep interaction layer. Tech stack: Python 3.11+, Vue.js frontend, OASIS (CAMEL-AI) for simulation, GraphRAG for extraction, Zep Cloud for agent memory, OpenAI SDK-compatible LLMs.

## What They Share

Both reject flat text as a knowledge substrate. Both build structured graphs from source material. Both care about the gap between "what was said" and "what it means."

## Fundamentally Different Problems

| | Composable Beliefs | Mirofish |
|---|---|---|
| **Goal** | Persistent agent reasoning that survives sessions and composes into understanding never explicitly derived | Predict futures by simulating social dynamics among thousands of agents |
| **Unit of work** | Single agent with deep, grounded beliefs | Thousands of shallow agents with personalities |
| **Knowledge direction** | Bottom-up: source quotes -> primitives -> compounds -> implications -> actions | Top-down: documents -> GraphRAG extraction -> simulation parameters |
| **Output** | Actionable beliefs with tracked provenance, confidence, and staleness | Prediction reports synthesized from simulated social behavior |
| **Time horizon** | Ongoing, accumulating, never-ending | One-shot simulation runs with optional follow-ups |

## Does GraphRAG Make Composable Beliefs Moot?

No. They solve different problems at different layers.

### What GraphRAG does

Extracts entities and relationships from documents into a knowledge graph. Answers "who are the players and how are they connected?" It is a retrieval and extraction technique - a better way to ingest unstructured text into structured form.

### What Composable Beliefs does that GraphRAG doesn't

**Confidence as first-class citizen.** GraphRAG extracts relationships as binary facts (entity A relates to entity B). The DAG carries calibrated uncertainty on every node. A 0.3-confidence primitive is qualitatively different from a 1.0 - and that difference propagates into reasoning about what to do next.

**Composition as the primary value.** GraphRAG's graph supports retrieval - finding relevant context for a query. The DAG's value is composition - surfacing questions nobody asked. Three scattered primitives converging on break 2 address (a041) isn't a retrieval problem. No one queried for it. The structure revealed the dependency fan-in.

**Immutability and belief evolution.** GraphRAG overwrites its graph when you re-index. The DAG never edits - it supersedes. The history of what was believed, when, and why it changed is itself valuable. GraphRAG has no concept of belief change over time.

**Self-referential assertions.** The a050-a057 series (agent observing its own failure modes) has no analogue in GraphRAG. A knowledge graph doesn't model the knower's biases.

**The action feedback loop.** Implication -> materialize -> todo -> resolution -> new primitive -> stale compound. GraphRAG is read-only extraction. The DAG drives action and ingests the results.

**Source grounding with quote discipline.** Every primitive carries the exact source language in `quote`. The gap between quote and claim is where misinterpretation lives. GraphRAG extracts triples - it doesn't preserve the original language for auditability.

## Where They Could Be Complementary

GraphRAG would be a reasonable ingestion layer for composable beliefs. It could automate extraction of entities and relationships from source documents, which would then be promoted to primitives with confidence scores, quotes, and proper source typing. GraphRAG does the "what entities exist" work; composable beliefs does the "what do we believe about them, how confident are we, and what should we do" work.

## The Deeper Difference

Mirofish uses graphs to bootstrap a simulation. The graph is scaffolding - consumed and discarded once agents are running. The value is in the emergent social dynamics.

Composable Beliefs uses the graph as the reasoning itself. The DAG isn't scaffolding for something else. It's the persistent orientation of the agent - the thing that makes session N+1 qualitatively different from session 1. The graph doesn't get consumed. It accumulates, composes, and drives action.

Mirofish asks: "What might happen in the world?"
Composable Beliefs asks: "What does this agent actually know, how well does it know it, and what should it do about it?"

## Bottom Line

GraphRAG is a retrieval technique. Composable Beliefs is an epistemological architecture. They operate at different levels of abstraction. GraphRAG could feed into the CB system as an extraction tool, but it doesn't replicate the confidence modeling, immutability, self-reference, composition, or action feedback loop that make the DAG valuable.

## Mirofish Limitations Noted

- No benchmarks comparing predictions against actual outcomes
- LLM agents susceptible to herd behavior - simulated crowds polarize faster than real ones
- Predictions are "plausible scenarios based on emergent agent behavior," not probability estimates
- No explicit confidence scoring mechanism
