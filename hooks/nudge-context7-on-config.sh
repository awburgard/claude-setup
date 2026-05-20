#!/bin/sh
# _comment: ADVISORY (PreToolUse) on edits to fast-moving-lib config files: nudges to
# consult Context7 first. Backstops the always-on Tier-1 rule with deterministic targeting
# at the spots where forgetting = catastrophic drift. See rules/08-security-webhooks.md #I.
set -e
TOOL_NAME=$(jq -r '.tool_name // ""')
case "$TOOL_NAME" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
PATH_=$(jq -r '.tool_input.file_path // ""')

case "$PATH_" in
  *wrangler.jsonc|*wrangler.toml|*wrangler.json) lib="Cloudflare Workers + Wrangler" ;;
  *drizzle.config.ts|*drizzle/*.ts) lib="Drizzle ORM + Drizzle Kit" ;;
  *vite.config.ts|*vite.config.js) lib="Vite" ;;
  *vitest.config.ts|*vitest.config.js) lib="Vitest" ;;
  *biome.json|*biome.jsonc) lib="Biome" ;;
  *tsconfig.json|*tsconfig.*.json) lib="TypeScript" ;;
  *tailwind.config.ts|*tailwind.config.js|*tailwind.config.cjs|*tailwind.config.mjs) lib="Tailwind v4" ;;
  *postcss.config.ts|*postcss.config.js|*postcss.config.cjs|*postcss.config.mjs) lib="PostCSS / Tailwind v4" ;;
  *app.config.ts|*app.config.js) lib="Expo (app.config.ts)" ;;
  *supabase/config.toml) lib="Supabase CLI" ;;
  *eas.json) lib="EAS CLI" ;;
  *package.json) lib="" ;;
  *) exit 0 ;;
esac

if [ -z "$lib" ]; then
  # For package.json, only nudge if Tier-2 libs are involved in the diff.
  OLD=$(jq -r '.tool_input.old_string // ""' 2>/dev/null || true)
  NEW=$(jq -r '.tool_input.new_string // ""' 2>/dev/null || true)
  if printf '%s%s\n' "$OLD" "$NEW" | grep -E -q '(@cloudflare/|wrangler|@supabase|drizzle-|pgvector|vite|@tanstack/|react-hook-form|tailwindcss|shadcn|expo|react-native|@react-navigation|reanimated|gesture-handler|expo-secure-store|expo-image|ai\b|@anthropic-ai/sdk|openai|typescript|zod|biome|vitest|xstate|@sentry/|langfuse|otel)'; then
    lib="a Tier-2 fast-moving library"
  else
    exit 0
  fi
fi

printf >&2 'NUDGE: editing %s — consult Context7 first.\n' "$PATH_"
printf >&2 'Library: %s. See sops/consult-context7.md for the procedure.\n' "$lib"
exit 0
