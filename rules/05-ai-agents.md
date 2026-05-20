# AI / agents

## 1. Vercel AI SDK is the default; `@anthropic-ai/sdk` is an escape hatch

All chat, tool calling, and structured output goes through Vercel AI SDK (`generateText`, `streamText`, `generateObject`, `streamObject`). Drop to `@anthropic-ai/sdk` only for:

- per-block `cache_control` granularity (long context prompt caching)
- Anthropic beta features (computer use, files API, message batches)
- fine-grained streaming control beyond what AI SDK exposes

Every `import ... from '@anthropic-ai/sdk'` requires an `// Escape: <feature>` comment immediately above. Hook: anthropic-sdk-escape advisory.

## 2. Service-method-to-tool adapter

```ts
// packages/worker/src/services/<service>/tools.ts
export const userTools = (svc: ReturnType<typeof createUserService>) => ({
  get_user: tool({
    description: '...',
    parameters: GetUserInput, // same Zod schema as the service method
    execute: async (args) => {
      const r = await svc.getUser(args);
      if (isErr(r)) throw new Error(r.error.message); // LLM expects throws at tool boundary
      return r.value;
    },
  }),
});
```

Same Zod schema serves both service input and tool params. Descriptions are LLM-facing prose — name the use case, not the implementation.

## 3. Structured output uses shared schemas

`generateObject` / `streamObject` with Zod schemas imported from `packages/shared/src/<domain>.ts`. Inline `z.object({...})` for AI extraction is banned — schema drift between AI output and DB types is unfixable downstream.

## 4. Telemetry on every AI SDK call

```ts
await generateText({
  ...,
  experimental_telemetry: {
    isEnabled: true,
    functionId: '<feature>.<method>',
    metadata: { userId },
  },
});
```

Worker entry point initializes OTel pointed at self-hosted Langfuse. `OBSERVABILITY=none` env opts out per project (Querencia uses this). Hook: ai-call-without-telemetry advisory.

## 5. Embedding discipline

OpenAI `text-embedding-3-large` @ 1536 dims. Centralized `EMBEDDING_DIMS` constant in `packages/shared/src/embeddings.ts`. Chunking per content type in `packages/worker/src/services/embeddings/chunking.ts` as atomic helpers — never reuse a chunker across content types. pgvector index HNSW with `m=16, ef_construction=64` as defaults; tune later from eval data.
