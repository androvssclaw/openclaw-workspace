#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_FILE="${ROOT}/TASKS.md"
STATE_FILE="${ROOT}/state/task_followup_last.txt"

now_epoch="$(date +%s)"
last_epoch=0
[[ -f "$STATE_FILE" ]] && last_epoch="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"

# no more than once per 24h
if (( now_epoch - last_epoch < 86400 )); then
  exit 0
fi

open_count="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{c++}END{print c+0}' "$TASKS_FILE" 2>/dev/null)"

if (( open_count > 0 )); then
  top3="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{print "- " substr($0,7); c++; if(c>=3) exit}' "$TASKS_FILE")"
  msg="📝 Follow-up: у тебя ${open_count} открытых задач. Топ-3:\n${top3}\n\nЕсли хочешь — скажи 'сфокусируй на сегодня', и я разложу приоритеты."
  openclaw message send --channel telegram --target 160093873 --message "$msg" >/dev/null
  echo "$now_epoch" > "$STATE_FILE"
fi