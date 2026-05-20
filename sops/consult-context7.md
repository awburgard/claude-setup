# SOP: consult-context7

**Purpose:** procedural recipe for the always-on Context7 rule (`08-security-webhooks.md` #I). Resolve the library, fetch fresh docs, cite them in the work.

**Consumed by:** any skill or rule context that touches library/API documentation, config, setup, or version-sensitive code.

## When this fires

Always, when:

- The user asks how to configure, set up, or use a library/API.
- You're about to edit a config file in the Tier-2 hook list (`08-security-webhooks.md` #I).
- You're about to write integration code for a library whose major has shifted in the last 12 months.
- You're suggesting a `pnpm add` or version bump for a Tier-2 library.

## Steps

1. **Resolve the library ID.** Call `resolve-library-id` with the library name (e.g. "Vercel AI SDK", "Drizzle ORM").
2. **Fetch focused docs.** Call `get-library-docs` with the resolved ID and a narrow `topic` matching the task at hand (e.g. `topic: 'tool calling'`, `topic: 'rls policies'`). Avoid pulling the entire doc set.
3. **Cite the version.** In the response or the resulting code comment (where load-bearing), name the library + version pulled. Example: `// Per Vercel AI SDK 4.x docs (consulted 2026-05-19)`.
4. **If Context7 has nothing for this lib:** say so explicitly and fall back to WebFetch on the upstream docs URL the user names. Never guess from training data on Tier-2 libs.

## Why this matters

The Tier-2 list contains libraries that have broken backwards compatibility within the last year. Acting from training data on these is the #1 source of agentic drift (origin: Supabase keys incident, 2026-Q1). Context7 is the deterministic backstop.

## Failure mode

If Context7 MCP is unavailable in the current session: surface the unavailability, name the library/version uncertainty explicitly, and proceed only after the user confirms.
