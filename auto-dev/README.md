# Auto-Dev Plugin

Autonomous development orchestrator for Claude Code with intelligent specialist delegation, multi-agent review battles, and automated PR workflows.

## Features

- **7-Phase Workflow**: Setup → Planning → Development → Cleanup → PR → Review → Merge
- **Intelligent Delegation**: Automatically routes tasks to specialist agents based on project complexity
- **Multi-Agent Review**: 4 reviewers run in parallel with voting-based consensus
- **Mobile Support**: Native Expo, React Native, and Supabase integration
- **Loop Automation**: Continues until completion or max iterations

## Installation

### Quick Install

```bash
# Clone or download this plugin
git clone <repo-url>
cd auto-dev

# Run setup to check dependencies
./setup.sh

# Install the plugin
claude plugins install --path .
```

### Manual Install

1. Copy the `auto-dev` folder to your plugins directory
2. Run `claude plugins install --path /path/to/auto-dev`

## Dependencies

### Required Plugins

These plugins are required for core functionality:

| Plugin | Purpose | Install |
|--------|---------|---------|
| `superpowers` | Brainstorming, planning, verification skills | `claude plugins install superpowers@claude-plugins-official` |
| `pr-review-toolkit` | Multi-agent code review | `claude plugins install pr-review-toolkit@claude-plugins-official` |

### Recommended Plugins

These plugins enhance functionality for specific stacks:

| Plugin | Purpose | Install |
|--------|---------|---------|
| `feature-dev` | Code architect and explorer agents | `claude plugins install feature-dev@claude-plugins-official` |
| `expo-app-design` | Mobile development skills | `claude plugins install expo-app-design@expo-plugins` |
| `supabase` | Database and backend integration | `claude plugins install supabase@claude-plugins-official` |

### Recommended Agents

Install these agents in `~/.claude/agents/` for specialist delegation:

| Agent | Specialty |
|-------|-----------|
| `react-specialist` | React hooks, state, components |
| `typescript-pro` | Advanced TypeScript types |
| `mobile-developer` | React Native/Expo apps |
| `mobile-app-developer` | Native mobile features |
| `backend-developer` | API routes, business logic |
| `postgres-pro` | PostgreSQL optimization |
| `security-engineer` | Auth, encryption, security |
| `frontend-developer` | UI components, styling |
| `api-designer` | REST/GraphQL design |

You can install community agents from [awesome-claude-code-subagents](https://github.com/anthropics/awesome-claude-code-subagents).

## Usage

### Basic Usage

```bash
# Start autonomous development for a feature
/auto-dev "Add user authentication with JWT"

# With options
/auto-dev "Build REST API" --max-iterations 50
/auto-dev "Fix login bug" --no-worktree
/auto-dev "Add dark mode" --auto-merge
```

### Check Status

```bash
/auto-dev-status
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--max-iterations N` | Maximum loop iterations | 100 |
| `--no-worktree` | Work in current directory | Creates worktree |
| `--auto-merge` | Auto-merge on review approval | Manual merge |

## How It Works

### Phase 1: SETUP
- Creates isolated git worktree
- Detects project stack (React, TypeScript, Expo, Supabase, etc.)
- Calculates complexity score (1-10)

### Phase 2: PLANNING
- Invokes brainstorming skill for requirements exploration
- Creates detailed implementation plan
- Gets user approval before proceeding

### Phase 3: DEVELOPMENT
- Executes plan tasks in order
- Delegates to specialist agents based on complexity:
  - Low (1-3): Handles directly
  - Medium (4-6): Selective delegation
  - High (7-10): Heavy delegation with architect coordination

### Phase 4: CLEANUP
- Removes dead code and unused imports
- Ensures consistent formatting
- Runs linting and verification

### Phase 5: PR_CREATION
- Creates pull request with summary and test plan
- Uses `gh` CLI for GitHub integration

### Phase 6: REVIEW (Review Battle)
- Launches 4 review agents in parallel:
  - `code-reviewer` - Guidelines and bugs
  - `code-simplifier` - Clarity and maintainability
  - `silent-failure-hunter` - Error handling
  - `pr-test-analyzer` - Test coverage
- Voting rules:
  - 3/4 approvals = Approved
  - Any critical issue = Blocked
  - < 3 approvals = Needs fixes (max 5 rounds)

### Phase 7: MERGE
- Runs pre-merge checks (CI, conflicts, consensus)
- Executes merge if `--auto-merge` enabled
- Otherwise reports ready status

## Mobile Development

Auto-dev has enhanced support for mobile projects:

### Expo Detection
- Detects `app.json` with Expo config
- Detects `expo-router` for navigation
- Invokes Expo skills automatically:
  - `expo-app-design:building-native-ui`
  - `expo-app-design:native-data-fetching`
  - `expo-app-design:expo-dev-client`

### Supabase Integration
- Detects `@supabase/supabase-js` in dependencies
- Uses Supabase MCP tools for:
  - Schema migrations
  - SQL execution
  - Edge function deployment

### Mobile Specialists
- `mobile-developer` - Cross-platform development
- `mobile-app-developer` - Native features and performance

## Configuration

### State File

Auto-dev creates `.claude/auto-dev.local.md` with YAML frontmatter tracking:
- Current phase and status
- Iteration count
- Detected stack and complexity
- Specialists invoked
- Review round results

### Completion

To complete the workflow, the assistant outputs:
```
<promise>AUTO-DEV COMPLETE</promise>
```

This only happens when all criteria are met:
- All tasks implemented
- All tests passing
- PR created and reviewed
- Merge ready (or completed)

## Troubleshooting

### Missing Dependencies

Run `./setup.sh` to check for missing plugins and agents.

### Loop Not Continuing

Check that `.claude/auto-dev.local.md` exists and has valid YAML frontmatter.

### Review Stuck

If reviews are stuck in "needs-fixes" loop:
1. Check the feedback from each reviewer
2. Address ALL issues, not just some
3. Maximum 5 rounds before human escalation

## Contributing

Issues and PRs welcome! Please include:
- Description of the problem or feature
- Steps to reproduce (for bugs)
- Expected vs actual behavior

## License

MIT
