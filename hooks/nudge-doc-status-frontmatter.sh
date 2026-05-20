#!/bin/sh
# _comment: ADVISORY (PostToolUse) when a file under initiatives/ or docs/adr/ is written
# without a Status frontmatter field. See rules/10-workflow.md "Doc-keeping discipline".
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *initiatives/*.md|*docs/adr/*.md) ;;
  *) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

# Frontmatter expected at top of file: three lines starting with ---, including a Status: line.
HEAD=$(head -10 "$PATH_")
if printf '%s\n' "$HEAD" | head -1 | grep -q '^---'; then
  if ! printf '%s\n' "$HEAD" | grep -E -q '^Status:[[:space:]]*(Active|Proposed|Accepted|Shipped|Cancelled|Superseded[[:space:]]+by:|Deprecated)'; then
    printf >&2 'NUDGE: %s has frontmatter but no Status field. Add `Status: Active|Proposed|Accepted|Shipped|Cancelled|Superseded by: <link>|Deprecated`.\n' "$PATH_"
  fi
else
  printf >&2 'NUDGE: %s has no frontmatter. Add a YAML frontmatter with a Status field. See rules/10-workflow.md.\n' "$PATH_"
fi
exit 0
