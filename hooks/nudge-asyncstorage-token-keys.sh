#!/bin/sh
# _comment: ADVISORY on AsyncStorage.setItem with token-shaped keys under packages/mobile/.
# Tokens/JWT/secrets belong in expo-secure-store; AsyncStorage is non-sensitive cache only.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *packages/mobile/*) ;; *) exit 0 ;; esac
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

HITS=$(grep -E -n 'AsyncStorage\.setItem\([[:space:]]*["'\''`]([^"'\''`]*?(token|auth|jwt|secret|password|refresh)[^"'\''`]*)["'\''`]' "$PATH_" -i 2>/dev/null || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s writes a token-shaped key to AsyncStorage.\n' "$PATH_"
  printf >&2 'Use expo-secure-store for tokens/JWT/secrets. See rules/07-mobile.md #B.\n'
  printf '%s\n' "$HITS" | head -3 >&2
fi
exit 0
