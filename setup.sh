#!/bin/bash

# Claude Code Setup Restoration Script
# Restores agents, settings, and installs plugins

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "Claude Code Setup Restoration"
echo "=========================================="
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/plugins"

# Copy agents
echo "Copying agents..."
if [ -d "$SCRIPT_DIR/agents" ]; then
    cp "$SCRIPT_DIR/agents/"*.md "$CLAUDE_DIR/agents/"
    echo "  ✓ Copied $(ls -1 "$SCRIPT_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ') agent files"
else
    echo "  ⚠ No agents directory found"
fi

# Copy settings
echo "Copying settings..."
if [ -f "$SCRIPT_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "  ✓ Copied settings.json"
else
    echo "  ⚠ No settings.json found"
fi

echo ""
echo "=========================================="
echo "Installing Plugins"
echo "=========================================="
echo ""

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "⚠ Claude CLI not found. Please install it first, then run:"
    echo ""
    echo "  # Add marketplaces"
    echo "  claude plugins add-marketplace https://github.com/anthropics/claude-plugins-official"
    echo "  claude plugins add-marketplace https://github.com/expo/expo-plugins"
    echo ""
    echo "  # Then run this script again"
    exit 1
fi

# Add marketplaces
echo "Adding plugin marketplaces..."
claude plugins add-marketplace https://github.com/anthropics/claude-plugins-official 2>/dev/null || true
claude plugins add-marketplace https://github.com/expo/expo-plugins 2>/dev/null || true
echo "  ✓ Marketplaces configured"

# Install official plugins
echo ""
echo "Installing official plugins..."

OFFICIAL_PLUGINS=(
    "frontend-design"
    "context7"
    "feature-dev"
    "code-review"
    "ralph-loop"
    "code-simplifier"
    "typescript-lsp"
    "commit-commands"
    "security-guidance"
    "superpowers"
    "pr-review-toolkit"
    "supabase"
    "figma"
    "atlassian"
    "greptile"
)

for plugin in "${OFFICIAL_PLUGINS[@]}"; do
    echo "  Installing $plugin..."
    claude plugins install "$plugin@claude-plugins-official" 2>/dev/null || echo "    ⚠ Failed or already installed: $plugin"
done

# Install expo plugins
echo ""
echo "Installing expo plugins..."

EXPO_PLUGINS=(
    "expo-app-design"
    "upgrading-expo"
)

for plugin in "${EXPO_PLUGINS[@]}"; do
    echo "  Installing $plugin..."
    claude plugins install "$plugin@expo-plugins" 2>/dev/null || echo "    ⚠ Failed or already installed: $plugin"
done

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Installed:"
echo "  • $(ls -1 "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ') agents"
echo "  • ${#OFFICIAL_PLUGINS[@]} official plugins"
echo "  • ${#EXPO_PLUGINS[@]} expo plugins"
echo ""
echo "Restart Claude Code to apply changes."
