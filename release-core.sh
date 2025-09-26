#!/bin/bash

# CloudX Core Local Release Script
# Usage: ./release-core.sh 1.1.54

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.54"
    exit 1
fi

VERSION=$1
BRANCH_NAME="release-core-v${VERSION}"
PODSPEC_FILE="core/CloudXCore.podspec"

echo "🚀 Starting CloudXCore v${VERSION} release..."

# 1. Check if we're on main and it's clean
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Please run this script from main branch"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Working directory is not clean. Please commit or stash changes."
    exit 1
fi

# 2. Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# 3. Create release branch
echo "🌿 Creating release branch: ${BRANCH_NAME}"
git checkout -b "$BRANCH_NAME"

# 4. Update podspec version
echo "📝 Updating podspec version to ${VERSION}..."
sed -i '' "s/s\.version.*=.*/s.version = '${VERSION}'/" "$PODSPEC_FILE"

# 5. Update podspec tag reference
echo "🔗 Updating podspec tag reference..."
sed -i '' "s/:tag => \".*\"/:tag => \"v${VERSION}-core\"/" "$PODSPEC_FILE"

# 6. Commit changes
echo "💾 Committing changes..."
git add "$PODSPEC_FILE"
git commit -m "Release CloudXCore v${VERSION}

- Updated podspec version to ${VERSION}
- Updated git tag reference for source distribution"

# 7. Push branch
echo "⬆️ Pushing release branch..."
git push -u origin "$BRANCH_NAME"

# 8. Lint podspec
echo "🔍 Linting podspec..."
cd core
pod spec lint CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean
cd ..

# 9. Push to CocoaPods trunk
echo "☁️ Pushing to CocoaPods trunk..."
cd core
for i in {1..5}; do
    if pod trunk push CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests; then
        echo "✅ Successfully pushed to CocoaPods trunk!"
        break
    else
        echo "⚠️ Pod trunk push failed. Retrying in 30 seconds... ($i/5)"
        sleep 30
    fi
done
cd ..

# 10. Verify pod push
echo "🔍 Verifying pod trunk push..."
pod trunk info CloudXCore

# 11. Switch back to main
echo "🔄 Switching back to main..."
git checkout main

# 12. Create PR URL
PR_URL="https://github.com/cloudx-io/cloudx-ios/pull/new/${BRANCH_NAME}"

echo "🎉 Release process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Create PR: $PR_URL"
echo "2. Merge the PR to main"
echo "3. Create git tag: git tag v${VERSION}-core && git push origin v${VERSION}-core"
echo "4. CloudXCore v${VERSION} is now available on CocoaPods!"
echo ""
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXCore"
