#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/backups/openclaw"
DAILY_DIR="${BASE_DIR}/daily"
MANIFEST_DIR="${BASE_DIR}/manifests"
OUT_DIR="${BASE_DIR}/restore-tests"
MODE="dry-run"
ARCHIVE=""

usage() {
  cat <<EOF
Usage: ./scripts/backup_restore_test.sh [--archive <path>] [--restore-sample] [--sample-limit N]

Default mode is dry-run verification:
- find latest backup archive
- verify sha256 checksum
- verify tar readability
- verify manifest presence (or generate warning)

Optional restore sample:
- extract first N files to a temp directory and report result
EOF
}

SAMPLE_LIMIT=50
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      ARCHIVE="${2:-}"
      shift 2
      ;;
    --restore-sample)
      MODE="restore-sample"
      shift
      ;;
    --sample-limit)
      SAMPLE_LIMIT="${2:-50}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$OUT_DIR"
TS="$(date -u +%Y%m%d-%H%M%S)"
REPORT="${OUT_DIR}/restore-test-${TS}.txt"

if [[ -z "$ARCHIVE" ]]; then
  ARCHIVE="$(ls -1t "${DAILY_DIR}"/openclaw-important-*.tar.gz 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "FAIL: backup archive not found" | tee "$REPORT"
  exit 1
fi

SHA_FILE="${ARCHIVE}.sha256"
MANIFEST_FILE="${MANIFEST_DIR}/$(basename "$ARCHIVE").list.txt"

{
  echo "=== BACKUP RESTORE TEST ==="
  echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Archive: $ARCHIVE"
  echo "Mode: $MODE"
  echo

  if [[ -f "$SHA_FILE" ]]; then
    if sha256sum -c "$SHA_FILE" >/dev/null 2>&1; then
      echo "checksum: PASS"
    else
      echo "checksum: FAIL"
      exit 1
    fi
  else
    echo "checksum: WARN (sha file missing: $SHA_FILE)"
  fi

  if tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
    echo "archive readability: PASS"
  else
    echo "archive readability: FAIL"
    exit 1
  fi

  if [[ -f "$MANIFEST_FILE" ]]; then
    echo "manifest: PASS ($MANIFEST_FILE)"
  else
    echo "manifest: WARN (missing: $MANIFEST_FILE)"
  fi

  COUNT="$(tar -tzf "$ARCHIVE" | wc -l | awk '{print $1}')"
  echo "entries: $COUNT"

  if [[ "$MODE" == "restore-sample" ]]; then
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    mapfile -t SAMPLE < <(tar -tzf "$ARCHIVE" | head -n "$SAMPLE_LIMIT")
    if [[ ${#SAMPLE[@]} -eq 0 ]]; then
      echo "restore-sample: FAIL (empty archive)"
      exit 1
    fi
    extracted=0
    for entry in "${SAMPLE[@]}"; do
      if tar -xzf "$ARCHIVE" -C "$TMP" "$entry" >/dev/null 2>&1; then
        extracted=$((extracted+1))
      fi
    done
    if [[ $extracted -eq 0 ]]; then
      echo "restore-sample: FAIL (sample entries could not be extracted)"
      exit 1
    fi
    echo "restore-sample: PASS (${extracted}/${#SAMPLE[@]} entries extracted to temp dir)"
  else
    echo "restore-sample: SKIP (dry-run)"
  fi

  echo
  echo "RESULT: PASS"
} | tee "$REPORT"

echo "Report: $REPORT"
