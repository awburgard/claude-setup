#!/bin/sh
# _comment: HARD BLOCK on `gh pr create` if `pnpm typecheck` or `pnpm lint` fails.
# Belt-and-suspenders to the subagent chain: this is the deterministic compiler-checkable gate.
# Disable only if you intentionally want to open a draft PR with known-broken types
# (then call `gh pr create --draft` and run with the hook disabled for that invocation).
# Hook event: PreToolUse on Bash `gh pr create`.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')
case "$CMD" in
  *"gh pr create"*) ;;
  *) exit 0 ;;
esac

# Skip if it's an explicit draft + user has flagged the override.
case "$CMD" in
  *"--draft"*)
    # Drafts skip the gate. Drafts must still pass the subagent marker check (separate hook).
    exit 0
    ;;
esac

if ! command -v pnpm >/dev/null 2>&1; then
  exit 0
fi

if ! pnpm typecheck >/tmp/.claude-typecheck.log 2>&1; then
  printf >&2 'BLOCK: pnpm typecheck failed. Output:\n'
  tail -50 /tmp/.claude-typecheck.log >&2
  exit 2
fi

if ! pnpm lint >/tmp/.claude-lint.log 2>&1; then
  printf >&2 'BLOCK: pnpm lint failed. Output:\n'
  tail -50 /tmp/.claude-lint.log >&2
  exit 2
fi

exit 0
