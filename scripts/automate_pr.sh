#!/usr/bin/env bash
# ==============================================================================
# Automated Pull Request lifecycle script for Manikutti Ecosystem.
# Validates tests, synchronizes with main, pushes to remote, creates/reuses PR,
# monitors GitHub Actions CI run logs, and merges the PR once checks pass.
# ==============================================================================

set -eo pipefail

REPO="${1:-mobile}"
TITLE="${2:-}"
BODY="${3:-}"
BASE="main"
BRANCH=""
SKIP_TESTS=false
AUTO_MERGE=true

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -d "$WORKSPACE_ROOT/.gh" ]; then
    export GH_CONFIG_DIR="$WORKSPACE_ROOT/.gh"
    echo "Using repository-scoped GH_CONFIG_DIR: $GH_CONFIG_DIR"
fi

case "$REPO" in
    mobile)  TARGET_DIR="$WORKSPACE_ROOT/manikutti_mobile" ;;
    web)     TARGET_DIR="$WORKSPACE_ROOT/Manikutti" ;;
    hub)     TARGET_DIR="$WORKSPACE_ROOT" ;;
    *)       TARGET_DIR="$(pwd)" ;;
esac

echo -e "\n\033[0;36m=== [STEP] Resolving Repository and Branch Context ($TARGET_DIR) ===\033[0m"
cd "$TARGET_DIR"

if [ -z "$BRANCH" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Current Branch : $BRANCH"
echo "Target Base    : $BASE"

if [ "$BRANCH" = "$BASE" ]; then
    echo -e "\033[0;31m❌ You are on base branch '$BASE'. Switch to a feature branch first.\033[0m"
    exit 1
fi

ORIGIN_URL=$(git remote get-url origin)
REPO_SLUG=$(echo "$ORIGIN_URL" | sed -E 's/.*github\.com[:\/]//; s/\.git$//')
echo "GitHub Repo    : $REPO_SLUG"

# 1. Run Pre-flight Tests
if [ "$SKIP_TESTS" = false ]; then
    echo -e "\n\033[0;36m=== [STEP] Running Pre-Flight Tests in $TARGET_DIR ===\033[0m"
    if [ -f "pubspec.yaml" ]; then
        echo "Running Flutter test suite..."
        flutter test
        echo -e "\033[0;32m✅ All Flutter tests passed.\033[0m"
    elif [ -f "package.json" ]; then
        echo "Running npm test..."
        npm test --if-present
        echo -e "\033[0;32m✅ All npm tests passed.\033[0m"
    fi
fi

# 2. Sync with Base
echo -e "\n\033[0;36m=== [STEP] Syncing with origin/$BASE ===\033[0m"
git fetch origin "$BASE"
git merge "origin/$BASE" --no-edit
echo -e "\033[0;32m✅ Branch is up-to-date with origin/$BASE.\033[0m"

# 3. Push to Remote
echo -e "\n\033[0;36m=== [STEP] Pushing $BRANCH to origin ===\033[0m"
git push origin "$BRANCH"
echo -e "\033[0;32m✅ Branch $BRANCH successfully pushed.\033[0m"

# 4. Check or Create PR
echo -e "\n\033[0;36m=== [STEP] Checking or Creating PR ===\033[0m"
PR_NUMBER=""
EXISTING_PR=$(gh pr list --repo "$REPO_SLUG" --head "$BRANCH" --state open --json number,url -q '.[0].number' 2>/dev/null || true)

if [ -n "$EXISTING_PR" ]; then
    PR_NUMBER="$EXISTING_PR"
    echo -e "\033[0;32m✅ Found existing open PR #$PR_NUMBER\033[0m"
else
    if [ -z "$TITLE" ]; then
        TITLE=$(git log -1 --pretty=%s)
    fi
    if [ -z "$BODY" ]; then
        BODY=$(git log -1 --pretty=%b)
        [ -z "$BODY" ] && BODY="Automated Pull Request for feature branch $BRANCH."
    fi

    set +e
    PR_URL=$(gh pr create --repo "$REPO_SLUG" --head "$BRANCH" --base "$BASE" --title "$TITLE" --body "$BODY" 2>/dev/null)
    set -e

    if [[ "$PR_URL" =~ /pull/([0-9]+) ]]; then
        PR_NUMBER="${BASH_REMATCH[1]}"
        echo -e "\033[0;32m✅ PR #$PR_NUMBER created: $PR_URL\033[0m"
    else
        WEB_URL="https://github.com/$REPO_SLUG/pull/new/$BRANCH"
        echo -e "\n\033[0;33m⚠️  CLI could not create PR automatically. Please open in browser:\033[0m"
        echo "$WEB_URL"
        read -p "Enter PR number once created: " PR_NUMBER
    fi
fi

# 5. Monitor CI
echo -e "\n\033[0;36m=== [STEP] Monitoring CI Pipeline for PR #$PR_NUMBER ===\033[0m"
RUN_ID=""
for i in {1..12}; do
    sleep 5
    RUN_ID=$(gh run list --repo "$REPO_SLUG" --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
    if [ -n "$RUN_ID" ]; then
        echo "Detected Workflow Run ID: $RUN_ID"
        break
    fi
done

if [ -n "$RUN_ID" ]; then
    echo "Watching CI run logs in real-time..."
    if ! gh run watch "$RUN_ID" --repo "$REPO_SLUG" --exit-status; then
        echo -e "\n\033[0;31m❌ CI Pipeline FAILED! Printing failed logs:\033[0m"
        gh run view "$RUN_ID" --repo "$REPO_SLUG" --log-failed
        exit 1
    fi
    echo -e "\033[0;32m✅ CI pipeline PASSED successfully!\033[0m"
fi

# 6. Merge PR
if [ "$AUTO_MERGE" = true ] && [ -n "$PR_NUMBER" ]; then
    echo -e "\n\033[0;36m=== [STEP] Merging PR #$PR_NUMBER into $BASE ===\033[0m"
    if ! gh pr merge "$PR_NUMBER" --repo "$REPO_SLUG" --squash --delete-branch 2>/dev/null; then
        echo "Could not merge via CLI. Please merge on GitHub: https://github.com/$REPO_SLUG/pull/$PR_NUMBER"
        read -p "Press Enter once merged..."
    fi

    git checkout "$BASE"
    git pull origin "$BASE"
    echo -e "\033[0;32m✅ Local $BASE branch updated.\033[0m"
fi

echo -e "\n\033[0;32m🎉 PR #$PR_NUMBER completed and merged successfully!\033[0m"
