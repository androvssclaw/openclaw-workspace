#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

# Ensure user systemd bus is reachable in cron context.
uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${uid}}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

LAST_STATUS_FILE="${STATE_DIR}/health_alert_last_status.txt"
LOG_FILE="${STATE_DIR}/health_alert.log"

ALERT_CHANNEL="${ALERT_CHANNEL:-telegram}"
ALERT_TARGET="${ALERT_TARGET:-160093873}"

set +e
output="$("${ROOT}/scripts/health_check_thresholds.sh" 2>&1)"
code=$?
set -e

now="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
new_status="OK"
if [[ $code -eq 1 ]]; then
  new_status="WARN"
elif [[ $code -ge 2 ]]; then
  new_status="CRIT"
fi

last_status="UNKNOWN"
if [[ -f "$LAST_STATUS_FILE" ]]; then
  last_status="$(cat "$LAST_STATUS_FILE")"
fi

echo "[$now] status=$new_status code=$code" >> "$LOG_FILE"

if [[ "$new_status" != "$last_status" ]]; then
  msg="🚨 OpenClaw health status changed: ${last_status} -> ${new_status}\nTime: ${now}\n\n${output}"
  openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
fi

echo "$new_status" > "$LAST_STATUS_FILE"
