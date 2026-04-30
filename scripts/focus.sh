#!/usr/bin/env bash
set -euo pipefail

TASKS_FILE="${TASKS_FILE:-./TASKS.md}"
LIMIT="${1:-3}"

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: ./scripts/focus.sh [count]"
  exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "TASKS.md not found"
  exit 1
fi

echo "=== FOCUS (${LIMIT}) ==="
awk -v max="$LIMIT" '
  /^## Open Tasks/{f=1;next}
  /^## Closed Tasks/{f=0}
  f && /^### /{grp=substr($0,5); next}
  f && /^- \[ \]/{
    c++
    print c ") [" grp "] " substr($0,7)
    if (c>=max) exit
  }
' "$TASKS_FILE"

if ! awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{found=1}END{exit !found}' "$TASKS_FILE"; then
  echo "Открытых задач нет 🎉"
fi