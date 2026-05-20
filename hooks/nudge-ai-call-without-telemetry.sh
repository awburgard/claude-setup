#!/bin/sh
# _comment: ADVISORY on Vercel AI SDK calls (generateText/streamText/generateObject/
# streamObject/embed) without `experimental_telemetry` configured. See rules/05-ai-agents.md #4.
# Querencia opts out via OBSERVABILITY=none — that's project-level, not file-level.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

# Look for AI SDK call sites in this file.
if ! grep -E -q '\b(generateText|streamText|generateObject|streamObject|embed)\(' "$PATH_"; then
  exit 0
fi

# Confirm telemetry block exists somewhere in the same file.
if ! grep -E -q 'experimental_telemetry' "$PATH_"; then
  printf >&2 'NUDGE: %s appears to call the Vercel AI SDK without experimental_telemetry.\n' "$PATH_"
  printf >&2 'Add `experimental_telemetry: { isEnabled: true, functionId: "<feature>.<method>", metadata: { userId } }`.\n'
  printf >&2 'See rules/05-ai-agents.md #4.\n'
fi
exit 0
