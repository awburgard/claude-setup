# Product development workflow

## Artifacts + placement

- **PRD** — lightweight 1-paragraph (user / problem / success) in the GitHub Issue body. Not a separate file. Value is in writing it.
- **TRD** — `initiatives/<slug>/TRD.md`. Status frontmatter required.
- **RFC** — `initiatives/<slug>/rfcs/NNNN-<topic>.md`. ONLY when one specific decision warrants its own doc and dedicated review (not one per initiative). Status frontmatter required.
- **Gherkin features** — `initiatives/<slug>/features/*.feature` (per-initiative) or `specs/<feature>.feature` (cross-cutting). File existence = active; deletion = feature removed. No status field.
- **Tasks** — GitHub Issues linked to the parent initiative. Closed when the corresponding PR merges.
- **ADRs** — `docs/adr/NNNN-<title>.md`. Status: `Proposed` → `Accepted` → (later) `Superseded by: <link>` / `Deprecated`. Forever; never deleted.
- **Retros** — dropped solo. Revisit at team scale.

## External tracker

GitHub Issues + GitHub Projects. The `gh` CLI is the only integration; no MCP needed. Migration to Linear/Notion only if a team forces it.

## Pipeline

```
Idea
  ↓ (always)
GH Issue + 1-paragraph PRD
  ↓
Triage — task or initiative?
  ├─ Task:        branch → /implement-task → PR → merge → close
  │               (no TRD, no Gherkin, no RFC; zero or one scenario)
  └─ Initiative:  /explore (Socratic, MANDATORY)
                  → /trd            → initiatives/<slug>/TRD.md
                  → optional /adr   for cross-cutting decisions surfaced inline
                  → optional RFC    for contested decisions
                  → /generate-bdd   → features/*.feature
                  → /generate-tasks → GH Issues + tasks.graph.json
                  → /implement-initiative (orchestrates per the DAG)
                  → close parent issue when all features pass
```

## Task vs initiative — escalators (ANY trigger promotes to initiative)

1. **User-visible behavior change** → initiative. Pure refactor / dep bump / typo / spec-clean bugfix → task.
2. **Multi-PR work** → initiative. Single-PR work → task.
3. **New entity, service, or database table** → initiative.

Socratic exploration via `/explore` is **mandatory** for every initiative. No "I'll just start." This is the front-end discipline that keeps the test-integrity rule from collapsing.

## Execution flow

Hybrid by dependency: parallel via worktrees for independent tasks, serial when one task blocks another. `/generate-tasks` produces `initiatives/<slug>/tasks.graph.json`. `/implement-initiative` reads it. **HARD RULE:** no parallel agent launches without that graph present.

## PR review — subagent layer is load-bearing

Engineer over-trusts agent code. Therefore: subagent review is the quality bar; human review is the sanity check.

- **`/self-review`** runs always, fresh-context, blocks PR open until clean. Checks against Gherkin / TRD / RFC / CLAUDE.md / rules / test integrity.
- **Targeted subagents** fire by glob (block PR open until clean):
  - `/security-review` — auth, RLS policies, webhook handlers, crypto, secret handling
  - `/schema-review` — `packages/worker/drizzle/migrations/**`, schema files
  - `/why-this-package` — any `package.json` diff with new deps
  - `/ai-code-review` — AI services, `**/tools.ts`, prompt code
  - `/mobile-native-review` — `packages/mobile/` native-dep changes, `app.config.ts`, `eas.json`
- **Cost-ceiling carve-out:** PR diff = only `package.json` + `pnpm-lock.yaml` with dep-only changes → run only `/why-this-package`, skip the rest.

## ADR triggers (auto-surfaced during `/explore` or by hook at edit time)

1. First adoption of a major library or pattern (first XState, first DO, first Workflow, first Queue, first DO-backed rate limiter)
2. `compatibility_date` bump in `wrangler.jsonc`
3. Major-version bump on a fast-moving Tier-2 lib (`08-security-webhooks.md` #I)
4. Explicit deviation from a CLAUDE.md or path-scoped rule (this is the ONLY way rule-debt stays visible)
5. Architecturally cross-cutting decision (auth flow, state-management swap, routing change)
6. Schema decision affecting multiple tables (soft delete, audit logging, multi-tenancy)
7. Choice to use AI vs deterministic code for a domain

NOT triggers: every RFC (only RFCs whose decision applies beyond the originating initiative); every new dep (covered by trigger 1 for load-bearing adoptions).

## RFC → ADR promotion

An RFC promotes to an ADR when its decision applies beyond the originating initiative. Initiative-scoped tradeoffs stay RFC-only.

## Doc-keeping discipline

- Status frontmatter required on TRDs, RFCs, ADRs (Gherkin uses file existence).
- No silent deletes. Superseded docs stay in place with a link to the replacement.
- Audit cadence: trigger-based on initiative close (handled by `/pr-create`) + quarterly catch-all via `/schedule '1st of Jan/Apr/Jul/Oct 09:00' /docs-audit`.
