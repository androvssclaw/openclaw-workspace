#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${uid}}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

ALERT_CHANNEL="${ALERT_CHANNEL:-telegram}"
ALERT_TARGET="${ALERT_TARGET:-160093873}"
LOG_FILE="${STATE_DIR}/health_alert.log"

today="$(date -u +%Y-%m-%d)"
window_start="${today} 00:00:00 UTC"

ok=0; warn=0; crit=0
if [[ -f "$LOG_FILE" ]]; then
  while IFS= read -r line; do
    [[ "$line" == *"[$today"* || "$line" == "${today}"* || "$line" == *"${today} "* ]] || continue
    [[ "$line" == *"status=OK"* ]] && ok=$((ok+1))
    [[ "$line" == *"status=WARN"* ]] && warn=$((warn+1))
    [[ "$line" == *"status=CRIT"* ]] && crit=$((crit+1))
  done < "$LOG_FILE"
fi

current="UNKNOWN"
if output="$(${ROOT}/scripts/health_check_thresholds.sh 2>&1)"; then
  current="OK"
else
  code=$?
  if [[ $code -eq 1 ]]; then current="WARN"; else current="CRIT"; fi
fi

msg="📊 Daily health digest (UTC)\nDate: ${today}\nCurrent: ${current}\nChecks today: OK=${ok}, WARN=${warn}, CRIT=${crit}\n\nTip: high WARN/CRIT counts = noisy environment, проверить пороги/шум."
openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
