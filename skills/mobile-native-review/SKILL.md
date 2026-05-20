---
name: mobile-native-review
description: Subagent that reviews packages/mobile/ changes touching native modules, app.config.ts, or eas.json — checks Expo SDK compat and whether OTA vs native rebuild is correctly applied. Use when those globs change in a mobile project, the user says "mobile native review", "is this OTA-safe", "EAS update or build", or runs as part of /pr-create's chain when a mobile project is in scope.
allowed_tools: [Read, Bash, Grep, mcp__context7]
---

# /mobile-native-review

Mobile native-side review. Path-scoped to mobile projects.

## Fires on globs

- `packages/mobile/package.json` (with native-dep additions: post-install scripts, `react-native` peer, `ios/`/`android/` folders, or known native-module names)
- `packages/mobile/app.config.ts`
- `packages/mobile/eas.json`
- Any `packages/mobile/**/*.podspec` or `packages/mobile/android/**/*.gradle`

## Outputs

- `.claude/scratch/mobile-native-review-findings-<branch>.json`.

## Procedure

1. **Read the diff.**
2. **Read `~/.claude/rules/07-mobile.md`** in full (paths-scoped rule).
3. **Consult Context7** for the current pinned Expo SDK version (`07-mobile.md` references the lib list).

### Native-dep checks
- New package adds a `react-native` peer or has `ios/`/`android/` folders? → native rebuild required (EAS Build, not EAS Update).
- Expo SDK compatibility: is the package's `react-native` peer compatible with the project's Expo SDK pinned version?
- Post-install scripts present in the new package? Flag.

### `app.config.ts` checks
- Function form (reads `process.env.APP_ENV`)? Static-object form is a blocker.
- Per-env values (`name`, `slug`, `ios.bundleIdentifier`, `android.package`, `extra.{supabaseUrl, workerUrl}`, `runtimeVersion`)?
- `runtimeVersion` bumped if the change is a native rebuild? Static `runtimeVersion` across native rebuilds breaks OTA semantics.
- No hardcoded strings?

### `eas.json` checks
- Build profiles aligned with `APP_ENV` (`dev` / `preview` / `production`)?
- `env` per profile uses EAS secrets (not inline keys)?
- Submit profiles configured for the project's release path?

### OTA vs rebuild decision
- Pure JS change → EAS Update.
- Touched any of: native deps, `app.config.ts`, `assets/`, Expo config plugins, `runtimeVersion` → EAS Build (rebuild).
- Surface the recommended deploy path in the findings.

## Failure mode

- Native-dep change without `runtimeVersion` bump → blocker.
- `app.config.ts` static form → blocker.
- Expo SDK incompatibility detected → blocker.

## Tool permissions

Read-only on filesystem; Context7 for Expo SDK version lookup.
