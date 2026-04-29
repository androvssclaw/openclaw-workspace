#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== git sanitize check ==="

echo "[1/3] Blocked paths present in git index/worktree?"
blocked_regex='(^|/)(\.openclaw/|state/|backups/|\.env($|\.)|.*\.(key|pem|p12|pfx|ovpn|wgconf)$)'

violations="$(git ls-files -co --exclude-standard | grep -E "$blocked_regex" || true)"
if [[ -n "$violations" ]]; then
  echo "FAIL: blocked files detected:"
  echo "$violations"
  exit 1
fi
echo "OK"

echo "[2/3] Quick secret-pattern scan (tracked + staged)"
files="$(git diff --cached --name-only; git ls-files)"
if [[ -n "$files" ]]; then
  if grep -RInE --exclude-dir=.git '(AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|oauth|token\s*=|api[_-]?key\s*=|client_secret\s*=|Authorization:\s*Bearer\s+)' $(echo "$files" | sort -u) >/tmp/git_sanitize_hits.txt 2>/dev/null; then
    echo "WARN: possible secrets found:"
    sed -n '1,40p' /tmp/git_sanitize_hits.txt
    exit 2
  fi
fi
echo "OK"

echo "[3/3] git status"
git status --short

echo "PASS: sanitize check complete"
