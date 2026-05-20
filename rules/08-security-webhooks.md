# Security + webhooks + dependency hygiene

## A. Secrets discipline

- `.env.example` per package; `.env` / `.dev.vars` gitignored at repo root.
- Worker secrets via `wrangler secret put --env <env>` (NOT `wrangler.jsonc` `vars`).
- Frontend env vars must be bundle-safe (publishable keys only).
- Service-role / `sb_secret_*` only in CI + migration/cron Worker entry points.

Hook: block-secrets-commit (hard block) — scans staged files for `sk_live_*`, `eyJ*`, long-base64; blocks `.env*`, `*.pem`, `*.key`, `.dev.vars` from being staged.

## B. Zod validation at every external boundary

HTTP body / query / headers, queue payloads, webhook bodies, AI structured output, any `JSON.parse(externalData)`. Hook: request-json-without-parse advisory — fires on `await request.json()` not immediately followed by `.parse()` / `.safeParse()`.

## C. Dangerous primitives — banned or justified

- `eval()` — banned, no exceptions.
- `new Function()` — banned, no exceptions.
- `setTimeout(string)` / `setInterval(string)` — banned.
- `dangerouslySetInnerHTML` — requires inline `// Sanitized:` comment and a DOMPurify wrap on the value.

Hook: block-dangerous-primitives (hard block).

## D. Rate limiting via Durable Objects

DO-backed token bucket or sliding window keyed on `(route, userId-or-IP)` for:

- Auth-adjacent endpoints (sign-in, sign-up, password reset, magic link)
- AI / embedding endpoints (cost protection)

## E. Web security headers

- **CSP** strict: `default-src 'self'`, no `unsafe-inline` / `unsafe-eval`, explicit allowlist for AI, CDN, Supabase.
- **CORS** allowlist per env (no `*` in production).
- **HSTS** on production: `max-age=31536000; includeSubDomains; preload`.

## F. Webhook handler pattern (verify → enqueue → ack)

1. Signature verification FIRST (before reading body).
2. Timestamp check (default 5min window).
3. Zod parse.
4. Idempotency dedupe via KV with 24h TTL.
5. Enqueue to a Queue.
6. Ack `200` immediately.

Never process inline. Use the provider's official verification SDK (Stripe, Svix, GitHub crypto). Never hand-roll HMAC.

## G. Dependency hygiene

- `pnpm audit` in CI blocks high-severity merges.
- Lockfile committed; never hand-edit; CI uses `pnpm install --frozen-lockfile`.
- New deps reviewed for maintenance + popularity + license + size (handled by `/why-this-package` subagent on every PR that touches `package.json`).

## H. Supabase keys (2026)

New format preferred: `sb_publishable_*` (client, public-safe) + `sb_secret_*` (server, system-tasks-only). Legacy `anon` / `service_role` still valid but discouraged for new projects. Publishable/anon key + user JWT for the RLS-as-floor flow. Service/secret keys never appear in user-request paths (`02-database-rls.md` #3). Per-project `RUNBOOK.md` documents key rotation.

## I. Context7 MCP — always-on (Tier 1)

Always use Context7 MCP when you need library/API documentation, code generation, setup, or configuration steps — without me having to explicitly ask. Procedure: `~/.claude/sops/consult-context7.md`.

**Tier-2 hook backstop** fires on pre-write to fast-moving-lib config files as a deterministic tripwire:

`wrangler.jsonc`, `drizzle.config.ts`, `drizzle/**/*.ts`, `vite.config.ts`, `vitest.config.ts`, `biome.json`, `tsconfig*.json`, `tailwind.config.*`, `postcss.config.*`, `app.config.ts`, `supabase/config.toml`, `eas.json`, `package.json` (when adding deps for listed libs).

**Tier-2 lib list (grouped):**
- **Runtime/backend:** Cloudflare Workers; Wrangler + `wrangler.jsonc`; CF primitives (Hyperdrive, R2, KV, Queues, Workflows, DOs).
- **Database:** Supabase (auth/RLS/keys/Storage/vector/Realtime); Supabase CLI; Drizzle ORM + Drizzle Kit; pgvector.
- **Frontend web:** Vite; React 19+ (Actions, useActionState, Suspense); TanStack Query v5+; TanStack Router; react-hook-form + `@hookform/resolvers/zod`; Tailwind v4; shadcn registry.
- **Mobile:** Expo SDK; Expo Router; React Native (New Architecture); Reanimated v3; react-native-gesture-handler; `expo-secure-store` / `expo-image` / `expo-notifications`; EAS CLI.
- **AI:** Vercel AI SDK; `@anthropic-ai/sdk` (escape); `openai` SDK (embeddings).
- **Type system / tooling:** TypeScript; Zod; pnpm (workspace); Biome; Vitest.
- **State / chat:** XState v5.
- **Observability:** Sentry SDKs (Workers / browser / RN separately); Langfuse + OTel integration.

**Meta-rule:** a library joins the Tier-2 list if it meets ANY of (1) breaks more than once a year, (2) setup/config has evolved meaningfully in the last 12 months, (3) current major has materially different APIs from prior major.

## J. Exact version pinning

- `.npmrc` includes `save-exact=true`. No `^` / `~` in `package.json`.
- `pnpm-lock.yaml` always committed; never regenerated to "fix" merge conflicts.
- CI uses `pnpm install --frozen-lockfile`.
- Upgrades explicit and one-at-a-time: `pnpm update <pkg>@<exact>`.
- Major-version bumps on fast-moving libs (Tier-2 list) require an ADR.
- `pnpm.overrides` used sparingly for transitive resolution.
- `pnpm outdated` monthly manual cadence — no Renovate/Dependabot.

Hook: version-ranges advisory — fires on `^` / `~` in `package.json`.
