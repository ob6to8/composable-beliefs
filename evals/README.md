# Assertion-Based Knowledge Representation for LLMs

This project explores whether structuring knowledge as **assertion dependency graphs** (DAGs of primitive and compound assertions) produces measurably better LLM adherence to design principles than equivalent knowledge presented as prose.

## Core Concepts

**Primitive assertion**: An atomic, irreducible claim. It cannot be decomposed further within the system. It is the smallest unit the system can reason about. Primitives are files.

**Compound assertion**: A structured composition of primitives via logical connectives (AND, OR, NOT, IMPLIES) with an explicit dependency graph. Compounds are files with associated `deps.json` files listing their primitive dependencies.

**Assertion DAG**: A directed acyclic graph where compound assertions depend on primitive assertions (and potentially other compounds). The graph is the reasoning structure, externalized as files and JSON.

The key distinction from prose instructions: **the composition is explicit**. A compound assertion doesn't just list ideas — it declares which primitives combine and what design decision their combination produces. The LLM receives not just *what* to value but *how those values compose into actions*.

## Repository Structure

```
assertions/
  README.md                    # this file
  METHODOLOGY.md               # detailed eval methodology and findings
  IMPLICATIONS.md              # theoretical implications and future directions
  CONNECTION_TO_ITSJUSTSHELL.md # relationship to the Its Just Shell thesis

  test_1/                      # original conceptual prototype (apples/fruit)
    primitives/                # 6 atomic claims about apples, fruit, colors
    claims/                    # basic, complex, and recombined compound claims
    diagram.txt                # ASCII dependency graph
    verdict.md                 # analysis of the complex claim

  eval/                        # empirical eval: prose vs assertion DAG
    task.md                    # the coding task given to the LLM
    context_a/prompt.md        # prose context (article ideas as paragraphs)
    context_b/prompt.md        # assertion DAG context (primitives + compounds + deps)
    primitives/                # 6 primitive assertions about testing philosophy
    compounds/                 # 3 compound assertions with deps.json files
    run.sh                     # generates outputs: N runs x 2 contexts
    score.sh                   # scores outputs against primitives and compounds
    results/                   # raw outputs and summary scores
```

## Quick Start

```bash
cd eval/
./run.sh 3       # generate 3 runs per context (6 total LLM calls)
./score.sh       # score all outputs (54 total LLM calls for scoring)
cat results/summary.txt
```

Requires `claude` CLI (Claude Code) installed and authenticated.

## Key Finding

In the initial eval (N=3, one task, one model), the assertion DAG produced:
- **Perfect compound adherence**: 9/9 across all runs
- **Near-perfect primitive adherence**: 17/18 across all runs
- **Structurally different code**: the LLM invented new abstractions to satisfy the compound assertions

The prose context produced:
- **Near-zero compound adherence**: 2/9 across all runs
- **Inconsistent primitive adherence**: 10/18 across all runs
- **Uniform code**: same structural approach every time (temp files, no purity separation)

See [METHODOLOGY.md](METHODOLOGY.md) for full details.

## Status

Early-stage experimental. N=3 on one task with one model. The signal is strong but narrow. This is a proof of concept, not a validated result.
