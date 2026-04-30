#!/usr/bin/env bash
set -euo pipefail

health="$(./scripts/health_check_thresholds.sh 2>/dev/null || true)"
next="$(./scripts/task.sh next | sed 's/^Следующая задача: //')"

echo "OK"
echo "- Health: ${health}"
echo "- Next task: ${next}"
echo "- Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"