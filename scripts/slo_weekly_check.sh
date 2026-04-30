#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
mkdir -p "$OUT_DIR"

WEEK="$(date -u +%G-%V)"
OUT_FILE="${OUT_DIR}/slo-weekly-${WEEK}.md"
LOG_FILE="${ROOT}/state/health_alert.log"

total=0
bad=0
if [[ -f "$LOG_FILE" ]]; then
  total="$(tail -n 672 "$LOG_FILE" | wc -l | awk '{print $1}')"
  bad="$(tail -n 672 "$LOG_FILE" | grep -Ec 'status=WARN|status=CRIT' || true)"
fi

if [[ "$total" -eq 0 ]]; then
  availability="n/a"
else
  availability="$(python3 - <<PY
from decimal import Decimal
T=Decimal("$total")
B=Decimal("$bad")
print(((T-B)/T*100).quantize(Decimal('0.01')))
PY
)%"
fi

{
  echo "# SLO Weekly Check (${WEEK})"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "- Objective (target): 99.5% healthy checks"
  echo "- Samples considered: ${total}"
  echo "- WARN/CRIT samples: ${bad}"
  echo "- Estimated healthy ratio: ${availability}"
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"