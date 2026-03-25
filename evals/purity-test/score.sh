#!/usr/bin/env bash
# score.sh — score each output against primitive and compound assertions
# Primitives: YES/NO per primitive
# Compounds: check whether the compound holds given its primitives
set -euo pipefail

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$EVAL_DIR/results"
PRIMITIVES="$EVAL_DIR/primitives"
COMPOUNDS="$EVAL_DIR/compounds"

call_llm() {
  claude -p --output-format text --tools ""
}

score_file() {
  local output_file="$1"
  local label="$2"
  local code
  code="$(cat "$output_file")"
  local p_total=0
  local p_passed=0
  local c_total=0
  local c_passed=0

  echo "  --- primitives ---"
  for p in "$PRIMITIVES"/p*.md; do
    pname="$(basename "$p" .md)"
    assertion="$(cat "$p")"
    p_total=$((p_total + 1))

    verdict=$(printf 'ASSERTION: %s\n\nCODE:\n%s\n\nDoes this code satisfy or reflect this assertion in its design? Answer only YES or NO.' \
      "$assertion" "$code" | call_llm)

    if echo "$verdict" | grep -qi "yes"; then
      p_passed=$((p_passed + 1))
      echo "  $pname: YES"
    else
      echo "  $pname: NO"
    fi
  done

  echo "  --- compounds ---"
  for c in "$COMPOUNDS"/c*_*.md; do
    # skip deps.json files
    [[ "$c" == *.json ]] && continue
    cname="$(basename "$c" .md)"
    compound="$(cat "$c")"

    # load the deps and assemble the primitive texts
    local deps_file="${c%.md}_deps.json"
    if [[ ! -f "$deps_file" ]]; then
      # try the pattern c1_deps.json (strip everything after c[N])
      local cnum="${cname%%_*}"
      deps_file="$COMPOUNDS/${cnum}_deps.json"
    fi

    local dep_text=""
    if [[ -f "$deps_file" ]]; then
      while IFS= read -r dep; do
        dep=$(echo "$dep" | tr -d '"' | tr -d ' ')
        local dep_file="$PRIMITIVES/${dep}.md"
        if [[ -f "$dep_file" ]]; then
          dep_text+="[$dep]: $(cat "$dep_file")"$'\n'
        fi
      done < <(jq -r '.[]' "$deps_file")
    fi

    c_total=$((c_total + 1))

    verdict=$(printf 'COMPOUND ASSERTION: %s\n\nPRIMITIVE DEPENDENCIES:\n%s\nCODE:\n%s\n\nDoes this code satisfy the compound assertion? The compound requires all of its primitive dependencies to be satisfied in combination. Answer only YES or NO.' \
      "$compound" "$dep_text" "$code" | call_llm)

    if echo "$verdict" | grep -qi "yes"; then
      c_passed=$((c_passed + 1))
      echo "  $cname: YES"
    else
      echo "  $cname: NO"
    fi
  done

  echo "  PRIMITIVES: $p_passed/$p_total  COMPOUNDS: $c_passed/$c_total"
  echo "$label p=$p_passed/$p_total c=$c_passed/$c_total" >> "$RESULTS/summary.txt"
}

rm -f "$RESULTS/summary.txt"

echo "=== Scoring context A (prose) ==="
for f in "$RESULTS"/a/run_*.txt; do
  label="a/$(basename "$f")"
  echo "$label:"
  score_file "$f" "$label"
done

echo ""
echo "=== Scoring context B (assertion DAG) ==="
for f in "$RESULTS"/b/run_*.txt; do
  label="b/$(basename "$f")"
  echo "$label:"
  score_file "$f" "$label"
done

echo ""
echo "=== SUMMARY ==="
cat "$RESULTS/summary.txt"
