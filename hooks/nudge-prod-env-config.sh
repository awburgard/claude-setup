#!/bin/sh
# _comment: ADVISORY on edits to wrangler.jsonc/wrangler.toml that touch [env.production]
# / "production":. These are production config changes; double-check before committing.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *wrangler.jsonc|*wrangler.toml|*wrangler.json) ;;
  *) exit 0 ;;
esac

OLD=$(jq -r '.tool_input.old_string // ""' 2>/dev/null || true)
NEW=$(jq -r '.tool_input.new_string // ""' 2>/dev/null || true)
CONTENT=$(jq -r '.tool_input.content // ""' 2>/dev/null || true)
if printf '%s%s%s\n' "$OLD" "$NEW" "$CONTENT" | grep -E -q '(\[env\.production\]|"production"[[:space:]]*:)'; then
  printf >&2 'NUDGE: %s edits production config in %s.\n' "$TOOL_NAME" "$PATH_"
  printf >&2 'Confirm the change is intentional. See rules/09-infra.md.\n'
fi
exit 0
