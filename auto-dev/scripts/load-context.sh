#!/bin/bash

# Auto-Dev Context Loader
# Discovers and loads available project context automatically
#
# Features:
#   - GitHub issue fetching (if gh CLI available)
#   - CLAUDE.md project conventions
#   - Design docs discovery
#   - Optional project config (.claude/auto-dev.config.yml)

set -euo pipefail

# Input: prompt text (may contain #123 issue references)
PROMPT="${1:-}"
OUTPUT_FILE="${2:-.claude/auto-dev-context.md}"

# Initialize context sections
GITHUB_CONTEXT=""
PROJECT_CONTEXT=""
DOCS_CONTEXT=""
CONFIG_CONTEXT=""

# Track what was discovered
DISCOVERED=()

echo "Loading project context..." >&2

# =============================================================================
# 1. GitHub Issue Detection
# =============================================================================

# Check if gh CLI is available and authenticated
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
  # Extract issue numbers from prompt (matches #123, #42, etc.)
  ISSUE_NUMBERS=$(echo "$PROMPT" | grep -oE '#[0-9]+' | tr -d '#' | sort -u)

  if [[ -n "$ISSUE_NUMBERS" ]]; then
    GITHUB_CONTEXT="## GitHub Issues\n\n"

    for issue_num in $ISSUE_NUMBERS; do
      echo "  Fetching GitHub issue #$issue_num..." >&2

      # Fetch issue details
      ISSUE_DATA=$(gh issue view "$issue_num" --json title,body,labels,state,comments 2>/dev/null || echo "")

      if [[ -n "$ISSUE_DATA" ]]; then
        TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')
        BODY=$(echo "$ISSUE_DATA" | jq -r '.body // "No description"')
        STATE=$(echo "$ISSUE_DATA" | jq -r '.state')
        LABELS=$(echo "$ISSUE_DATA" | jq -r '.labels[].name' 2>/dev/null | tr '\n' ', ' | sed 's/, $//')

        GITHUB_CONTEXT+="### Issue #$issue_num: $TITLE\n\n"
        GITHUB_CONTEXT+="**State:** $STATE\n"
        [[ -n "$LABELS" ]] && GITHUB_CONTEXT+="**Labels:** $LABELS\n"
        GITHUB_CONTEXT+="\n**Description:**\n$BODY\n\n"

        DISCOVERED+=("github-issue-$issue_num")
      else
        echo "  Warning: Could not fetch issue #$issue_num" >&2
      fi
    done
  fi
else
  if echo "$PROMPT" | grep -qE '#[0-9]+'; then
    echo "  Note: gh CLI not available, skipping issue fetch" >&2
  fi
fi

# =============================================================================
# 2. CLAUDE.md Project Conventions
# =============================================================================

if [[ -f "CLAUDE.md" ]]; then
  echo "  Found CLAUDE.md" >&2
  PROJECT_CONTEXT="## Project Conventions (CLAUDE.md)\n\n"
  PROJECT_CONTEXT+="$(cat CLAUDE.md)\n\n"
  DISCOVERED+=("claude-md")
elif [[ -f ".claude/CLAUDE.md" ]]; then
  echo "  Found .claude/CLAUDE.md" >&2
  PROJECT_CONTEXT="## Project Conventions (CLAUDE.md)\n\n"
  PROJECT_CONTEXT+="$(cat .claude/CLAUDE.md)\n\n"
  DISCOVERED+=("claude-md")
fi

# =============================================================================
# 3. Design Docs Discovery
# =============================================================================

# Common doc locations to check
DOC_LOCATIONS=(
  "docs"
  "doc"
  ".github"
  "documentation"
)

# Common doc file patterns
DOC_PATTERNS=(
  "DESIGN*.md"
  "ARCHITECTURE*.md"
  "STYLE*.md"
  "CONTRIBUTING*.md"
  "SCOPES*.yml"
  "SCOPES*.yaml"
  "TASKS*.md"
  "TODO*.md"
)

FOUND_DOCS=()

for loc in "${DOC_LOCATIONS[@]}"; do
  if [[ -d "$loc" ]]; then
    for pattern in "${DOC_PATTERNS[@]}"; do
      while IFS= read -r -d '' doc; do
        FOUND_DOCS+=("$doc")
      done < <(find "$loc" -maxdepth 2 -name "$pattern" -print0 2>/dev/null)
    done
  fi
done

