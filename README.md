# claude-setup

An opinionated Claude Code configuration for solo, prompt-driven engineering. Turns Claude Code into a disciplined collaborator for a Cloudflare Workers + Supabase + TypeScript stack — with a full product development workflow (explore → TRD → BDD → tasks → implement → PR), a tripwire layer of pre/post-tool hooks, and named slash-command skills for every phase.

## What it gives you

- **A codified stack.** TypeScript strict, Cloudflare Workers + tRPC, Supabase Postgres with RLS-as-floor, Drizzle, Vercel AI SDK, Vite + React + TanStack, Expo + Reanimated, Vitest, pnpm workspaces. See `CLAUDE.md`.
- **11 engineering rules** that override defaults — TypeScript discipline, DB/RLS rules, testing floor + integrity, backend service patterns, AI/agent patterns, frontend, mobile, security + webhooks, infra, and a workflow rule.
- **18 slash-command skills** covering the full pipeline: `/explore`, `/trd`, `/generate-bdd`, `/generate-tasks`, `/implement-task`, `/implement-initiative`, `/pr-create`, `/self-review`, `/security-review`, `/schema-review`, `/ai-code-review`, `/mobile-native-review`, `/why-this-package`, `/docs-audit`, `/adr`, `/scaffold-project`, `/scaffold-entity`, `/scaffold-agentic-chat`.
- **33 hooks** wired into `settings.json` — hard blocks (secrets, prod writes, push-to-main, service-role in user paths, pgTable without RLS, migration edits, test-edit tripwire) and advisory nudges (anonymous types, mutation audit, await-in-loop, AI telemetry, ADR triggers, doc status frontmatter, named-script, version ranges, and more).
- **5 SOPs** for procedures Claude follows the same way every time (Context7 consult, ADR trigger check, initiative context read, quality checks, spec derivation verification).

## Layout

```
.
├── CLAUDE.md       # Global engineering context — stack, monorepo layout, commands
├── settings.json   # Hook wiring, enabled plugins, theme, effort level
├── rules/          # Codified rules (override CLAUDE.md on conflict)
├── skills/         # Slash-command skills, one folder each
├── sops/           # Standard operating procedures
└── hooks/          # Shell scripts wired into Pre/PostToolUse + SessionStart
```

## Precedence

Higher wins (from `rules/00-meta.md`):

1. Explicit user instruction in current message
2. Project `.claude/rules/*.md` (path-scoped if `paths:` frontmatter)
3. `~/.claude/rules/*.md`
4. `~/.claude/CLAUDE.md`
5. Memory entries under `~/.claude/projects/*/memory/`
6. Claude's defaults

## The workflow

```
Idea
  ↓
GitHub Issue + 1-paragraph PRD
  ↓
Triage — task or initiative?
  ├─ Task:        branch → /implement-task → PR → merge → close
  └─ Initiative:  /explore → /trd → optional /adr or RFC
                  → /generate-bdd → /generate-tasks
                  → /implement-initiative → /pr-create
```

`/explore` is mandatory for every initiative — no "I'll just start." `/generate-tasks` produces `initiatives/<slug>/tasks.graph.json`; `/implement-initiative` reads it to launch parallel worktrees only where the dependency graph allows.

## Install

```bash
git clone https://github.com/awburgard/claude-setup.git ~/claude-setup
cp ~/claude-setup/CLAUDE.md ~/.claude/CLAUDE.md
cp ~/claude-setup/settings.json ~/.claude/settings.json
cp -R ~/claude-setup/rules ~/.claude/rules
cp -R ~/claude-setup/skills ~/.claude/skills
cp -R ~/claude-setup/sops ~/.claude/sops
cp -R ~/claude-setup/hooks ~/.claude/hooks
chmod +x ~/.claude/hooks/*.sh
```

Plugins enabled in `settings.json` (`frontend-design`, `supabase` from `claude-plugins-official`) install separately via Claude Code's plugin marketplace.
