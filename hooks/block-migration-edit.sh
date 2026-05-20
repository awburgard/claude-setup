#!/bin/sh
# _comment: HARD BLOCK on edits to existing migration files. Migrations are append-only.
# A new migration is fine; modifying an existing one corrupts linearity and risks prod drift.
# Disable only when reverting a migration that has not been applied anywhere (extreme case).
# Hook event: PreToolUse on Edit/Write/MultiEdit, path matching drizzle/migrations.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *packages/worker/drizzle/migrations/*|*drizzle/migrations/*) ;;
  *) exit 0 ;;
esac

# Allow if the file does not yet exist (initial creation).
if [ ! -f "$PATH_" ]; then
  exit 0
fi

# Allow new directory addition: if Write into a folder where nothing exists yet, exit 0 above already.
printf >&2 'BLOCK: %s is an existing migration file. Migrations are append-only.\n' "$PATH_"
printf >&2 'Generate a new migration with `pnpm db:migrate` instead.\n'
exit 2
