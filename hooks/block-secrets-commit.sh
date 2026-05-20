#!/bin/sh
# _comment: HARD BLOCK on `git commit` if staged files contain secret-shape patterns
# (sk_live_*, eyJ*, long base64), or stage any of: .env*, *.pem, *.key, .dev.vars.
# Disable only if you have a documented reason to commit credentials (you don't).
# Hook event: PreToolUse on Bash tool calls matching `git commit`.
set -e

TOOL_NAME=$(jq -r '.tool_name // ""')
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""')
case "$CMD" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

STAGED=$(git diff --cached --name-only 2>/dev/null || true)
[ -z "$STAGED" ] && exit 0

# Blocked filenames
for f in $STAGED; do
  case "$f" in
    .env|.env.*|*.pem|*.key|.dev.vars|.dev.vars.*)
      printf >&2 'BLOCK: %s is a secret-class file and cannot be committed.\n' "$f"
      exit 2
      ;;
  esac
done

# Secret-shape grep across staged content
DIFF=$(git diff --cached -U0 2>/dev/null || true)
if printf '%s\n' "$DIFF" | grep -E -q '(sk_live_[A-Za-z0-9_-]{16,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|sb_secret_[A-Za-z0-9_-]{16,})'; then
  printf >&2 'BLOCK: staged content matches a secret pattern (Stripe/JWT/Supabase secret). Audit the diff.\n'
  exit 2
fi

# Long base64 blobs are warned but not blocked (too noisy as a block).
if printf '%s\n' "$DIFF" | grep -E -q '"[A-Za-z0-9+/]{60,}={0,2}"'; then
  printf >&2 'WARN: long base64 string in staged content — confirm it is not a secret.\n'
fi

exit 0
