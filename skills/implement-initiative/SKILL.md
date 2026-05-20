---
name: implement-initiative
description: Orchestrates parallel implementation of an initiative's tasks across worktrees, respecting the dependency graph at initiatives/<slug>/tasks.graph.json. Use when the user says "implement the initiative", "ship all the tasks", "run the initiative", "work through this initiative", or after /generate-tasks completes. HARD requirement — never launches parallel work without a tasks.graph.json present.
allowed_tools: [Read, Bash, Write, Agent]
---

# /implement-initiative

Orchestrates `/implement-task` across the initiative's task graph. Parallel where the graph allows, serial where it doesn't.

## Inputs

- Initiative slug (resolves `initiatives/<slug>/tasks.graph.json`).

## Outputs

- One worktree per parallel-capable task (under `~/.claude/worktrees/<slug>/<task-id>/`).
- One branch per task, each with passing pre-PR review chain.
- Status JSON: `.claude/scratch/implement-initiative-result-<sid>.json` with `{slug, completed: [task_ids], in_progress: [task_ids], blocked: [task_ids], next_actions: [...]}`.

## Procedure

1. **Read the graph.** `initiatives/<slug>/tasks.graph.json`. **HALT if missing** — parallelism without the graph is merge hell.
2. **Compute the ready set.** Tasks where `blocked_by` is empty or fully merged.
3. **For each ready task, decide isolation:**
   - Independent (no shared files with another ready task) → launch in a new worktree as a subagent invoking `/implement-task`.
   - Shared files → run serially in the main checkout.
4. **Launch subagents in parallel** (one Agent call per worktree, all in a single message). Each subagent runs `/implement-task` for its task ID.
5. **Wait, then resync.** When subagents return, check findings JSON for each. Merge clean branches first; re-queue any with `status: fail`.
6. **Recompute the ready set** and loop.
7. **Close the initiative.** When all tasks are merged, prompt user to run `/pr-create` for the final PR (if any), then `/docs-audit`-style status flip (TRD → `Shipped`, ADR check) — actually handled inside `/pr-create` on the closing PR.

## Worktree convention

`git worktree add ~/.claude/worktrees/<slug>/<task-id> -b <type>/<slug>-<task-id>`. Worktrees cleaned up by the orchestrator when their branch is merged.

## Failure mode

- Graph missing → halt.
- Cycle detected in remaining graph → halt; ask the user to split the offending task.
- Multiple subagents touch the same file (manifest-detected post-hoc) → fall back to serial for that subgraph and re-queue.
- Subagent returns `ambiguous` → escalate to user; never auto-bless.
