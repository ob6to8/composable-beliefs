#!/usr/bin/env bash
set -euo pipefail

tests_dir="./tests"
passed=0
failed=0
failed_tests=()

if [[ ! -d "$tests_dir" ]]; then
  echo "No tests directory found at $tests_dir"
  exit 1
fi

shopt -s nullglob
test_files=("$tests_dir"/*)
shopt -u nullglob

test_count=0

for test_file in "${test_files[@]}"; do
  [[ -f "$test_file" && -x "$test_file" ]] || continue
  test_count=$((test_count + 1))
  test_name="$(basename "$test_file")"

  if "$test_file"; then
    echo "PASS: $test_name"
    passed=$((passed + 1))
  else
    echo "FAIL: $test_name"
    failed=$((failed + 1))
    failed_tests+=("$test_name")
  fi
done

if [[ $test_count -eq 0 ]]; then
  echo "No executable test files found in $tests_dir"
  exit 1
fi

echo ""
echo "Results: $passed passed, $failed failed out of $test_count tests"

if [[ $failed -gt 0 ]]; then
  echo "Failed tests:"
  for name in "${failed_tests[@]}"; do
    echo "  - $name"
  done
  exit 1
fi

exit 0
