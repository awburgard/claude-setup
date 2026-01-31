#!/bin/bash

# Auto-Dev Plugin Setup Script
# Checks for required and recommended dependencies

set -euo pipefail

echo "═══════════════════════════════════════════════════════════"
echo "  Auto-Dev Plugin Setup"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
REQUIRED_MISSING=0
RECOMMENDED_MISSING=0
AGENTS_MISSING=0

# Check for Claude Code CLI
echo "Checking prerequisites..."
echo ""

if ! command -v claude &> /dev/null; then
  echo -e "${RED}✗ Claude Code CLI not found${NC}"
  echo "  Install from: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
else
  echo -e "${GREEN}✓ Claude Code CLI found${NC}"
fi

if ! command -v gh &> /dev/null; then
  echo -e "${YELLOW}! GitHub CLI (gh) not found${NC}"
  echo "  Required for PR creation. Install from: https://cli.github.com"
else
  echo -e "${GREEN}✓ GitHub CLI (gh) found${NC}"
fi

if ! command -v jq &> /dev/null; then
  echo -e "${RED}✗ jq not found${NC}"
  echo "  Required for JSON parsing. Install with: brew install jq"
  exit 1
else
  echo -e "${GREEN}✓ jq found${NC}"
fi

echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Checking Required Plugins"
echo "───────────────────────────────────────────────────────────"
echo ""

# Function to check if a plugin is installed
check_plugin() {
  local plugin_name=$1
  local marketplace=$2
  local full_name="${plugin_name}@${marketplace}"

  if [[ -f ~/.claude/plugins/installed_plugins.json ]]; then
    if jq -e ".plugins[\"$full_name\"]" ~/.claude/plugins/installed_plugins.json > /dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

# Required plugins
REQUIRED_PLUGINS=(
  "superpowers:claude-plugins-official:Brainstorming, planning, verification skills"
  "pr-review-toolkit:claude-plugins-official:Multi-agent code review"
)

for plugin_info in "${REQUIRED_PLUGINS[@]}"; do
  IFS=':' read -r name marketplace desc <<< "$plugin_info"
  if check_plugin "$name" "$marketplace"; then
    echo -e "${GREEN}✓ $name${NC} - $desc"
  else
    echo -e "${RED}✗ $name${NC} - $desc"
    echo "  Install: claude plugins install ${name}@${marketplace}"
    REQUIRED_MISSING=$((REQUIRED_MISSING + 1))
  fi
done

echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Checking Recommended Plugins"
echo "───────────────────────────────────────────────────────────"
echo ""

# Recommended plugins
RECOMMENDED_PLUGINS=(
  "feature-dev:claude-plugins-official:Code architect and explorer agents"
  "expo-app-design:expo-plugins:Mobile development skills (Expo)"
  "upgrading-expo:expo-plugins:Expo SDK upgrade assistance"
  "supabase:claude-plugins-official:Supabase database integration"
  "commit-commands:claude-plugins-official:Git commit helpers"
)

for plugin_info in "${RECOMMENDED_PLUGINS[@]}"; do
  IFS=':' read -r name marketplace desc <<< "$plugin_info"
  if check_plugin "$name" "$marketplace"; then
    echo -e "${GREEN}✓ $name${NC} - $desc"
  else
    echo -e "${YELLOW}○ $name${NC} - $desc"
    echo "  Install: claude plugins install ${name}@${marketplace}"
    RECOMMENDED_MISSING=$((RECOMMENDED_MISSING + 1))
  fi
done

echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Checking Recommended Agents"
echo "───────────────────────────────────────────────────────────"
echo ""

# Recommended agents
RECOMMENDED_AGENTS=(
  "react-specialist:React hooks, state, components"
  "typescript-pro:Advanced TypeScript types"
  "mobile-developer:React Native/Expo apps"
  "mobile-app-developer:Native mobile features"
  "backend-developer:API routes, business logic"
  "postgres-pro:PostgreSQL optimization"
  "security-engineer:Auth, encryption, security"
  "frontend-developer:UI components, styling"
  "api-designer:REST/GraphQL design"
  "database-administrator:Database administration"
)

AGENTS_DIR="${HOME}/.claude/agents"

for agent_info in "${RECOMMENDED_AGENTS[@]}"; do
  IFS=':' read -r name desc <<< "$agent_info"
  if [[ -f "${AGENTS_DIR}/${name}.md" ]]; then
    echo -e "${GREEN}✓ $name${NC} - $desc"
  else
    echo -e "${YELLOW}○ $name${NC} - $desc"
    AGENTS_MISSING=$((AGENTS_MISSING + 1))
  fi
done

if [[ $AGENTS_MISSING -gt 0 ]]; then
  echo ""
  echo "  Missing agents can be installed from:"
  echo "  https://github.com/anthropics/awesome-claude-code-subagents"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [[ $REQUIRED_MISSING -gt 0 ]]; then
  echo -e "${RED}✗ $REQUIRED_MISSING required plugin(s) missing${NC}"
  echo "  Auto-dev will not work correctly without these."
  echo ""
fi

if [[ $RECOMMENDED_MISSING -gt 0 ]]; then
  echo -e "${YELLOW}○ $RECOMMENDED_MISSING recommended plugin(s) missing${NC}"
  echo "  Auto-dev will work but with reduced functionality."
  echo ""
fi

if [[ $AGENTS_MISSING -gt 0 ]]; then
  echo -e "${YELLOW}○ $AGENTS_MISSING recommended agent(s) missing${NC}"
  echo "  Specialist delegation will be limited."
  echo ""
fi

if [[ $REQUIRED_MISSING -eq 0 ]] && [[ $RECOMMENDED_MISSING -eq 0 ]] && [[ $AGENTS_MISSING -eq 0 ]]; then
  echo -e "${GREEN}✓ All dependencies satisfied!${NC}"
  echo ""
fi

echo "───────────────────────────────────────────────────────────"
echo "  Installation"
echo "───────────────────────────────────────────────────────────"
echo ""

if [[ $REQUIRED_MISSING -gt 0 ]]; then
  echo "Install required plugins first:"
  echo ""
  for plugin_info in "${REQUIRED_PLUGINS[@]}"; do
    IFS=':' read -r name marketplace desc <<< "$plugin_info"
    if ! check_plugin "$name" "$marketplace"; then
      echo "  claude plugins install ${name}@${marketplace}"
    fi
  done
  echo ""
fi

echo "To install the auto-dev plugin:"
echo ""
echo "  claude plugins install --path $(pwd)"
echo ""
echo "Then start with:"
echo ""
echo "  /auto-dev \"your feature description\""
echo ""
