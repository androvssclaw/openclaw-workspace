#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/clawd/.openclaw/workspace"
STATE_DIR="$ROOT/state"
LOG_FILE="$STATE_DIR/vpn_health.log"
EVENTS_FILE="$STATE_DIR/vpn_health_events.log"
LAST_FAIL_FILE="$STATE_DIR/vpn_health_last_fail.txt"

mkdir -p "$STATE_DIR"

TS_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TS_EPOCH="$(date -u +%s)"

OUT=""
RC=0
if ! OUT="$("$ROOT/scripts/vpn_health.sh" --domain vpn.veltemio.com --expected-ip 178.104.226.202 --port 31921 --iface amn0 2>&1)"; then
  RC=$?
fi

STATUS="ok"
if [[ $RC -ne 0 ]]; then
  STATUS="fail"
fi

echo "$TS_EPOCH $STATUS" >> "$EVENTS_FILE"
{
  echo "[$TS_ISO] status=$STATUS rc=$RC"
  echo "$OUT"
  echo "---"
} >> "$LOG_FILE"

if [[ "$STATUS" == "fail" ]]; then
  {
    echo "[$TS_ISO] VPN HEALTH FAIL rc=$RC"
    echo "$OUT" | grep -E '^\[FAIL\]' || echo "$OUT" | tail -n 20
  } > "$LAST_FAIL_FILE"
fi

exit 0
