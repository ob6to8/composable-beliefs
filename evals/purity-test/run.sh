#!/usr/bin/env bash
# run.sh — run the eval N times for both contexts
# Calls claude -p with tools disabled (pure text-in/text-out)
set -euo pipefail

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$EVAL_DIR/results"
TASK="$(cat "$EVAL_DIR/task.md")"
N="${1:-3}"

rm -rf "$RESULTS"
mkdir -p "$RESULTS/a" "$RESULTS/b"

call_llm() {
  # claude -p with all tools disabled — pure function, text in text out
  claude -p --output-format text --tools ""
}

for i in $(seq 1 "$N"); do
  echo "--- run $i of $N ---"

  # Context A: prose article
  context_a="$(cat "$EVAL_DIR/context_a/prompt.md")"
  printf '%s\n\nTASK:\n%s' "$context_a" "$TASK" | call_llm > "$RESULTS/a/run_${i}.txt"
  echo "  a done"

  # Context B: primitive assertions
  context_b="$(cat "$EVAL_DIR/context_b/prompt.md")"
  printf '%s\n\nTASK:\n%s' "$context_b" "$TASK" | call_llm > "$RESULTS/b/run_${i}.txt"
  echo "  b done"
done

echo "=== outputs in $RESULTS ==="
