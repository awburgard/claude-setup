---
name: trd
description: Writes a Technical Requirements Document for an initiative at initiatives/<slug>/TRD.md with required status frontmatter. Use when the user says "write the TRD", "draft a TRD for", "TRD this", "spec this out technically", or after /explore completes. Halts if no exploration.md exists — TRDs are never written cold. Surfaces ADR triggers inline.
allowed_tools: [Read, Bash, Write, Edit]
---

# /trd

Writes the technical spec for an initiative, derived from a prior `/explore` exploration.

## Inputs

- Initiative slug, OR a path to `initiatives/<slug>/exploration.md`.

## Outputs

- `initiatives/<slug>/TRD.md` with `Status: Active` frontmatter.
- Status JSON: `.claude/scratch/trd-result-<sid>.json` with `{slug, trd_path, adrs_captured: [...], next_skill_suggested: "generate-bdd"}`.

## Procedure

1. **Read exploration.** If `initiatives/<slug>/exploration.md` is missing or marked anything other than `Active`, halt and surface "no active exploration — run `/explore` first".

2. **Read all relevant rules.** `~/.claude/rules/*.md` (especially the domains the initiative touches) + any `<project>/.claude/rules/*.md`. The TRD MUST reflect committed conventions.

3. **Consult Context7** for any library/API the TRD references (per `~/.claude/sops/consult-context7.md`). Cite versions.

4. **Draft the TRD.** Use the template at `~/.claude/skills/trd/references/template.md`. Sections (minimum):
   - Goals + non-goals
   - User flows (with Gherkin-shaped phrasing where possible — this seeds `/generate-bdd`)
   - Data model (entity-by-entity; brand IDs; RLS posture per `02-database-rls.md`)
   - Service surface (one service method = one externally-meaningful operation; lists the candidate methods)
   - AI surface, if any (which calls use Vercel AI SDK; any escapes to `@anthropic-ai/sdk`; telemetry function IDs)
   - Async work decisions (Queues / Workflows / DOs per `04-backend-services.md` decision tree)
   - Failure modes
   - Open questions

5. **Surface ADR triggers** (a)–(g) per `~/.claude/sops/adr-trigger-check.md` as you go.

6. **Confirm with user before writing.** Show the TRD outline; only write to disk after explicit "yes" or "ship it" in this conversation.

## Failure mode

- Exploration missing or stale → halt.
- Ambiguity that the exploration didn't resolve → surface the open question, do not invent the decision.
- TRD would contradict an existing rule → flag the contradiction and apply the exception protocol from `~/.claude/rules/00-meta.md`.
