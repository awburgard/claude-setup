---
name: docs-audit
description: Sweeps docs/adr/ and initiatives/ for stale status, link rot, and code-vs-doc contradictions, plus audits ~/.claude/projects/*/memory/ for bloat and rule-promotion candidates. Use when the user says "audit the docs", "stale doc check", "run the audit", "memory audit", or fires automatically on the quarterly /schedule cron (1st of Jan/Apr/Jul/Oct). Writes a report engineer reads on next session.
allowed_tools: [Read, Bash, Write, Edit, Grep]
---

# /docs-audit

Quarterly health pass over docs + memory.

## Inputs

- None (sweeps the project + user memory automatically).
- Optional `--quick` flag to skip the memory layer.

## Outputs

- `~/.claude/scratch/audit-YYYY-Qn.md` — full report.
- SessionStart hook surfaces the unread report on next session.
- Status JSON: `.claude/scratch/docs-audit-result-<sid>.json` with `{report_path, doc_issues: n, memory_issues: n, promotion_candidates: n}`.

## Procedure

### Layer 1: Doc content audit

1. **Walk `docs/adr/`.** For each ADR:
   - Frontmatter present and valid? If not, flag.
   - Status `Active`/`Accepted`/`Proposed`/`Superseded by:`/`Deprecated`? If something else, flag.
   - `Superseded by:` link resolves? If not, flag.
   - For `Active`/`Accepted` ADRs: grep the codebase for the pattern they document. If code clearly contradicts, flag for review.
2. **Walk `initiatives/`.** For each TRD:
   - Status set? If missing, flag.
   - If `Active`: are there open GH Issues linked? If zero and PRs are all merged, prompt status flip to `Shipped`.
   - `Shipped`/`Cancelled`: just verify status; no action.
3. **Gherkin orphans.** Walk `initiatives/<slug>/features/*.feature` — if no source file references the scenario by name (best-effort grep), flag as possibly stale.

### Layer 2: Memory audit

4. **Walk `~/.claude/projects/*/memory/`.** For each `.md` file:
   - Frontmatter intact? Type valid (`user` / `feedback` / `project` / `reference`)?
   - For `project` type: dates absolute and not >12mo old?
   - Description specific enough to drive future recall?
   - Body has `Why:` + `How to apply:` lines for `feedback`/`project`?
   - Flag entries that look stale, contradictory, or low-signal.
5. **Promotion candidates.** Group memory entries by topic. Surface any topic with:
   - ≥3 entries → candidate for a codified rule.
   - 1 entry referenced across ≥3 distinct project memory directories → candidate for `~/.claude/rules/`.
   For each, propose: "promote to rule, keep as memory, or delete?"

### Layer 3: Initiative-close audit (also called inline from `/pr-create`)

6. **Triggered by an initiative TRD flipping to `Shipped`.** Sweep ADRs for any that reference the initiative or its patterns — prompt the user: "does the shipped initiative change anything documented in ADR-NNNN?"

## Report format

```markdown
# Audit YYYY-Qn

## Doc issues
- [ ] `docs/adr/0007-state-management.md` — Active, but code uses Jotai in 3 places. Flag for review.

## Memory issues
- [ ] `~/.claude/projects/.../memory/feedback_testing_loud.md` — last referenced 18mo ago, possibly stale.

## Promotion candidates
- [ ] "always run `pnpm typecheck` before opening PR" appears in 4 feedback entries — promote to rule under `03-testing.md`?
```

## Failure mode

- No issues found → write a 1-line "clean" report and exit.
- Memory directory missing → skip layer 2, note in report.
- Permission denied reading a memory file → flag in report; do not silently skip.
