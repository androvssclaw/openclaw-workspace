#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/state/weekly-digest-$(date -u +%G-%V).md"
mkdir -p "${ROOT}/state"

open_tasks="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"
next_task="$(cd "$ROOT" && ./scripts/task.sh next | sed 's/^Следующая задача: //')"
health="$(cd "$ROOT" && ./scripts/health_check_thresholds.sh 2>/dev/null || true)"

{
  echo "# Weekly Digest"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## Tasks"
  echo "- Open: ${open_tasks}"
  echo "- Next: ${next_task}"
  echo
  echo "## Ops"
  echo "- Health: ${health}"
  echo "- Alerts tail:"
  tail -n 5 "${ROOT}/state/health_alert.log" 2>/dev/null || echo "(no alerts)"
  echo
  echo "## KPI"
  if [[ -f "${ROOT}/state/kpi-weekly-$(date -u +%G-%V).md" ]]; then
    sed -n '3,20p' "${ROOT}/state/kpi-weekly-$(date -u +%G-%V).md"
  else
    echo "- KPI snapshot not generated yet (run ./scripts/kpi_weekly.sh)"
  fi
  echo
  echo "## Release evidence"
  latest_evidence="$(ls -1t "${ROOT}"/state/release-evidence-*.md 2>/dev/null | head -n1 || true)"
  if [[ -n "${latest_evidence}" ]]; then
    overall="$(grep -E '^- Overall:' "${latest_evidence}" | sed 's/^- Overall: //')"
    th="$(grep -E '^authoritative_status:' "${latest_evidence}" | sed -n '1p' | awk '{print $2}')"
    hd="$(grep -E '^authoritative_status:' "${latest_evidence}" | sed -n '2p' | awk '{print $2}')"
    op="$(grep -E '^authoritative_status:' "${latest_evidence}" | sed -n '3p' | awk '{print $2}')"
    echo "- Latest file: ${latest_evidence}"
    echo "- Overall: ${overall:-unknown}"
    echo "- test_harness: ${th:-unknown}"
    echo "- production_hardening_dry_run: ${hd:-unknown}"
    echo "- ops_brief: ${op:-unknown}"
  else
    echo "- Evidence not found yet (run ./scripts/release_evidence.sh)"
  fi
  echo
  echo "## Risks"
  echo "- Review overdue reminders via ./scripts/reminder_audit.sh"
  echo
  echo "## Next actions"
  echo "1. Закрыть 1 задачу p1/p2"
  echo "2. Прогнать ops_brief"
  echo "3. Проверить reminder_audit"
} > "$OUT"

echo "Saved: $OUT"
