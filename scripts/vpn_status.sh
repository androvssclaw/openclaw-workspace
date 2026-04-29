#!/usr/bin/env bash
set -euo pipefail

# Read-only compatibility/status check for AmneziaWG 2.0 prerequisites.
# Does NOT change firewall/docker/systemd/network/VPN configs.

ok=0
warn=0
fail=0

pass() { printf "[PASS] %s\n" "$1"; ok=$((ok+1)); }
warning() { printf "[WARN] %s\n" "$1"; warn=$((warn+1)); }
bad() { printf "[FAIL] %s\n" "$1"; fail=$((fail+1)); }

ver_ge() {
  # returns 0 when $1 >= $2
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

require_min() {
  local name="$1" value="$2" min="$3"
  if (( value >= min )); then
    pass "$name: $value (>= $min)"
  else
    bad "$name: $value (< $min)"
  fi
}

. /etc/os-release
OS_PRETTY="$PRETTY_NAME"
KERNEL="$(uname -r | cut -d- -f1)"
ARCH="$(uname -m)"
VIRT="$(systemd-detect-virt 2>/dev/null || true)"
PID1="$(ps -p 1 -o comm= 2>/dev/null || true)"
VCPU="$(nproc 2>/dev/null || echo 0)"
RAM_MB="$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)"
DISK_GB="$(df -BG / 2>/dev/null | awk 'NR==2 {gsub("G","",$2); print $2}' || echo 0)"
IPV4="$(curl -4 -fsS --max-time 5 ifconfig.me 2>/dev/null || true)"
DOCKER="no"; command -v docker >/dev/null 2>&1 && DOCKER="yes"
WG_TOOL="no"; command -v wg >/dev/null 2>&1 && WG_TOOL="yes"
WG_MOD="no"; modprobe -n wireguard >/dev/null 2>&1 && WG_MOD="yes"

printf "=== VPN STATUS (AmneziaWG 2.0 readiness) ===\n"
printf "Checked at: %s UTC\n\n" "$(date -u +"%Y-%m-%d %H:%M:%S")"

printf '%s\n' '-- System --'
printf "OS: %s\nKernel: %s\nArch: %s\nVirtualization: %s\nPID1: %s\nvCPU: %s\nRAM: %s MB\nDisk /: %s GB\nPublic IPv4: %s\n\n" \
  "$OS_PRETTY" "$KERNEL" "$ARCH" "${VIRT:-unknown}" "${PID1:-unknown}" "$VCPU" "$RAM_MB" "$DISK_GB" "${IPV4:-unavailable}"

printf '%s\n' '-- Compatibility checks (official baseline) --'
case "$OS_PRETTY" in
  *"Ubuntu 24.04"*|*"Ubuntu 22.04"*|*"Debian GNU/Linux 12"*|*"Debian GNU/Linux 13"*)
    pass "OS supported: $OS_PRETTY"
    ;;
  *)
    warning "OS not in officially supported list: $OS_PRETTY"
    ;;
esac

if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
  pass "Architecture supported: $ARCH"
else
  bad "Architecture unsupported for Amnezia self-hosted baseline: $ARCH"
fi

if [[ "${VIRT,,}" == "kvm" ]]; then
  pass "Virtualization supported: $VIRT"
elif [[ -n "$VIRT" ]]; then
  warning "Virtualization is '$VIRT' (officially recommended: kvm)"
else
  warning "Virtualization could not be detected"
fi

if ver_ge "$KERNEL" "4.14"; then
  pass "Kernel version OK for AmneziaWG 2.0: $KERNEL"
else
  bad "Kernel too old for AmneziaWG 2.0: $KERNEL (< 4.14)"
fi

if [[ "${PID1,,}" == "systemd" ]]; then
  pass "systemd detected"
else
  bad "systemd not detected as PID1"
fi

require_min "vCPU" "$VCPU" 1
require_min "RAM_MB" "$RAM_MB" 1024
require_min "Disk_root_GB" "$DISK_GB" 10

if [[ -n "$IPV4" ]]; then
  pass "Public IPv4 reachable: $IPV4"
else
  bad "Public IPv4 not detected"
fi

printf "\n"
printf '%s\n' '-- Informational (not required for this read-only check) --'
printf "Docker in PATH: %s\n" "$DOCKER"
printf "wg tool in PATH: %s\n" "$WG_TOOL"
printf "wireguard module loadable now: %s\n" "$WG_MOD"
if [[ "$WG_TOOL" == "no" || "$WG_MOD" == "no" ]]; then
  warning "WireGuard userspace/module may be installed during VPN setup; re-check after install"
fi

printf "\n=== Summary ===\n"
printf "PASS: %d | WARN: %d | FAIL: %d\n" "$ok" "$warn" "$fail"

if (( fail > 0 )); then
  exit 2
fi

exit 0
