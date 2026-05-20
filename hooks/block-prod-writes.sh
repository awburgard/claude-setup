#!/bin/sh
# _comment: HARD BLOCK on commands that write to production / linked environments:
# `--env production`, `--linked`, `drizzle-kit push`, `:prod` script suffixes.
# Override: include the literal string "production confirmed" in the most recent user
# turn (Claude can read this from context — surface in chat and ask the user).
# Hook event: PreToolUse on Bash.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')

# Block patterns
if printf '%s\n' "$CMD" | grep -E -q '(--env[[:space:]]+production|--linked([[:space:]]|$)|drizzle-kit[[:space:]]+push|pnpm[[:space:]]+[A-Za-z0-9:_-]*:prod([[:space:]]|$))'; then
  # Allow `pnpm deploy:prod` explicitly only when the user has confirmed.
  # The harness should surface this; the hook stays strict.
  printf >&2 'BLOCK: %s\n' "$CMD"
  printf >&2 'This command writes to production or a linked environment.\n'
  printf >&2 'Use `pnpm deploy:prod` only via the migration workflow gate, or after explicit user confirmation in this turn.\n'
  exit 2
fi

exit 0
