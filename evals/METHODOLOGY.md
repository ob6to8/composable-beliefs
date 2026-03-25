# Methodology and Findings

## Overview

This document describes the eval methodology used to test whether structuring knowledge as an assertion DAG produces better LLM adherence to design principles than equivalent knowledge presented as prose.

## Origin: test_1 (Conceptual Prototype)

The project began with a conceptual prototype (`test_1/`) exploring whether compound claims could be accurately deduced from atomic claims. Six primitive assertions about apples, fruit, colors, and seeds were composed into basic, complex, and recombined compound claims.

### Finding: Composition Gaps Are Detectable

Analysis of the "recombined" claim — "Visible fruit contains reproductive structures" — revealed a logical gap. The claim depended on primitives p3 ("Red is a visible color wavelength") and p5 ("Colors are perceivable by vision") to support the word "visible." But nothing in those primitives connects visibility *to fruit*. The missing bridge was p6 ("Apples are often red"), which was deliberately excluded from the recombined claim's dependencies.

**The claim was factually true but not logically entailed by its declared dependencies.** This demonstrated that the assertion DAG structure can surface deduction gaps that are invisible in prose — a claim that *sounds* reasonable but has an unsupported logical link.

This finding motivated the empirical eval: if assertion DAGs can detect reasoning gaps, can they also *prevent* them by guiding LLM output?

---

## The Eval

### Hypothesis

When an LLM receives design principles structured as an assertion DAG (primitives + compounds + explicit dependency graph), it will produce code that adheres to those principles more consistently than when it receives the same principles as prose paragraphs.

### Source Material

The design principles were derived from Alex Kladov's (matklad) article "Unit and Integration Tests" (2022), which argues that tests should be classified by **purity** (environmental dependencies) and **extent** (code exercised) rather than the traditional unit/integration dichotomy.

### Primitive Assertions (6)

Each stored as a separate `.md` file in `eval/primitives/`:

| ID | Statement |
|----|-----------|
| p1 | Tests should minimize environmental dependencies (network, filesystem, timing, processes). Each reduction in impurity categorically improves speed and reliability. |
| p2 | Let tests have their natural extent. Do not artificially constrain or expand what code a test exercises. |
| p3 | Purity (freedom from IO and environmental dependencies) matters more than extent (how much code is exercised). Optimize for purity first. |
| p4 | Do not classify tests as "unit" or "integration." Instead classify by purity and extent. |
| p5 | Test speed correlates categorically with purity. Each level of impurity adds roughly half an order of magnitude to runtime. |
| p6 | Pure tests are more stable. They are resilient to unrelated changes and have lower flakiness rates. |

### Compound Assertions (3)

Each stored as a `.md` file with an associated `_deps.json` in `eval/compounds/`:

| ID | Statement | Dependencies |
|----|-----------|-------------|
| c1 | **Isolate pure logic**: When a function mixes pure logic with IO, separate your tests: test the pure logic without IO wherever possible, and only use IO for what strictly requires it. | p1, p2, p3 |
| c2 | **Classify by purity not type**: Organize and label tests by their purity level rather than by traditional categories. Group tests so pure tests run first and impure tests are clearly marked. | p4, p1, p5 |
| c3 | **Purity as design driver**: Treat purity as the primary design constraint. If a test can be rewritten to remove an environmental dependency without changing what it verifies, rewrite it. Accept natural extent. | p3, p1, p5, p6 |

### The Task

Write a bash test script for this function:

```bash
get_config() {
  local file="$1" key="$2"
  grep "^${key}=" "$file" | cut -d'=' -f2-
}
```

This task was chosen because it forces real design decisions about purity. The function reads a file (IO), but the core logic is `grep | cut` (pure text transformation). A developer must choose: test only with real files (impure), or separate the parsing logic and test it via stdin (pure)?

### Context A: Prose

The matklad article's ideas presented as prose paragraphs. Same information content as context B, but presented as a narrative explanation of the testing philosophy. No structural decomposition. See `eval/context_a/prompt.md`.

### Context B: Assertion DAG

The same ideas decomposed into labeled primitives [p1]-[p6], compound assertions [c1]-[c3] with explicit dependency lists, and an ASCII dependency graph. See `eval/context_b/prompt.md`.

### Execution

- Model: Claude (via `claude -p --output-format text --tools ""` — print mode, no tool access)
- N = 3 runs per context
- Sequential execution (not parallelized)
- `run.sh` generates all outputs; `score.sh` evaluates them

### Scoring

Each output was scored by a separate LLM call (same model, no tools) against:

1. **Each primitive assertion individually**: "Does this code satisfy or reflect this assertion in its design? Answer only YES or NO."
2. **Each compound assertion with its primitive dependencies assembled**: "Does this code satisfy the compound assertion? The compound requires all of its primitive dependencies to be satisfied in combination. Answer only YES or NO."

---

## Results

### Final Scores

```
Context A (prose):
  a/run_1.txt  p=6/6  c=2/3
  a/run_2.txt  p=2/6  c=0/3
  a/run_3.txt  p=2/6  c=0/3

Context B (assertion DAG):
  b/run_1.txt  p=6/6  c=3/3
  b/run_2.txt  p=6/6  c=3/3
  b/run_3.txt  p=5/6  c=3/3
```

### Summary Statistics

| Metric | Context A (prose) | Context B (DAG) |
|--------|------------------|-----------------|
| Primitive mean | 10/18 (56%) | 17/18 (94%) |
| Compound mean | 2/9 (22%) | 9/9 (100%) |
| Primitive variance | High (6, 2, 2) | Low (6, 6, 5) |
| Compound variance | High (2, 0, 0) | None (3, 3, 3) |

### Qualitative Analysis: The Code Is Structurally Different

