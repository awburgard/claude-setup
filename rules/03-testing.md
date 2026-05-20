# Testing

## 1. Vitest is the only runner

No Jest, no node:test, no ts-node loader hacks. Vitest config per package with shared base in `packages/shared/vitest.base.ts`.

## 2. Test inventory floor — the entire allowed surface

These are the ONLY tests that should exist:

- **1 happy-path integration test per public tRPC procedure** (real Worker, real Supabase local, real auth).
- **1 RLS policy test per table** in `tests/db/policies/<table>.test.ts` (user A cannot touch user B's rows: SELECT/INSERT/UPDATE/DELETE).
- **1 critical-failure test per service method** for non-authz failure classes only (state machine, business rules, race conditions). Authz is RLS's job, tested at the policy layer.
- **Unit tests** for non-trivial pure helpers in `helpers.ts` files.

NO tests for: Zod schemas, tRPC routing, trivial passthroughs, generated code, anything requiring mocking internal code.

## 3. Spec-first derivation

Every test derives from a Gherkin scenario, PRD/TRD/RFC passage, ADR, or reproduced bug. Net-new "coverage" tests are banned. If you can't point to the spec line a test came from, delete the test.

## 4. Test integrity — tests are never modified to make code pass

If a test fails, fix the code or escalate that the spec is wrong. The only legitimate modification is when the spec itself changed — and that requires an explicit user statement *in this conversation* plus a `touch .claude/scratch/spec-update-active` to clear the test-edit tripwire hook. Hook: block-test-edit-tripwire (hard block, git-based).

## 5. Brevity

Each `it()` proves exactly one behavior. Multiple `expect()`s allowed only if they prove that one behavior together. Names describe behavior, not mechanism (`it('rejects when the workspace is at quota')`, not `it('returns 429')`). Setup via `beforeEach` with `supabase db reset` + fixture seed.

## 6. Integration > unit by default

Reach for the integration test first (real DB, real Worker, real auth). Unit tests are reserved for pure-function logic where booting infra would add noise without signal.

## 7. No mocking internal code

Services take dependencies via injection (see `04-backend-services.md`). Tests pass real instances or in-memory test doubles built from the same factory pattern. `vi.mock()` only for true externals (Stripe, third-party APIs). Prefer MSW over `vi.mock` for HTTP.

## Layout

Co-located `<file>.test.ts` next to source by default. `tests/` tree only for cross-cutting concerns:

- `tests/db/policies/` — RLS policy tests
- `tests/e2e/` — full-stack flows
- `tests/fixtures/` — shared test data
- `tests/helpers/` — shared test setup
