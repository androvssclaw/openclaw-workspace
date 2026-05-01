#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/state/decision-log-$(date -u +%G-%V).md"
mkdir -p "${ROOT}/state"

{
  echo "# Decision Log"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "- Branch policy: bot/updates-init only"
  echo "- Docs sync policy: update ROADMAP/README in same cycle"
  echo "- Alert policy: status-change + anti-noise + CRIT priority"
} > "$OUT"

echo "Saved: $OUT"