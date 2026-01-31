#!/bin/bash

# Auto-Dev Setup Script
# Creates state file and optionally git worktree for autonomous development

set -euo pipefail

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=100
NO_WORKTREE=false
AUTO_MERGE=false

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Auto-Dev - Autonomous Development Orchestrator

USAGE:
  /auto-dev "<feature description>" [OPTIONS]

ARGUMENTS:
  "<feature description>"  Description of the feature to build (use quotes)

OPTIONS:
  --max-iterations <n>     Maximum iterations before auto-stop (default: 100)
  --no-worktree            Skip git worktree creation (work in current directory)
  --auto-merge             Automatically merge PR on review consensus
  -h, --help               Show this help message

DESCRIPTION:
  Starts an autonomous development workflow with 7 phases:
  1. SETUP - Initialize worktree and detect project
  2. PLANNING - Brainstorm and create implementation plan
  3. DEVELOPMENT - Execute plan with specialist delegation
  4. CLEANUP - Code quality and simplification
  5. PR_CREATION - Create pull request
  6. REVIEW - Multi-agent review battle (4 reviewers)
  7. MERGE - Auto-merge on consensus (3/4 approval)

  The workflow continues automatically until completion or max iterations.

EXAMPLES:
  /auto-dev "Add user authentication with JWT"
  /auto-dev "Build REST API for todos" --max-iterations 50
  /auto-dev "Fix checkout bug" --no-worktree
  /auto-dev "Add dark mode" --auto-merge

  # GitHub issue integration (auto-detected)
  /auto-dev "#42"                    # Fetches issue #42 details
  /auto-dev "Implement #42 and #43"  # Fetches multiple issues

CONTEXT AUTO-DISCOVERY:
  Auto-dev automatically detects and loads:
  - GitHub issues (#123 references, requires gh CLI)
  - CLAUDE.md project conventions
  - Design docs in docs/ folder
  - Custom config (.claude/auto-dev.config.yml)

MONITORING:
  /auto-dev-status  # Show current phase and progress

STOPPING:
  Output: <promise>AUTO-DEV COMPLETE</promise>
  Or reach max iterations
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer, got: $2" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --no-worktree)
      NO_WORKTREE=true
      shift
      ;;
    --auto-merge)
      AUTO_MERGE=true
      shift
      ;;
    *)
      # Non-option argument - collect as prompt parts
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join all prompt parts with spaces
FEATURE_NAME="${PROMPT_PARTS[*]}"

# Validate feature name is non-empty
if [[ -z "$FEATURE_NAME" ]]; then
  echo "Error: No feature description provided" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo '  /auto-dev "Add user authentication"' >&2
  echo '  /auto-dev "Build REST API for todos"' >&2
  echo "" >&2
  echo "For all options: /auto-dev --help" >&2
  exit 1
fi

# Generate session ID: ad-YYYYMMDD-HHMMSS-<4char>
SESSION_ID="ad-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 2)"

# Create slug from feature name (lowercase, replace spaces with dashes, keep first 30 chars)
FEATURE_SLUG=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-30)

# Get repo name from current directory
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")

# Get current branch for base
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Generate branch name
BRANCH_NAME="auto-dev/${FEATURE_SLUG}"

# Determine worktree path
if [[ "$NO_WORKTREE" == "true" ]]; then
  WORKTREE_PATH="."
else
  WORKTREE_PATH="../${REPO_NAME}-ad-${FEATURE_SLUG}-${SESSION_ID: -4}"
fi

# Create branch (and optionally worktree)
if [[ "$NO_WORKTREE" == "true" ]]; then
  # No worktree: create branch and check it out in current directory
  if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    echo "Warning: Branch ${BRANCH_NAME} already exists, switching to it" >&2
    git checkout "$BRANCH_NAME" 2>/dev/null || {
      echo "Error: Failed to checkout branch $BRANCH_NAME" >&2
      exit 1
    }
  else
    git checkout -b "$BRANCH_NAME" "$CURRENT_BRANCH" 2>/dev/null || {
      echo "Error: Failed to create branch $BRANCH_NAME" >&2
      exit 1
    }
  fi
