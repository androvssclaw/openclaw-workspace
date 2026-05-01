#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

pass=0; fail=0
run(){
  local name="$1"; shift
  if "$@" >/tmp/openclaw-test.out 2>/tmp/openclaw-test.err; then
    echo "PASS: $name"; pass=$((pass+1))
  else
    echo "FAIL: $name"; fail=$((fail+1)); sed -n '1,5p' /tmp/openclaw-test.err || true
  fi
}

run "health thresholds" ./scripts/health_check_thresholds.sh
run "task next" ./scripts/task.sh next
run "task lint" ./scripts/task.sh lint
run "status short" ./scripts/status_short.sh
run "smoke check" ./scripts/smoke_check.sh
run "reminder audit" ./scripts/reminder_audit.sh
run "quality trend (no-alert)" ./scripts/quality_trend_weekly.sh --no-alert

echo "Result: PASS=$pass FAIL=$fail"
[[ $fail -eq 0 ]]
