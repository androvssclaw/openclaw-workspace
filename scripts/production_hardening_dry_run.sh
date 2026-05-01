#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

scripts=(
  ./scripts/weekly_ops_review.sh
  ./scripts/weekly_progress_review.sh
  ./scripts/slo_weekly_check.sh
  ./scripts/reminder_weekly_audit.sh
  ./scripts/weekly_digest.sh
  ./scripts/memory_review.sh
  ./scripts/decision_log_weekly.sh
  ./scripts/kpi_weekly.sh
  ./scripts/runbook_drill.sh
  ./scripts/restore_test_cron.sh
)

pass=0; fail=0
for s in "${scripts[@]}"; do
  if [[ ! -x "$s" ]]; then
    echo "SKIP: $s (not executable)"
    continue
  fi
  if "$s" >/tmp/openclaw-v4.out 2>/tmp/openclaw-v4.err; then
    echo "PASS: $s"
    pass=$((pass+1))
  else
    echo "FAIL: $s"
    sed -n '1,10p' /tmp/openclaw-v4.err || true
    fail=$((fail+1))
  fi
done

echo "Dry-run chain result: PASS=$pass FAIL=$fail"
[[ $fail -eq 0 ]]
