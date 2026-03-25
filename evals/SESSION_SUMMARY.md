# Session Summary: Assertion DAG Investigation

## What Happened

This session began with reviewing a conceptual prototype (`test_1/`) testing whether a "recombined claim" was accurately deduced from atomic claims about apples/fruit/colors/seeds. It evolved into a full empirical investigation, theoretical framework, and thesis decomposition.

## Timeline

### 1. Conceptual Prototype Review (`test_1/`)
- Reviewed primitives about apples, fruit, colors, seeds
- Found logical gap in recombined claim: "Visible fruit contains reproductive structures" — the "visible" qualifier isn't properly supported by its dependencies

### 2. Research: Formal Logic & LLM Hallucination
- Investigated whether assertion DAGs could reduce LLM hallucinations
- Surveyed existing work: FActScore, SAFE, FoVer — none implement full epistemic dependency graphs with topological verification
- User reframed goal: auditing agent belief systems for observability, security, and self-correction

### 3. Building the Eval
- Decomposed matklad's testing article into assertion primitives (p1-p6) and compounds (c1-c3)
- Built `eval/` with prose context (A) vs DAG context (B)
- Task: write tests for `get_config()` function

### 4. Failed Attempts & Fixes
| Error | Root Cause | Fix |
|---|---|---|
| `llm` CLI not found | Not on PATH | Switched to `agent` script / `claude -p` |
| Claude reading filesystem | `claude -p` has tools by default | Added `--tools ""` flag |
| Task misalignment | "Write a test runner" can't exercise purity tradeoffs | Changed to "write tests for get_config()" |
| **Flat primitives = no difference** | Labeled bullets ≈ prose with different typography | **Added compound assertions with deps.json** |

### 5. Breakthrough Result (N=3)
```
Context A (prose):          primitive 10/18 (56%), compound 2/9 (22%)
Context B (assertion DAG):  primitive 17/18 (94%), compound 9/9 (100%)
```
- **Composition is the active ingredient** — flat primitives showed no difference from prose
- DAG-guided LLM independently invented `get_config_pure()` wrapper to separate IO from logic
- No prose run did this

### 6. Conflation Discovery
Three failures occurred during the session that are conventionally called "hallucination" but are better described as **conflation** — merging distinct reasoning nodes:

1. **Step conflation**: Built eval with flat primitives despite knowing compounds are the active ingredient (conflated understanding with executing)
2. **Identity conflation**: Advised user on building the DAG, then asked "should I build it?" — conflated self with future agent
3. **Format conflation**: First eval used labeled bullets and called them "assertions" — conflated formatting with structure

**Key reframe**: The intervention for fabrication is fact-checking. The intervention for conflation is **structural decomposition** — making distinct nodes visible so they can't be merged.

### 7. Thesis DAG Construction
Decomposed the Its Just Shell thesis into a 4-layer assertion DAG:
- **14 primitives** (p01-p14): LLM is pure function, Unix is substrate, composition beats monoliths, etc.
- **7 L2 compounds** (c01-c07) with deps.json
- **3 L3 compounds** (c08-c10): ground floor thesis, control as spectrum, composability enables scaling
- **1 L4 compound** (c11): Its Just Shell (top-level thesis)

### 8. Structural Analysis Findings
- **p06 (composition beats monoliths)**: keystone — 4 compounds depend on it
- **p11 (single > multi)**: orphaned — no compound depends on it
- **p03 (files are state)**: overrepresented in rhetoric vs actual structural role (only 1 compound)
- **Two independent pillars**: Sufficiency (c08) and Trust/Control (c09) share only p01
- **Emergent weights**: Dependency reuse patterns reveal structural importance, analogous to neural network weights but inspectable and discrete

## Key Conceptual Findings

### Conflation > Hallucination
Most LLM reasoning failures observed were not fabrication but merging of distinct nodes. Four types identified:
- **Step conflation**: Collapsing sequential steps ("understand X" + "do X" → "handled X")
- **Identity conflation**: Collapsing distinct agents (self vs future agent)
- **Format conflation**: Collapsing representations (labeled bullets ≈ assertion DAG)
- **Level conflation**: Collapsing abstraction levels (knowing about purity ≈ designing for purity)

### Structural Weights
DAG reuse patterns produce emergent "weights" — the number of compounds depending on each primitive reveals how load-bearing it is. Nobody assigns these weights; they emerge from the dependency structure. Unlike neural network weights, they are inspectable, discrete, and contestable.

### Authoring-Time vs Inference-Time Value
The DAG may be primarily a **thinking tool** — the decomposition process itself surfaces gaps, redundancies, and misplaced emphasis. The four-condition experiment (A/B/C/D) was designed to isolate this.

## Likelihood Assessment
- **65%** general direction holds (structured assertions > prose for LLM adherence)
- **40%** specifically DAG structure is the active ingredient (vs. decomposition specificity)
- Biggest threat: information asymmetry — compounds add specificity, not just structure

## Files Created

### Documentation
- `README.md` — project overview
- `METHODOLOGY.md` — full eval methodology, results, failed approaches
- `IMPLICATIONS.md` — theoretical implications and future directions
- `LIKELIHOOD_ANALYSIS.md` — probability assessment, testing needs
- `CONFLATION.md` — reframing hallucination as conflation
- `CONNECTION_TO_ITSJUSTSHELL.md` — how this extends the thesis
- `NEXT_EXPERIMENT.md` — four-condition experiment design (A/B/C/D)
- `PROMPT_FOR_NEXT_SESSION.md` — prompt to launch four-condition eval

### Eval Infrastructure
- `eval/task.md` — get_config() test generation task
- `eval/context_a/prompt.md` — prose context
- `eval/context_b/prompt.md` — assertion DAG context
- `eval/primitives/p1-p6.md` — testing primitives
- `eval/compounds/c1-c3.md + deps.json` — testing compounds
- `eval/run.sh` — eval runner using `claude -p --tools ""`
- `eval/score.sh` — primitive + compound scoring
- `eval/results/` — raw outputs and summary

### Thesis DAG
- `thesis_dag/primitives/p01-p14.md` — 14 atomic assertions
- `thesis_dag/compounds_l2/c01-c07.md + deps.json` — 7 composed claims
- `thesis_dag/compounds_l3/c08-c10.md + deps.json` — 3 architectural claims
- `thesis_dag/compounds_l4/c11.md + deps.json` — top-level thesis
- `thesis_dag/diagram.txt` — ASCII dependency graph with reuse matrix
- `thesis_dag/ANALYSIS.md` — structural analysis

### Reasoning Test Package
- `its-just-shell-dag-reasoning-test/README.md` — test protocol and evaluation criteria
- `its-just-shell-dag-reasoning-test/prose.md` — thesis as prose
- `its-just-shell-dag-reasoning-test/dag/` — full thesis DAG (copy)

## Next Steps (Not Yet Executed)

1. **Human-evaluated reasoning test**: Open two LLM conversations — one with `prose.md`, one with `dag/` — and run the comparison protocol from the README
2. **Four-condition automated eval**: Use `PROMPT_FOR_NEXT_SESSION.md` to build and run the A/B/C/D experiment isolating DAG structure vs decomposition specificity
3. **Identity DAG exploration**: Structuring agent identity as assertion DAG in system prompts to prevent identity conflation (discussed but not implemented)

## Critical Technical Note
- `claude -p --output-format text --tools ""` is the correct invocation for pure text generation
- Without `--tools ""`, Claude reads the filesystem instead of generating code
- The `agent` script doesn't expose `--tools` flag, so eval calls `claude` directly
- No API key available — use Claude Code Max (`claude -p`) for LLM calls
