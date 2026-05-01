#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/state/reminder-audit-$(date -u +%G-%V).txt"
mkdir -p "${ROOT}/state"

set +e
report="$(cd "$ROOT" && ./scripts/reminder_audit.sh 2>&1)"
code=$?
set -e

{
  echo "# Reminder Weekly Audit"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "$report"
} > "$OUT"

echo "Saved: $OUT"

if [[ $code -ne 0 ]]; then
  msg="⏰ Reminder audit: найден риск по one-shot reminders. См. ${OUT##*/}"
  openclaw message send --channel telegram --target 160093873 --message "$msg" >/dev/null || true
fi