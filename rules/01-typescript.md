# TypeScript

## 1. No anonymous object types

Every shape gets a named `type`. No inline `{ a: string }` in params, returns, consts, generics, or nested positions. Why: searchability, refactor cost, agentic legibility, codegen consistency. Hook: anonymous-types advisory.

## 2. Types co-located by feature

`packages/<pkg>/src/features/<feature>/types.ts` per feature. Cross-package types in `packages/shared/src/<domain>.ts`, derived from Zod via `z.infer<>`. No barrel re-exports. Imports point at specific files.

## 3. Factories over classes

Use factory functions returning objects of methods. Carve-outs (only these): Cloudflare Durable Objects (runtime forces classes), React error boundaries (API forces classes). Hook: class-outside-allowlist advisory.

## 4. `Result<T, E>` for error handling

Custom util at `packages/shared/src/result.ts`. API: `Ok(v)`, `Err(e)`, `isOk(r)`, `isErr(r)`. Async: `Promise<Result<T, E>>` (no separate `ResultAsync`). No chaining (`map`/`andThen` deliberately omitted — agentic uniformity). Test-only: `unwrapOk`, `assertOk`, `unwrapErr`, `assertErr`. Boundary conversion: `tryCatch`, `tryCatchAsync`. Service methods + framework boundaries return `Result`. tRPC procedures convert at the edge. Programmer errors (`invariant`/`assert`) throw plain `Error` with `cause`. Hooks: unwrap-outside-tests, throw-outside-programmer-errors.

## 5. Branded types for ALL entity PKs

Via Zod: `export const UserId = z.string().uuid().brand<'UserId'>()`. Per-entity file in `packages/shared/src/<domain>.ts`. Drizzle `.$type<UserId>()` on every PK and FK column. Casts allowed only at `crypto.randomUUID() as UserId` and Drizzle schema files. Banned elsewhere. Hook: as-cast-branded-ids.

## 6. Explicit return types

Required on: exported functions, service factory methods, tRPC procedures, named module-scope functions. NOT required on: arrow callbacks, IIFEs, `useMemo`/`useCallback` bodies.

## 7. Single object param for 2+ args

Named conventions: `<FnName>Input` for service methods (LLM tool surface), `<Component>Props` for React, `<FnName>Args` everywhere else. Exception: pure homogeneous primitive helpers (`add(a, b)`, `lerp(a, b, t)`); max 3 positional args.

## 8. Strict TS settings

`type` not `interface`. No enums (union of literals + `as const` objects). No `any` (no `as any`, no `// @ts-ignore`; `unknown` + narrowing is the path). `noUncheckedIndexedAccess: true`, `exactOptionalProperties: true`, `verbatimModuleSyntax: true`.
