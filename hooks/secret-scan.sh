#!/usr/bin/env bash
# secret-scan.sh — Claude Code PreToolUse hook (register on BOTH matchers):
#   matcher "Bash":            scans commands for token literals and credential-file access
#   matcher "Read|Edit|Write": scans file paths for credential/secret files
# One script handles both by checking which field is present in the input.
# Exit 2 => blocked; Exit 0 => allowed.
set -euo pipefail

# GUI-launch fix: Homebrew isn't on launchd's PATH when Claude Desktop starts from the Dock.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

INPUT="$(cat)"

if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')"
elif command -v node >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write((JSON.parse(s).tool_input||{}).command||"")}catch(e){process.stdout.write("")}})')"
  FILE_PATH="$(printf '%s' "$INPUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write((JSON.parse(s).tool_input||{}).file_path||"")}catch(e){process.stdout.write("")}})')"
else
  CMD="$INPUT"
  FILE_PATH=""
fi

block() {
  echo "[secret-scan] BLOCKED: $1" >&2
  exit 2
}

# ---- File-tool guard (Read/Edit/Write): block credential/secret file paths ----
if [ -n "$FILE_PATH" ]; then
  # Expand ~ for matching
  FILE_PATH="${FILE_PATH/#\~/$HOME}"
  if printf '%s' "$FILE_PATH" | grep -Eq '(^|/)\.env(\.[A-Za-z0-9._-]+)?$|/\.aws/|/\.ssh/|/\.kube/|/\.gnupg/|credentials|id_rsa|id_ed25519|\.pem$|\.gpg$|_token|token_|\.netrc$'; then
    block "'$FILE_PATH' looks like a credential/secret file. If access is genuinely needed, ask Mike — don't work around this."
  fi
fi

# ---- Bash guard: token literals and credential-file access via commands ----
if [ -n "$CMD" ]; then
  printf '%s' "$CMD" | grep -Eq '(ghp_|gho_|ghu_|ghs_|github_pat_)[A-Za-z0-9_]{20,}' \
    && block "GitHub token literal in command. Use a credential helper / env var."
  printf '%s' "$CMD" | grep -Eq 'npm_[A-Za-z0-9]{36,}' \
    && block "npm token literal in command."
  printf '%s' "$CMD" | grep -Eq 'AKIA[0-9A-Z]{16}|aws_secret_access_key' \
    && block "AWS credential literal in command."
  printf '%s' "$CMD" | grep -Eq 'sk-(ant-)?[A-Za-z0-9_-]{20,}' \
    && block "API key literal in command."
  printf '%s' "$CMD" | grep -Eq '(cat|less|head|tail|cp|scp|curl|nc)[^|;&]*(\.npmrc|\.env|\.aws/credentials|id_rsa|\.ssh/)' \
    && block "command touches a credential file. Confirm this is intended."
fi

exit 0
