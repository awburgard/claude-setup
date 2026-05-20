#!/bin/sh
# _comment: ADVISORY on `await request.json()` not followed by .parse() / .safeParse() on the next line.
# External boundaries must Zod-validate. See rules/08-security-webhooks.md #B.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')
case "$PATH_" in *.ts|*.tsx) ;; *) exit 0 ;; esac
[ -f "$PATH_" ] || exit 0

awk '
  /await[[:space:]]+(req|request|c\.req|ctx\.req|event\.request)\.json\(\)/ {
    matched_line = NR
    # Look ahead 2 lines for .parse( / .safeParse(
    for (i = NR; i <= NR + 2 && i <= total; i++) {
      if (cache[i] ~ /\.(safeParse|parse)\(/) { ok = 1; break }
    }
    if (!ok) { print NR ": " $0; bad = 1 }
    ok = 0
  }
  { cache[NR] = $0; total = NR }
  END { exit bad }
' "$PATH_" >/dev/null
if [ $? -ne 0 ]; then
  printf >&2 'NUDGE: %s reads request.json() without an immediate Zod .parse()/.safeParse().\n' "$PATH_"
  printf >&2 'Validate at external boundaries. See rules/08-security-webhooks.md #B.\n'
fi
exit 0
