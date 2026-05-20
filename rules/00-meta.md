# Meta — how rules, memory, and docs interact

## Precedence (highest wins)

1. Explicit instruction in the current user message
2. Project `.claude/rules/*.md` (path-scoped if `paths:` frontmatter)
3. `~/.claude/rules/*.md`
4. `~/.claude/CLAUDE.md`
5. Memory entries under `~/.claude/projects/*/memory/`
6. Claude's defaults

## Exception protocol

When the user asks for something that contradicts a codified rule:

1. Name the rule and the contradiction in one sentence.
2. Offer three paths: (a) update the rule, (b) write an ADR documenting the exception, (c) one-time waiver (rule still binds future work).
3. Wait for the choice. Do not silently comply.

This is the only way rule-debt stays visible.

## Memory rules

- Memory never contradicts a codified rule. If a memory entry conflicts with a rule, prefer the rule and surface the memory for deletion on next `/docs-audit`.
- Never memorize: code patterns, file paths, debugging recipes, ephemeral task state, git history, or anything derivable by reading the project.
- Save only: user profile (`user`), feedback (corrections AND validated approaches — both with `Why:` and `How to apply:` lines), project facts (with absolute dates), and external-system references.

## Doc status semantics

Every doc under `docs/adr/`, `initiatives/`, and the engineer's RFCs carries a status frontmatter field:

- `Active` — current, load-bearing. Code SHOULD match.
- `Proposed` — under discussion; not yet authoritative.
- `Accepted` — committed (ADRs only).
- `Shipped` — initiative complete; historical context.
- `Cancelled` — dropped before ship; historical context.
- `Superseded by: <link>` — replaced; follow the link.
- `Deprecated` — kept for traceability; do not apply.

Rule: docs in any state other than `Active`/`Accepted` are historical context only. If `Active`/`Accepted` doc contradicts code, trust the code and flag the doc as stale (queue for `/docs-audit`).

## Never delete docs silently

Superseded/cancelled docs stay in place with a status field and link to the replacement. Moving or deleting a doc creates link rot and breaks grep-based discovery.
