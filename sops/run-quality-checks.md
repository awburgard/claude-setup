# SOP: run-quality-checks

**Purpose:** the deterministic pre-PR / pre-commit quality gate. Used by hooks and skills that need a clean compiler-and-lint signal before continuing.

**Consumed by:** `/pr-create`, `/self-review`, `/implement-task`.

## Inputs

- None. Operates on the current working tree.

## Steps

1. **Typecheck:** `pnpm typecheck`. Non-zero exit → halt with the compiler output.
2. **Lint:** `pnpm lint`. Non-zero exit → halt with the lint output.
3. **Targeted tests:** if a `tasks.graph.json` or recent task scope is available, run `pnpm test -- <changed-files-derived-globs>`. Otherwise `pnpm test`. Non-zero exit → halt.
4. **Bundle-size gate** (only for `/pr-create` PRs touching `packages/{web,worker,mobile}/`): `pnpm size`. Non-zero (hard limit breached) → halt. Soft warning → continue but include in the PR body.

## Outputs

Returns a status object:

```json
{
  "typecheck": "pass" | "fail",
  "lint": "pass" | "fail",
  "tests": { "status": "pass" | "fail", "ran": <n>, "failed": [ ... ] },
  "size": { "status": "pass" | "soft-warn" | "hard-fail", "details": "..." }
}
```

## Failure mode

Any `fail` halts the caller. **Never fix lint/typecheck errors by weakening the rule** (e.g. adding `// eslint-disable`, casting to `any`, widening types). Fix the code or escalate that the rule is wrong.