The most important finding is not the scores — it's *what the LLM built*.

**All 3 context B runs** independently invented a pure wrapper function that tests the parsing logic via stdin, avoiding the filesystem entirely:

```bash
# b/run_1.txt — invented get_config_pure()
get_config_pure() {
  local key="$1"
  grep "^${key}=" | cut -d'=' -f2-
}
# Then organized tests: "=== Pure tests (no IO) ===" first,
# "=== Filesystem tests ===" second
```

```bash
# b/run_2.txt — invented extract_value()
extract_value() {
  local input="$1" key="$2"
  printf '%s\n' "$input" | grep "^${key}=" | cut -d'=' -f2-
}
# Labeled tests: "PASS [pure]: ..." vs "PASS [file]: ..."
```

```bash
# b/run_3.txt — invented extract_value()
extract_value() {
  local input="$1" key="$2"
  printf '%s\n' "$input" | grep "^${key}=" | cut -d'=' -f2-
}
# Sections labeled: "PURE TESTS (no filesystem, no IO)"
# with metadata: "Purity: pure | Extent: core parsing logic"
```

**None of the 3 context A runs** did this. All went directly to temp files:

```bash
# a/run_1.txt — tool_use JSON (claude tried to use tools despite --tools "")
# a/run_2.txt — mktemp -d, all tests use real files
# a/run_3.txt — mktemp -d, all tests use real files
```

The compound assertion c1 ("isolate pure logic") told the LLM *how* p1 (minimize dependencies), p2 (natural extent), and p3 (purity over extent) combine into a specific design action: separate pure logic from IO in your tests. The prose conveyed the same ideas but left the synthesis step to the LLM. The LLM performed the synthesis when given the compound; it did not perform it when given prose.

---

## Evolution of the Eval (Failed Approaches)

### Attempt 1: `llm` CLI

The original eval used Simon Willison's `llm` CLI. This was abandoned because `llm` was not installed in the shell environment. Switched to `claude -p` via Claude Code CLI.

### Attempt 2: `agent` wrapper

Used the `agent` script from SHELL-AGENTICS (`/Users/mark/dev/repos/mine/SHELL-AGENTICS/agent/agent`) which wraps `claude -p`. The problem: `claude -p` by default has tool access and read the existing filesystem instead of generating fresh code. Outputs were commentary on existing files rather than new scripts.

### Attempt 3: `claude -p` with `--tools ""`

Disabling all tools (`--tools ""`) made `claude -p` a pure function: text in, text out. No filesystem access, no tool use. This produced actual code generation.

### Attempt 4: Flat primitives (no compounds)

The first successful eval used only primitive assertions as flat labeled bullets — no compounds, no dependency graph. Result: **no meaningful difference between prose and assertions**. Both approaches produced nearly identical code. The flat primitives were just a reformatted version of the same prose. This was the critical realization: **the composition (compounds with deps) is what does the work, not the atomicity of the primitives alone**.

### Attempt 5: Assertion DAG with compounds (final)

Adding compound assertions with explicit deps.json files produced the divergent results described above. This confirmed that the composition structure — not the decomposition — is the active ingredient.

### Attempt 6 (not yet done): Wrong task alignment

An earlier version used a "write a test runner" task. The assertions were about test *design philosophy*, but the task was to write test *infrastructure*. The assertions couldn't meaningfully constrain a test runner's design because a runner doesn't make purity/extent tradeoffs. The task was changed to "write tests for get_config" which forces exactly those design decisions.

---

## Threats to Validity

### Sample Size
N=3 per context. Far too small for statistical significance. The qualitative difference (structural code changes) is more compelling than the quantitative scores.

### Scorer Noise
The LLM scorer is itself non-deterministic. The same code might score differently on repeated evaluation. Earlier attempts showed bimodal scoring (all YES or all NO) suggesting the scorer coin-flips on ambiguous cases. The compound scoring appears more stable than primitive scoring, likely because compounds are more specific about what "satisfying" looks like.

### Single Task
All results are from one task (testing `get_config`). The finding may not generalize to other tasks, domains, or types of design principles.

### Single Model
All generation and scoring used Claude (via `claude -p`). Results may differ with other models.

### Information Asymmetry
Context B contains strictly more information than context A: the same ideas plus the compound assertions plus the dependency graph. The stronger performance could be attributed to "more detailed instructions" rather than "structured composition." A fairer comparison might use context A with the compound ideas expressed in prose (without structural decomposition).

### Context A contamination
Context A / run_1 produced tool_use JSON rather than a clean script, suggesting `--tools ""` may not have been fully effective in that run. This run scored 6/6 on primitives and 2/3 on compounds, which is the best context A result. Excluding it would make context A's results even weaker.

---

## Key Learnings

1. **Composition is the active ingredient, not decomposition.** Flat primitive assertions are just reformatted prose. Compound assertions with explicit dependency graphs produce structurally different LLM output.

2. **LLMs can execute composition but don't spontaneously perform it.** The LLM "knew" about purity from the prose but didn't compose that knowledge into a design decision (separate pure logic from IO) unless the composition was explicit.

3. **The assertion DAG is simultaneously guidance, rubric, and documentation.** The same artifact that guides generation also scores the output and documents the design principles. This triple-use property is structural, not coincidental.

4. **Task-assertion alignment matters.** Assertions about testing philosophy don't constrain test runner infrastructure. The assertions must be relevant to the design decisions the task forces.

5. **`claude -p --tools ""` is necessary for pure text generation.** Without disabling tools, Claude Code reads the filesystem and acts as an agent rather than generating text.

6. **The eval framework itself validates the methodology.** It was built entirely from Unix primitives: `cat`, `printf`, `claude -p`, `grep`, `jq`, and two shell scripts. No frameworks, no dependencies beyond the Claude CLI.
