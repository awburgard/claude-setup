#!/bin/sh
# _comment: HARD BLOCK on creating a Drizzle pgTable without enableRowLevelSecurity()
# in the same module. RLS-as-floor is non-negotiable; a table without RLS is a tenant
# isolation breach waiting to happen.
# Disable only if the table is genuinely public (e.g., feature_flags lookups) — and capture an ADR.
# Hook event: PostToolUse on Edit/Write/MultiEdit to drizzle schema files.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *packages/worker/src/db/schema/*|*packages/worker/drizzle/schema/*|*db/schema/*.ts|*schema.ts) ;;
  *) exit 0 ;;
esac

[ -f "$PATH_" ] || exit 0

# Check that every pgTable() call has an enableRowLevelSecurity in the same file.
if grep -E -q 'pgTable\(' "$PATH_"; then
  if ! grep -E -q '(enableRowLevelSecurity\(\)|enableRLS\(\))' "$PATH_"; then
    printf >&2 'BLOCK: %s declares a pgTable but no enableRowLevelSecurity() call in this module.\n' "$PATH_"
    printf >&2 'RLS-as-floor is required (see rules/02-database-rls.md #1).\n'
    exit 2
  fi
  if ! grep -E -q 'pgPolicy\(' "$PATH_"; then
    printf >&2 'BLOCK: %s declares a pgTable but no pgPolicy() call. RLS without policies blocks everything.\n' "$PATH_"
    exit 2
  fi
fi

exit 0
