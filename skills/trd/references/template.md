---
Status: Active
Created: {{date}}
Slug: {{slug}}
Supersedes:
Superseded by:
---

# TRD: {{title}}

## Goals
- ...

## Non-goals
- ...

## User flows

### Flow: {{flow-name}}
Given ...
When ...
Then ...

## Data model

### Entity: {{Entity}}
- PK: `{{Entity}}Id` (branded, Zod)
- Columns: ...
- RLS: `auth.uid() = user_id` (or per-table policy)
- Indexes: ...

## Service surface

### Service: `{{service}}`
- `{{method}}({{Method}}Input) -> Result<{{Method}}Output, {{Method}}Error>`
  - LLM tool: yes / no
  - Notes: ...

## AI surface
- Calls: ...
- Telemetry `functionId`s: `<feature>.<method>`
- Any `@anthropic-ai/sdk` escapes: (none) or (list with `// Escape: <feature>`)

## Async work
- Synchronous-in-request: ...
- Queues: ...
- Workflows: ...
- Durable Objects: ...

## Failure modes
- ...

## Open questions
- ...

## ADR captures
- [ ] (trigger letter) — short description — captured at `docs/adr/NNNN-<title>.md`
