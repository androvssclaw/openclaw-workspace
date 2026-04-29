#!/usr/bin/env bash
set -euo pipefail

SERVICE="openclaw-gateway.service"
OUT_DIR="state/incidents"
LINES="${1:-200}"
mkdir -p "$OUT_DIR"
TS="$(date -u +%Y%m%d-%H%M%S)"
OUT="${OUT_DIR}/incident-${TS}.md"

health_status="OK"
service_active="unknown"
port_status="unknown"

if systemctl --user is-active --quiet "$SERVICE"; then
  service_active="active"
else
  service_active="inactive"
  health_status="DEGRADED"
fi

if ss -ltn 2>/dev/null | grep -q "127.0.0.1:18789 "; then
  port_status="listening"
else
  port_status="not_listening"
  [[ "$health_status" == "OK" ]] && health_status="DEGRADED"
fi

load_avg="$(awk '{print $1" "$2" "$3}' /proc/loadavg)"
disk_pct="$(df -P / | awk 'NR==2{print $5}')"
mem_line="$(free -h | awk '/^Mem:/{print $3" used / "$2" total"}')"

risk_notes=()
if [[ "$disk_pct" =~ ^([0-9]+)%$ ]]; then
  d="${BASH_REMATCH[1]}"
  if (( d >= 90 )); then
    risk_notes+=("Disk usage is critical (${disk_pct})")
    health_status="DEGRADED"
  elif (( d >= 80 )); then
    risk_notes+=("Disk usage is high (${disk_pct})")
  fi
fi

recent_errors="$(journalctl --user -u "$SERVICE" -n "$LINES" --no-pager 2>/dev/null | grep -Ei "error|fatal|panic|failed" | tail -n 20 || true)"

{
  echo "# Incident Report"
  echo
  echo "- Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "- Overall: **$health_status**"
  echo "- Service: $service_active"
  echo "- Gateway: $port_status"
  echo "- Load: $load_avg"
  echo "- Disk /: $disk_pct"
  echo "- Memory: $mem_line"
  echo
  echo "## Symptom"
  if [[ "$health_status" == "OK" ]]; then
    echo "No active incident detected from quick checks."
  else
    echo "One or more health checks are degraded."
  fi
  echo
  echo "## Impact"
  if [[ "$service_active" != "active" ]]; then
    echo "- OpenClaw gateway may be unavailable for chat/control traffic."
  fi
  if [[ "$port_status" != "listening" ]]; then
    echo "- Local gateway endpoint is not listening on expected localhost socket."
  fi
  if [[ "$service_active" == "active" && "$port_status" == "listening" ]]; then
    echo "- No direct user-facing impact detected."
  fi
  echo
  echo "## Probable cause"
  if [[ -n "$recent_errors" ]]; then
    echo "Recent service errors found in logs (see excerpt below)."
  else
    echo "No obvious fatal patterns in recent service logs."
  fi
  if (( ${#risk_notes[@]} > 0 )); then
    printf '%s\n' "${risk_notes[@]}"
  fi
  echo
  echo "## Recommended actions"
  echo "1. Run ./scripts/health.sh"
  echo "2. Run ./scripts/logs.sh 200"
  echo "3. If service inactive: systemctl --user restart $SERVICE"
  echo "4. If issue persists: inspect journal for stack traces and recent config changes"
  echo
  echo "## Log excerpt (errors only)"
  if [[ -n "$recent_errors" ]]; then
    echo '```'
    echo "$recent_errors"
    echo '```'
  else
    echo "(none)"
  fi
} > "$OUT"

echo "$OUT"