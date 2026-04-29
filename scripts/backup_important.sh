#!/usr/bin/env bash
set -euo pipefail

# Variant A backup: important state only (small, restorable), excludes heavy runtime caches.

TS="$(date -u +%Y%m%d-%H%M%S)"
HOST="$(hostname -s)"
BASE_DIR="${HOME}/backups/openclaw"
DAILY_DIR="${BASE_DIR}/daily"
MANIFEST_DIR="${BASE_DIR}/manifests"
OUT="${DAILY_DIR}/openclaw-important-${HOST}-${TS}.tar.gz"

mkdir -p "$DAILY_DIR" "$MANIFEST_DIR"

TMP_LIST="$(mktemp)"
trap 'rm -f "$TMP_LIST"' EXIT

cat > "$TMP_LIST" <<EOF
.openclaw/config
.openclaw/identity
.openclaw/memory
.openclaw/agents
.openclaw/cron
.openclaw/tasks
.openclaw/flows
.openclaw/workspace
.openclaw/devices
.openclaw/telegram
.openclaw/delivery-queue
.config/systemd/user/openclaw-gateway.service
.config/systemd/user/openclaw-gateway.service.bak
EOF

# Keep only existing paths
EXISTING=()
while IFS= read -r p; do
  [[ -e "$HOME/$p" ]] && EXISTING+=("$p")
done < "$TMP_LIST"

if [[ ${#EXISTING[@]} -eq 0 ]]; then
  echo "No backup targets found under $HOME"
  exit 1
fi

tar -C "$HOME" -czf "$OUT" "${EXISTING[@]}"

sha256sum "$OUT" > "${OUT}.sha256"

tar -tzf "$OUT" > "${MANIFEST_DIR}/$(basename "$OUT").list.txt"

SIZE="$(du -h "$OUT" | awk '{print $1}')"
echo "Backup created: $OUT"
echo "Checksum: ${OUT}.sha256"
echo "Manifest: ${MANIFEST_DIR}/$(basename "$OUT").list.txt"
echo "Size: $SIZE"
