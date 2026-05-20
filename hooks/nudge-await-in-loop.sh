#!/bin/sh
# _comment: ADVISORY on `for (...) { await aiCall/embed/db op... }` or `Promise.all` over
# a runtime-sized array inside router/procedure files. This blocks the request loop and
# usually means the work should be offloaded to a Queue/Workflow/DO.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$PATH_" in
  *packages/worker/src/routers/*|*packages/worker/src/services/**/*procedures*|*routers/*.ts) ;;
  *) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

# Heuristic: for/while loop with an await on an AI/DB/embed call inside.
if awk '
  /(for|while)[[:space:]]*\(/ { in_loop = 1; depth = 0 }
  in_loop {
    depth += gsub(/\{/, "{")
    depth -= gsub(/\}/, "}")
    if (/await[[:space:]]+(generateText|generateObject|streamText|streamObject|embed|sql`|db\.|svc\.|ai\.)/) {
      print NR ": " $0
      hit = 1
    }
    if (depth <= 0 && /\}/) in_loop = 0
  }
  END { exit !hit }
' "$PATH_"; then
  printf >&2 'NUDGE: %s appears to await an AI/DB call inside a loop in a request-path file.\n' "$PATH_"
  printf >&2 'Consider offloading to a Queue/Workflow/DO. See rules/04-backend-services.md #4.\n'
fi
exit 0
