#!/usr/bin/env bash
set -euo pipefail

SERVICE="openclaw-gateway.service"
PORT="18789"

echo "=== HEALTH ==="
echo "Checked at: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo

echo "[SYSTEM]"
printf "kernel: "; uname -r
printf "uptime: "; uptime -p
printf "load: "; awk '{print $1" "$2" "$3}' /proc/loadavg
printf "disk /: "; df -h / | awk 'NR==2{print $3" used / "$2" total ("$5")"}'
printf "memory: "; free -h | awk '/^Mem:/{print $3" used / "$2" total"}'
echo

echo "[OPENCLAW SERVICE]"
if systemctl --user is-active --quiet "$SERVICE"; then
  echo "service: PASS ($SERVICE active)"
else
  echo "service: FAIL ($SERVICE not active)"
fi

if command -v openclaw >/dev/null 2>&1; then
  printf "openclaw: "; openclaw --version || true
  printf "binary: "; command -v openclaw
else
  echo "openclaw: FAIL (binary not found)"
fi

echo

echo "[GATEWAY PORT]"
if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  echo "port ${PORT}/tcp: PASS (listening)"
else
  echo "port ${PORT}/tcp: WARN (not found in ss -ltn)"
fi

echo

echo "[VPN QUICK]"
if command -v ./scripts/vpn_health.sh >/dev/null 2>&1 || [ -x ./scripts/vpn_health.sh ]; then
  ./scripts/vpn_health.sh --domain vpn.veltemio.com --expected-ip 178.104.226.202 --port 31921 --iface amn0 || true
else
  echo "vpn_health.sh not found"
fi
