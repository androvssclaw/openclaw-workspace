#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_FILE="${ROOT}/TASKS.md"

echo "=== TODAY ==="
echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo

echo "[TOP TASKS]"
if [[ -f "$TASKS_FILE" ]]; then
  awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{print "- " substr($0,7); c++; if(c>=5) exit}' "$TASKS_FILE"
else
  echo "- TASKS.md not found"
fi

echo

echo "[HEALTH]"
"${ROOT}/scripts/health_check_thresholds.sh" || true

echo

echo "[REMINDERS]"
if command -v openclaw >/dev/null 2>&1; then
  cron_json="$(openclaw cron list --json 2>/dev/null || true)"
  if [[ -z "$cron_json" ]]; then
    echo "- unable to read cron list"
    exit 0
  fi
  python3 - "$cron_json" <<'PY'
import json,sys
try:
    data=json.loads(sys.argv[1])
except Exception:
    print("- unable to read cron list")
    raise SystemExit(0)
jobs=data.get("jobs") or data if isinstance(data,list) else []
if not jobs:
    print("- no scheduled jobs")
    raise SystemExit(0)
count=0
for j in jobs:
    s=j.get("schedule",{})
    kind=s.get("kind")
    at=s.get("at")
    name=j.get("name","(no-name)")
    if kind=="at":
        print(f"- {name}: at {at}")
        count+=1
    if count>=5:
        break
if count==0:
    print("- no one-shot reminders found")
PY
else
  echo "- openclaw CLI not found"
fi
