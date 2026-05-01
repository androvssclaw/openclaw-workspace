#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
mkdir -p "$OUT_DIR"
OUT_FILE="${OUT_DIR}/runbook-drill-$(date -u +%Y%m%d).md"

{
  echo "# Runbook Drill"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## Checks"
  echo "- health thresholds"
  "${ROOT}/scripts/health_check_thresholds.sh" || true
  echo
  echo "- vpn status"
  "${ROOT}/scripts/vpn_status.sh" || true
  echo
  echo "- latest incident path"
  ls -1t "${ROOT}/state/incidents"/incident-*.md 2>/dev/null | head -n 1 || echo "(none)"
  echo
  echo "## Drill checklist"
  echo "- Confirm rollback command path is known"
  echo "- Confirm backup restore test history is present"
  echo "- Confirm alert channel receives messages"
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"