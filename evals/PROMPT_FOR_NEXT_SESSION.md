# Prompt: Build the Four-Condition Assertion DAG Experiment

Read these files first, in order, to understand the full context:

1. `/Users/mark/dev/repos/mine/ITS JUST/assertions/README.md` — project overview
2. `/Users/mark/dev/repos/mine/ITS JUST/assertions/METHODOLOGY.md` — what was already tested, how, what was found, what failed
3. `/Users/mark/dev/repos/mine/ITS JUST/assertions/IMPLICATIONS.md` — theoretical implications
4. `/Users/mark/dev/repos/mine/ITS JUST/assertions/LIKELIHOOD_ANALYSIS.md` — honest assessment of likelihood, including the authoring-time vs inference-time question
5. `/Users/mark/dev/repos/mine/ITS JUST/assertions/NEXT_EXPERIMENT.md` — the experiment design you need to build
6. `/Users/mark/dev/repos/mine/ITS JUST/assertions/eval/` — the existing eval scripts and results (read run.sh, score.sh, task.md, context_a/prompt.md, context_b/prompt.md, all primitives, all compounds)

## What you need to build

Extend the existing eval in `/Users/mark/dev/repos/mine/ITS JUST/assertions/eval/` to support four conditions instead of two. The existing code tests condition A (prose) and condition B (full DAG). You need to add conditions C and D.

### Condition C: Compounds as prose

Write `eval/context_c/prompt.md`. This must contain the same ideas and same specificity as the compound assertions in context B, but written as natural prose paragraphs. NO labeled assertions, NO primitive IDs, NO deps, NO dependency graph. The point is to match the *information content* of context B without the *structure*.

For example, where context B says:
```
[c1] Isolate pure logic (deps: p1, p2, p3)
When a function mixes pure logic with IO, separate your tests...
```

Context C should say something like:
```
When a function mixes pure logic with IO, you should separate your tests. Test the pure logic without IO wherever possible, and only use IO for what strictly requires it. This produces faster, more stable tests without artificially constraining what they cover. Purity — freedom from environmental dependencies like filesystem, network, timing — matters more than extent. Let tests exercise whatever code they naturally touch.
```

The key constraint: context C must be **as specific as context B but with no structural markers**. Same actionable guidance, prose format.

### Condition D: Compounds only

Write `eval/context_d/prompt.md`. This contains ONLY the three compound assertions [c1], [c2], [c3] as labeled items. No primitives listed. No deps.json references. No dependency graph. Just the compound statements themselves.

### Update run.sh

Extend `eval/run.sh` to generate outputs for all four conditions (A, B, C, D). Store results in `results/a/`, `results/b/`, `results/c/`, `results/d/`. N should default to 10 (configurable via first argument).

Runs should be sequential (not backgrounded) since `claude -p` may not handle concurrent calls well.

### Update score.sh

Extend `eval/score.sh` to score all four conditions. Add a scorer consistency check: after scoring everything, re-score 5 randomly selected outputs and report agreement rate.

The summary should clearly show all four conditions for easy comparison.

### Important technical details

- Use `claude -p --output-format text --tools ""` for all LLM calls. The `--tools ""` flag is **critical** — without it, Claude reads the filesystem instead of generating text.
- The task in `eval/task.md` should stay unchanged (write tests for `get_config`)
- The primitives and compounds are the scoring rubric and should stay unchanged
- All prompts should include: "You are a code generator. Output ONLY a bash script. No explanation, no markdown fences, no commentary. Do not read or reference any existing files."
- Run `shellcheck` on all bash scripts before finishing

### After building, run it

Run the full experiment: `./run.sh 10` then `./score.sh`. This will take a while (~445 LLM calls). Run it and report the results.

### Observations from the previous session

These observations should inform your approach:

1. **Composition is the active ingredient, not decomposition.** The first eval attempt used flat primitive assertions (no compounds, no deps). Result: no meaningful difference from prose. Adding compounds with deps.json is what changed the output. The structure of the DAG — not the atomicity of the primitives — drove the difference.

2. **The DAG-guided LLM invented new abstractions.** All 3 context B runs independently created a pure wrapper function (`get_config_pure()` or `extract_value()`) that tests parsing logic via stdin, avoiding the filesystem. It organized tests by purity level and labeled them. No context A run did this.

3. **The key open question is authoring-time vs inference-time value.** The act of decomposing principles into primitives and compounds may itself surface better instructions (a thinking tool). The DAG format at inference time may be cosmetic — the value may have already been captured during decomposition. Context C tests this: if prose with the same specificity performs equally, the structure doesn't matter at inference time.

4. **Task-assertion alignment matters.** An earlier attempt used "write a test runner" as the task. The assertions about test design philosophy couldn't meaningfully constrain test runner infrastructure. The task was changed to "write tests for get_config" which forces the design decisions the assertions are about.

5. **Scorer noise is a concern.** Earlier attempts showed bimodal scoring (all YES or all NO) on ambiguous assertions. The compound scoring appears more stable than primitive scoring. The consistency check will quantify this.

6. **Context A may have contamination.** In the previous run, context A / run_1 produced tool_use JSON despite --tools "". It scored 6/6 primitives and 2/3 compounds — the best context A result. With it excluded, context A looks even weaker. Watch for similar contamination.

### What success looks like

After running, you should have:
- 40 generated outputs (10 per condition)
- Scores for all 40 outputs against 6 primitives and 3 compounds
- A scorer consistency report
- A clear summary comparing all four conditions
- An honest analysis of what the results mean, including whether the information asymmetry concern was valid

Update `METHODOLOGY.md` with the new results (append, don't overwrite the existing content). Update `NEXT_EXPERIMENT.md` with what was found and what to test next.