# Also check root directory
for pattern in "${DOC_PATTERNS[@]}"; do
  while IFS= read -r -d '' doc; do
    FOUND_DOCS+=("$doc")
  done < <(find . -maxdepth 1 -name "$pattern" -print0 2>/dev/null)
done

if [[ ${#FOUND_DOCS[@]} -gt 0 ]]; then
  echo "  Found ${#FOUND_DOCS[@]} design doc(s)" >&2
  DOCS_CONTEXT="## Available Design Documents\n\n"
  DOCS_CONTEXT+="The following design documents are available for reference:\n\n"

  for doc in "${FOUND_DOCS[@]}"; do
    # Get file size
    SIZE=$(wc -c < "$doc" | tr -d ' ')
    LINES=$(wc -l < "$doc" | tr -d ' ')
    DOCS_CONTEXT+="- \`$doc\` ($LINES lines)\n"
  done

  DOCS_CONTEXT+="\n**Tip:** Read these docs during planning phase for project-specific patterns.\n\n"
  DISCOVERED+=("design-docs")
fi

# =============================================================================
# 4. Project Config (.claude/auto-dev.config.yml)
# =============================================================================

CONFIG_FILE=".claude/auto-dev.config.yml"

if [[ -f "$CONFIG_FILE" ]]; then
  echo "  Found project config: $CONFIG_FILE" >&2
  CONFIG_CONTEXT="## Project Configuration\n\n"
  CONFIG_CONTEXT+="Custom auto-dev configuration found:\n\n"
  CONFIG_CONTEXT+="\`\`\`yaml\n$(cat "$CONFIG_FILE")\n\`\`\`\n\n"
  DISCOVERED+=("project-config")

  # Parse config for custom task file
  if command -v yq &> /dev/null; then
    TASK_FILE=$(yq -r '.task_file // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$TASK_FILE" ]] && [[ -f "$TASK_FILE" ]]; then
      echo "  Loading custom task file: $TASK_FILE" >&2
      # Check if it's YAML or MD
      if [[ "$TASK_FILE" == *.yml ]] || [[ "$TASK_FILE" == *.yaml ]]; then
        CONFIG_CONTEXT+="### Task Definitions ($TASK_FILE)\n\n"
        CONFIG_CONTEXT+="\`\`\`yaml\n$(cat "$TASK_FILE")\n\`\`\`\n\n"
      else
        CONFIG_CONTEXT+="### Task Definitions ($TASK_FILE)\n\n"
        CONFIG_CONTEXT+="$(cat "$TASK_FILE")\n\n"
      fi
      DISCOVERED+=("custom-tasks")
    fi
  fi
fi

# =============================================================================
# 5. Output Context File
# =============================================================================

mkdir -p "$(dirname "$OUTPUT_FILE")"

{
  echo "# Auto-Dev Context"
  echo ""
  echo "This context was automatically discovered for your project."
  echo ""
  echo "**Discovered sources:** ${DISCOVERED[*]:-none}"
  echo ""
  echo "---"
  echo ""

  [[ -n "$GITHUB_CONTEXT" ]] && echo -e "$GITHUB_CONTEXT"
  [[ -n "$PROJECT_CONTEXT" ]] && echo -e "$PROJECT_CONTEXT"
  [[ -n "$DOCS_CONTEXT" ]] && echo -e "$DOCS_CONTEXT"
  [[ -n "$CONFIG_CONTEXT" ]] && echo -e "$CONFIG_CONTEXT"

  if [[ ${#DISCOVERED[@]} -eq 0 ]]; then
    echo "No additional context discovered. Using prompt as-is."
    echo ""
    echo "**Tip:** Add a CLAUDE.md file or docs/ folder for project-specific guidance."
  fi

} > "$OUTPUT_FILE"

# Output summary as JSON for the setup script
jq -n \
  --arg prompt "$PROMPT" \
  --argjson discovered "$(printf '%s\n' "${DISCOVERED[@]:-}" | jq -R . | jq -s .)" \
  --arg context_file "$OUTPUT_FILE" \
  --argjson doc_count "${#FOUND_DOCS[@]}" \
  '{
    prompt: $prompt,
    discovered: $discovered,
    context_file: $context_file,
    docs_found: $doc_count,
    has_github_issues: ($discovered | index("github-issue") != null),
    has_claude_md: ($discovered | index("claude-md") != null),
    has_design_docs: ($discovered | index("design-docs") != null),
    has_project_config: ($discovered | index("project-config") != null)
  }'
