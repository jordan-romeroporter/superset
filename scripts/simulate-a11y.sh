#!/usr/bin/env bash
# simulate-a11y.sh — Run the a11y-devin workflow locally inside Docker.
#
# Usage:
#   ./scripts/simulate-a11y.sh <owner/repo> <pr_number>
#
# Required environment variables (set in .env or export before running):
#   DEVIN_API_KEY    — Devin API key (https://app.devin.ai/settings)
#   DEVIN_ORG_ID     — Devin organisation ID
#   GITHUB_TOKEN     — GitHub PAT with repo + pull-request read/write scope
#
# Optional:
#   DRY_RUN=1        — Print the prompt that would be sent to Devin, then exit

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <owner/repo> <pr_number>"
  exit 1
fi

REPO="$1"
PR_NUMBER="$2"

if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${DEVIN_API_KEY:?Set DEVIN_API_KEY in .env or environment}"
: "${DEVIN_ORG_ID:?Set DEVIN_ORG_ID in .env or environment}"
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN in .env or environment}"

# ── 1. Fetch PR metadata ────────────────────────────────────────────────────
echo "▸ Fetching PR #${PR_NUMBER} from ${REPO}..."
PR_JSON=$(curl -sf \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}")

PR_URL=$(echo "$PR_JSON" | jq -r '.html_url')
BASE_BRANCH=$(echo "$PR_JSON" | jq -r '.base.ref')
HEAD_BRANCH=$(echo "$PR_JSON" | jq -r '.head.ref')

echo "  PR URL:       $PR_URL"
echo "  Base branch:  $BASE_BRANCH"
echo "  Head branch:  $HEAD_BRANCH"

# ── 2. Fetch the diff and filter for front-end files ────────────────────────
echo "▸ Fetching diff..."
DIFF=$(curl -sf \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3.diff" \
  "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}")

FE_DIFF=$(echo "$DIFF" | awk '
  /^diff --git/ { file=$0; keep=0 }
  /\.(tsx|jsx|html)$/ { keep=1 }
  keep { print }
')

if [ -z "$FE_DIFF" ]; then
  echo "✓ No front-end files (.tsx/.jsx/.html) changed — nothing to triage."
  exit 0
fi

CHANGED_FILES=$(echo "$FE_DIFF" | grep '^diff --git' | sed 's|diff --git a/||;s| b/.*||' | paste -sd ',' -)
echo "  Changed front-end files: $CHANGED_FILES"

# ── 3. Build the Devin session prompt ───────────────────────────────────────
echo "▸ Building session prompt..."
PROMPT=$(cat prompts/devin-a11y-session.md)
PROMPT="${PROMPT//\{\{REPO\}\}/$REPO}"
PROMPT="${PROMPT//\{\{PR_NUMBER\}\}/$PR_NUMBER}"
PROMPT="${PROMPT//\{\{PR_URL\}\}/$PR_URL}"
PROMPT="${PROMPT//\{\{FILES\}\}/$CHANGED_FILES}"
PROMPT="${PROMPT//\{\{BASE_BRANCH\}\}/$BASE_BRANCH}"
PROMPT="${PROMPT//\{\{HEAD_BRANCH\}\}/$HEAD_BRANCH}"

PROMPT="$PROMPT

--- BEGIN DIFF ---
$FE_DIFF
--- END DIFF ---"

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo ""
  echo "═══ DRY RUN — prompt that would be sent to Devin ═══"
  echo "$PROMPT"
  exit 0
fi

# ── 4. Create Devin session ────────────────────────────────────────────────
echo "▸ Creating Devin session..."
PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg repo  "$REPO" \
  '{
    prompt: $prompt,
    repos: [$repo],
    tags: ["a11y-triage", "local-simulate"]
  }')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://api.devin.ai/v3/organizations/$DEVIN_ORG_ID/sessions" \
  -H "Authorization: Bearer $DEVIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "✗ Devin API returned HTTP $HTTP_CODE"
  echo "$BODY"
  exit 1
fi

SESSION_ID=$(echo "$BODY" | jq -r '.session_id')
SESSION_URL=$(echo "$BODY" | jq -r '.url')

echo "  Session created: $SESSION_URL"

# ── 5. Poll until terminal state ──────────────────────────────────────────
echo "▸ Polling session (30 s intervals, max 30 min)..."
MAX_POLLS=60
for i in $(seq 1 $MAX_POLLS); do
  POLL=$(curl -sf \
    "https://api.devin.ai/v3/organizations/$DEVIN_ORG_ID/sessions/$SESSION_ID" \
    -H "Authorization: Bearer $DEVIN_API_KEY")

  STATUS=$(echo "$POLL" | jq -r '.status')
  DETAIL=$(echo "$POLL" | jq -r '.status_detail // empty')

  echo "  [$i/$MAX_POLLS] status=$STATUS ${DETAIL:+detail=$DETAIL}"

  case "$STATUS" in
    exit)      echo "✓ Session completed successfully."; break ;;
    error)     echo "✗ Session ended with error.";       exit 1 ;;
    suspended) echo "⚠ Session suspended ($DETAIL).";    exit 1 ;;
  esac

  if [ "$i" -eq "$MAX_POLLS" ]; then
    echo "⚠ Polling timed out."
    exit 1
  fi

  sleep 30
done

echo ""
echo "Done. View full results at: $SESSION_URL"
