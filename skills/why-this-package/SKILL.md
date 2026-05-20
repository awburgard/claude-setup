---
name: why-this-package
description: Subagent that justifies every new dependency added to package.json — pulls Context7 docs, reviews maintenance/popularity/license/size/alternatives. Use when a package.json diff adds new deps, the user says "why this package", "review this dep", "evaluate adding X", or runs as part of /pr-create's chain (and is the SOLE check for dep-only PRs).
allowed_tools: [Read, Bash, Grep, WebFetch, mcp__context7]
---

# /why-this-package

Justifies new dependencies. Only check on dep-only PRs (carve-out from `/pr-create`).

## Fires on globs

- Any `**/package.json` with added entries in `dependencies` / `devDependencies` / `peerDependencies`.

## Outputs

- `.claude/scratch/why-this-package-findings-<branch>.json`:

```json
{
  "commit_sha": "<sha>",
  "status": "pass" | "fail" | "ambiguous",
  "packages": [
    {
      "name": "...",
      "version": "...",
      "status": "ok" | "blocker" | "warn",
      "maintenance": "active" | "stale" | "abandoned",
      "popularity": { "weekly_downloads": <n>, "github_stars": <n> },
      "license": "MIT",
      "bundle_size_min_gz": "X kB",
      "alternatives_considered": [ ... ],
      "concerns": [ ... ]
    }
  ]
}
```

## Procedure

1. **Identify added packages.** `git diff origin/main...HEAD -- '**/package.json'` → parse added lines.
2. **For each package, gather:**
   - **Version pinned exactly?** (No `^` / `~`. Hook backstop.)
   - **Context7 docs available?** If yes, this is a Tier-2 candidate (probably already on the list). If on the Tier-2 list, this is a major-version bump → ADR may be needed (trigger c).
   - **Maintenance signal:** last release date (npm registry), open issue count, last commit. `active`/`stale` (>1y no release)/`abandoned` (>2y).
   - **Popularity:** npm weekly downloads, GitHub stars. Surface but don't gate.
   - **License:** MIT / ISC / Apache-2.0 = ok. Anything else = warn (require explicit ADR if not in the standard set).
   - **Bundle size (gzipped minified):** via bundlephobia.com or local probe. Compare to the relevant threshold from `~/.claude/rules/09-infra.md` #F.
   - **Alternatives:** name 1–3 alternatives and the reason this one was chosen. If the engineer didn't supply one, surface the question.
3. **Surface concerns inline.** Examples: post-install scripts (mobile native gate), peer-dep version conflicts, lockfile churn beyond the named package.
4. **Emit findings JSON.**

## Failure mode

- Package abandoned / no recent release → blocker.
- Non-standard license without ADR → blocker.
- Bundle size breach (hard limit) → blocker.
- Mobile native dep added without `mobile-native-add` nudge handled → escalate to `/mobile-native-review`.

## Tool permissions

Read-only on filesystem; Context7 + WebFetch allowed for registry / docs lookups.
