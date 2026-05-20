# Global engineering context

Solo engineer, 100% prompt-driven workflow. Optimize for review velocity and catching agent drift, not human ergonomics. Configuration is portable across projects (side projects today, employment later) — keep choices defensible to a future teammate.

## Default stack (every new project)

- **Runtime/API:** Cloudflare Workers + TypeScript strict + tRPC (Workers fetch adapter)
- **Database:** Supabase Postgres with RLS-as-floor; Drizzle + `postgres.js` over Hyperdrive (Supavisor `:6543` fallback)
- **Auth:** Supabase Auth; JWT propagated per request via `set local request.jwt.claims = ...`
- **AI:** Vercel AI SDK default; `@anthropic-ai/sdk` is an escape hatch (must be marked); OpenAI `text-embedding-3-large` @ 1536 dims for embeddings
- **Web:** Vite + React + Tailwind v4 + shadcn registry + TanStack Router + TanStack Query
- **Mobile:** Expo + Expo Router + StyleSheet + Reanimated v3 + `expo-image`
- **State:** server → TanStack Query; bookmarkable/shareable → URL params; local UI → `useState`/`useReducer` (forms: react-hook-form + Zod resolver); cross-tree → Zustand last resort; state-machine UI (agentic chat) → XState v5
- **Storage:** R2 default; Supabase Storage only when RLS-on-objects matters
- **Async:** CF Queues (fan-out), CF Workflows (durable multi-step), Durable Objects (stateful per-entity)
- **Testing:** Vitest + Supabase local stack (`supabase start`)
- **CI/CD:** GitHub Actions; preview Workers per PR; `wrangler deploy --env production` on merge to `main`
- **Observability:** self-hosted Langfuse on Fly via AI SDK OTel telemetry. `OBSERVABILITY=none` env opts out per project.
- **Errors:** Sentry (Workers / browser / React Native SDKs separately)
- **Package management:** pnpm + workspaces. No Turborepo until measurable CI pain. Exact version pinning.

## Monorepo layout

`packages/web`, `packages/worker`, `packages/mobile`, `packages/shared`. Features never import features. `shared` is the only lateral dependency. Initiative docs in `initiatives/<slug>/`; ADRs in `docs/adr/NNNN-<title>.md`.

## Commands

Top-level `package.json` is the **only** sanctioned invocation surface. Never type raw `wrangler`, `drizzle-kit`, `supabase`, or `pnpm --filter` at the shell.

```
pnpm dev               # supabase + worker + web (concurrently)
pnpm dev:all           # adds mobile
pnpm build             # all packages
pnpm test              # vitest run
pnpm typecheck         # tsc --noEmit
pnpm lint              # biome check
pnpm db:migrate        # drizzle-kit generate + apply (local)
pnpm db:reset          # supabase db reset + seed
pnpm seed              # dev fixtures
pnpm deploy:preview    # wrangler --env preview
pnpm deploy:prod       # wrangler --env production (gated by hook)
pnpm size              # bundle size gate
pnpm healthz           # local /healthz sanity
```

## Rules

Domain rules live in `~/.claude/rules/`. They override this file on conflict.

- `00-meta.md` — precedence, memory rules, doc status semantics, exception protocol
- `01-typescript.md` · `02-database-rls.md` · `03-testing.md` · `04-backend-services.md`
- `05-ai-agents.md` · `06-frontend-web.md` · `07-mobile.md` (paths-scoped) · `08-security-webhooks.md`
- `09-infra.md` · `10-workflow.md`

Project-specific overrides go in `<project>/.claude/rules/`.

## Always use Context7 MCP

Always use Context7 MCP when you need library/API documentation, code generation, setup, or configuration steps — without me having to explicitly ask. See `08-security-webhooks.md` (Tier-2 fast-moving-lib list) and `~/.claude/sops/consult-context7.md` (procedure).

## Memory precedence

Codified rules in `~/.claude/rules/` and `<project>/.claude/rules/` override memory. Never write a memory that contradicts a rule. If asked for an exception, flag the contradiction and ask whether to update the rule, write an ADR, or treat as a one-time waiver.

## Doc status semantics

Docs marked `Shipped`, `Cancelled`, `Superseded by: ...`, or `Deprecated` are historical context only — never treat as current guidance. If code contradicts a doc marked `Active`, trust the code and flag the doc as stale (surface for the next `/docs-audit`).
