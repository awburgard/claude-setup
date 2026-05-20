---
name: ai-code-review
description: Subagent that reviews AI/agent code (Vercel AI SDK calls, tool adapters, prompt code) for prompt quality, structured-output schema discipline, telemetry wiring, and escape-hatch justification. Use when AI service files or tools.ts change, the user says "review the AI code", "check this prompt", "AI review", or runs as part of /pr-create's chain. Always-on for matching globs.
allowed_tools: [Read, Bash, Grep, Glob]
---

# /ai-code-review

Reviews AI/agent code for the patterns from `~/.claude/rules/05-ai-agents.md`.

## Fires on globs

- `packages/worker/src/services/**/ai*`, `**/agents/**`
- Any file importing `ai` (Vercel AI SDK), `@anthropic-ai/sdk`, `openai`
- `**/tools.ts`
- `**/prompts/**`

## Outputs

- `.claude/scratch/ai-code-review-findings-<branch>.json`.

## Procedure

1. **Read the diff** for matching files.
2. **Read `~/.claude/rules/05-ai-agents.md`** in full.

### Vercel AI SDK calls
- `experimental_telemetry` block present with `functionId` and `metadata.userId`? (Hook backstop; surface if it slipped through.)
- `functionId` follows `<feature>.<method>` convention?
- `generateObject` / `streamObject` uses a Zod schema imported from `packages/shared/src/<domain>.ts`? Inline `z.object({...})` is a blocker.
- Streaming responses correctly piped through tRPC's `httpBatchStreamLink` (no manual SSE plumbing)?

### Escape hatch (`@anthropic-ai/sdk`)
- Import preceded by `// Escape: <feature>` comment? (Hook backstop.)
- Justification names a feature actually missing in Vercel AI SDK at the current pinned version (verify via Context7)?
- Code surface is minimal (the escape is scoped to what AI SDK can't do; the rest of the flow stays on AI SDK)?

### Tool adapters
- Adapter lives at `<service>/tools.ts`?
- Same Zod schema serves both service input and tool params?
- `execute` does `if (isErr(r)) throw new Error(r.error.message)` at the tool boundary?
- Tool description is LLM-facing prose (use case, not implementation)?
- Tool names are stable across runs (LLM tool-use caches on names)?

### Embedding discipline
- Uses `EMBEDDING_DIMS` constant from `packages/shared/src/embeddings.ts`?
- Chunker lives in `packages/worker/src/services/embeddings/chunking.ts` and is content-type-specific?
- pgvector index uses HNSW with `m=16, ef_construction=64` (or ADR explaining deviation)?

### Prompt smells (warn-level)
- Prompts ≥500 chars and stable across calls → candidate for cache control (consider escape hatch with `cache_control`).
- Tool list mutates per-call → defeats prompt caching; flag.
- System prompt has user data interpolated → escapes any caching benefits; flag.

## Failure mode

- Inline Zod schema for AI output → blocker.
- AI call without telemetry (no `OBSERVABILITY=none` opt-out in scope) → blocker.
- `@anthropic-ai/sdk` import without `// Escape:` comment → blocker.

## Tool permissions

Read-only.
