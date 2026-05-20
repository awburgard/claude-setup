#!/bin/sh
# _comment: ADVISORY when @anthropic-ai/sdk is imported without a preceding `// Escape:` comment.
# Vercel AI SDK is the default; @anthropic-ai/sdk is the escape hatch and must be marked.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

if ! grep -q '@anthropic-ai/sdk' "$PATH_"; then exit 0; fi

# For every import line referencing @anthropic-ai/sdk, check the preceding line for `// Escape:`.
awk '
  /from[[:space:]]+["'\''`]@anthropic-ai\/sdk/ {
    if (prev !~ /\/\/[[:space:]]*Escape:/) {
      print NR ": " $0
      bad = 1
    }
  }
  { prev = $0 }
  END { exit bad }
' "$PATH_" >/dev/null
if [ $? -ne 0 ]; then
  printf >&2 'NUDGE: %s imports @anthropic-ai/sdk without a preceding `// Escape: <feature>` comment.\n' "$PATH_"
  printf >&2 'See rules/05-ai-agents.md #1.\n'
fi
exit 0
