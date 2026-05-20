#!/bin/sh
# _comment: ADVISORY on `class` declarations outside the carve-out paths (DOs, RN error boundaries).
# Factories over classes per rules/01-typescript.md #3.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

# Allowed paths: Durable Object files (heuristic: import from DurableObject or extends DurableObject),
# React error boundaries (heuristic: extends Component<..., ErrorBoundary*>).
case "$PATH_" in
  */durable-objects/*|*/do/*) exit 0 ;;
  */error-boundary*|*ErrorBoundary*) exit 0 ;;
esac

if grep -E -q '(^|[[:space:]])class[[:space:]]+[A-Z]' "$PATH_"; then
  # Verify it's not a DO/error boundary in disguise.
  if ! grep -E -q '(extends[[:space:]]+(DurableObject|Component|React\.Component))' "$PATH_"; then
    printf >&2 'NUDGE: %s declares a class outside the DO/error-boundary carve-out.\n' "$PATH_"
    printf >&2 'See rules/01-typescript.md #3 (factories over classes).\n'
  fi
fi
exit 0
