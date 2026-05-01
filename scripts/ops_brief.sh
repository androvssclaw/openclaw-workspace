#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== OPS BRIEF ==="
echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo

echo "[health thresholds]"
"${ROOT}/scripts/health_check_thresholds.sh" || true

echo

echo "[last health alerts]"
tail -n 5 "${ROOT}/state/health_alert.log" 2>/dev/null || echo "(no health alert log)"

echo

echo "[latest incident]"
latest="$(ls -1t "${ROOT}/state/incidents"/incident-*.md 2>/dev/null | head -n 1 || true)"
if [[ -n "$latest" ]]; then
  echo "$latest"
  sed -n '1,20p' "$latest"
else
  echo "(no incidents yet)"
fi