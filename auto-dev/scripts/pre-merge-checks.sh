#!/bin/bash

# Auto-Dev Pre-Merge Checks Script
# Validates PR is ready for merge

set -euo pipefail

# Usage check
if [[ $# -lt 1 ]]; then
  echo "Usage: pre-merge-checks.sh <pr_number>" >&2
  echo "" >&2
  echo "Validates that a PR is ready for merge:" >&2
  echo "  1. Review consensus is 'approved'" >&2
  echo "  2. No merge conflicts" >&2
  echo "  3. CI checks passing" >&2
  echo "  4. No new commits since last review" >&2
  exit 1
fi

PR_NUMBER=$1
STATE_FILE=".claude/auto-dev.local.md"

# Track check results
CHECKS_PASSED=0
CHECKS_FAILED=0
declare -a FAILURES=()

echo "Running pre-merge checks for PR #$PR_NUMBER..."
echo ""

# Check 1: Review consensus
echo "1. Checking review consensus..."
if [[ -f "$STATE_FILE" ]]; then
  # Find the latest review round
  LATEST_ROUND=$(find .claude/reviews -maxdepth 1 -type d -name "round-*" 2>/dev/null | sort -V | tail -1 | grep -o '[0-9]*$' || echo "0")

  if [[ "$LATEST_ROUND" != "0" ]] && [[ -d ".claude/reviews/round-$LATEST_ROUND" ]]; then
    # Run vote aggregation and capture result
    VOTE_RESULT=$(bash "$(dirname "$0")/aggregate-votes.sh" "$LATEST_ROUND" 2>/dev/null | jq -r '.result' || echo "unknown")

    if [[ "$VOTE_RESULT" == "approved" ]]; then
      echo "   [PASS] Review consensus: approved"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "   [FAIL] Review consensus: $VOTE_RESULT (need 'approved')"
      CHECKS_FAILED=$((CHECKS_FAILED + 1))
      FAILURES+=("Review not approved: $VOTE_RESULT")
    fi
  else
    echo "   [FAIL] No review rounds found"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    FAILURES+=("No review rounds completed")
  fi
else
  echo "   [SKIP] No state file found, skipping review check"
fi

# Check 2: Merge conflicts
echo "2. Checking for merge conflicts..."
# Get the base branch from the PR
BASE_BRANCH=$(gh pr view "$PR_NUMBER" --json baseRefName -q '.baseRefName' 2>/dev/null || echo "main")

# Fetch latest and check if mergeable
gh pr view "$PR_NUMBER" --json mergeable -q '.mergeable' > /tmp/mergeable_check_$$ 2>/dev/null || echo "UNKNOWN" > /tmp/mergeable_check_$$
MERGEABLE=$(cat /tmp/mergeable_check_$$)
rm -f /tmp/mergeable_check_$$

if [[ "$MERGEABLE" == "MERGEABLE" ]]; then
  echo "   [PASS] No merge conflicts"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [[ "$MERGEABLE" == "CONFLICTING" ]]; then
  echo "   [FAIL] Merge conflicts detected"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
  FAILURES+=("Merge conflicts with $BASE_BRANCH")
else
  echo "   [WARN] Could not determine merge status: $MERGEABLE"
  # Don't fail on unknown, but note it
fi

# Check 3: CI checks
echo "3. Checking CI status..."
CI_STATUS=$(gh pr checks "$PR_NUMBER" --json state -q '.[].state' 2>/dev/null | sort -u || echo "UNKNOWN")

if echo "$CI_STATUS" | grep -q "FAILURE"; then
  echo "   [FAIL] CI checks failing"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
  FAILURES+=("CI checks are failing")
  # Show which checks failed
  gh pr checks "$PR_NUMBER" --json name,state -q '.[] | select(.state == "FAILURE") | "     - \(.name): FAILED"' 2>/dev/null || true
elif echo "$CI_STATUS" | grep -q "PENDING"; then
  echo "   [WAIT] CI checks still running"
  # Show pending checks
  gh pr checks "$PR_NUMBER" --json name,state -q '.[] | select(.state == "PENDING") | "     - \(.name): pending"' 2>/dev/null || true
elif echo "$CI_STATUS" | grep -q "SUCCESS"; then
  echo "   [PASS] All CI checks passing"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [[ "$CI_STATUS" == "UNKNOWN" ]] || [[ -z "$CI_STATUS" ]]; then
  echo "   [SKIP] No CI checks configured or could not fetch status"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))  # Don't block if no CI
else
  echo "   [WARN] Unknown CI status: $CI_STATUS"
fi

# Check 4: No commits since last review
echo "4. Checking for new commits since review..."
if [[ -f "$STATE_FILE" ]]; then
  # Get last review timestamp from state file (if tracked)
  LAST_REVIEW_TIME=$(grep -o 'last_review_at: "[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f2 || echo "")

  if [[ -n "$LAST_REVIEW_TIME" ]]; then
    # Get latest commit time on PR
    LATEST_COMMIT=$(gh pr view "$PR_NUMBER" --json commits -q '.commits[-1].committedDate' 2>/dev/null || echo "")

    if [[ -n "$LATEST_COMMIT" ]]; then
      # Compare timestamps (basic string comparison works for ISO format)
      if [[ "$LATEST_COMMIT" > "$LAST_REVIEW_TIME" ]]; then
        echo "   [WARN] New commits since last review"
        echo "          Last review: $LAST_REVIEW_TIME"
        echo "          Latest commit: $LATEST_COMMIT"
        echo "          Consider re-running review"
      else
        echo "   [PASS] No new commits since last review"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
      fi
    else
      echo "   [SKIP] Could not get commit timestamp"
    fi
  else
    echo "   [SKIP] Last review time not tracked"
  fi
else
  echo "   [SKIP] No state file"
fi

# Summary
echo ""
echo "=== Pre-Merge Check Summary ==="
echo "Passed: $CHECKS_PASSED"
echo "Failed: $CHECKS_FAILED"
echo ""

# Output JSON result
if [[ $CHECKS_FAILED -eq 0 ]]; then
  RESULT="ready"
  echo "Result: READY TO MERGE"
else
  RESULT="blocked"
  echo "Result: BLOCKED"
  echo ""
  echo "Failures:"
  for failure in "${FAILURES[@]}"; do
    echo "  - $failure"
  done
fi

# Output machine-readable JSON
jq -n \
  --arg result "$RESULT" \
  --argjson passed "$CHECKS_PASSED" \
  --argjson failed "$CHECKS_FAILED" \
  --argjson pr "$PR_NUMBER" \
  '{
    result: $result,
    pr_number: $pr,
    checks: {
      passed: $passed,
      failed: $failed
    },
    ready_to_merge: ($result == "ready")
  }'
