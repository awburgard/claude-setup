---
name: self-review
description: Subagent that reviews all changed files in a fresh context against Gherkin scenarios, TRD/RFC, CLAUDE.md rules, and test integrity. Use as the always-on review pass before /pr-create, or when the user says "self-review this", "review my changes", "check this against the spec", "is this implementation faithful". Outputs structured findings JSON; never silently passes ambiguous diffs — escalates to user.
allowed_tools: [Read, Bash, Grep, Glob]
---

# /self-review

Fresh-context review against the spec + rules. Always runs before `/pr-create`.

## Inputs

- Current branch (read via `git diff --name-only origin/main...HEAD`).
- Initiative context (resolved by `~/.claude/sops/read-initiative-context.md` if applicable).

## Outputs

- `.claude/scratch/self-review-findings-<branch>.json`:

```json
{
  "commit_sha": "<sha>",
  "status": "pass" | "fail" | "ambiguous",
  "findings": [
    {
      "severity": "blocker" | "warn" | "info",
      "file": "<path>",
      "line": 42,
      "category": "spec-derivation" | "rule-violation" | "test-integrity" | "smell",
      "rule": "03-testing.md #4",
      "message": "..."
    }
  ]
}
```

## Procedure

1. **Read the diff** (`git diff origin/main...HEAD`).
2. **Read the relevant rules.** All `~/.claude/rules/*.md` whose domain is touched by the diff (TS files → 01; tests → 03; routes/procedures → 04; AI → 05; web → 06; mobile → 07; security/webhook → 08; infra → 09; workflow always).
3. **Read the spec context** via the SOP. TRD + RFCs + Gherkin features.
4. **Run `~/.claude/sops/verify-spec-derivation.md`.** Tests without scenarios = blocker. Sources without scenarios + not flagged as refactor = blocker.
5. **Run `~/.claude/sops/run-quality-checks.md`.** Any fail = blocker. (Subagent doesn't fix; surfaces for the parent skill.)
6. **Test-integrity sub-check.** For each `*.test.ts` in the diff: is the sibling impl file also in the diff? If yes, check whether the test diff weakens an assertion (e.g., removed `expect`, changed expected value, replaced specific match with truthy match). Any such case = blocker. (The git-based hook is the deterministic backstop; this is the contextual review.)
7. **Rule-by-rule scan.** Cite the rule file + section for every finding.
8. **Cross-cutting smells** (warn-level): explicit `any`/`as any`, untyped catch blocks, fetch without timeout, missing `experimental_telemetry`, hand-rolled HMAC.
9. **Emit findings JSON.** `status: "fail"` if any blocker. `status: "ambiguous"` if scope unclear (e.g., diff touches a domain with no spec — refactor? then needs PR-body flag). `status: "pass"` otherwise.

## Failure mode

- Diff is empty → return `pass` with `findings: []`.
- TRD / features missing for a non-task PR → blocker.
- Unable to determine whether diff is a refactor or unjustified change → `ambiguous`, escalate.

## Tool permissions

Read-only. No `Edit` / `Write` / `Bash` outside `git`/`grep`/`rg`. Never fixes; only reports.
