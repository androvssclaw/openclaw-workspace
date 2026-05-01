#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

STATUS_FILE="${STATE_DIR}/cron_drift_status.txt"
LOG_FILE="${STATE_DIR}/cron_drift_guard.log"

ALERT_CHANNEL="${ALERT_CHANNEL:-telegram}"
ALERT_TARGET="${ALERT_TARGET:-160093873}"

now="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

set +e
check_out="$(cd "$ROOT" && ./scripts/setup_v5_cron.sh check 2>&1)"
code=$?
set -e

new_status="OK"
[[ $code -ne 0 ]] && new_status="DRIFT"

last_status="UNKNOWN"
[[ -f "$STATUS_FILE" ]] && last_status="$(cat "$STATUS_FILE" 2>/dev/null || echo UNKNOWN)"

echo "[$now] status=$new_status code=$code" >> "$LOG_FILE"

if [[ "$new_status" != "$last_status" ]]; then
  if [[ "$new_status" == "DRIFT" ]]; then
    msg="⚠️ Cron drift detected\nTime: ${now}\n\n${check_out}"
    openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
  elif [[ "$last_status" == "DRIFT" && "$new_status" == "OK" ]]; then
    msg="✅ Cron drift resolved\nTime: ${now}\nsetup_v5_cron.sh check: OK"
    openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
  fi
fi

echo "$new_status" > "$STATUS_FILE"
