#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

checks=(
  "./scripts/health_check_thresholds.sh"
  "./scripts/tasks.sh"
  "./scripts/task.sh next"
  "./scripts/today.sh"
  "./scripts/ops_brief.sh"
)

fail=0
for cmd in "${checks[@]}"; do
  echo "[SMOKE] $cmd"
  if ! bash -lc "$cmd" >/dev/null 2>&1; then
    echo "  FAIL"
    fail=1
  else
    echo "  OK"
  fi
done

if [[ $fail -eq 0 ]]; then
  echo "Smoke checks: PASS"
  exit 0
fi

echo "Smoke checks: FAIL"
exit 1