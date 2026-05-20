#!/bin/sh
# _comment: ADVISORY on inline anonymous object types in TS positions. Every shape should
# be a named `type`. Disable only if a specific lib's typing forces inline objects (rare).
# Hook event: PostToolUse on Edit/Write/MultiEdit (.ts/.tsx).
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

# Heuristic patterns: function signatures with inline object params/returns, const annotations.
HITS=$(grep -E -n '(:[[:space:]]*\{[^}]*[a-zA-Z][^}]*\})|(=>[[:space:]]*\{[[:space:]]*[a-zA-Z_]+[[:space:]]*:)' "$PATH_" 2>/dev/null || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s appears to use inline object types. See rules/01-typescript.md #1.\n' "$PATH_"
  printf '%s\n' "$HITS" | head -5 >&2
fi
exit 0
