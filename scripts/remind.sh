#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/remind.sh <when> <message>

Examples:
  ./scripts/remind.sh 20m "Проверить деплой"
  ./scripts/remind.sh +2h "Созвон с командой"
  ./scripts/remind.sh "2026-04-29T09:00:00+03:00" "Оплатить VPS"

Notes:
- <when> can be +duration, duration (20m/2h/1d), or ISO datetime.
- Creates a one-shot OpenClaw cron reminder in main session.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

when_raw="$1"
shift
msg="$*"

when_arg="$when_raw"

created_at="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
job_name="remind-$(date -u '+%Y%m%d-%H%M%S')"
text="⏰ Reminder: $msg (set at $created_at)"

openclaw cron add \
  --name "$job_name" \
  --at "$when_arg" \
  --message "$text" \
  --session isolated \
  --announce \
  --channel last \
  --delete-after-run \
  --json
