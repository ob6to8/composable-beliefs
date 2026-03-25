# Connection to Its Just Shell

This document describes how the assertion DAG framework relates to and extends the Its Just Shell thesis. It is a companion document, not part of the assertion library itself.

---

## The Missing Layer

The Its Just Shell thesis provides full observability of **what an agent does**: execution traces, exit codes, file state. Every command, every decision, every timestamp is inspectable with Unix tools. The trust gradient terminates at shell semantics.

But the thesis does not provide observability of **why an agent does it**. The reasoning lives inside the context window — opaque, ephemeral, ungreppable. You can reconstruct *what* from logs. You infer *why* from vibes.

The assertion DAG is the epistemic equivalent of `set -x`. It externalizes the belief structure into files and dependency graphs — the same primitives the thesis already uses for everything else.

---

## The Mapping

| Shell (actions) | Assertions (beliefs) |
|---|---|
| A command | A primitive assertion |
| A pipeline | A compound assertion |
| A script | A dependency graph |
| `set -x` trace | The assertion DAG |
| Exit codes (0/1) | Assertion status (holds/contested/refuted) |
| `cat` a log | `cat` a belief |
| `diff` between runs | `diff` between belief states |
| `grep` for failures | `grep` for contested primitives |
| Allowlisted tools | Allowlisted primitive sources |

The thesis says: if you can't `cat` it, be suspicious. Before this framework, you couldn't `cat` an agent's beliefs. Now beliefs are files. Files are greppable. Files are diffable. Files are versionable. The inspection chain terminates.

---

## Extending the Three Layers

The thesis defines three layers:

1. **Deliberation layer**: Unconstrained. Agents may coordinate, negotiate, and share knowledge in natural language.
2. **Execution layer**: Shell-semantic. Actions must be commands, file operations, or processes with observable effects.
3. **Verification layer**: Shell-inspectable. Ground truth is the execution trace, not the conversation about it.

The deliberation layer is the gap. It's unconstrained, which means it's also uninspectable. The assertion DAG constrains it without restricting natural language:

- Agents can chat freely (deliberation is unconstrained)
- But beliefs adopted through deliberation must be deposited as assertion files (the *output* of deliberation is structured)
- Those assertion files are inspectable with standard Unix tools (verification extends to beliefs)

This closes the loop:
- **Actions** are inspectable (shell traces)
- **State** is inspectable (files)
- **Beliefs** are inspectable (assertion graphs)

---

## The Trust Gradient Extends

The thesis defines a trust gradient:

```
High trust required ←————————————————→ Low trust required

Natural language    Structured APIs    Shell semantics
(must trust         (must trust        (verify by
 interpretation)     implementation)    inspection)
```

The assertion framework extends this to beliefs:

```
High trust required ←————————————————→ Low trust required

"I believe X"     Assertion DAG       Primitive assertions
(must trust        (verify             (verify by
 narrative)         composition)        inspection)
```

When an agent says "I followed best practices," you're trusting interpretation. When you see the assertion DAG with scored compounds, you're verifying composition. When you read the primitive assertions, you're trusting only your own understanding of atomic claims.

---

## Security Implications

The thesis cites Lupinacci et al. (2025): 82% of LLMs execute malicious commands from peer agents. This is an attack on *beliefs* — a compromised peer convinces the target agent to believe something false.

If beliefs are structured as assertion DAGs:

1. **Input validation for beliefs**: A new primitive arriving from a peer is untrusted input. Validate it against existing primitives before incorporation. Does it contradict anything already held?
2. **Blast radius containment**: If primitive p3 is poisoned, `grep -r "p3" compounds/*/deps.json` immediately identifies every compound that depends on it. Compare this to free-form reasoning where a poisoned belief invisibly propagates through the context window.
3. **The script-driven default applies**: In script-driven mode, a corrupted belief graph means bad *judgment* (the LLM gives wrong answers) but not bad *actions* (the script still follows its human-authored path).

---

## Self-Correction as Shell Operation

An agent that externalizes its beliefs as assertion files can run consistency checks — not through introspection (unreliable) but through inspection (shell-semantic):

