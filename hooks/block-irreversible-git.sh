#!/bin/sh
# _comment: HARD BLOCK on irreversible git/filesystem ops:
#   rm -rf, git reset --hard, git push --force / --force-with-lease, git branch -D,
#   git clean -fd, git checkout -- (discard), git restore --staged --worktree --source=...
# These overwrite local work or upstream history. Disable only when the user explicitly
# authorizes the specific destructive op in the current turn.
# Hook event: PreToolUse on Bash.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')

block() {
  printf >&2 'BLOCK: %s\n' "$CMD"
  printf >&2 'Irreversible operation: %s.\n' "$1"
  printf >&2 'Ask the user for explicit confirmation before retrying.\n'
  exit 2
}

# rm -rf (anywhere except node_modules / .next / dist / build / coverage etc — but a hook
# can't reliably whitelist those, so we err on the side of blocking).
if printf '%s\n' "$CMD" | grep -E -q '(^|[[:space:];&|])rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f|-[A-Za-z]*f[A-Za-z]*r|--recursive[[:space:]]+--force|-rf|-fr)'; then
  case "$CMD" in
    *"node_modules"*|*".next"*|*"dist"*|*"build"*|*"coverage"*|*".turbo"*|*".vite"*|*".wrangler"*) ;;
    *) block "rm -rf" ;;
  esac
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+reset[[:space:]]+(--hard|--keep)'; then
  block "git reset --hard"
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+push[[:space:]]+.*(--force([[:space:]]|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))'; then
  block "git push --force"
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+branch[[:space:]]+-D'; then
  block "git branch -D"
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+clean[[:space:]]+(-f|.*-[A-Za-z]*f[A-Za-z]*d|.*-[A-Za-z]*d[A-Za-z]*f)'; then
  block "git clean -fd"
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+checkout[[:space:]]+--[[:space:]]'; then
  block "git checkout -- (discard worktree)"
fi

if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+restore[[:space:]]+--(worktree|staged|source)'; then
  block "git restore --worktree/--staged"
fi

exit 0
