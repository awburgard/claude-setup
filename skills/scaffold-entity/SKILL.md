---
name: scaffold-entity
description: Scaffolds a complete entity surface — Zod schema + branded ID + Drizzle table + migration + service factory + tools.ts adapter + RLS policies + policy tests. Use when the user says "scaffold an entity", "add a new entity", "create a User table" (or similar), "scaffold the X domain". Single skill replaces per-aspect scaffolds — one chain, atomic output.
allowed_tools: [Read, Bash, Write, Edit]
---

# /scaffold-entity

End-to-end scaffold of a new entity following all conventions.

## Inputs

- Entity name (PascalCase: `User`, `Workspace`, `Document`).
- Zod-shaped field list (interactively if not provided).

## Outputs

- `packages/shared/src/<entity>.ts` — Zod schema + branded ID + inferred types.
- `packages/worker/src/db/schema/<entity>.ts` — Drizzle table + RLS enable + at least one policy.
- `packages/worker/drizzle/migrations/<timestamp>_create_<entity>s.sql` — generated migration.
- `packages/worker/src/services/<entity>/index.ts` — service factory stub with one happy-path method.
- `packages/worker/src/services/<entity>/tools.ts` — tool adapter for the LLM-callable methods.
- `tests/db/policies/<entity>.test.ts` — RLS policy test (user A vs user B for SELECT/INSERT/UPDATE/DELETE).
- `packages/worker/src/services/<entity>/index.test.ts` — service test stub.
- Status JSON: `.claude/scratch/scaffold-entity-result-<sid>.json` with `{entity, files_written: [...], next_steps: [...]}`.

## Procedure

1. **Confirm field list with user.** Each field gets a Zod type + DB-column mapping. Force a primary key field named `id: <Entity>Id` (branded UUID).
2. **Write the shared schema** (`packages/shared/src/<entity>.ts`):

```ts
import { z } from 'zod';

export const {{Entity}}Id = z.string().uuid().brand<'{{Entity}}Id'>();
export type {{Entity}}Id = z.infer<typeof {{Entity}}Id>;

export const {{Entity}} = z.object({
  id: {{Entity}}Id,
  // ...fields
  createdAt: z.date(),
  updatedAt: z.date(),
}).readonly();
export type {{Entity}} = z.infer<typeof {{Entity}}>;
```

3. **Write the Drizzle schema** with `.$type<{{Entity}}Id>()` on PK + any FK, `enableRowLevelSecurity()`, and at least one `pgPolicy` keyed on `auth.uid()`.
4. **Generate the migration** via `pnpm db:migrate` (drizzle-kit generate) — append-only.
5. **Write the service factory** with one happy-path method that returns `Result<{{Entity}}, {{Entity}}Error>`.
6. **Write the tools adapter** at `tools.ts`.
7. **Write the RLS policy test** that proves user A cannot SELECT/INSERT/UPDATE/DELETE user B's rows.
8. **Write the service test stub** for the happy-path method.
9. **Surface next steps:**
   - Add scenarios to a `.feature` file (`/generate-bdd` or manual).
   - Wire the service into `WorkerDeps` and tRPC procedures.
   - Add the entity to the relevant initiative's TRD.

## Failure mode

- Entity name collides with existing file → halt.
- User declines to add a branded ID (every entity must have one) → halt with rationale.
- `drizzle-kit generate` produces an empty diff (schema already exists) → halt; surface the conflict.
