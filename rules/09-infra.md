# Infra

## A. `wrangler.jsonc` — three envs

`default` (dev), `[env.preview]`, `[env.production]`. Every binding (Hyperdrive, R2, Queue, KV, DO) defined per-env. `vars.ENV` is the canonical env discriminator in code; **never read `process.env` in a Worker** — read from the env arg passed into `fetch`.

## B. Compatibility date locked

`compatibility_date` is set at project creation and bumping it requires an ADR. Hook: compatibility-date advisory (subset of prod-env-config).

## C. Local dev

`pnpm dev` runs `supabase start` + `wrangler dev` + Vite via `concurrently`. Mobile is opt-in via `pnpm dev:mobile`. `pnpm dev:all` includes mobile.

## D. CI/CD — three GitHub Actions workflows

1. **PR workflow** — `pnpm install --frozen-lockfile`, typecheck, lint, test, preview deploy, PR comment with preview URL.
2. **Main workflow** — deploy production after merge to `main`.
3. **Migration workflow** — manually triggered with an environment approval gate.

## E. Migration deploy gate

Append-only migrations (`02-database-rls.md` #6). Generated locally, applied local → preview (auto on merge) → production (manual approval in the migration workflow). `drizzle-kit push` is banned everywhere.

## F. Bundle size thresholds (gzipped)

| Layer | Target | Hard limit |
|---|---|---|
| Worker | 1 MB | 2 MB |
| Web initial JS | 300 KB | 700 KB |
| Web total chunks | 1.5 MB | 3 MB |
| Mobile JS (Hermes bytecode) | 8 MB | 15 MB |

CI gates via `pnpm size`. Soft warnings at target; hard fail at hard limit. A PR pushing past soft target must explain in the description.

## G. `/healthz` endpoint

Returns JSON: `{ ok, checks: { db, ai, storage }, env, version }`. Used by uptime monitor, CI smoke test after deploy, and local `pnpm healthz` sanity.

## Named scripts — the only sanctioned invocation surface

Engineer never types `pnpm --filter`, `wrangler`, `drizzle-kit`, or `supabase` directly at the shell. Concrete script surface:

```
dev, dev:all, dev:web, dev:worker, dev:mobile, dev:supabase
build, build:web, build:worker, build:mobile
test, test:watch, test:web, test:worker, test:mobile
typecheck, lint, lint:fix, format
db:migrate, db:migrate:prod, db:reset, db:studio
seed
deploy:preview, deploy:prod
size, analyze:web, analyze:worker
healthz
outdated
```

New common operation = new top-level alias. Hook: named-script advisory.
