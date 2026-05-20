---
name: implement-task
description: Implements a single task end-to-end — branch, commits, pre-PR subagent review chain. Use when the user says "implement task <id>", "do the next task", "ship issue #N", "work on this issue", or pastes a GitHub Issue URL. Halts if the task has no spec derivation. Always runs /self-review and applicable targeted subagents BEFORE opening the PR.
allowed_tools: [Read, Bash, Write, Edit, Agent]
---

# /implement-task

End-to-end implementation of a single task. The unit of execution in the pipeline.

## Inputs

- GitHub Issue number, OR a task ID from `initiatives/<slug>/tasks.graph.json`.

## Outputs

- A feature branch with one or more commits.
- A passing pre-PR review chain (markers under `.claude/scratch/<skill>-findings-<branch>.json`).
- Status JSON: `.claude/scratch/implement-task-result-<sid>.json` with `{task_id, branch, commits: [...], review_status, next_skill_suggested: "pr-create"}`.

## Procedure

1. **Resolve the task.** `gh issue view <N>`. If it's part of an initiative, read context via `~/.claude/sops/read-initiative-context.md`. Confirm the task's `blocked_by` are all merged.

2. **Verify spec derivation** for the planned changes against the linked scenarios. Per `~/.claude/sops/verify-spec-derivation.md`.

3. **Create the branch.** `git checkout -b <type>/<slug>` where type ∈ {feat, fix, refactor, chore} and slug derives from the issue title.

4. **Consult Context7** for any libraries touched (per `~/.claude/sops/consult-context7.md`).

5. **Implement.** Follow all rules in `~/.claude/rules/`. Commit in conventional-commit form: `type(scope): description`. Hooks fire as you go — heed advisory nudges, do not override hard blocks without an explicit exception protocol.

6. **Run quality checks** (`~/.claude/sops/run-quality-checks.md`). Fix until clean.

7. **Run the subagent review chain.** All of these are Agents (separate context), gated on changed-file globs:
   - **Always:** `/self-review`
   - **If auth/RLS/webhooks/crypto/secrets touched:** `/security-review`
   - **If migrations or schema touched:** `/schema-review`
   - **If AI services / `tools.ts` / prompt code touched:** `/ai-code-review`
   - **If `package.json` has new deps:** `/why-this-package`
   - **If `packages/mobile/` native deps / `app.config.ts` / `eas.json` touched:** `/mobile-native-review`

   Findings written to `.claude/scratch/<skill>-findings-<branch>.json`. Halt on any `status: fail`. Resolve and re-run.

8. **Surface ADR triggers** detected during implementation (per `~/.claude/sops/adr-trigger-check.md`).

9. **Hand off.** Suggest `/pr-create`.

## Failure mode

- Spec derivation fails → halt; refuse to write tests-without-scenarios.
- Subagent returns `status: fail` → halt; do not paper over findings.
- Hard-block hook fires → halt; bring the user in.
- Task has no linked scenario AND isn't a refactor/dep-bump → halt; require scenario first.
