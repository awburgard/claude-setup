#!/bin/sh
# _comment: SessionStart hook. If ~/.claude/scratch/audit-YYYY-Qn.md exists without
# a sibling .read marker, print a one-line nudge so the quarterly /docs-audit report
# doesn't get forgotten. Stateless: stamp the .read marker after processing.
set -e

SCRATCH=~/.claude/scratch
[ -d "$SCRATCH" ] || exit 0

UNREAD=$(ls "$SCRATCH"/audit-*.md 2>/dev/null | while read -r f; do
  [ -f "$f.read" ] && continue
  echo "$f"
done)

if [ -n "$UNREAD" ]; then
  printf '\033[1;33m[claude]\033[0m Unread audit report(s):\n'
  printf '%s\n' "$UNREAD" | sed 's/^/  - /'
  printf '         Review when convenient; stamp `<file>.read` to clear.\n'
fi

exit 0