else
  # With worktree: create branch in separate directory
  if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    echo "Warning: Branch ${BRANCH_NAME} already exists, using existing branch" >&2
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>/dev/null || {
      echo "Error: Failed to create worktree at $WORKTREE_PATH" >&2
      exit 1
    }
  else
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$CURRENT_BRANCH" 2>/dev/null || {
      echo "Error: Failed to create worktree at $WORKTREE_PATH" >&2
      exit 1
    }
  fi
fi

# Create state file directory
mkdir -p .claude

# Create state file with YAML frontmatter
cat > .claude/auto-dev.local.md <<EOF
---
version: 1
session_id: "${SESSION_ID}"
feature_name: "${FEATURE_NAME}"
branch_name: "${BRANCH_NAME}"
base_branch: "${CURRENT_BRANCH}"
worktree_path: "${WORKTREE_PATH}"
current_phase: "SETUP"
phase_status: "in_progress"
total_iterations: 1
max_total_iterations: ${MAX_ITERATIONS}
completion_promise: "AUTO-DEV COMPLETE"
auto_merge: ${AUTO_MERGE}
phases:
  SETUP: { status: "in_progress", iterations: 1 }
  PLANNING: { status: "pending" }
  DEVELOPMENT: { status: "pending", tasks: { total: 0, completed: 0 } }
  CLEANUP: { status: "pending" }
  PR_CREATION: { status: "pending", result: { pr_number: null } }
  REVIEW: { status: "pending", rounds: [] }
  MERGE: { status: "pending" }
complexity:
  overall_score: null
  detected_stack: []
specialists:
  invoked: []
review_tracking:
  total_rounds: 0
  current_round: null
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

# Auto-Dev Session: ${FEATURE_NAME}

## Current Task
Initialize project detection and begin planning phase.

## Prompt
${FEATURE_NAME}
EOF

# Get script directory for loading context script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load project context (GitHub issues, CLAUDE.md, design docs)
echo "Discovering project context..." >&2
CONTEXT_RESULT=$("$SCRIPT_DIR/load-context.sh" "$FEATURE_NAME" ".claude/auto-dev-context.md" 2>&1 | tail -1)

# Parse context discovery results
CONTEXT_SOURCES=$(echo "$CONTEXT_RESULT" | jq -r '.discovered | join(", ")' 2>/dev/null || echo "none")
HAS_ISSUES=$(echo "$CONTEXT_RESULT" | jq -r '.has_github_issues' 2>/dev/null || echo "false")
DOCS_COUNT=$(echo "$CONTEXT_RESULT" | jq -r '.docs_found' 2>/dev/null || echo "0")

# Output setup message
cat <<EOF
Auto-Dev session initialized!

Session ID: ${SESSION_ID}
Feature: ${FEATURE_NAME}
Worktree: ${WORKTREE_PATH}
Max iterations: ${MAX_ITERATIONS}
Auto-merge: ${AUTO_MERGE}
Context sources: ${CONTEXT_SOURCES:-none}

PHASE 1: SETUP
- Detect project stack and complexity
- Initialize development environment

To monitor progress: /auto-dev-status
To complete: output <promise>AUTO-DEV COMPLETE</promise>

Starting autonomous development workflow...
EOF

# Output the feature prompt for the orchestrator
echo ""
echo "---"
echo ""
echo "Feature to build: ${FEATURE_NAME}"
echo ""
echo "Begin by:"
echo "1. Read .claude/auto-dev-context.md for discovered project context"
echo "2. Run detect-project.sh to analyze the codebase"
echo "3. Update state file with detected stack and complexity"
echo "4. Invoke superpowers:brainstorming skill for planning phase"
echo "5. Create implementation plan using superpowers:writing-plans skill"
echo "6. Execute plan with appropriate specialist delegation"

# Show context summary if any was discovered
if [[ "$CONTEXT_SOURCES" != "none" ]] && [[ -n "$CONTEXT_SOURCES" ]]; then
  echo ""
  echo "Discovered context:"
  [[ "$HAS_ISSUES" == "true" ]] && echo "  - GitHub issue details loaded"
  [[ -f "CLAUDE.md" ]] && echo "  - CLAUDE.md project conventions"
  [[ "$DOCS_COUNT" -gt 0 ]] && echo "  - $DOCS_COUNT design doc(s) found"
  [[ -f ".claude/auto-dev.config.yml" ]] && echo "  - Custom project config"
fi
