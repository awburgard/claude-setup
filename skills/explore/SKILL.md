---
name: explore
description: Conducts a Socratic exploration for a new initiative before any TRD or code is written. Use when the user mentions "let's explore", "I want to think through", "before I start on X", "help me figure out", "I'm not sure how to approach", or opens a GitHub Issue describing something that meets any task-vs-initiative escalator. Mandatory for every initiative; never skipped. Surfaces ADR triggers inline. Outputs initiatives/<slug>/exploration.md.
allowed_tools: [Read, WebFetch, Bash, Write, Edit]
---

# /explore

Socratic exploration of a problem space before any TRD or code is written. The front-end discipline that keeps test-integrity from collapsing later.

## Inputs

- Free-text idea, OR
- A GitHub Issue URL (read via `gh issue view`).

## Outputs

- `initiatives/<slug>/exploration.md` with sections: Problem, Users, Constraints, Approaches considered, Decisions surfaced, Open questions.
- Inline ADR captures via `/adr` if any trigger from `~/.claude/sops/adr-trigger-check.md` fires.
- Status JSON: `.claude/scratch/explore-result-<sid>.json` with `{slug, exploration_path, adrs_captured: [...], next_skill_suggested: "trd"}`.

## Procedure

1. **Confirm initiative scope.** Check escalators from `~/.claude/rules/10-workflow.md`:
   - User-visible behavior change? (i)
   - Multi-PR work? (ii)
   - New entity, service, or table? (iii)

   If none: surface "this looks like a task, not an initiative — proceed as `/implement-task`?" and halt unless user insists.

2. **Pick a slug.** Kebab-case, ≤30 chars, derived from the problem statement.

3. **Run the Socratic loop, one question at a time.** Cover at minimum:
   - Who is the user and what are they trying to do?
   - What does success look like? What's the smallest version that ships?
   - What's the dumbest version of this? Why not that?
   - What are the constraints (data, latency, cost, privacy, irreversibility)?
   - What approaches did you consider and reject?
   - What's the riskiest assumption?

4. **Watch for ADR triggers** (a)–(g) per `~/.claude/sops/adr-trigger-check.md`. Each time one fires, surface the prompt inline and offer `/adr` immediately.

5. **Write the exploration doc.** Use the template at `~/.claude/skills/explore/references/template.md` (one level deep). Status frontmatter: `Status: Active`.

6. **Suggest next step.** Default: `/trd`. If the exploration revealed a contested decision that warrants its own doc + review, also suggest one RFC under `initiatives/<slug>/rfcs/`.

## Failure mode

- Scope too narrow → suggest `/implement-task`.
- User can't articulate users or success → halt, do not write a placeholder TRD.
- Context7 unavailable when needed for library research → surface, don't guess.
