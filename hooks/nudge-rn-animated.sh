#!/bin/sh
# _comment: ADVISORY on `import { Animated } from 'react-native'` under packages/mobile/.
# Use Reanimated v3 instead. See rules/07-mobile.md #C.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *packages/mobile/*) ;; *) exit 0 ;; esac
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

if grep -E -q 'import[[:space:]]+\{[^}]*\bAnimated\b[^}]*\}[[:space:]]+from[[:space:]]+["'\''`]react-native["'\''`]' "$PATH_"; then
  printf >&2 'NUDGE: %s imports Animated from react-native.\n' "$PATH_"
  printf >&2 'Use react-native-reanimated v3 instead. See rules/07-mobile.md #C.\n'
fi
exit 0
