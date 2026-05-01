#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
mkdir -p "$OUT_DIR"
OUT_FILE="${OUT_DIR}/ops_report.txt"

{
  echo "# OPS REPORT"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## OpenClaw status"
  openclaw status | sed -n '1,40p'
  echo
  echo "## Health thresholds"
  "${ROOT}/scripts/health_check_thresholds.sh" || true
  echo
  echo "## Alerts tail"
  tail -n 10 "${ROOT}/state/health_alert.log" 2>/dev/null || true
  echo
  echo "## Latest incident"
  latest="$(ls -1t "${ROOT}/state/incidents"/incident-*.md 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest" ]]; then
    echo "$latest"
    sed -n '1,30p' "$latest"
  else
    echo "(no incidents)"
  fi
  echo
  echo "## Backup restore test tail"
  tail -n 10 "${ROOT}/state/backup_restore_test_history.log" 2>/dev/null || echo "(no history)"
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"