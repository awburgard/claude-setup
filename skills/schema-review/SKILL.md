---
name: schema-review
description: Subagent that reviews Drizzle schema and migration changes for RLS coverage, irreversibility, append-only discipline, and branded-ID + immutability conformance. Use when packages/worker/drizzle/** changes, the user says "review the migration", "schema review", "check my drizzle changes", or runs as part of /pr-create's chain. Always-on for matching globs; irreversibility class.
allowed_tools: [Read, Bash, Grep, Glob]
---

# /schema-review

Drizzle schema + migration review. Irreversibility class — high bar.

## Fires on globs

- `packages/worker/drizzle/migrations/**`
- `packages/worker/drizzle/schema/**`
- `**/schema.ts`, `**/schema/*.ts` inside `packages/worker/`
- `drizzle.config.ts`

## Outputs

- `.claude/scratch/schema-review-findings-<branch>.json`.

## Procedure

1. **Read the diff.** Separate migration files from schema files.
2. **Migration discipline:**
   - Migration file is new (append-only)? Editing an existing file should already be hard-blocked by the hook — surface as blocker if it slipped through.
   - SQL is `IF NOT EXISTS` / `IF EXISTS` guarded where appropriate?
   - Destructive changes (`DROP COLUMN`, `DROP TABLE`, `ALTER COLUMN ... TYPE ...` on a non-empty column) flagged?
   - Foreign keys created with explicit `ON DELETE` policy?
   - Indexes named explicitly (not auto-named)?
3. **Schema discipline:**
   - New `pgTable` ships with `enableRowLevelSecurity()` call + at least one `pgPolicy`? (Hook backstop; surface if it slipped through.)
   - PK column uses `.$type<EntityId>()` for the branded ID?
   - FK columns reference branded IDs?
   - Timestamp columns are `.notNull().defaultNow()` and `.$type<Date>()` where appropriate?
   - Boolean columns have explicit defaults?
   - `created_at`, `updated_at`, `deleted_at` pattern consistent across tables (or explicitly justified ADR if not)?
4. **Policy review** for new `pgPolicy()` definitions:
   - Reference `auth.uid()` (RLS-as-floor)?
   - Both `USING` and `WITH CHECK` clauses present where mutation is allowed?
   - Service-role excluded from user policies?
5. **Cross-cutting:**
   - `tests/db/policies/<table>.test.ts` added or updated for any new/changed table?
   - Migration deploy path (`pnpm db:migrate` → preview → manual prod) not bypassed?

## Failure mode

- Edited existing migration → blocker (should not reach this subagent; hook backstop).
- New table with no RLS policy + no policy test → blocker.
- Destructive migration without ADR + explicit user confirmation → blocker.

## Tool permissions

Read-only. No `Edit` / `Write`.
