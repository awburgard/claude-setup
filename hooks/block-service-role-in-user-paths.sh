#!/bin/sh
# _comment: HARD BLOCK on referencing service-role / sb_secret_* keys in user-request
# Worker code paths (routers + services), except under **/admin/**. Service-role bypasses
# RLS — using it in a user-request path is a tenant-isolation breach.
# Disable only if the path is genuinely an admin/cron/migration entry point — and live in **/admin/**.
# Hook event: PostToolUse on Edit/Write/MultiEdit.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *packages/worker/src/routers/*|*packages/worker/src/services/*) ;;
  *) exit 0 ;;
esac

# Admin paths are allowed.
case "$PATH_" in
  *admin/*) exit 0 ;;
esac

[ -f "$PATH_" ] || exit 0

if grep -E -q '(SUPABASE_SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY|sb_secret_|service_role)' "$PATH_"; then
  printf >&2 'BLOCK: %s references service-role/sb_secret_*/service_role in a user-request path.\n' "$PATH_"
  printf >&2 'Service-role bypasses RLS. Move admin work under **/admin/** or use the user JWT path.\n'
  printf >&2 'See rules/02-database-rls.md #3.\n'
  exit 2
fi

exit 0
