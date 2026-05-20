# SOP: adr-trigger-check

**Purpose:** the canonical (a)–(g) ADR trigger list and the "capture now or defer?" prompt. Ensures decisions get recorded at the moment they're cheapest (during exploration or at edit time), not months later from memory.

**Consumed by:** `/explore`, `/implement-task`, `/pr-create`, and the `nudge-adr-trigger` advisory hook.

## Triggers (any one fires the prompt)

a. **First adoption of a major library or pattern** in this codebase. Examples: first XState use, first Durable Object, first CF Workflow, first CF Queue, first DO-backed rate limiter.

b. **`compatibility_date` bump** in `wrangler.jsonc`. Also a Phase-5 hook.

c. **Major-version bump** on a Tier-2 fast-moving library (`08-security-webhooks.md` #I). Examples: TanStack Query v5 → v6, Expo SDK 53 → 54, React 19 → 20.

d. **Explicit deviation from a CLAUDE.md or path-scoped rule.** This is the ONLY way rule-debt stays visible. Without an ADR, the deviation becomes an undocumented exception that future agents will widen.

e. **Architecturally cross-cutting decision.** Examples: auth flow change, state-management swap, routing change, monorepo-tooling change.

f. **Schema decision affecting multiple tables.** Examples: soft-delete strategy, audit logging, multi-tenancy approach, immutable-event-log pattern.

g. **Choice to use AI vs deterministic code for a domain.** Example: "use Claude for relationship extraction" vs rule-based parsing.

## Not triggers

- Every RFC (only RFCs whose decision applies beyond the originating initiative — see `10-workflow.md` "RFC → ADR promotion").
- Every new dependency (covered by trigger a for load-bearing adoptions).

## The prompt

When a trigger fires, surface this:

> This looks ADR-worthy: **<trigger letter and one-line reason>**. Capture now (`/adr`), defer (note for the PR description), or skip (this isn't a decision)?

Default to capturing if the user doesn't redirect within the same turn.

## Outputs

If user picks "capture now": invoke `/adr` with the trigger context as the seed. If "defer": append a `## ADR follow-ups` section to `.claude/scratch/pending-adrs.md`. If "skip": no-op.

## Failure mode

If `/adr` invocation fails (missing template, write permission), surface the trigger context and the failure verbatim — never silently drop the decision.
