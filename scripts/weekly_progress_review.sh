#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
mkdir -p "$OUT_DIR"
WEEK="$(date -u +%G-%V)"
OUT_FILE="${OUT_DIR}/weekly-progress-${WEEK}.md"

open_tasks="$(awk '/^## Open Tasks/{f=1;next}/^## Closed Tasks/{f=0}f && /^- \[ \]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"
closed_tasks="$(awk '/^## Closed Tasks/{f=1;next}f && /^- \[x\]/{c++}END{print c+0}' "${ROOT}/TASKS.md" 2>/dev/null)"

{
  echo "# Weekly Progress Review (${WEEK})"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## Snapshot"
  echo "- Open tasks: ${open_tasks}"
  echo "- Closed tasks total: ${closed_tasks}"
  echo
  echo "## Suggested actions (next week)"
  echo "1. Закрыть минимум 1 личную задачу из top списка."
  echo "2. Проверить health alerts и отфильтровать шум при необходимости."
  echo "3. Прогнать weekly cleanup: memory + scorecard + ops brief."
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"