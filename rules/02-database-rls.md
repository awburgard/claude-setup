# Database + RLS

## 1. RLS enabled on every table — no exceptions

Every `pgTable` ships with `enableRowLevelSecurity()` and at least one `pgPolicy`. Policies reference `auth.uid()`. Hook: block-pgtable-without-rls (hard block on PostToolUse).

## 2. JWT propagated per request

Before any query in a request handler:

```ts
await sql`set local request.jwt.claims = ${JSON.stringify(claims)}`;
```

Per-request lease, not pool-shared across users. Without this, `auth.uid()` is null and RLS lets nothing through (or — if a permissive policy exists — leaks across tenants). Validate JWT via `supabase.auth.getUser(token)` first.

## 3. Service-role / `sb_secret_*` never in user-request paths

Banned under `packages/worker/src/routers/**` and `packages/worker/src/services/**` (except `**/admin/**` for explicit admin/cron/migration entry points). Service-role bypasses RLS — using it from a user-request path is a tenant-isolation breach. Hook: block-service-role-in-user-paths (hard block).

## 4. Connection via Hyperdrive (default) or Supavisor pooler

`postgres.js` over CF Hyperdrive binding. Fallback: Supabase Supavisor pooler in transaction mode (port `6543`) — NOT the session pooler (`5432`) and NOT direct connect. Direct connect to Postgres from Workers is forbidden in production (no connection reuse, exhausts limits).

## 5. RLS policy tests per table

`tests/db/policies/<table>.test.ts` proves: user A cannot SELECT, INSERT, UPDATE, or DELETE user B's rows. Required before the table ships. See `~/.claude/skills/scaffold-entity/` for the generator.

## 6. Migrations append-only; `drizzle-kit push` banned

All schema changes go through `drizzle-kit generate` → reviewed migration file → `pnpm db:migrate`. Existing migration files are never edited. Hook: block-migration-edit (hard block). `drizzle-kit push` is banned in `package.json` scripts and CI; it corrupts the migration linearity story and silently overwrites prod schema state.
