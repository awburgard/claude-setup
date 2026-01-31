---
description: "Check auto-dev session progress and status"
allowed-tools: ["Bash", "Read"]
---

# Auto-Dev Status Command

Display the current status of the auto-dev session.

```bash
STATE_FILE=".claude/auto-dev.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active auto-dev session found."
  echo ""
  echo "Start a new session with:"
  echo '  /auto-dev "your feature description"'
  exit 0
fi

# Parse YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Extract fields
SESSION_ID=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' | sed 's/^"\(.*\)"$/\1/')
FEATURE_NAME=$(echo "$FRONTMATTER" | grep '^feature_name:' | sed 's/feature_name: *//' | sed 's/^"\(.*\)"$/\1/')
CURRENT_PHASE=$(echo "$FRONTMATTER" | grep '^current_phase:' | sed 's/current_phase: *//' | sed 's/^"\(.*\)"$/\1/')
PHASE_STATUS=$(echo "$FRONTMATTER" | grep '^phase_status:' | sed 's/phase_status: *//' | sed 's/^"\(.*\)"$/\1/')
ITERATION=$(echo "$FRONTMATTER" | grep '^total_iterations:' | sed 's/total_iterations: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_total_iterations:' | sed 's/max_total_iterations: *//')
WORKTREE_PATH=$(echo "$FRONTMATTER" | grep '^worktree_path:' | sed 's/worktree_path: *//' | sed 's/^"\(.*\)"$/\1/')
AUTO_MERGE=$(echo "$FRONTMATTER" | grep '^auto_merge:' | sed 's/auto_merge: *//')
STARTED_AT=$(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/')

# Extract complexity info
COMPLEXITY_SCORE=$(echo "$FRONTMATTER" | grep 'overall_score:' | sed 's/.*overall_score: *//' | head -1)

# Extract specialists invoked (basic parsing)
SPECIALISTS=$(echo "$FRONTMATTER" | sed -n '/invoked:/,/^[a-z]/p' | grep -v 'invoked:' | grep -v '^[a-z]' | tr -d ' -' | tr '\n' ', ' | sed 's/,$//')

# Calculate phase progress
declare -A PHASE_ORDER=([SETUP]=1 [PLANNING]=2 [DEVELOPMENT]=3 [CLEANUP]=4 [PR_CREATION]=5 [REVIEW]=6 [MERGE]=7)
CURRENT_PHASE_NUM=${PHASE_ORDER[$CURRENT_PHASE]:-0}

# Output status
echo "═══════════════════════════════════════════════════════════"
echo "  Auto-Dev Session Status"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Session:     $SESSION_ID"
echo "Feature:     $FEATURE_NAME"
echo "Started:     $STARTED_AT"
echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Progress"
echo "───────────────────────────────────────────────────────────"
echo ""
echo "Phase:       $CURRENT_PHASE ($PHASE_STATUS)"
echo "Iteration:   $ITERATION / $MAX_ITERATIONS"
echo ""

# Phase progress visualization
echo "Phases:      [1] [2] [3] [4] [5] [6] [7]"
echo -n "             "
for i in 1 2 3 4 5 6 7; do
  if [[ $i -lt $CURRENT_PHASE_NUM ]]; then
    echo -n " ✓  "
  elif [[ $i -eq $CURRENT_PHASE_NUM ]]; then
    echo -n " ►  "
  else
    echo -n " ○  "
  fi
done
echo ""
echo "             SET PLA DEV CLN PR  REV MRG"
echo ""

echo "───────────────────────────────────────────────────────────"
echo "  Configuration"
echo "───────────────────────────────────────────────────────────"
echo ""
echo "Worktree:    $WORKTREE_PATH"
echo "Auto-merge:  $AUTO_MERGE"
if [[ -n "$COMPLEXITY_SCORE" ]] && [[ "$COMPLEXITY_SCORE" != "null" ]]; then
  echo "Complexity:  $COMPLEXITY_SCORE/10"
fi
echo ""

# Show specialists if any
if [[ -n "$SPECIALISTS" ]]; then
  echo "───────────────────────────────────────────────────────────"
  echo "  Specialists Invoked"
  echo "───────────────────────────────────────────────────────────"
  echo ""
  echo "$SPECIALISTS" | tr ',' '\n' | while read -r spec; do
    if [[ -n "$spec" ]]; then
      echo "  • $spec"
    fi
  done
  echo ""
fi

# Show review status if in REVIEW phase
if [[ "$CURRENT_PHASE" == "REVIEW" ]] || [[ "$CURRENT_PHASE" == "MERGE" ]]; then
  if [[ -d ".claude/reviews" ]]; then
    REVIEW_ROUNDS=$(find .claude/reviews -maxdepth 1 -type d -name "round-*" 2>/dev/null | wc -l | tr -d ' ')
    LATEST_ROUND=$(find .claude/reviews -maxdepth 1 -type d -name "round-*" 2>/dev/null | sort -V | tail -1 | grep -o '[0-9]*$' || echo "0")

    echo "───────────────────────────────────────────────────────────"
    echo "  Review Status"
    echo "───────────────────────────────────────────────────────────"
    echo ""
    echo "Review rounds: $REVIEW_ROUNDS"

    if [[ "$LATEST_ROUND" != "0" ]] && [[ -d ".claude/reviews/round-$LATEST_ROUND" ]]; then
      APPROVALS=$(find ".claude/reviews/round-$LATEST_ROUND" -name "*.json" -exec jq -r '.vote' {} \; 2>/dev/null | grep -c "approve" || echo "0")
      TOTAL=$(find ".claude/reviews/round-$LATEST_ROUND" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
      echo "Latest round:  $LATEST_ROUND ($APPROVALS/$TOTAL approvals)"
    fi
    echo ""
  fi
fi

echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Commands:"
echo "  /auto-dev-status   Refresh this status"
echo "  Cancel:            Delete .claude/auto-dev.local.md"
echo ""
```

The status display shows:
- Session ID and feature name
- Current phase with visual progress indicator
- Iteration count
- Configuration (worktree, auto-merge, complexity)
- Specialists invoked during the session
- Review status (if applicable)
