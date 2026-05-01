#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

TS="$(date -u +%Y%m%d-%H%M%S)"
OUT="${STATE_DIR}/release-evidence-${TS}.md"

cd "$ROOT"

th_ok=1
hd_ok=1
ops_ok=1

th_out="$(./scripts/test_harness.sh 2>&1)" || th_ok=0
hd_out="$(./scripts/production_hardening_dry_run.sh 2>&1)" || hd_ok=0
ops_out="$(./scripts/ops_brief.sh 2>&1)" || ops_ok=0

status="PASS"
if [[ $th_ok -ne 1 || $hd_ok -ne 1 || $ops_ok -ne 1 ]]; then
  status="FAIL"
fi

cat > "$OUT" <<EOF
# Release Evidence

- Generated (UTC): $(date -u '+%Y-%m-%d %H:%M:%S UTC')
- Overall: **${status}**

## 1) Test harness

authoritative_status: $([[ $th_ok -eq 1 ]] && echo PASS || echo FAIL)

\`\`\`
${th_out}
\`\`\`

## 2) Production hardening dry-run

authoritative_status: $([[ $hd_ok -eq 1 ]] && echo PASS || echo FAIL)

\`\`\`
${hd_out}
\`\`\`

## 3) Ops brief

authoritative_status: $([[ $ops_ok -eq 1 ]] && echo PASS || echo FAIL)

\`\`\`
${ops_out}
\`\`\`
EOF

echo "$OUT"
[[ "$status" == "PASS" ]]
