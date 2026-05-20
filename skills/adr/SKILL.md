---
name: adr
description: Captures an architectural decision as an ADR at docs/adr/NNNN-<title>.md with required status frontmatter. Use when the user says "write an ADR", "capture this decision", "ADR this", "record the decision", "this is ADR-worthy", or when /explore or a hook detects an ADR trigger (a)–(g) per the canonical list. Distinguishes a decision (gets an ADR) from a fact (gets a memory entry).
allowed_tools: [Read, Bash, Write, Edit]
---

# /adr

Captures an architectural decision.

## Inputs

- Decision context (in conversation or via trigger from `/explore`, `/pr-create`, or `nudge-adr-trigger` hook).

## Outputs

- `docs/adr/NNNN-<title>.md` with `Status: Proposed` initially, flipped to `Accepted` after user confirms.
- Status JSON: `.claude/scratch/adr-result-<sid>.json` with `{adr_number, adr_path, status, trigger}`.

## Procedure

1. **Verify this is actually a decision.** Check against `~/.claude/sops/adr-trigger-check.md` triggers (a)–(g). If none match and the user wasn't explicit: surface "this might be a memory entry, not an ADR — capture as memory instead?" and offer that path.

2. **Compute the next ADR number.** `ls docs/adr/ | sort -n | tail -1` → next.

3. **Draft the ADR** using `~/.claude/skills/adr/references/template.md`. Sections:
   - **Context** — what forced the decision; ≤2 paragraphs.
   - **Decision** — what we're doing; ≤1 paragraph + bullets if needed.
   - **Consequences** — positive + negative + neutral. Be honest about what we're giving up.
   - **Alternatives considered** — at least 2, with one-line rejection reason each.
   - **Triggered by** — letter from `adr-trigger-check.md` + the source (PR / initiative / conversation).

4. **Confirm with user.** Show the draft; write only on "yes" / "ship it" / "accept".

5. **Write at `Status: Proposed`.** On user approval ("accepted"), edit frontmatter to `Status: Accepted`. Default to flipping immediately in the same turn unless the user says otherwise.

6. **Cross-link.** If this ADR supersedes a previous one, update the prior ADR's frontmatter: `Superseded by: ./NNNN-<title>.md`.

## Failure mode

- "Decision" turns out to be a code pattern → recommend the rules/ system instead.
- "Decision" turns out to be a temporal fact ("we're freezing merges Thursday") → recommend memory.
- ADR number collision (parallel writes) → halt; pick the next free number.
