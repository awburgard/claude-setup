#!/bin/sh
# _comment: HARD BLOCK on editing a test file when the corresponding impl file has
# also been changed on this branch vs origin/main, AND the test existed at the branch
# point. This catches "weaken the test to make the new code pass." Tests are spec-bound.
# Override path: touch .claude/scratch/spec-update-active after a Gherkin/spec change.
# Hook event: PreToolUse on Edit/Write/MultiEdit, path glob **/*.test.{ts,tsx}.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

TEST_PATH=$(jq -r '.tool_input.file_path // ""')
case "$TEST_PATH" in
  *.test.ts|*.test.tsx) ;;
  *) exit 0 ;;
esac

# Override marker
if [ -f .claude/scratch/spec-update-active ]; then
  exit 0
fi

# Derive impl sibling
case "$TEST_PATH" in
  *.test.ts)  IMPL="${TEST_PATH%.test.ts}.ts" ;;
  *.test.tsx) IMPL="${TEST_PATH%.test.tsx}.tsx" ;;
esac

# Need git + origin/main to evaluate.
if ! git rev-parse --git-dir >/dev/null 2>&1; then exit 0; fi
if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  if ! git rev-parse --verify origin/master >/dev/null 2>&1; then exit 0; fi
  BASE=origin/master
else
  BASE=origin/main
fi

# Did impl change on this branch?
IMPL_REL=$(git ls-files --full-name -- "$IMPL" 2>/dev/null | head -1)
[ -n "$IMPL_REL" ] || exit 0
if ! git diff --name-only "$BASE"...HEAD -- "$IMPL_REL" 2>/dev/null | grep -q .; then
  exit 0
fi

# Did the test exist at baseline?
TEST_REL=$(git ls-files --full-name -- "$TEST_PATH" 2>/dev/null | head -1)
[ -n "$TEST_REL" ] || exit 0
if ! git ls-tree "$BASE" -- "$TEST_REL" 2>/dev/null | grep -q .; then
  exit 0
fi

printf >&2 'BLOCK: %s\n' "$TEST_PATH"
printf >&2 'Test-edit tripwire: this test existed at branch baseline AND the sibling impl (%s) has changed on this branch.\n' "$IMPL_REL"
printf >&2 'Tests are derived from spec — they are never modified to make code pass.\n'
printf >&2 'If the spec genuinely changed: update the Gherkin/spec first, then `touch .claude/scratch/spec-update-active` to clear this hook.\n'
exit 2
