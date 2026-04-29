#!/usr/bin/env bash
set -euo pipefail

TASKS_FILE="${TASKS_FILE:-./TASKS.md}"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "Ошибка: $TASKS_FILE не найден"
  echo "Подсказка: восстанови файл из backup или создай вручную через ./scripts/task.sh add ..."
  exit 1
fi

echo "=== TASKS ==="

awk '
  BEGIN { n=0 }
  /^## /  { print "\n" $0; next }
  /^### / { print $0; next }
  /^- \[[ xX]\]/ {
    n++
    id = ""
    if (match($0, /#[0-9]+/)) {
      id = substr($0, RSTART + 1, RLENGTH - 1)
    }
    label = (id != "" ? id : n)
    printf "%s) %s\n", label, $0
  }
' "$TASKS_FILE"
