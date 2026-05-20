#!/bin/sh
# _comment: HARD BLOCK on npm/yarn/bun invocations. pnpm is the only package manager.
# Mixing managers corrupts lockfiles and node_modules layout.
# Disable only if a third-party tool genuinely requires npm (call it out in PR description).
# Hook event: PreToolUse on Bash.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')

# Match npm/yarn/bun at start of a command segment.
# Allow `npm run` only if it's calling into pnpm via a script — but realistically, just block.
# Also allow `npx --` invocations of one-off CLIs (we still mostly want this routed through pnpm dlx).
if printf '%s\n' "$CMD" | grep -E -q '(^|[[:space:];&|]|^\s*)(npm|yarn|bun)([[:space:]]|$)'; then
  printf >&2 'BLOCK: %s invokes a non-pnpm package manager. Use pnpm.\n' "$CMD"
  printf >&2 'For one-off binaries, use `pnpm dlx <pkg>` instead of `npx`.\n'
  exit 2
fi

exit 0
