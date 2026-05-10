#!/usr/bin/env bash
# T248: Security audit — scan committed history for accidentally exposed
# secrets. Run periodically (recommended: monthly + before each release).
#
# Exit codes:
#   0  no findings
#   1  potential secret(s) found — review the output
#   2  invocation error (missing tool, bad cwd)
#
# Usage:
#   ./scripts/audit-secrets.sh            # scan tracked files in HEAD
#   ./scripts/audit-secrets.sh --history  # also walk full git history (slow)
#
# Patterns intentionally narrow — false positives waste reviewer attention
# more than they prevent leaks. Adjust as new secret types are introduced.

set -uo pipefail

cd "$(dirname "$0")/.." || { echo "cannot cd to repo root" >&2; exit 2; }

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 2
fi

SCAN_HISTORY=0
if [[ "${1:-}" == "--history" ]]; then
  SCAN_HISTORY=1
fi

found=0
red() { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }

check() {
  local label="$1" pattern="$2" exclude="$3"
  printf "▸ %-32s " "$label"

  local cmd
  if [[ "$SCAN_HISTORY" -eq 1 ]]; then
    cmd="git log --all -p -G '$pattern'"
  else
    cmd="git grep -nE '$pattern'"
  fi

  local output
  output=$(eval "$cmd" 2>/dev/null | grep -vE "$exclude" || true)
  if [[ -n "$output" ]]; then
    red "FAIL"
    echo "$output" | head -10
    found=$((found + 1))
  else
    green "ok"
  fi
}

# AWS access key
check "AWS access key" \
  'AKIA[0-9A-Z]{16}' \
  '^$'

# OpenAI / generic api keys with sk- prefix and length
check "OpenAI / sk- prefixed key" \
  'sk-[a-zA-Z0-9]{30,}' \
  '^$'

# Real-looking JWT secrets (filtered for placeholder values)
check "JWT_SECRET literal value" \
  'JWT_SECRET\s*[:=]\s*[\"\x27][A-Za-z0-9+/]{30,}' \
  'change-me|your-secret|test|example|unused|ci-only'

# 42 OAuth client/secret IDs (real format includes hex hash 40+ chars)
check "42 OAuth real-looking ID" \
  '(u|s)-s4t2ud-[a-f0-9]{40,}' \
  '^$'

# Generic Bearer tokens that look like real JWTs (≥3 base64 segments)
check "Bearer token (live JWT shape)" \
  'Bearer\s+[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}' \
  'test|fake|stub|example'

# Private key blocks
check "Private key blocks" \
  '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  '^$'

# Committed .env files (anything beyond .env.example is suspicious)
printf "▸ %-32s " "Committed .env files"
env_files=$(git ls-files | grep -E '\.env(\.[a-z]+)?$' | grep -v '\.example$' || true)
if [[ -n "$env_files" ]]; then
  red "FAIL"
  echo "$env_files"
  found=$((found + 1))
else
  green "ok"
fi

echo
if [[ "$found" -eq 0 ]]; then
  if [[ "$SCAN_HISTORY" -eq 1 ]]; then
    green "✓ No secrets detected (scope: full git history)."
  else
    green "✓ No secrets detected (scope: tracked files in HEAD)."
  fi
  exit 0
else
  red "✗ $found pattern(s) flagged. Review above."
  echo
  echo "Next steps:"
  echo "  1. If false positive: tighten the pattern or add to exclusion."
  echo "  2. If real leak:"
  echo "     a) Rotate the secret immediately at the source (42 intra, AWS, etc)"
  echo "     b) Purge from history: git-filter-repo or BFG (see GitHub docs)"
  echo "     c) Force-push (risky — coordinate with team)"
  exit 1
fi
