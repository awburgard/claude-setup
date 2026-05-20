#!/bin/sh
# _comment: ADVISORY on `throw new Error` outside programmer-error sites
# (invariant/assert helpers, tool-boundary execute()s, tests).
# Service code should return Result<T, E>, not throw.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$PATH_" in
  *.test.ts|*.test.tsx) exit 0 ;;
  */tools.ts) exit 0 ;;
  */invariant.ts|*/assert.ts|*/result.ts) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

HITS=$(grep -E -n 'throw[[:space:]]+(new[[:space:]]+(Error|TypeError|RangeError)|[a-zA-Z_])' "$PATH_" 2>/dev/null || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s throws outside the programmer-error / tool-boundary carve-out.\n' "$PATH_"
  printf >&2 'Return Result<T, E> instead. See rules/01-typescript.md #4.\n'
  printf '%s\n' "$HITS" | head -3 >&2
fi
exit 0
