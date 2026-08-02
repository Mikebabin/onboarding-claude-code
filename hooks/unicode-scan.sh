#!/usr/bin/env bash
# unicode-scan.sh
# Scans visible files in the working directory for suspicious Unicode:
# - Zero-width characters (U+200B, U+200C, U+200D, U+FEFF)
# - Private Use Area (U+E000–U+F8FF) — often used to hide code
# - Bi-directional overrides (U+202A–U+202E) — can flip code direction
#
# Runs at SessionStart. Exits 0 always (informational).
# Exit 2 is reserved for blocking; this is detection/warning only.

set -o pipefail

# GUI-launch fix: Homebrew isn't on launchd's PATH when Claude Desktop starts from the Dock.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Patterns for dangerous Unicode.
# These are rare in legitimate code and extremely common in supply-chain attacks.

# Zero-width characters
ZW_PATTERN=$'[\u200B\u200C\u200D\u034F\u061C\u180E\uFEFF\u2060\u2061\u2062\u2063\u2064\u2065\u2066\u2067\u2068\u2069\u206A\u206B\u206C\u206D\u206E\u206F]'

# Private Use Area (U+E000–U+F8FF)
PUA_PATTERN=$'[\uE000-\uF8FF]'

# Bi-directional overrides (U+202A–U+202E, U+2066–U+2069)
BIDI_PATTERN=$'[\u202A\u202B\u202C\u202D\u202E\u2066\u2067\u2068\u2069]'

# Scan the working directory (excluding .git, node_modules, .claude, hidden dirs)
FOUND_ISSUES=0
SUSPICIOUS_FILES=()

while IFS= read -r file; do
  # Skip binary files (check for null bytes)
  if file "$file" 2>/dev/null | grep -q 'binary'; then
    continue
  fi

  # Check for zero-width characters
  if grep -q "$ZW_PATTERN" "$file" 2>/dev/null; then
    SUSPICIOUS_FILES+=("$file [zero-width chars]")
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
  fi

  # Check for Private Use Area
  if grep -q "$PUA_PATTERN" "$file" 2>/dev/null; then
    SUSPICIOUS_FILES+=("$file [Private Use Area]")
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
  fi

  # Check for bi-directional overrides
  if grep -q "$BIDI_PATTERN" "$file" 2>/dev/null; then
    SUSPICIOUS_FILES+=("$file [bi-directional override]")
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
  fi
done < <(find . -type f \( -not -path '*/.*' -not -path '*/node_modules/*' -not -path '*/.git/*' \) 2>/dev/null | head -100)

# Report findings
if [ $FOUND_ISSUES -gt 0 ]; then
  OUTPUT='{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "systemMessage": "⚠️ Unicode scan found suspicious patterns in: '"$(printf '%s, ' "${SUSPICIOUS_FILES[@]}" | sed 's/, $//')"'. These are extremely rare in legitimate code. If unexpected, ask before proceeding."
    }
  }'
else
  OUTPUT='{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": "Unicode security scan: no suspicious patterns detected."
    }
  }'
fi

echo "$OUTPUT"
exit 0
