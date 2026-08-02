#!/usr/bin/env bash
# unicode-scan.sh
# Scans visible files in the working directory for suspicious Unicode:
# - Zero-width characters (U+200B, U+200C, U+200D, U+FEFF, ...)
# - Private Use Area (U+E000-U+F8FF) - often used to hide code
# - Bi-directional overrides (U+202A-U+202E, U+2066-U+2069) - can flip code direction
#
# Runs at SessionStart. Exits 0 always (informational).
# Exit 2 is reserved for blocking; this is detection/warning only.
#
# NOTE: matching is done in perl, not bash. macOS ships bash 3.2, where $'\uXXXX'
# escapes do NOT expand (they were added in bash 4.2) - the pattern stays as the
# literal characters backslash-u-2-0-0-B and so on, which collapses into the ASCII bracket set
# {\, u, 0-9, A-F} and therefore matches essentially every text file. perl lives
# at /usr/bin/perl on every mac and supports \x{...} directly, so the patterns
# below mean what they say regardless of bash version.

set -o pipefail

# GUI-launch fix: Homebrew isn't on launchd's PATH when Claude Desktop starts from the Dock.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Scan the working directory (excluding .git, node_modules, hidden dirs), first 100 files.
FINDINGS="$(
  find . -type f \( -not -path '*/.*' -not -path '*/node_modules/*' -not -path '*/.git/*' \) 2>/dev/null \
    | head -100 \
    | tr '\n' '\0' \
    | xargs -0 perl -e '
use strict;
use warnings;
use Encode qw(decode);

# Rare in legitimate code, extremely common in supply-chain attacks.
my $ZW   = qr/[\x{200B}\x{200C}\x{200D}\x{034F}\x{061C}\x{180E}\x{FEFF}\x{2060}-\x{2064}\x{206A}-\x{206F}]/;
my $PUA  = qr/[\x{E000}-\x{F8FF}]/;
my $BIDI = qr/[\x{202A}-\x{202E}\x{2066}-\x{2069}]/;

for my $f (@ARGV) {
    open my $fh, "<:raw", $f or next;
    my $raw = do { local $/; <$fh> };
    close $fh;
    next unless defined $raw && length $raw;
    next if index($raw, "\0") >= 0;                      # binary
    my $t = eval { decode("UTF-8", $raw, Encode::FB_CROAK) };
    next unless defined $t;                              # not valid UTF-8

    print "$f [zero-width chars]\n"        if $t =~ $ZW;
    print "$f [Private Use Area]\n"        if $t =~ $PUA;
    print "$f [bi-directional override]\n" if $t =~ $BIDI;
}
' 2>/dev/null
)"

# Escape a string for embedding in a JSON string literal.
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' '
}

# Report findings
if [ -n "$FINDINGS" ]; then
  LIST="$(printf '%s' "$FINDINGS" | tr '\n' '@' | sed -e 's/@$//' -e 's/@/, /g')"
  MSG="Unicode scan found suspicious patterns in: $(json_escape "$LIST"). These are extremely rare in legitimate code. If unexpected, ask before proceeding."
  OUTPUT='{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "systemMessage": "'"$MSG"'"
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
