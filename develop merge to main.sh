#!/bin/bash

cd "./Pipeline-Test"

AUTOMATION_BRANCH="bot/squash-main"
set -euo pipefail   # Exit immediately on any error

git checkout main
git fetch origin main
git fetch origin develop

# Check if automation branch exists
if git show-ref --verify "refs/heads/$AUTOMATION_BRANCH"; then
    echo "Automation branch '$AUTOMATION_BRANCH' exists. Recreating it."
    git branch -D "$AUTOMATION_BRANCH"
else
    echo "Creating branch '$AUTOMATION_BRANCH'"
fi

git checkout -b "$AUTOMATION_BRANCH" origin/main


DEVELOP_MERGE_LIST=$(gh pr list --base develop --state merged --json number,title)  # Intended for merge commits only
MAIN_MERGE_LIST=$(gh pr list --base main --state merged --json number,title)     # Intended for squash merges only

DEV_NUMBERS=$(echo "$DEVELOP_MERGE_LIST" | jq -r '.[].number' | sort)
MAIN_NUMBERS=$(echo "$MAIN_MERGE_LIST" | jq -r '.[].number' | sort)

MISSING_PRS_MAIN=$(comm -23 <(echo "$DEV_NUMBERS") <(echo "$MAIN_NUMBERS"))
MISSING_PRS_DEVELOP=$(comm -13 <(echo "$DEV_NUMBERS") <(echo "$MAIN_NUMBERS"))

if [ -n "$MISSING_PRS_DEVELOP" ]; then
    echo "Found PRs merged into main but not into develop. Main has diverged: ($MISSING_PRS_DEVELOP)"
    exit 1
fi

# Add each PR to main
for PR in $MISSING_PRS_MAIN; do
    TITLE=$(echo "$DEVELOP_MERGE_LIST" | jq -r ".[] | select(.number==$PR) | .title")
    echo "Adding PR #$PR -> $TITLE"
    echo "Commits:"
    
    # Get commits in the PR
    COMMITS=$(gh pr view "$PR" --json commits --jq '.commits[] | {hash: .oid, message: .messageHeadline}')

    echo "$COMMITS" | jq -r '. | "  \(.hash) \(.message | split("\n")[0])"' | while read -r COMMIT_LINE; do
        echo "$COMMIT_LINE"
    done
    echo ""

    # Commit changes to the automation branch
    COMMIT_HASHES=$(echo "$COMMITS" | jq -r '.hash' | tr '\n' ' ')
    
    git cherry-pick --no-commit $COMMIT_HASHES || {
        echo "Conflict detected while applying PR #$PR. Aborting."
        git cherry-pick --abort
        exit 1
    }

    git commit -m "(#$PR) $TITLE"
done

# Merge automation branch to main
git checkout main
git merge --ff-only "$AUTOMATION_BRANCH" || {
    echo "Merge failed. Aborting."
    exit 1
}

git push origin main
echo "Pushed changes to main"

git branch -D "$AUTOMATION_BRANCH"
echo "Automation branch successfully deleted"