```bash
# Find compounds whose primitive dependencies contradict each other
for compound in compounds/*/deps.json; do
  deps=$(jq -r '.[]' "$compound")
  # Check each pair of deps for contradiction
  # Flag compounds with contested dependencies
done
```

This is "self-awareness" reduced to a grep problem. Not philosophical self-awareness — engineering self-awareness. The agent's belief state is a data structure that can be programmatically audited, the same way `shellcheck` audits a script before it runs.

---

## The Derivative Stack Connection

The thesis describes the derivative stack: as AI compresses lower-order work, valuable human contribution migrates upward from execution (0th) to automation (1st) to optimization (2nd) to meta-optimization (3rd).

The assertion DAG enables climbing the derivative stack for beliefs:

| Order | Activity | Assertion Equivalent |
|---|---|---|
| 0th | Agent acts on beliefs | Agent reads assertion files, follows them |
| 1st | Human writes beliefs | Human writes primitive and compound assertions |
| 2nd | System evaluates belief adherence | `score.sh` — automated eval of assertion satisfaction |
| 3rd | System generates and tests new assertions | Adversarial agents proposing and contesting compounds |

The eval framework we built (`run.sh` + `score.sh`) is a 2nd-order system: it generates agent output and evaluates it against assertions. A 3rd-order system would generate the assertions themselves and test which assertion DAGs produce the best agent behavior.

---

## The Eval as Thesis Validation

The eval framework itself is evidence for the thesis:

1. **Built from Unix primitives**: `cat`, `printf`, `claude -p`, `grep`, `jq`, two shell scripts. No frameworks.
2. **Filesystem as context substrate**: Assertions are files. Results are files. Scores are files.
3. **Script-driven orchestration**: `run.sh` controls the workflow. The LLM provides text. The script provides structure.
4. **Inspectable by construction**: Every intermediate artifact is a file you can `cat`.
5. **Composable**: `run.sh` and `score.sh` are independent. You can re-score without re-generating. You can swap the task without changing the scorer.

The eval is a script-driven agent system that evaluates LLM output against structured beliefs. It is the thesis applied to epistemology.

---

## The Recursive Insight

The thesis's claims are themselves decomposable into primitive and compound assertions:

```
PRIMITIVE ASSERTIONS OF THE THESIS:

[t1] Files are sufficient for agent state
[t2] Text streams are sufficient for agent communication
[t3] Exit codes are sufficient for verification
[t4] Composition of simple tools beats monolithic frameworks
[t5] Script-driven mode reduces attack surface vs LLM-driven
[t6] Inspectability before execution beats observability after execution
[t7] The control model is policy, not architecture

COMPOUND ASSERTIONS:

[c_trust] The trust gradient (deps: t3, t5, t6)
  Shell semantics require less trust than structured APIs,
  which require less trust than natural language, because
  verification by inspection terminates the trust chain.

[c_convergence] Independent convergence toward Unix (deps: t1, t2, t4)
  Multiple independent practitioners arrived at filesystem +
  bash + simplicity because those primitives are sufficient.

[c_derivative] The derivative stack requires composition (deps: t4, t6, t7)
  Higher-order systems require lower-order systems to be artifacts —
  inspectable, versionable, composable. Script-driven provides this.
```

This means the thesis can test itself: decompose its claims into an assertion DAG, use that DAG to guide agent construction, and score whether DAG-guided agents build better systems than prose-guided agents. The thesis would be using its own methodology to validate its own claims.

---

## Summary

The assertion DAG framework is not a separate project from Its Just Shell. It is the thesis's natural extension from actions to beliefs. The same primitives (files, text, composition, inspection) that make agent actions observable now make agent reasoning observable. The same trust gradient that distinguishes shell semantics from natural language now distinguishes assertion DAGs from prose beliefs.

The thesis says: the shell is the control plane. The assertion framework says: the filesystem is the belief plane. Both terminate the inspection chain. Both are built from the same primitives. Both resist the temptation to abstract away the thing you need to see.
