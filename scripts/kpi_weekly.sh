#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/state/kpi-weekly-$(date -u +%G-%V).md"
mkdir -p "${ROOT}/state"

log="${ROOT}/state/health_alert.log"
total=0; bad=0; crit=0
if [[ -f "$log" ]]; then
  total="$(tail -n 672 "$log" | wc -l | awk '{print $1}')"
  bad="$(tail -n 672 "$log" | grep -Ec 'status=WARN|status=CRIT' || true)"
  crit="$(tail -n 672 "$log" | grep -Ec 'status=CRIT' || true)"
fi
open_tasks="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"
closed_tasks="$(awk '/^## Closed Tasks/{f=1;next}f && /^- \[x\]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"
{
  echo "# Weekly KPIs"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "- checks_total: $total"
  echo "- checks_warn_or_crit: $bad"
  echo "- checks_crit: $crit"
  echo "- tasks_open: $open_tasks"
  echo "- tasks_closed_total: $closed_tasks"
} > "$OUT"

echo "Saved: $OUT"