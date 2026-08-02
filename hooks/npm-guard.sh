#!/usr/bin/env bash
# npm-guard.sh — Claude Code PreToolUse(Bash) hook
# Blocks high-risk npm/npx/pnpm/yarn patterns and pipe-to-shell downloads.
# Exit 2 => Claude is blocked and sees stderr. Exit 0 => allowed.
# Safe on every Bash call: exits 0 immediately for non-package-manager commands.
set -euo pipefail

# GUI-launch fix: Claude Desktop started from the Dock inherits launchd's PATH,
# which lacks Homebrew. Without this line, jq/node below silently aren't found.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

INPUT="$(cat)"

# Extract the command. Prefer jq; fall back to node; else grep the raw JSON.
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"
elif command -v node >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write((JSON.parse(s).tool_input||{}).command||"")}catch(e){process.stdout.write("")}})')"
else
  CMD="$INPUT"
fi

block() {
  echo "[npm-guard] BLOCKED: $1" >&2
  echo "[npm-guard] Command: $CMD" >&2
  echo "[npm-guard] If this is intentional, ask Mike or run it yourself in a terminal." >&2
  exit 2
}

# General guard (applies to ALL commands): curl/wget piped straight into a shell.
printf '%s' "$CMD" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sh|bash|node)\b' \
  && block "pipe-to-shell download. Fetch, inspect, then run."

# Fast exit for anything that isn't a package manager.
printf '%s' "$CMD" | grep -Eq '\b(npm|npx|pnpm|yarn)\b' || exit 0

# 1) Blanket updates pull poisoned releases under caret/tilde ranges.
printf '%s' "$CMD" | grep -Eq '\b(npm (update|up)|pnpm up(date)?|yarn up(grade)?)\b' \
  && block "blanket dependency update. Pin exact versions instead."

# 1b) npm audit fix is a blanket update in disguise: it bumps versions automatically.
printf '%s' "$CMD" | grep -Eq '\bnpm audit fix\b' \
  && block "'npm audit fix' auto-bumps versions. Run 'npm audit' to review, then pin fixes explicitly."

# 2) Global installs broaden blast radius and bypass project lockfiles.
printf '%s' "$CMD" | grep -Eq '\bnpm (i|install|add) +.*(-g|--global)\b|\bnpm (i|install|add) +-[a-zA-Z]*g\b|\bpnpm add +.*-g\b|\byarn global add\b' \
  && block "global install. Install into the project with a pinned version."

# 3) Custom/alternate registries are a registry-swap / typosquat vector.
printf '%s' "$CMD" | grep -Eq -- '--registry(=| )|//[^ ]*:_authToken|set +registry' \
  && block "custom registry or inline auth token in the command line."

# 4) Re-enabling install scripts inline defeats the .npmrc protection.
printf '%s' "$CMD" | grep -Eq -- '--ignore-scripts=false|--foreground-scripts|--unsafe-perm' \
  && block "command re-enables install scripts. Allow them via a project .npmrc instead."

exit 0
