#!/bin/sh
# _comment: HARD BLOCK on eval(), new Function(), setTimeout/setInterval with string arg,
# and dangerouslySetInnerHTML without an inline "// Sanitized:" comment + DOMPurify wrap.
# These are reliable RCE / XSS sources. Disable only with an ADR documenting the exception.
# Hook event: PostToolUse on Edit/Write/MultiEdit (TS/TSX/JS/JSX).
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac
[ -f "$PATH_" ] || exit 0

if grep -E -n '(^|[^A-Za-z0-9_])eval\(' "$PATH_" >/dev/null 2>&1; then
  printf >&2 'BLOCK: %s uses eval(). Banned per rules/08-security-webhooks.md #C.\n' "$PATH_"
  exit 2
fi

if grep -E -n 'new[[:space:]]+Function[[:space:]]*\(' "$PATH_" >/dev/null 2>&1; then
  printf >&2 'BLOCK: %s uses new Function(). Banned.\n' "$PATH_"
  exit 2
fi

# setTimeout/setInterval with string arg: first arg looks like a quoted literal
if grep -E -n '(setTimeout|setInterval)\(["'\''`]' "$PATH_" >/dev/null 2>&1; then
  printf >&2 'BLOCK: %s passes a string to setTimeout/setInterval. Banned.\n' "$PATH_"
  exit 2
fi

# dangerouslySetInnerHTML without // Sanitized: on the preceding line
if grep -E -n 'dangerouslySetInnerHTML' "$PATH_" >/dev/null 2>&1; then
  # Check that every match has a "Sanitized:" comment within 3 lines before it
  awk '
    /dangerouslySetInnerHTML/ {
      ok = 0
      for (i = NR - 1; i >= NR - 3 && i > 0; i--) {
        if (lines[i] ~ /\/\/[[:space:]]*Sanitized:/) { ok = 1; break }
      }
      if (!ok) { print NR ": " $0; bad = 1 }
    }
    { lines[NR] = $0 }
    END { exit bad }
  ' "$PATH_" >/dev/null
  if [ $? -ne 0 ]; then
    printf >&2 'BLOCK: %s uses dangerouslySetInnerHTML without a "// Sanitized:" comment.\n' "$PATH_"
    printf >&2 'Sanitize via DOMPurify and add the comment immediately above. See rules/08-security-webhooks.md #C.\n'
    exit 2
  fi
fi

exit 0
