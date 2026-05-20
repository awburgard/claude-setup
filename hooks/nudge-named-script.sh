#!/bin/sh
# _comment: ADVISORY on raw `wrangler`, `drizzle-kit`, `supabase`, or `pnpm --filter` calls
# at the shell. Everything goes through top-level scripts. See rules/09-infra.md "Named scripts".
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0
CMD=$(jq -r '.tool_input.command // ""')

# Allow when explicitly invoked from a pnpm/npm script (we can't fully detect this; we approximate
# by checking that the wrapper isn't already inside `pnpm run` chain — heuristic).
if printf '%s\n' "$CMD" | grep -E -q '(^|[[:space:];&|])(wrangler|drizzle-kit|supabase)([[:space:]]|$)'; then
  printf >&2 'NUDGE: %s\n' "$CMD"
  printf >&2 'Use the top-level script (pnpm dev / pnpm db:migrate / pnpm deploy:* etc.) instead.\n'
  printf >&2 'See rules/09-infra.md "Named scripts".\n'
fi

if printf '%s\n' "$CMD" | grep -E -q 'pnpm[[:space:]]+(--filter|-F)[[:space:]]'; then
  printf >&2 'NUDGE: raw `pnpm --filter` invocation. Add a top-level alias and use that instead.\n'
fi
exit 0
