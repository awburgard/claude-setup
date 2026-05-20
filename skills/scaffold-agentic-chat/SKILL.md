---
name: scaffold-agentic-chat
description: Scaffolds an agentic chat loop — XState v5 machine + Vercel AI SDK loop + tools adapter + telemetry config + initial Gherkin feature file. Use when the user says "scaffold an agent", "build an agentic chat", "set up the chat loop for X", "agentic chat for X feature". Halts unless the feature directory exists — must follow /trd and /generate-bdd.
allowed_tools: [Read, Bash, Write, Edit]
---

# /scaffold-agentic-chat

Stands up the canonical pattern for agentic chat: state-machine-driven, AI-SDK-powered, tool-calling.

## Inputs

- Feature name (kebab-case): `relationship-extraction`, `support-triage`.
- Tool list (service-method names that the agent can call).

## Outputs

- `packages/worker/src/services/agents/<feature>/machine.ts` — XState v5 machine.
- `packages/worker/src/services/agents/<feature>/loop.ts` — AI SDK loop (streamText with tools).
- `packages/worker/src/services/agents/<feature>/tools.ts` — tools adapter (delegates to existing service methods).
- `packages/worker/src/services/agents/<feature>/index.ts` — `createAgent<Feature>` factory.
- `packages/worker/src/services/agents/<feature>/index.test.ts` — integration test stub.
- `initiatives/<slug>/features/<feature>-chat.feature` — Gherkin file with one scenario per state transition.
- Telemetry config: `functionId: 'agents.<feature>'`.
- Status JSON: `.claude/scratch/scaffold-agentic-chat-result-<sid>.json`.

## Procedure

1. **Verify prerequisites.** Initiative directory + TRD + features dir exist. Halt otherwise — agentic chat is initiative-class work.
2. **Read the TRD** via `~/.claude/sops/read-initiative-context.md` to understand the agent's job-to-be-done.
3. **Confirm tool list with user.** Each tool maps to a service method exposed via its `tools.ts` adapter (from `/scaffold-entity` or existing services).
4. **Write the XState v5 machine.** States cover at minimum: `idle`, `thinking`, `tool-calling`, `responding`, `error`. Transitions are typed. Context is `Immutable<>`.
5. **Write the loop.** Vercel AI SDK `streamText` with tools + telemetry. Emits state-machine events on tool calls / completions / errors. Handles tool errors via the boundary `throw` convention (`05-ai-agents.md` #2).
6. **Write the tools adapter** that re-exports the service-method tools, scoped to the agent's permitted set.
7. **Write the factory** `createAgent<Feature>(deps: Pick<WorkerDeps, ...>)` returning `{run, stop, getState}`.
8. **Write the integration test stub** that drives one full happy-path interaction (real Supabase local + mocked AI response).
9. **Write the initial Gherkin file** — one scenario per top-level state transition.
10. **Surface next steps:**
    - First ADR captured for this agent (trigger a: first XState use, if applicable).
    - Wire the agent into the route layer.
    - Run `/generate-tasks` to break out remaining work.

## Failure mode

- Initiative dir missing → halt; suggest `/explore` + `/trd`.
- Features dir missing → halt; suggest `/generate-bdd`.
- Service method named in tool list doesn't exist → halt; surface for the user to scaffold it (`/scaffold-entity`-derived method).
