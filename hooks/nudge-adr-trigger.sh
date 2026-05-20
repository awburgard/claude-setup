#!/bin/sh
# _comment: ADVISORY surfacing ADR triggers at edit time. Catches first-adoption of
# XState/DO/Workflow/Queue/pgvector, compatibility_date bumps (also nudge-compatibility-date),
# and major-version bumps on Tier-2 libs. See sops/adr-trigger-check.md.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')

OLD=$(jq -r '.tool_input.old_string // ""' 2>/dev/null || true)
NEW=$(jq -r '.tool_input.new_string // ""' 2>/dev/null || true)
CONTENT=$(jq -r '.tool_input.content // ""' 2>/dev/null || true)
DIFF="$OLD$NEW$CONTENT"

# First-adoption heuristic — only nudge when an import is newly added.
case "$PATH_" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Trigger (a): import lines for XState, DOs, Workflows, Queues, pgvector.
if printf '%s\n' "$NEW$CONTENT" | grep -E -q "import[[:space:]]+.*from[[:space:]]+['\"](xstate|@cloudflare/workers-types.*\\bDurableObject\\b|@cloudflare/workers-types.*\\bWorkflow\\b|@cloudflare/workers-types.*\\bQueue\\b|drizzle-orm/pg-vector|pgvector)['\"]"; then
  printf >&2 'NUDGE: %s appears to introduce a major library/pattern (XState / DO / Workflow / Queue / pgvector).\n' "$PATH_"
  printf >&2 'ADR-worthy (trigger a). Capture via `/adr` or note in .claude/scratch/pending-adrs.md.\n'
fi

exit 0
