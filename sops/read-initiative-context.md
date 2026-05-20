# SOP: read-initiative-context

**Purpose:** load the full context for an initiative (TRD + RFCs + Gherkin + status) so downstream skills don't re-implement discovery.

**Consumed by:** `/generate-tasks`, `/implement-task`, `/self-review`, `/docs-audit`.

## Inputs

- An initiative slug (e.g. `relationship-graph`) OR a task identifier that links back to one.

## Steps

1. **Resolve the initiative directory.** Path: `initiatives/<slug>/`. If missing, halt and surface "no initiative for slug `<slug>` — was `/explore` and `/trd` run?".
2. **Read the TRD.** `initiatives/<slug>/TRD.md`. Extract the status frontmatter field.
   - If status is `Cancelled` / `Superseded by: <link>` / `Deprecated`: halt and surface "initiative <slug> is <status>". Follow the link if `Superseded`.
   - If status is `Shipped`: this is historical context only. Permitted for `/docs-audit` reads; halt for `/implement-task` or `/generate-tasks` (no new work on shipped initiatives).
3. **Read every RFC.** `initiatives/<slug>/rfcs/*.md`. Honor status fields the same way.
4. **Read every Gherkin feature.** `initiatives/<slug>/features/*.feature`. File existence = active.
5. **Look up linked GH Issues.** `gh issue list --search "initiative:<slug>"` (or label scheme used by the project). Note open vs closed.
6. **Emit a structured context object** that the calling skill can consume:

```json
{
  "slug": "<slug>",
  "trd": { "path": "...", "status": "Active", "body": "..." },
  "rfcs": [ { "path": "...", "status": "Accepted", "body": "..." } ],
  "features": [ { "path": "...", "body": "..." } ],
  "issues": [ { "number": 42, "title": "...", "state": "open" } ]
}
```

## Failure mode

If TRD is missing, ambiguous, or marked `Active` but contradicted by code in obvious ways: halt and surface for user resolution. Never fabricate context.
