#!/bin/sh
# _comment: HARD BLOCK on `gh pr create` without a fresh subagent self-review marker
# for the current commit. Subagent review is the load-bearing review; PRs cannot open
# until findings JSON exists at HEAD's SHA.
# Disable only if your /pr-create flow ran but failed to write the marker.
# Hook event: PreToolUse on Bash `gh pr create`.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')
case "$CMD" in
  *"gh pr create"*) ;;
  *) exit 0 ;;
esac

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
[ -n "$BRANCH" ] || exit 0
HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
[ -n "$HEAD_SHA" ] || exit 0

MARKER=".claude/scratch/self-review-findings-${BRANCH}.json"
if [ ! -f "$MARKER" ]; then
  printf >&2 'BLOCK: no /self-review marker for branch %s. Run /pr-create (which invokes /self-review) instead.\n' "$BRANCH"
  exit 2
fi

MARKER_SHA=$(jq -r '.commit_sha // ""' < "$MARKER")
STATUS=$(jq -r '.status // ""' < "$MARKER")

if [ "$MARKER_SHA" != "$HEAD_SHA" ]; then
  printf >&2 'BLOCK: stale /self-review marker. Marker SHA=%s; HEAD=%s. Re-run /self-review.\n' "$MARKER_SHA" "$HEAD_SHA"
  exit 2
fi

if [ "$STATUS" != "pass" ]; then
  printf >&2 'BLOCK: /self-review status=%s (must be "pass" to open PR).\n' "$STATUS"
  exit 2
fi

exit 0
