---
name: generate-bdd
description: Generates Gherkin feature files at initiatives/<slug>/features/*.feature derived from a TRD's user flows. Use when the user says "write the Gherkin", "BDD this", "generate features", "turn this TRD into scenarios", or after /trd completes. Halts on TRD ambiguity — never fabricates scenarios. Output files become the spec-of-record for the test-integrity rule.
allowed_tools: [Read, Write, Edit]
---

# /generate-bdd

Turns TRD user flows into Gherkin feature files, which become the spec-of-record for tests.

## Inputs

- Path to a TRD (`initiatives/<slug>/TRD.md`) marked `Status: Active`.

## Outputs

- One file per feature under `initiatives/<slug>/features/<feature>.feature`.
- Status JSON: `.claude/scratch/generate-bdd-result-<sid>.json` with `{slug, feature_paths: [...], scenario_count, next_skill_suggested: "generate-tasks"}`.

## Procedure

1. **Read the TRD** (via `~/.claude/sops/read-initiative-context.md`). Confirm `Status: Active`.
2. **Identify features.** Each top-level user-flow section in the TRD becomes one `.feature` file. Map ambiguous sections back to the user before writing — never invent a feature boundary.
3. **For each feature, draft scenarios.** Use the template at `~/.claude/skills/generate-bdd/references/template.feature`. Conventions:
   - Title in present tense: `Feature: Inviting a teammate`
   - Background for shared setup; reset between scenarios via Vitest `beforeEach` later.
   - One behavior per scenario. Scenario name describes behavior, not mechanism (mirrors testing rule #5).
   - Cover happy path + critical-failure paths only (mirrors test inventory floor).
   - Use concrete data (`a workspace named "Acme"`), not placeholders.
4. **Confirm scenario list with the user before writing.** Show titles; write only on "yes" / "ship it".
5. **Never invent.** If the TRD doesn't say what happens on a given input, surface the question; do not author the scenario.

## Failure mode

- TRD missing or non-`Active` → halt.
- TRD has user-flow sections that aren't behavior-shaped (e.g., implementation notes) → surface for the user to clarify or move out of the flows section.
- Scenario count comes out to zero → halt with "this initiative has no externally observable behavior — is the TRD wrong, or is this actually a task?"
