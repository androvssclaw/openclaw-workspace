#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/clawd/.openclaw/workspace"
STATE_DIR="$ROOT/state"
EVENTS_FILE="$STATE_DIR/vpn_health_events.log"
OUT_FILE="$STATE_DIR/vpn_health_daily_summary.txt"
HISTORY_FILE="$STATE_DIR/vpn_health_daily_summary_history.log"

mkdir -p "$STATE_DIR"

NOW_EPOCH="$(date -u +%s)"
CUTOFF="$((NOW_EPOCH - 86400))"
TS_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TOTAL=0
OK=0
FAIL=0

if [[ -f "$EVENTS_FILE" ]]; then
  read -r TOTAL OK FAIL < <(awk -v c="$CUTOFF" '
    $1 >= c {
      total++
      if ($2=="ok") ok++
      else if ($2=="fail") fail++
    }
    END { printf "%d %d %d\n", total+0, ok+0, fail+0 }
  ' "$EVENTS_FILE")
fi

SUMMARY="[$TS_ISO] VPN daily summary (last 24h): runs=$TOTAL ok=$OK fail=$FAIL"
echo "$SUMMARY" > "$OUT_FILE"
echo "$SUMMARY" >> "$HISTORY_FILE"

exit 0
