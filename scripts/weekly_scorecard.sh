#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
mkdir -p "$OUT_DIR"

WEEK="$(date -u +%G-%V)"
OUT_FILE="${OUT_DIR}/scorecard-${WEEK}.md"

health_transitions=0
if [[ -f "${ROOT}/state/health_alert.log" ]]; then
  # approximate: number of status records in last 7 days
  health_transitions="$(tail -n 672 "${ROOT}/state/health_alert.log" 2>/dev/null | wc -l | awk '{print $1}')"
fi

open_tasks="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"
closed_tasks="$(awk '/^## Closed Tasks/{f=1;next}f && /^- \[x\]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"

{
  echo "# Weekly Scorecard (${WEEK})"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "- completed_work_items_total: ${closed_tasks}"
  echo "- open_work_items_total: ${open_tasks}"
  echo "- health_checks_logged_recent: ${health_transitions}"
  echo "- proactive_updates_sent: [fill manually if needed]"
  echo "- false_positive_pings: [fill manually if needed]"
  echo "- blocked_items_waiting_user: [fill manually if needed]"
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"