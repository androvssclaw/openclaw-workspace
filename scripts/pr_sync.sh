#!/usr/bin/env bash
set -euo pipefail

branch="$(git branch --show-current)"
if [[ "$branch" != "bot/updates-init" ]]; then
  echo "Skip: current branch is $branch"
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "WARN: gh not installed; cannot auto-sync PR"
  exit 0
fi

tmp_body="$(mktemp)"
changed_files="$(git diff --name-only main...bot/updates-init 2>/dev/null || true)"
[[ -z "$changed_files" ]] && changed_files="$(git diff --name-only HEAD~1..HEAD 2>/dev/null || true)"

evidence_file=""
evidence_block=""
if [[ -x "./scripts/release_evidence.sh" ]]; then
  if evidence_file="$(./scripts/release_evidence.sh 2>/dev/null)"; then
    overall="$(grep -E '^- Overall:' "$evidence_file" | sed 's/^- Overall: //')"
    th="$(grep -E '^authoritative_status:' "$evidence_file" | sed -n '1p' | awk '{print $2}')"
    hd="$(grep -E '^authoritative_status:' "$evidence_file" | sed -n '2p' | awk '{print $2}')"
    op="$(grep -E '^authoritative_status:' "$evidence_file" | sed -n '3p' | awk '{print $2}')"
    evidence_block=$(cat <<EOF
### Release evidence
- File: \`${evidence_file}\`
- Overall: ${overall:-unknown}
- test_harness: ${th:-unknown}
- production_hardening_dry_run: ${hd:-unknown}
- ops_brief: ${op:-unknown}
EOF
)
  else
    evidence_block="### Release evidence\n- Failed to generate (see local run: ./scripts/release_evidence.sh)"
  fi
fi

{
  cat .github/PULL_REQUEST_TEMPLATE.md
  echo
  echo "## Auto Summary"
  echo "### Changed files"
  if [[ -n "$changed_files" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && echo "- $f"
    done <<< "$changed_files"
  else
    echo "- (no file diff detected)"
  fi
  echo
  echo "### Risk hints"
  if grep -qE '^(scripts/|\.github/|README\.md|ROADMAP|docs/)' <<< "$changed_files"; then
    echo "- Script/runtime changes present: verify cron/env/exit-codes"
  else
    echo "- Mostly docs/meta changes"
  fi
  if [[ -n "$evidence_block" ]]; then
    echo
    printf '%b\n' "$evidence_block"
  fi
} > "$tmp_body"

if gh pr view --head bot/updates-init --json number >/dev/null 2>&1; then
  num="$(gh pr view --head bot/updates-init --json number -q .number)"
  gh pr edit "$num" --title "bot: workspace updates" --body-file "$tmp_body" >/dev/null || true
  echo "Updated PR #$num"
else
  gh pr create --base main --head bot/updates-init --title "bot: workspace updates" --body-file "$tmp_body" >/dev/null
  echo "Created PR"
fi

rm -f "$tmp_body"
