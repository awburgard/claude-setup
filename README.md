# Claude Code Setup Backup

Personal backup of Claude Code configuration including agents, plugins, and settings.

## Contents

```
claude-setup/
├── agents/                    # 34 custom agent definitions
├── plugins/
│   ├── installed_plugins.json # Plugin installation manifest
│   └── known_marketplaces.json
├── settings.json              # Enabled plugins configuration
├── setup.sh                   # Restoration script
└── README.md
```

## Installed Plugins

### Official Plugins (claude-plugins-official)
- `frontend-design` - Frontend design skill
- `context7` - Context management
- `feature-dev` - Feature development workflow
- `code-review` - Code review skill
- `ralph-loop` - Ralph loop automation
- `code-simplifier` - Code simplification
- `typescript-lsp` - TypeScript language server
- `commit-commands` - Git commit helpers
- `security-guidance` - Security best practices
- `superpowers` - Enhanced skills and workflows
- `pr-review-toolkit` - PR review agents
- `supabase` - Supabase integration
- `figma` - Figma design integration
- `atlassian` - Jira/Confluence integration
- `greptile` - Code search and review

### Expo Plugins (expo-plugins)
- `expo-app-design` - Expo app development skills
- `upgrading-expo` - Expo SDK upgrade assistance

## Agents (34 total)

| Agent | Description |
|-------|-------------|
| agent-installer | Install agents from awesome-claude-code-subagents |
| agent-organizer | Multi-agent orchestration |
| api-designer | REST/GraphQL API design |
| api-documenter | API documentation |
| architect-reviewer | Architecture review |
| backend-developer | Backend development |
| build-engineer | Build system optimization |
| context-manager | Context management |
| data-analyst | Data analysis and BI |
| database-administrator | Database administration |
| database-optimizer | Query optimization |
| dependency-manager | Package management |
| documentation-engineer | Technical documentation |
| dx-optimizer | Developer experience |
| frontend-developer | Frontend development |
| fullstack-developer | Full-stack development |
| javascript-pro | JavaScript specialist |
| knowledge-synthesizer | Knowledge extraction |
| legacy-modernizer | Legacy system migration |
| mobile-app-developer | Mobile development |
| mobile-developer | Cross-platform mobile |
| multi-agent-coordinator | Agent coordination |
| performance-monitor | Performance monitoring |
| postgres-pro | PostgreSQL specialist |
| react-specialist | React development |
| refactoring-specialist | Code refactoring |
| security-engineer | Security engineering |
| seo-specialist | SEO optimization |
| sql-pro | SQL development |
| task-distributor | Task allocation |
| tooling-engineer | Developer tooling |
| typescript-pro | TypeScript specialist |
| ui-designer | UI design |
| workflow-orchestrator | Workflow automation |

## Restoration

### Quick Setup
```bash
./setup.sh
```

### Manual Setup

1. **Copy agents:**
   ```bash
   mkdir -p ~/.claude/agents
   cp agents/*.md ~/.claude/agents/
   ```

2. **Copy settings:**
   ```bash
   cp settings.json ~/.claude/settings.json
   ```

3. **Install plugins via Claude Code CLI:**
   ```bash
   # Add marketplaces
   claude plugins add-marketplace https://github.com/anthropics/claude-plugins-official
   claude plugins add-marketplace https://github.com/expo/expo-plugins

   # Install each plugin
   claude plugins install frontend-design@claude-plugins-official
   claude plugins install context7@claude-plugins-official
   claude plugins install feature-dev@claude-plugins-official
   claude plugins install code-review@claude-plugins-official
   claude plugins install ralph-loop@claude-plugins-official
   claude plugins install code-simplifier@claude-plugins-official
   claude plugins install typescript-lsp@claude-plugins-official
   claude plugins install commit-commands@claude-plugins-official
   claude plugins install security-guidance@claude-plugins-official
   claude plugins install superpowers@claude-plugins-official
   claude plugins install pr-review-toolkit@claude-plugins-official
   claude plugins install supabase@claude-plugins-official
   claude plugins install figma@claude-plugins-official
   claude plugins install atlassian@claude-plugins-official
   claude plugins install greptile@claude-plugins-official
   claude plugins install expo-app-design@expo-plugins
   claude plugins install upgrading-expo@expo-plugins
   ```

## Backup Date

Created: 2026-01-31
