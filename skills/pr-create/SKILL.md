---
name: pr-create
description: Opens a GitHub pull request with the subagent review chain results embedded in the body, gates on a fresh review-pass marker, and flips TRD/initiative status to Shipped when the closing PR merges. Use when the user says "open the PR", "create the PR", "ship it", "PR this", or after /implement-task completes. Has a dep-only carve-out — PRs touching only package.json + lockfile run only /why-this-package.
allowed_tools: [Read, Bash, Edit, Write, Agent]
---

# /pr-create

Opens the PR, embeds review-chain findings, runs the closing checks for initiative PRs.

## Inputs

- Current branch (or explicit `--branch` arg).

## Outputs

- GitHub PR via `gh pr create`.
- TRD status flip to `Shipped` (if this PR closes the initiative).
- ADR-trigger sweep before opening.
- Status JSON: `.claude/scratch/pr-create-result-<sid>.json` with `{branch, pr_url, review_pass_sha, initiative_closed?: slug}`.

## Procedure

1. **Detect carve-out.** If the diff is only `package.json` + `pnpm-lock.yaml` with dep changes and no source code: **skip full chain**, run only `/why-this-package`. Otherwise continue.

2. **Verify subagent chain ran on current commit.** Read `.claude/scratch/<skill>-findings-<branch>.json` for every applicable subagent. The `commit_sha` field MUST match `git rev-parse HEAD`. Stale findings → halt; re-run `/implement-task`'s review step.

3. **Run quality checks** (`~/.claude/sops/run-quality-checks.md`). Belt-and-suspenders against the deterministic hook gate.

4. **ADR-trigger sweep.** Per `~/.claude/sops/adr-trigger-check.md`. Anything detected at edit-time but not yet captured → prompt now.

5. **Detect initiative-closing PR.** A PR closes the initiative when all tasks in `initiatives/<slug>/tasks.graph.json` will be merged after this PR merges. If so:
   - Edit `initiatives/<slug>/TRD.md` frontmatter `Status: Active` → `Status: Shipped`.
   - Run `/docs-audit` against `docs/adr/` to flag any ADR that needs updating because of this initiative.

6. **Compose PR body.** Sections:
   - Summary (1–3 bullets — what changed, why)
   - Scenarios advanced (links to `.feature` files)
   - Review chain (one line per subagent, status + findings link)
   - ADR captures (if any)
   - Test plan (markdown checklist; auto-derived from scenario list)

7. **Open the PR.** `gh pr create --title "<conventional-commit>" --body "$(<body)"`. Title is imperative, lowercase, `<72` chars. No "Generated with Claude Code" trailer unless the user explicitly opts in (portability to professional review).

8. **Write status JSON.** Surface the PR URL.

## Failure mode

- Stale review marker → halt.
- Quality checks fail → halt.
- Trying to open against `main` without a PR → blocked by hook `block-push-to-main`.
- `gh pr create` errors → surface; do not retry destructive operations.
