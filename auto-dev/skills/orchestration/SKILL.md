---
name: orchestration
description: "Use when coordinating multi-phase autonomous development with specialist delegation"
---

# Orchestration Skill

## Overview

This skill guides intelligent delegation and coordination during autonomous development workflows. Use it to determine when to delegate to specialists vs handle directly.

## Delegation Heuristics Table

| Domain | Complexity Signal | Delegate To | When to Handle Directly |
|--------|-------------------|-------------|------------------------|
| **React** | Custom hooks, context, complex state | `react-specialist` | Simple components, basic props |
| **TypeScript** | Generics, conditional types, mapped types | `typescript-pro` | Basic interfaces, simple types |
| **Architecture** | Multi-service, new patterns, scale concerns | `feature-dev:code-architect` | Following existing patterns |
| **Database** | Schema changes, complex queries, migrations | `postgres-pro` | Simple CRUD operations |
| **Security** | Auth flows, encryption, user data | `security-engineer` | Non-sensitive operations |
| **API Design** | New endpoints, versioning, contracts | `api-designer` | Extending existing endpoints |
| **Frontend** | Complex UI, animations, accessibility | `frontend-developer` | Simple styling changes |
| **Backend** | Business logic, integrations, caching | `backend-developer` | Simple route handlers |
| **Exploration** | Understanding large codebases | `feature-dev:code-explorer` | Small, focused searches |
| **Mobile/Expo** | Navigation, native APIs, platform-specific | `mobile-developer` | Simple UI tweaks |
| **React Native** | Native modules, performance, gestures | `mobile-app-developer` | Basic React components |
| **Supabase** | Auth, realtime, edge functions | Use Supabase MCP tools | Simple queries |

## Complexity Thresholds

Based on the `complexity_score` from project detection (1-10):

### Low Complexity (1-3)
- Handle most tasks directly
- Delegate only for specialized domains (security, complex types)
- Focus on speed over coordination overhead

### Medium Complexity (4-6)
- Delegate complex subtasks to specialists
- Use code-explorer for understanding existing patterns
- Coordinate multiple specialists if needed

### High Complexity (7-10)
- Heavy delegation recommended
- Use `feature-dev:code-architect` for coordination
- Break down into smaller, delegatable units
- Consider parallel agent dispatch for independent tasks

## Specialist Selection Rules

### Must Delegate (Non-negotiable)
- Security-sensitive code → `security-engineer`
- Database schema changes → `postgres-pro` or `database-administrator`
- New architectural patterns → `feature-dev:code-architect`

### Should Delegate (Recommended)
- React state management → `react-specialist`
- Complex TypeScript types → `typescript-pro`
- API contract design → `api-designer`

### May Handle Directly
- Following existing patterns exactly
- Simple CRUD operations
- Bug fixes in isolated code
- Documentation updates

## Mobile Development Rules

When detected stack includes `expo`, `react-native`, or mobile patterns:

### Expo Projects

**Always invoke skills for:**
- Navigation setup → `expo-app-design:building-native-ui`
- Data fetching → `expo-app-design:native-data-fetching`
- API routes → `expo-app-design:expo-api-routes`
- Dev builds → `expo-app-design:expo-dev-client`
- Styling setup → `expo-app-design:expo-tailwind-setup`
- SDK upgrades → `upgrading-expo:upgrading-expo`

**Delegate to specialists:**
- Complex navigation patterns → `mobile-developer`
- Platform-specific features → `mobile-app-developer`
- Performance optimization → `mobile-developer`
- Native module integration → `mobile-app-developer`

### Supabase Projects

**Use MCP tools for:**
- Schema design → `mcp__plugin_supabase_supabase__apply_migration`
- Query execution → `mcp__plugin_supabase_supabase__execute_sql`
- Edge functions → `mcp__plugin_supabase_supabase__deploy_edge_function`
- Project setup → `mcp__plugin_supabase_supabase__get_project_url`

**Load tools with ToolSearch:**
```
ToolSearch(query: "+supabase execute")
ToolSearch(query: "+supabase migration")
```

### Mobile + Supabase Integration

Common patterns:
1. Auth → Supabase Auth + Expo SecureStore
2. Realtime → Supabase Realtime subscriptions
3. Storage → Supabase Storage + Expo FileSystem
4. Push notifications → Supabase + Expo Notifications

## Phase Transition Checklist

### SETUP → PLANNING
- [ ] Project detection complete
- [ ] Stack identified in state file
- [ ] Complexity score calculated
- [ ] Existing patterns documented

### PLANNING → DEVELOPMENT
- [ ] Brainstorming skill invoked
- [ ] Writing-plans skill invoked
- [ ] Plan has clear task breakdown
- [ ] User approved approach

### DEVELOPMENT → CLEANUP
- [ ] All planned tasks completed
- [ ] Tests written and passing
- [ ] No TODO comments left
- [ ] Commits made incrementally

### CLEANUP → PR_CREATION
- [ ] No linting errors
- [ ] No unused imports/variables
- [ ] Code formatted consistently
- [ ] Documentation accurate

### PR_CREATION → REVIEW
- [ ] PR created with gh CLI
- [ ] Title under 70 characters
- [ ] Description includes summary and test plan
- [ ] PR number recorded in state file

### REVIEW → MERGE
- [ ] 4 review agents ran in parallel
- [ ] Vote aggregation complete
- [ ] 3/4 approvals achieved
- [ ] No critical issues outstanding

### MERGE → COMPLETE
- [ ] Pre-merge checks passed
- [ ] CI green
- [ ] No merge conflicts
- [ ] Merge executed (or ready for human)

## Review Voting Rules

### Approval Threshold
- **Approved**: 3 or more of 4 reviewers approve
- **Needs Fixes**: < 3 approvals, no critical issues
- **Blocked**: Any reviewer flags a CRITICAL issue

### Critical Issue Definition
A critical issue is one that:
- Introduces security vulnerabilities
- Breaks existing functionality
- Causes data loss or corruption
- Violates fundamental architectural constraints

### Review Round Limits
- Maximum 5 review rounds
- After round 5: escalate to human review
- Each round should address ALL feedback, not just some

## Auto-Merge Criteria

Auto-merge is allowed when ALL conditions met:
1. `--auto-merge` flag was passed
2. Review vote is "approved"
3. CI checks passing
4. No merge conflicts
5. No commits since last review round
6. PR is not to protected branch (main/master requires human)

## Parallel Agent Dispatch

When tasks are independent, dispatch multiple agents simultaneously:

```
# Good: Independent tasks in parallel
Task(react-specialist, "Build LoginForm component")
Task(backend-developer, "Create /auth/login endpoint")
Task(postgres-pro, "Design users table schema")
```

**Independence criteria:**
- Different files/modules
- No shared state
- No sequential dependencies
- Can be integrated after completion

**Do NOT parallelize when:**
- Tasks modify same files
- One task depends on another's output
- Shared database migrations
- Integration testing needed between tasks

## Error Recovery Patterns

### Test Failures
1. Read failure output carefully
2. Identify root cause (logic vs environment)
3. Fix implementation
4. Re-run specific test
5. Continue only when green

### Review Rejections
1. Read ALL feedback (not just first issue)
2. Address systematically
3. Do not argue with reviewers
4. Commit fixes
5. Re-run review round

### Merge Conflicts
1. Fetch latest from base branch
2. Rebase feature branch
3. Resolve conflicts preserving both changes
4. Re-run tests
5. Update PR

### Stuck Loops
If iteration count climbing without progress:
1. Document current state
2. Identify blocking issue
3. Ask for human guidance
4. Do NOT output false completion promise
