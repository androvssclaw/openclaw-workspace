#!/usr/bin/env bash
set -euo pipefail

DOMAIN="vpn.veltemio.com"
EXPECTED_IP=""
PORT="31921"
IFACE="amn0"
SAMPLE_SEC="2"

ok=0
warn=0
fail=0

pass() { printf "[PASS] %s\n" "$1"; ok=$((ok+1)); }
warning() { printf "[WARN] %s\n" "$1"; warn=$((warn+1)); }
bad() { printf "[FAIL] %s\n" "$1"; fail=$((fail+1)); }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --domain <name>         VPN domain (default: ${DOMAIN})
  --expected-ip <ip>      Expected A record IP (optional)
  --port <udp-port>       VPN UDP port (default: ${PORT})
  --iface <name>          VPN host interface (default: ${IFACE})
  --sample-sec <seconds>  RX/TX delta sample window (default: ${SAMPLE_SEC})
  -h, --help              Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    --expected-ip) EXPECTED_IP="${2:-}"; shift 2 ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --iface) IFACE="${2:-}"; shift 2 ;;
    --sample-sec) SAMPLE_SEC="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

printf "=== VPN HEALTH ===\n"
printf "Checked at: %s UTC\n" "$(date -u +"%Y-%m-%d %H:%M:%S")"
printf "Domain: %s | Port: %s/udp | Interface: %s\n\n" "$DOMAIN" "$PORT" "$IFACE"

if ! command -v dig >/dev/null 2>&1; then
  bad "dig not found (install dnsutils)"
else
  for resolver in 1.1.1.1 8.8.8.8; do
    resolved="$(dig +short A "$DOMAIN" @"$resolver" | tail -n1 || true)"
    if [[ -n "$resolved" ]]; then
      pass "DNS @${resolver}: ${DOMAIN} -> ${resolved}"
      if [[ -n "$EXPECTED_IP" ]]; then
        if [[ "$resolved" == "$EXPECTED_IP" ]]; then
          pass "Expected IP matched: ${EXPECTED_IP}"
        else
          bad "Expected IP mismatch via ${resolver}: got ${resolved}, want ${EXPECTED_IP}"
        fi
      fi
    else
      bad "DNS @${resolver}: no A record response for ${DOMAIN}"
    fi
  done
fi

if ip -br link show "$IFACE" >/dev/null 2>&1; then
  state="$(ip -br link show "$IFACE" | awk '{print $2}')"
  if [[ "$state" == "UP" ]]; then
    pass "Interface ${IFACE} is UP"
  else
    bad "Interface ${IFACE} state: ${state}"
  fi
else
  bad "Interface ${IFACE} not found"
fi

if ss -uln | awk '{print $5}' | grep -Eq "(^|:)${PORT}$"; then
  pass "UDP port ${PORT} appears to be listening on host"
else
  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Ports}}' | grep -Eq "(:|\])${PORT}->${PORT}/udp"; then
    pass "UDP port ${PORT} is published by Docker"
  else
    bad "UDP port ${PORT} not detected (host ss or Docker publish)"
  fi
fi

read_bytes() {
  ip -s link show "$IFACE" 2>/dev/null | awk '
    /RX:/ {getline; rx=$1}
    /TX:/ {getline; tx=$1}
    END {if (rx=="" || tx=="") exit 1; print rx " " tx}
  '
}

if bytes1="$(read_bytes)"; then
  rx1="$(awk '{print $1}' <<<"$bytes1")"
  tx1="$(awk '{print $2}' <<<"$bytes1")"
  sleep "$SAMPLE_SEC"
  if bytes2="$(read_bytes)"; then
    rx2="$(awk '{print $1}' <<<"$bytes2")"
    tx2="$(awk '{print $2}' <<<"$bytes2")"
    drx=$((rx2-rx1))
    dtx=$((tx2-tx1))
    if (( drx > 0 || dtx > 0 )); then
      pass "Traffic delta over ${SAMPLE_SEC}s: RX +${drx}, TX +${dtx}"
    else
      warning "No RX/TX growth over ${SAMPLE_SEC}s (may be idle)"
    fi
  else
    warning "Could not read second RX/TX sample on ${IFACE}"
  fi
else
  warning "Could not read RX/TX counters on ${IFACE}"
fi

printf "\n=== Summary ===\n"
printf "PASS: %d | WARN: %d | FAIL: %d\n" "$ok" "$warn" "$fail"

if (( fail > 0 )); then
  exit 2
fi

exit 0
