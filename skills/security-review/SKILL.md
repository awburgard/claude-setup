---
name: security-review
description: Subagent that reviews changes touching auth, RLS policies, webhook handlers, crypto, or secret handling for OWASP and project-specific failure modes. Use when those globs change, when the user says "security review", "check for vulns", "OWASP this", "audit for secrets/auth issues", or runs as part of /pr-create's targeted subagent chain. Always-on for matching globs; never advisory.
allowed_tools: [Read, Bash, Grep, Glob]
---

# /security-review

OWASP + project-specific security review for sensitive globs.

## Inputs

- Current branch (read diff).

## Fires on globs

- `packages/worker/src/routers/**/*auth*`, `**/auth/**`, `**/middleware/auth*`
- `packages/worker/src/services/**/auth*`, `**/auth/**`
- Drizzle policy code: `**/policies.ts`, `**/rls.ts`
- Webhook handlers: `**/webhooks/**`, `**/webhook*.ts`
- Crypto: any import of `crypto`, `subtle`, `node:crypto`
- Secret handling: any reference to env keys (`SUPABASE_*`, `STRIPE_*`, `SENTRY_*`, etc.)

## Outputs

- `.claude/scratch/security-review-findings-<branch>.json` (same shape as `/self-review`).

## Procedure

1. **Read the diff** for matching files.
2. **Read `~/.claude/rules/08-security-webhooks.md`** and `~/.claude/rules/02-database-rls.md` in full.
3. **Run the checklist:**

   **Auth + RLS**
   - JWT validated via `supabase.auth.getUser(token)` before any DB access?
   - `set local request.jwt.claims = ...` set on the per-request session before queries?
   - Service-role / `sb_secret_*` references in user-request paths? (Blocker — hook should already have caught.)
   - New `pgTable` ships with `enableRowLevelSecurity()` + `pgPolicy`?
   - Policy tests added under `tests/db/policies/<table>.test.ts`?

   **Webhooks**
   - Signature verification BEFORE body read?
   - Timestamp check (≤5min)?
   - Idempotency dedupe via KV with TTL?
   - Enqueue + ack 200, not inline processing?
   - Official provider SDK (no hand-rolled HMAC)?

   **Crypto + dangerous primitives**
   - `eval` / `new Function` / `setTimeout(string)`? (Blocker — hook backstop.)
   - `dangerouslySetInnerHTML` without `// Sanitized:` + DOMPurify wrap?
   - Hand-rolled HMAC / signature verification?

   **Secrets**
   - `.env*` / `*.pem` / `*.key` staged? (Hook backstop.)
   - Hardcoded keys (long-base64 / `sk_live_*` / `eyJ*`)?
   - Service-role/secret used outside admin paths?

   **HTTP security**
   - CSP includes `unsafe-inline` / `unsafe-eval`?
   - CORS `*` in production?
   - HSTS missing in production?

   **Rate limiting**
   - Auth-adjacent endpoint without DO-backed rate limiting?
   - AI / embedding endpoint without rate limiting?

4. **Emit findings JSON.**

## Failure mode

- Diff doesn't actually match the globs (false invocation) → `pass`, no findings.
- Ambiguity around whether a service path counts as "admin" (where service-role is OK) → `ambiguous`, escalate.

## Tool permissions

Read-only. No `Edit` / `Write`.
