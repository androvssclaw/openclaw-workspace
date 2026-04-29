#!/usr/bin/env bash
set -euo pipefail

# Retention policy:
# - Keep daily for last 7 days
# - Keep weekly (Monday snapshots) for last 4 weeks
# - Keep monthly (day 01 snapshots) for last 3 months

BASE_DIR="${HOME}/backups/openclaw"
DAILY_DIR="${BASE_DIR}/daily"
WEEKLY_DIR="${BASE_DIR}/weekly"
MONTHLY_DIR="${BASE_DIR}/monthly"

mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"

shopt -s nullglob

for f in "$DAILY_DIR"/*.tar.gz; do
  bn="$(basename "$f")"

  # Extract UTC timestamp from filename: ...-YYYYMMDD-HHMMSS.tar.gz
  if [[ "$bn" =~ ([0-9]{8})-([0-9]{6})\.tar\.gz$ ]]; then
    dpart="${BASH_REMATCH[1]}"
    tpart="${BASH_REMATCH[2]}"
    ts_iso="${dpart:0:4}-${dpart:4:2}-${dpart:6:2} ${tpart:0:2}:${tpart:2:2}:${tpart:4:2} UTC"
    dow="$(date -u -d "$ts_iso" +%u)"   # 1..7, Monday=1
    mday="$(date -u -d "$ts_iso" +%d)"
  else
    continue
  fi

  if [[ "$dow" == "1" ]]; then
    cp -f "$f" "$WEEKLY_DIR/$bn"
    [[ -f "$f.sha256" ]] && cp -f "$f.sha256" "$WEEKLY_DIR/$bn.sha256"
  fi

  if [[ "$mday" == "01" ]]; then
    cp -f "$f" "$MONTHLY_DIR/$bn"
    [[ -f "$f.sha256" ]] && cp -f "$f.sha256" "$MONTHLY_DIR/$bn.sha256"
  fi
done

# prune helper: keep newest N by filename (timestamp in name)
prune_keep_n() {
  local dir="$1"; local n="$2"
  mapfile -t files < <(find "$dir" -maxdepth 1 -type f -name '*.tar.gz' -printf '%f\n' | sort -r)
  local count=${#files[@]}
  if (( count > n )); then
    for ((i=n; i<count; i++)); do
      rm -f "$dir/${files[$i]}" "$dir/${files[$i]}.sha256"
    done
  fi
}

prune_keep_n "$DAILY_DIR" 7
prune_keep_n "$WEEKLY_DIR" 4
prune_keep_n "$MONTHLY_DIR" 3

echo "Retention applied: daily=7 weekly=4 monthly=3"
