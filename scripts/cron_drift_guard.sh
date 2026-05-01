#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

AUTO_HEAL=0
if [[ "${1:-}" == "--auto-heal" ]]; then
  AUTO_HEAL=1
fi

STATUS_FILE="${STATE_DIR}/cron_drift_status.txt"
LOG_FILE="${STATE_DIR}/cron_drift_guard.log"
LAST_HEAL_EPOCH_FILE="${STATE_DIR}/cron_drift_last_heal_epoch.txt"

ALERT_CHANNEL="${ALERT_CHANNEL:-telegram}"
ALERT_TARGET="${ALERT_TARGET:-160093873}"
HEAL_COOLDOWN_SECONDS="${HEAL_COOLDOWN_SECONDS:-21600}"

now="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

set +e
check_out="$(cd "$ROOT" && ./scripts/setup_v5_cron.sh check 2>&1)"
code=$?
set -e

new_status="OK"
[[ $code -ne 0 ]] && new_status="DRIFT"

last_status="UNKNOWN"
[[ -f "$STATUS_FILE" ]] && last_status="$(cat "$STATUS_FILE" 2>/dev/null || echo UNKNOWN)"

healed="no"
heal_result="none"

if [[ "$new_status" == "DRIFT" && $AUTO_HEAL -eq 1 ]]; then
  now_epoch="$(date -u +%s)"
  last_heal_epoch=0
  [[ -f "$LAST_HEAL_EPOCH_FILE" ]] && last_heal_epoch="$(cat "$LAST_HEAL_EPOCH_FILE" 2>/dev/null || echo 0)"

  if (( now_epoch - last_heal_epoch >= HEAL_COOLDOWN_SECONDS )); then
    if (cd "$ROOT" && ./scripts/setup_v5_cron.sh install >/dev/null 2>&1); then
      set +e
      post_heal_check="$(cd "$ROOT" && ./scripts/setup_v5_cron.sh check 2>&1)"
      post_heal_code=$?
      set -e
      echo "$now_epoch" > "$LAST_HEAL_EPOCH_FILE"

      if [[ $post_heal_code -eq 0 ]]; then
        new_status="OK"
        healed="yes"
        heal_result="success"
      else
        healed="yes"
        heal_result="failed"
        check_out="$post_heal_check"
      fi
    else
      healed="yes"
      heal_result="failed"
    fi
  else
    healed="no"
    heal_result="cooldown"
  fi
fi

echo "[$now] status=$new_status code=$code auto_heal=$AUTO_HEAL healed=$healed heal_result=$heal_result" >> "$LOG_FILE"

if [[ "$new_status" != "$last_status" ]]; then
  if [[ "$new_status" == "DRIFT" ]]; then
    if [[ "$heal_result" == "failed" ]]; then
      msg="🚨 Cron drift persists after auto-heal\nTime: ${now}\n\n${check_out}"
    else
      msg="⚠️ Cron drift detected\nTime: ${now}\n\n${check_out}"
    fi
    openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
  elif [[ "$last_status" == "DRIFT" && "$new_status" == "OK" ]]; then
    if [[ "$healed" == "yes" && "$heal_result" == "success" ]]; then
      msg="✅ Cron drift auto-healed\nTime: ${now}\nsetup_v5_cron.sh check: OK"
    else
      msg="✅ Cron drift resolved\nTime: ${now}\nsetup_v5_cron.sh check: OK"
    fi
    openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
  fi
fi

echo "$new_status" > "$STATUS_FILE"
