#!/bin/sh
# _comment: ADVISORY on `^` or `~` version ranges in package.json. Exact pinning per
# rules/08-security-webhooks.md #J. Also flags missing `save-exact=true` in .npmrc.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  */package.json) ;;
  *) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

# Skip workspace protocol references (workspace:* / workspace:^ / workspace:~).
HITS=$(grep -E -n '"[~^][0-9]' "$PATH_" | grep -v 'workspace:' || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s contains caret/tilde version ranges.\n' "$PATH_"
  printf >&2 'Pin exact versions. See rules/08-security-webhooks.md #J. Also ensure .npmrc has `save-exact=true`.\n'
  printf '%s\n' "$HITS" | head -5 >&2
fi
exit 0
