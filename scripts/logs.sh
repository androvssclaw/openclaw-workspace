#!/usr/bin/env bash
set -euo pipefail

SERVICE="openclaw-gateway.service"
LINES="${1:-120}"

if ! [[ "$LINES" =~ ^[0-9]+$ ]]; then
  echo "Usage: ./scripts/logs.sh [lines]"
  exit 1
fi

echo "=== LOGS ==="
echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Service: ${SERVICE}"
echo "Lines: ${LINES}"
echo

echo "--- systemd status (short) ---"
systemctl --user status "$SERVICE" --no-pager | sed -n '1,20p' || true
echo

echo "--- journal (recent ${LINES}) ---"
journalctl --user -u "$SERVICE" -n "$LINES" --no-pager || true
