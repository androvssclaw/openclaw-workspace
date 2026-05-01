#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT}/state"
mkdir -p "$STATE_DIR"

HISTORY_FILE="${STATE_DIR}/quality-trend-history.tsv"
OUT_FILE="${STATE_DIR}/quality-trend-$(date -u +%G-%V).md"
LAST_ALERT_WEEK_FILE="${STATE_DIR}/quality-trend-last-alert-week.txt"

ALERT_CHANNEL="${ALERT_CHANNEL:-telegram}"
ALERT_TARGET="${ALERT_TARGET:-160093873}"

week="$(date -u +%G-%V)"
ts="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

latest_evidence="$(ls -1t "${STATE_DIR}"/release-evidence-*.md 2>/dev/null | head -n1 || true)"
if [[ -z "$latest_evidence" ]]; then
  echo "No release evidence found. Run ./scripts/release_evidence.sh first."
  exit 1
fi

overall="$(grep -E '^- Overall:' "$latest_evidence" | sed 's/^- Overall: //' | tr -d '*')"
th="$(grep -E '^authoritative_status:' "$latest_evidence" | sed -n '1p' | awk '{print $2}')"
hd="$(grep -E '^authoritative_status:' "$latest_evidence" | sed -n '2p' | awk '{print $2}')"
op="$(grep -E '^authoritative_status:' "$latest_evidence" | sed -n '3p' | awk '{print $2}')"

score=0
[[ "$th" == "PASS" ]] && score=$((score+1))
[[ "$hd" == "PASS" ]] && score=$((score+1))
[[ "$op" == "PASS" ]] && score=$((score+1))

if [[ ! -f "$HISTORY_FILE" ]]; then
  echo -e "week\ttimestamp\toverall\ttest_harness\thardening\tops_brief\tscore" > "$HISTORY_FILE"
fi

# upsert current week
if grep -q "^${week}\t" "$HISTORY_FILE"; then
  awk -F'\t' -v OFS='\t' -v w="$week" -v t="$ts" -v o="$overall" -v thv="$th" -v hdv="$hd" -v opv="$op" -v sc="$score" 'NR==1{print;next} $1==w{$1=w;$2=t;$3=o;$4=thv;$5=hdv;$6=opv;$7=sc} {print}' "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
  mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
else
  echo -e "${week}\t${ts}\t${overall}\t${th}\t${hd}\t${op}\t${score}" >> "$HISTORY_FILE"
fi

prev_line="$(awk -F'\t' 'NR>1{print}' "$HISTORY_FILE" | tail -n2 | head -n1 || true)"
prev_week=""; prev_score=""
if [[ -n "$prev_line" ]]; then
  prev_week="$(awk -F'\t' '{print $1}' <<< "$prev_line")"
  prev_score="$(awk -F'\t' '{print $7}' <<< "$prev_line")"
fi

degraded=0
reason=""
if [[ -n "$prev_score" && "$score" -lt "$prev_score" ]]; then
  degraded=1
  reason="score dropped ${prev_score} -> ${score}"
fi

{
  echo "# Quality Trend Weekly"
  echo "Generated: ${ts}"
  echo
  echo "- Week: ${week}"
  echo "- Latest evidence: ${latest_evidence}"
  echo "- Overall: ${overall}"
  echo "- test_harness: ${th}"
  echo "- production_hardening_dry_run: ${hd}"
  echo "- ops_brief: ${op}"
  echo "- Score: ${score}/3"
  if [[ -n "$prev_week" ]]; then
    echo "- Previous week: ${prev_week} (score ${prev_score})"
  fi
  echo
  echo "## Trend history"
  tail -n 8 "$HISTORY_FILE"
  if [[ $degraded -eq 1 ]]; then
    echo
    echo "## Degradation"
    echo "- ${reason}"
  fi
} > "$OUT_FILE"

if [[ $degraded -eq 1 ]]; then
  last_alert_week=""
  [[ -f "$LAST_ALERT_WEEK_FILE" ]] && last_alert_week="$(cat "$LAST_ALERT_WEEK_FILE" 2>/dev/null || true)"
  if [[ "$last_alert_week" != "$week" ]]; then
    msg="⚠️ Quality trend degraded (${reason})\nWeek: ${week}\nEvidence: ${latest_evidence}\nReport: ${OUT_FILE}"
    openclaw message send --channel "$ALERT_CHANNEL" --target "$ALERT_TARGET" --message "$msg" >/dev/null
    echo "$week" > "$LAST_ALERT_WEEK_FILE"
  fi
fi

echo "Saved: $OUT_FILE"
