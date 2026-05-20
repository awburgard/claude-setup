# Backend — service layer + immutability

## 1. Service factory pattern

```ts
export function createUserService(deps: Pick<WorkerDeps, 'db' | 'logger' | 'ai'>) {
  return {
    async getUser(input: GetUserInput): Promise<Result<User, UserError>> { ... },
  };
}
```

Each service declares its own dependency subset via `Pick<WorkerDeps, ...>`. `WorkerDeps` is the single dep bag, built once per request in the fetch handler. tRPC procedures access it via `ctx.deps`. No globals, no module-scope singletons for stateful resources.

## 2. Atomic helpers — pure, in `helpers.ts`

Live in a sibling `helpers.ts` next to the service. Constraints: no I/O, no input mutation, no `Date.now()` / `Math.random()` / `crypto.randomUUID()` unless passed as inputs. Service methods orchestrate atomic helpers + I/O.

## 3. Service method = one externally-meaningful operation = one LLM tool call shape

Each method has a single `<Method>Input` Zod schema. The same schema serves the tool adapter in `<service>/tools.ts`. If you can't write the tool description in one sentence, split the method.

## 4. Long-running work offload — decision tree

Synchronous-in-request is allowed ONLY if **both**:
- ≤ 2s p95 wall-clock
- bounded I/O: ≤ 1 DB roundtrip + (≤ 1 AI call OR ≤ 1 embedding call)

Hard ceiling: 2s p95 / 10s p99. Beyond either, offload:

- **CF Queues** — fan-out async (ingest N docs → embed each)
- **CF Workflows** — durable multi-step with retries + checkpointing
- **Durable Objects** — stateful per-entity coordination (agent sessions, rate limiting, real-time)

Hook: await-in-loop advisory (catches `for (...) await aiCall()` and `Promise.all` over runtime-sized arrays in router/procedure files).

## 5. Immutability — readonly by default

- All `type` properties `readonly` (`type Foo = { readonly id: UserId; ... }`).
- All arrays typed `readonly T[]` / `ReadonlyArray<T>`.
- Zod-derived types wrapped via `Readonly<>` or the `Immutable<T>` helper in `packages/shared/src/types.ts`.

**Banned operations:** `.push`, `.pop`, `.shift`, `.unshift`, `.splice`, in-place `.sort()`/`.reverse()`, property assignment, `delete`, bracket assignment. Use `.toSorted` / `.toReversed` / `.toSpliced` / `.with` / spread instead.

**Carve-out:** encapsulated mutation inside a pure function (local accumulator) is fine as long as inputs aren't mutated and the output is treated as readonly by callers. Hook: mutation-audit advisory (scoped to outside `**/helpers.ts`).

## Effect ecosystem — deliberately not adopted

Noted as the next-level answer for compositional service code. Not picked: wholesale stack commitment, heavier mental model, less training data → more agentic drift risk. Revisit when team scale and a measurable problem make the tradeoff worth it.
