#!/bin/bash

# Auto-Dev Vote Aggregation Script
# Parses review agent outputs and determines consensus

set -euo pipefail

# Usage check
if [[ $# -lt 1 ]]; then
  echo "Usage: aggregate-votes.sh <round_number>" >&2
  echo "" >&2
  echo "Aggregates review votes from .claude/reviews/round-N/" >&2
  echo "" >&2
  echo "Expected JSON format in each review file:" >&2
  echo '  {"reviewer": "code-reviewer", "vote": "approve|reject", "issues": [...]}' >&2
  exit 1
fi

ROUND=$1
REVIEW_DIR=".claude/reviews/round-${ROUND}"

# Check if review directory exists
if [[ ! -d "$REVIEW_DIR" ]]; then
  echo "Error: Review directory not found: $REVIEW_DIR" >&2
  echo "" >&2
  echo "Expected directory structure:" >&2
  echo "  .claude/reviews/round-1/" >&2
  echo "    code-reviewer.json" >&2
  echo "    code-simplifier.json" >&2
  echo "    silent-failure-hunter.json" >&2
  echo "    pr-test-analyzer.json" >&2
  exit 1
fi

# Count review files
REVIEW_COUNT=$(find "$REVIEW_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ $REVIEW_COUNT -eq 0 ]]; then
  echo "Error: No review files found in $REVIEW_DIR" >&2
  exit 1
fi

# Initialize counters
APPROVALS=0
REJECTIONS=0
CRITICAL_COUNT=0
TOTAL_ISSUES=0

# Arrays to track details
declare -a CRITICAL_ISSUES=()
declare -a REVIEWERS_APPROVED=()
declare -a REVIEWERS_REJECTED=()

# Process each review file
for review_file in "$REVIEW_DIR"/*.json; do
  if [[ ! -f "$review_file" ]]; then
    continue
  fi

  # Extract reviewer name from filename
  REVIEWER=$(basename "$review_file" .json)

  # Parse vote
  VOTE=$(jq -r '.vote // "unknown"' "$review_file" 2>/dev/null || echo "parse_error")

  if [[ "$VOTE" == "approve" ]]; then
    APPROVALS=$((APPROVALS + 1))
    REVIEWERS_APPROVED+=("$REVIEWER")
  elif [[ "$VOTE" == "reject" ]]; then
    REJECTIONS=$((REJECTIONS + 1))
    REVIEWERS_REJECTED+=("$REVIEWER")
  fi

  # Count issues by severity
  ISSUE_COUNT=$(jq '.issues | length' "$review_file" 2>/dev/null || echo "0")
  TOTAL_ISSUES=$((TOTAL_ISSUES + ISSUE_COUNT))

  # Check for critical issues
  CRITICAL=$(jq '[.issues[]? | select(.severity == "critical")] | length' "$review_file" 2>/dev/null || echo "0")
  if [[ $CRITICAL -gt 0 ]]; then
    CRITICAL_COUNT=$((CRITICAL_COUNT + CRITICAL))
    # Extract critical issue descriptions
    while IFS= read -r issue; do
      CRITICAL_ISSUES+=("[$REVIEWER] $issue")
    done < <(jq -r '.issues[]? | select(.severity == "critical") | .description // .message // "Unknown critical issue"' "$review_file" 2>/dev/null)
  fi
done

# Determine consensus
if [[ $CRITICAL_COUNT -gt 0 ]]; then
  RESULT="blocked"
  REASON="Critical issues found ($CRITICAL_COUNT)"
elif [[ $APPROVALS -ge 3 ]]; then
  RESULT="approved"
  REASON="Majority approval ($APPROVALS/$REVIEW_COUNT)"
else
  RESULT="needs-fixes"
  REASON="Insufficient approvals ($APPROVALS/$REVIEW_COUNT, need 3)"
fi

# Output results as JSON
jq -n \
  --arg result "$RESULT" \
  --arg reason "$REASON" \
  --argjson approvals "$APPROVALS" \
  --argjson rejections "$REJECTIONS" \
  --argjson total_reviews "$REVIEW_COUNT" \
  --argjson critical_count "$CRITICAL_COUNT" \
  --argjson total_issues "$TOTAL_ISSUES" \
  --argjson round "$ROUND" \
  --arg approved_by "$(IFS=,; echo "${REVIEWERS_APPROVED[*]:-}")" \
  --arg rejected_by "$(IFS=,; echo "${REVIEWERS_REJECTED[*]:-}")" \
  '{
    result: $result,
    reason: $reason,
    round: $round,
    votes: {
      approvals: $approvals,
      rejections: $rejections,
      total: $total_reviews,
      approved_by: ($approved_by | split(",") | map(select(. != ""))),
      rejected_by: ($rejected_by | split(",") | map(select(. != "")))
    },
    issues: {
      critical: $critical_count,
      total: $total_issues
    }
  }'

# Also output human-readable summary to stderr
echo "" >&2
echo "=== Review Round $ROUND Summary ===" >&2
echo "Result: $RESULT" >&2
echo "Reason: $REASON" >&2
echo "" >&2
echo "Votes:" >&2
echo "  Approvals: $APPROVALS" >&2
echo "  Rejections: $REJECTIONS" >&2
echo "  Total reviews: $REVIEW_COUNT" >&2
echo "" >&2
echo "Issues:" >&2
echo "  Critical: $CRITICAL_COUNT" >&2
echo "  Total: $TOTAL_ISSUES" >&2

if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
  echo "" >&2
  echo "Critical Issues:" >&2
  for issue in "${CRITICAL_ISSUES[@]}"; do
    echo "  - $issue" >&2
  done
fi

echo "" >&2
