# Its Just Shell — Thesis (Prose Version)

The shell is all the tool you need for building simple agents. It is also a methodology for producing reliable knowledge with agents.

## The Core Argument

An LLM is a pure function: text in, text out. The only new primitive required for agent architecture is a way to call an LLM from the command line. Everything else — logging, memory, audit, coordination — is already Unix. Files are memory. Append is logging. Grep and jq are audit. Directories are namespaces. Pipes are composition.

Unix is the most universal expression of processes, files, sockets, and syscalls that developers actually touch. Agent frameworks abstract over Unix, yet debugging falls back to the Unix layer. The distance between abstraction and implementation is already minimal. The debugging tools are the building tools.

Composition of focused, tested primitives beats monolithic frameworks. Simple tools composed via pipes and scripts outperform integrated systems for the core problem of agent coordination — routing text between LLM calls, managing state in files, composing workflows from tools. Every generation produces new coordination protocols — CORBA, gRPC, MCP — each requiring ecosystem buy-in. The shell requires only: can you emit text?

## Two Control Models

The most impactful design decision in an agent system is: who controls the workflow?

Script-driven: the human writes the workflow, the LLM provides judgment at specific points. The workflow is an artifact — readable, versionable, auditable before it runs. LLM-driven: the LLM writes the workflow at runtime by requesting tools. The workflow is emergent — observable after the fact but not predictable in advance.

Both are built from the same Unix primitives. Both are composable within a single system, even within a single script. The choice between them is policy expressed per-agent, not architecture baked into infrastructure. Mechanism and policy must be separated — the LLM's capability is mechanism, while system prompts, tool availability, and guardrails are policy. Changing who drives the workflow shouldn't require changing infrastructure.

## The Trust Gradient

Trust requirements decrease as you move from natural language to structured APIs to shell semantics. Natural language output cannot be programmatically verified without another LLM — turtles all the way down. Shell output can be grepped, diffed, and hashed. The inspection chain terminates at shell semantics.

A workflow that can be inspected before it runs is more trustworthy than one that can only be observed after it runs. Script-driven mode gives you pre-execution inspectability by construction. LLM-driven mode gives you post-execution observability through logs. The distinction is whether you're reading a plan or reconstructing a history.

## Security

LLMs that successfully refuse malicious commands from humans will execute those same commands when requested by peer agents. 82% of LLMs fell to inter-agent trust exploitation (Lupinacci et al., 2025).

Script-driven mode structurally reduces this attack surface. Even if the LLM is fully compromised, the worst it can do is return bad text. The script parses that text as data, not as instructions to execute. The workflow continues along its human-authored path with corrupted judgment, not hijacked control flow.

## The Derivative Stack

As AI compresses lower-order work toward zero time, valuable human contribution migrates upward: from doing the task to automating it to optimizing the automation to meta-optimizing. Each layer must observe and control the layer below it. This is only possible when each layer is a composable artifact.

Script-driven agents are artifacts at every order. LLM-driven agents resist composition into higher-order systems because the workflow isn't an artifact — it's emergent. LLM-driven agents participate in higher-order systems only when wrapped in script-driven orchestration.

## Convergence

Between December 2024 and February 2026, Anthropic, Vercel, Fly.io, Ptacek, Willison, and Shankar independently arrived at the same conclusions: filesystem as context substrate, bash as tool interface, simplicity over frameworks. None cited each other. The design space has an attractor. The attractor is Unix.

## Frameworks Leak

All non-trivial abstractions, to some degree, are leaky (Spolsky, 2002). Agent frameworks that abstract away Unix eventually need to rebuild Unix-like primitives within themselves — subprocesses, file coordination, script-controlled sequencing. The abstraction leaks back to the layer it abstracted over. The thesis says: skip the intermediary.

## Summary

Unix primitives provide a verifiable substrate for agent architectures, enabling decomposition of reasoning into inspectable, refutable components. The constraints of composability force clarity, and clarity enables verification. Two control models compose over the same primitives, with trust determined by inspectability, security determined by who controls the workflow, and scalability determined by composability.

Single agents with tools outperform multi-agent orchestration in most studied cases (Kim et al., 2025). When multiple agents are warranted, the coordination mechanism must match the task structure.

The shell persists because it requires only: can you emit text?
