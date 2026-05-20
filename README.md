# claude-setup

Personal mirror of `~/.claude/` — global engineering setup for Claude Code.

## Contents

```
.
├── CLAUDE.md      # Global engineering context (default stack, monorepo layout, commands)
├── settings.json  # Hook wiring, enabled plugins, theme, effort level
├── rules/         # 11 codified engineering rules (TS, RLS, testing, backend, AI, etc.)
├── skills/        # 18 slash-command skills (explore, trd, generate-bdd, implement-*, etc.)
├── sops/          # 5 standard operating procedures (Context7 consult, ADR triggers, etc.)
└── hooks/         # 33 hook scripts (hard blocks + advisory nudges) wired in settings.json
```

## Precedence

Per `rules/00-meta.md`, highest wins:

1. Explicit user instruction in current message
2. Project `.claude/rules/*.md` (path-scoped if `paths:` frontmatter)
3. `~/.claude/rules/*.md` (this repo)
4. `~/.claude/CLAUDE.md` (this repo)
5. Memory entries under `~/.claude/projects/*/memory/`
6. Claude's defaults

## Restoration

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

Plugins enabled in `settings.json` (`frontend-design`, `supabase` from `claude-plugins-official`) must be installed separately via Claude Code's plugin marketplace.

## Backup workflow

This repo is updated by asking Claude Code to mirror `~/.claude/` and push. A regular overwrite commit is used — no force-push, per the no-force-push rule.
