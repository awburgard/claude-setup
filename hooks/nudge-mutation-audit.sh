#!/bin/sh
# _comment: ADVISORY on in-place mutation outside helpers.ts files.
# Banned methods: .push/.pop/.shift/.unshift/.splice/.sort()/.reverse()/property-assign/delete/bracket-assign.
# Encapsulated mutation inside a pure function (helpers.ts) is allowed.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$PATH_" in
  */helpers.ts) exit 0 ;;
  *.test.ts|*.test.tsx) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

HITS=$(grep -E -n '(\.push\(|\.pop\(|\.shift\(|\.unshift\(|\.splice\(|\.sort\([^),]*\)|\.reverse\(\)|^[[:space:]]*delete[[:space:]]+[A-Za-z_])' "$PATH_" 2>/dev/null || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s appears to use in-place mutation.\n' "$PATH_"
  printf >&2 'Prefer .toSorted/.toReversed/.toSpliced/.with/spread. See rules/04-backend-services.md #5.\n'
  printf '%s\n' "$HITS" | head -5 >&2
fi
exit 0
