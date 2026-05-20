# SOP: verify-spec-derivation

**Purpose:** prove every change in the working tree (or PR diff) traces back to a Gherkin scenario, a referenced spec passage, or a reproduced bug. Backstops the "tests are never modified to make code pass" rule.

**Consumed by:** `/implement-task`, `/self-review`.

## Inputs

- The set of changed files (current branch vs `origin/main`).
- The initiative context (from `read-initiative-context.md`) if applicable.

## Steps

1. **Enumerate changed files.** `git diff --name-only origin/main...HEAD`.
2. **Bucket each file:**
   - `**/*.test.{ts,tsx}` → test file (needs derivation source)
   - `**/*.feature` → spec file (the source itself)
   - source code → needs to map to a feature or bug
   - docs, configs, scripts → exempt from spec derivation but flagged for `/docs-audit` if status frontmatter is missing
3. **For each test file:** find the spec line it implements. Acceptable sources:
   - A scenario in `initiatives/<slug>/features/*.feature` or `specs/*.feature`
   - A PRD passage in the GitHub Issue body (linked in the commit message)
   - A bug reproduction (linked issue with a failing-test commit before this branch)

   If no source exists, surface: "Test `<file>` has no spec derivation. Either delete the test, or add the scenario to `<feature-file>` first."
4. **For each source file:** identify which scenario(s) drive the change. The relationship is many-to-many; one source change can serve multiple scenarios. If a change serves zero scenarios, it's either a refactor (must be flagged as such in the commit/PR) or it's dead code.
5. **Emit a derivation report:**

```json
{
  "tests": [ { "file": "...", "source": { "kind": "feature", "path": "...", "line": 42 } } ],
  "sources": [ { "file": "...", "scenarios": [ "..." ] } ],
  "unresolved": [ { "file": "...", "reason": "no scenario found" } ]
}
```

## Failure mode

If `unresolved` is non-empty, the calling skill halts. The remediation is one of:

- Add the missing scenario to a `.feature` file (preferred; then re-run derivation).
- Mark the change as a refactor in the PR description and confirm in conversation.
- Delete the unjustified change.
