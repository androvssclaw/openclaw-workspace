#!/usr/bin/env bash
set -euo pipefail

RCLONE="${HOME}/.local/bin/rclone"
REMOTE="gdrive:openclaw-backups"
SRC="${HOME}/backups/openclaw"

mkdir -p "$SRC"

"$RCLONE" mkdir "$REMOTE"
"$RCLONE" sync "$SRC" "$REMOTE" --create-empty-src-dirs --transfers 4 --checkers 8
"$RCLONE" lsf "$REMOTE" --max-depth 2 > "${SRC}/last_remote_listing.txt"

echo "Google Drive sync OK: $REMOTE"
