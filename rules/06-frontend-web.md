# Frontend — web

## A. Router: TanStack Router (file-based)

Routes live under `packages/web/src/routes/`. Fully typed routes, Zod search-param schemas, integrates with TanStack Query. No React Router. No hand-rolled `<Switch>`.

## B. Folder layout — feature-scoped

```
packages/web/src/
  routes/              # TanStack file-based routes
  features/<feature>/  # components/, hooks.ts, types.ts
  lib/                 # trpc client, query client, env, supabase client
  components/          # shadcn-owned primitives
```

Features never import from other features. Cross-feature shared types go in `packages/shared/src/<domain>.ts`.

## C. Loading + error patterns

- **Suspense + `useSuspenseQuery`** at the route level for data dependencies.
- **TanStack Router `errorComponent`** per route + an app-shell catch-all.
- **Explicit `<Empty />` component** for empty states — don't conflate empty with loading.

**Banned:** manual `isLoading`/`isError` plumbing in leaf components, inline `?? <Skeleton />` short-circuits, throwing inside JSX. These hide loading semantics and produce inconsistent UI.

## D. Components

PascalCase file names matching the exported component. Named exports only — no default exports. No barrel `index.ts` inside feature folders. One component per file for non-trivial components; trivial sub-components can co-locate in the same file as their parent.

## E. Imports

Path aliases via tsconfig: `@web/features/*`, `@web/lib/*`, `@web/components/*`, `@shared/*`. Relative imports limited to one directory level (`./foo`, not `../../bar`).
