#!/bin/sh
# _comment: HARD BLOCK on `git push ... main` and `gh pr merge ... main` direct merges.
# Pushes to main go via merged PRs only. Disable only if you are intentionally
# bypassing PR review (you should not).
# Hook event: PreToolUse on Bash matching push/merge against main.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')

# git push to main
if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+push([[:space:]]+--[A-Za-z-]+)*[[:space:]]+[A-Za-z0-9_./-]+[[:space:]]+(main|master)([[:space:]]|$)'; then
  printf >&2 'BLOCK: direct push to main is forbidden. Open a PR.\n'
  exit 2
fi
# git push HEAD:main / : main
if printf '%s\n' "$CMD" | grep -E -q 'git[[:space:]]+push.*(:main([[:space:]]|$)|:master([[:space:]]|$))'; then
  printf >&2 'BLOCK: direct push to main is forbidden. Open a PR.\n'
  exit 2
fi
# gh pr merge of main is not a thing, but `gh api ... merge` against main shouldn't happen
if printf '%s\n' "$CMD" | grep -E -q 'gh[[:space:]]+api[[:space:]]+.*pulls/[0-9]+/merge.*"base"[[:space:]]*:[[:space:]]*"(main|master)"'; then
  printf >&2 'BLOCK: merging via gh api against main is forbidden. Use gh pr merge with a PR number.\n'
  exit 2
fi

exit 0
