#!/bin/bash

# Auto-Dev Stop Hook
# Prevents session exit when auto-dev is active
# Continues the autonomous development loop until completion

set -euo pipefail

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if auto-dev is active
AUTO_DEV_STATE_FILE=".claude/auto-dev.local.md"

if [[ ! -f "$AUTO_DEV_STATE_FILE" ]]; then
  # No active session - allow exit
  exit 0
fi

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$AUTO_DEV_STATE_FILE")

# Extract key fields
ITERATION=$(echo "$FRONTMATTER" | grep '^total_iterations:' | sed 's/total_iterations: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_total_iterations:' | sed 's/max_total_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
CURRENT_PHASE=$(echo "$FRONTMATTER" | grep '^current_phase:' | sed 's/current_phase: *//' | sed 's/^"\(.*\)"$/\1/')
FEATURE_NAME=$(echo "$FRONTMATTER" | grep '^feature_name:' | sed 's/feature_name: *//' | sed 's/^"\(.*\)"$/\1/')
SESSION_ID=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: Auto-dev state file corrupted (iteration: '$ITERATION')" >&2
  echo "Auto-dev loop stopping. Run /auto-dev again to start fresh." >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: Auto-dev state file corrupted (max_iterations: '$MAX_ITERATIONS')" >&2
  echo "Auto-dev loop stopping. Run /auto-dev again to start fresh." >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Auto-dev: Max iterations ($MAX_ITERATIONS) reached."
  echo "Session: $SESSION_ID"
  echo "Feature: $FEATURE_NAME"
  echo "Final phase: $CURRENT_PHASE"
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Warning: Auto-dev transcript not found" >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Warning: No assistant messages in transcript" >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "Warning: Failed to extract assistant message" >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Parse JSON to get text content
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1)

if [[ $? -ne 0 ]] || [[ -z "$LAST_OUTPUT" ]]; then
  echo "Warning: Failed to parse assistant message" >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Check for completion promise
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Auto-dev complete: <promise>$COMPLETION_PROMISE</promise>"
    echo "Session: $SESSION_ID"
    echo "Feature: $FEATURE_NAME"
    echo "Total iterations: $ITERATION"
    rm "$AUTO_DEV_STATE_FILE"
    exit 0
  fi
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Extract the prompt section (everything after closing ---)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$AUTO_DEV_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Warning: No prompt found in state file" >&2
  rm "$AUTO_DEV_STATE_FILE"
  exit 0
fi

# Update iteration in frontmatter
TEMP_FILE="${AUTO_DEV_STATE_FILE}.tmp.$$"
sed "s/^total_iterations: .*/total_iterations: $NEXT_ITERATION/" "$AUTO_DEV_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$AUTO_DEV_STATE_FILE"

# Build system message with phase info
SYSTEM_MSG="Auto-dev iteration $NEXT_ITERATION | Phase: $CURRENT_PHASE | Feature: $FEATURE_NAME | To complete: <promise>$COMPLETION_PROMISE</promise>"

# Output JSON to block the stop and continue the loop
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
