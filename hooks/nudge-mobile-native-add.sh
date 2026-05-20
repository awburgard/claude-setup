#!/bin/sh
# _comment: ADVISORY on `pnpm add` inside packages/mobile/. Native deps require EAS Build,
# not OTA. Surface for explicit confirmation + Expo SDK compat check.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')
case "$CMD" in
  *"pnpm add"*|*"pnpm install "*) ;;
  *) exit 0 ;;
esac

# Filter heuristic: command targets packages/mobile (--filter mobile, or run from packages/mobile/).
case "$CMD" in
  *"--filter mobile"*|*"--filter ./packages/mobile"*|*"packages/mobile"*) ;;
  *) exit 0 ;;
esac

printf >&2 'NUDGE: adding a dependency to packages/mobile/.\n'
printf >&2 'Confirm: (1) does this package have native deps (post-install, ios/ android/, react-native peer)?\n'
printf >&2 '         (2) is it compatible with the project Expo SDK pinned version?\n'
printf >&2 'Native deps require EAS Build (not OTA) on next deploy. See rules/07-mobile.md #I.\n'
exit 0
