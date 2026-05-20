---
name: generate-tasks
description: Decomposes a TRD + Gherkin features into GitHub Issues plus a dependency graph at initiatives/<slug>/tasks.graph.json. Use when the user says "generate tasks", "break this into tasks", "create the issues", "decompose the initiative", or after /generate-bdd completes. The graph is REQUIRED for /implement-initiative to launch parallel work — without it, no worktree parallelism is allowed.
allowed_tools: [Read, Bash, Write]
---

# /generate-tasks

Decomposes an initiative into atomic GH Issues + a dependency DAG.

## Inputs

- Initiative slug (resolves to TRD + features via `~/.claude/sops/read-initiative-context.md`).

## Outputs

- One GitHub Issue per task via `gh issue create` (labeled with the initiative slug, linked to the parent issue).
- `initiatives/<slug>/tasks.graph.json` — dependency DAG.
- Status JSON: `.claude/scratch/generate-tasks-result-<sid>.json` with `{slug, task_count, issue_numbers: [...], graph_path, next_skill_suggested: "implement-initiative"}`.

## Procedure

1. **Read initiative context** via the SOP.
2. **Identify task boundaries.** A task is:
   - Single-PR sized (if multi-PR, split).
   - Independently testable (has at least one scenario it advances).
   - Owns one concern (entity scaffold, service method, route, RLS policy + tests, etc.).
3. **Identify dependencies.** A task depends on another if it cannot start until the other is merged. Common patterns:
   - Service method depends on entity scaffold.
   - tRPC procedure depends on service method.
   - Route depends on procedure.
   - RLS policy tests depend on entity scaffold.
4. **Write `tasks.graph.json`:**

```json
{
  "slug": "<slug>",
  "tasks": [
    {
      "id": "T1",
      "issue": 42,
      "title": "Scaffold User entity",
      "blocks": ["T2", "T3"],
      "blocked_by": [],
      "scenarios": ["user-can-sign-up"]
    }
  ]
}
```

5. **Confirm decomposition with user.** Show task titles + dependency edges; create issues only on "yes" / "ship it".
6. **Create GH Issues** via `gh issue create --title ... --body ... --label initiative:<slug>`. Cross-link parent ↔ child in bodies.

## Failure mode

- Features missing → halt; require `/generate-bdd` first.
- A task has no scenario → halt; the test-integrity rule depends on every task tracing to a scenario.
- Dependency cycle detected → halt and surface; cycles indicate split-boundary error.
