#!/usr/bin/env bash
set -euo pipefail

# Exit codes:
# 0 = OK
# 1 = WARN
# 2 = CRITICAL

DISK_WARN_PCT="${DISK_WARN_PCT:-80}"
DISK_CRIT_PCT="${DISK_CRIT_PCT:-90}"
MEM_WARN_PCT="${MEM_WARN_PCT:-85}"
MEM_CRIT_PCT="${MEM_CRIT_PCT:-95}"
LOAD_WARN="${LOAD_WARN:-2.0}"
LOAD_CRIT="${LOAD_CRIT:-4.0}"
SERVICE="${SERVICE:-openclaw-gateway.service}"

# Cron may not have user-bus env; set sane defaults for --user systemd calls.
uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${uid}}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

status=0
notes=()

add_warn() {
  [[ $status -lt 1 ]] && status=1
  notes+=("WARN: $1")
}

add_crit() {
  status=2
  notes+=("CRIT: $1")
}

# service
if ! service_state="$(systemctl --user is-active "$SERVICE" 2>/dev/null)"; then
  if pgrep -f "openclaw.*gateway|openclaw-gateway" >/dev/null 2>&1; then
    add_warn "systemd user bus unavailable; gateway process exists (degraded signal)"
  else
    add_crit "$SERVICE state unknown (user bus unavailable) and gateway process not found"
  fi
elif [[ "$service_state" != "active" ]]; then
  add_crit "$SERVICE is ${service_state}"
fi

# disk /
disk_pct="$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
if (( disk_pct >= DISK_CRIT_PCT )); then
  add_crit "disk / is ${disk_pct}% (>=${DISK_CRIT_PCT}%)"
elif (( disk_pct >= DISK_WARN_PCT )); then
  add_warn "disk / is ${disk_pct}% (>=${DISK_WARN_PCT}%)"
fi

# memory
mem_pct="$(free | awk '/^Mem:/{printf("%.0f", ($3/$2)*100)}')"
if (( mem_pct >= MEM_CRIT_PCT )); then
  add_crit "memory is ${mem_pct}% (>=${MEM_CRIT_PCT}%)"
elif (( mem_pct >= MEM_WARN_PCT )); then
  add_warn "memory is ${mem_pct}% (>=${MEM_WARN_PCT}%)"
fi

# loadavg 1m
load1="$(awk '{print $1}' /proc/loadavg)"
if awk -v v="$load1" -v c="$LOAD_CRIT" 'BEGIN{exit !(v>=c)}'; then
  add_crit "load1 is ${load1} (>=${LOAD_CRIT})"
elif awk -v v="$load1" -v w="$LOAD_WARN" 'BEGIN{exit !(v>=w)}'; then
  add_warn "load1 is ${load1} (>=${LOAD_WARN})"
fi

if [[ ${#notes[@]} -eq 0 ]]; then
  echo "OK: service, disk, memory, load are within thresholds"
  exit 0
fi

printf '%s\n' "${notes[@]}"
exit "$status"
