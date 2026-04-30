#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
OUT_FILE="${OUT_DIR}/weekly_ops_review.txt"
mkdir -p "$OUT_DIR"

cd "$ROOT"

{
  echo "# Weekly Ops Review"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo

  echo "## Health snapshot"
  ./scripts/health.sh || true
  echo

  echo "## Incident snapshot"
  incident_path="$(./scripts/incident_report.sh 300)"
  echo "Latest incident report: ${incident_path}"
  echo

  echo "## Backup restore-test history (last 20 lines)"
  tail -n 20 "${ROOT}/state/backup_restore_test_history.log" 2>/dev/null || echo "(no restore-test history yet)"
  echo

  echo "## Open tasks"
  ./scripts/tasks.sh || true
  echo

  echo "## Memory compact"
  ./scripts/memory_compact.sh || true
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"