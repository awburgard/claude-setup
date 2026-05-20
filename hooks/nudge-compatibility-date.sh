#!/bin/sh
# _comment: ADVISORY on edits to `compatibility_date` in wrangler.jsonc/wrangler.toml.
# Compatibility-date bumps are ADR-worthy (trigger b). See sops/adr-trigger-check.md.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *wrangler.jsonc|*wrangler.toml|*wrangler.json) ;;
  *) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

# Detect that this edit touches compatibility_date.
OLD=$(jq -r '.tool_input.old_string // ""' 2>/dev/null || true)
NEW=$(jq -r '.tool_input.new_string // ""' 2>/dev/null || true)
if printf '%s%s\n' "$OLD" "$NEW" | grep -q 'compatibility_date'; then
  printf >&2 'NUDGE: %s edits compatibility_date. ADR-worthy (trigger b).\n' "$PATH_"
  printf >&2 'Capture via `/adr` now or add to .claude/scratch/pending-adrs.md.\n'
fi
exit 0
