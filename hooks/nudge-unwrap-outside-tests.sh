#!/bin/sh
# _comment: ADVISORY on unwrapOk / .value direct access on Result outside *.test.ts files.
# unwrapOk/assertOk are test-only; production code must isOk-narrow first.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.test.ts|*.test.tsx) exit 0 ;; esac
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

HITS=$(grep -E -n '(\bunwrapOk\(|\bassertOk\(|\bunwrapErr\(|\bassertErr\()' "$PATH_" 2>/dev/null || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s uses unwrapOk/assertOk/unwrapErr/assertErr outside a test file.\n' "$PATH_"
  printf >&2 'Production code should isOk(...)/isErr(...)-narrow. See rules/01-typescript.md #4.\n'
  printf '%s\n' "$HITS" | head -3 >&2
fi
exit 0
