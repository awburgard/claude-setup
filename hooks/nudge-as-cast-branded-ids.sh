#!/bin/sh
# _comment: ADVISORY on `as <FooId>` casts outside the allowed sites:
#   crypto.randomUUID() as FooId (entity creation)
#   **/schema.ts files (Drizzle column .$type<FooId>() inference)
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$PATH_" in
  *schema.ts|*schema/*.ts) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

# Match `as <Capitalized>Id`. Exclude lines that include crypto.randomUUID() on the same line.
HITS=$(grep -E -n 'as[[:space:]]+[A-Z][A-Za-z0-9_]*Id\b' "$PATH_" | grep -v 'crypto\.randomUUID' || true)
if [ -n "$HITS" ]; then
  printf >&2 'NUDGE: %s casts to a branded *Id outside the allowed sites.\n' "$PATH_"
  printf >&2 'Allowed: crypto.randomUUID() as FooId, and schema files. See rules/01-typescript.md #5.\n'
  printf '%s\n' "$HITS" | head -3 >&2
fi
exit 0
