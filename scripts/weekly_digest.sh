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
  echo "## Quality trend"
  latest_trend="$(ls -1t "${ROOT}"/state/quality-trend-*.md 2>/dev/null | head -n1 || true)"
  if [[ -n "${latest_trend}" ]]; then
    trend_score="$(grep -E '^- Score:' "${latest_trend}" | sed 's/^- Score: //')"
    trend_prev="$(grep -E '^- Previous week:' "${latest_trend}" | sed 's/^- Previous week: //')"
    echo "- Latest report: ${latest_trend}"
    echo "- Score: ${trend_score:-unknown}"
    [[ -n "${trend_prev}" ]] && echo "- Previous: ${trend_prev}"
  else
    echo "- Trend not found yet (run ./scripts/quality_trend_weekly.sh)"
  fi
  echo
  echo "## Cron drift"
  drift_stats="$(python3 - <<'PY'
from pathlib import Path
from datetime import datetime, timezone, timedelta
import re

log=Path("state/cron_drift_guard.log")
if not log.exists():
    print("incidents=0\nauto_heal_success=0\nauto_heal_failed=0")
    raise SystemExit

cutoff=datetime.now(timezone.utc)-timedelta(days=7)
inc=0; ok=0; fail=0
for line in log.read_text(encoding='utf-8', errors='ignore').splitlines():
    m=re.match(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC\]\s+(.*)$', line)
    if not m:
        continue
    try:
        ts=datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
    except Exception:
        continue
    if ts < cutoff:
        continue
    rest=m.group(2)
    if "status=DRIFT" in rest:
        inc += 1
    if "heal_result=success" in rest:
        ok += 1
    if "heal_result=failed" in rest:
        fail += 1

print(f"incidents={inc}")
print(f"auto_heal_success={ok}")
print(f"auto_heal_failed={fail}")
PY
)"
  echo "- Last 7d incidents: $(grep '^incidents=' <<<"$drift_stats" | cut -d= -f2)"
  echo "- Auto-heal success: $(grep '^auto_heal_success=' <<<"$drift_stats" | cut -d= -f2)"
  echo "- Auto-heal failed: $(grep '^auto_heal_failed=' <<<"$drift_stats" | cut -d= -f2)"
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
