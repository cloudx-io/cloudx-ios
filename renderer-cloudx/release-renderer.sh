#!/bin/bash

# ============================================================================
# CloudX Renderer - Stable Release Script
# ============================================================================
#
# OVERVIEW:
#   Publishes stable CloudXRenderer releases to CocoaPods Trunk.
#   Uses SOURCE distribution for easier debugging and integration.
#
# USAGE:
#   cd cloudx-ios/renderer-cloudx
#   ./release-renderer.sh 1.1.59
#
# WHAT IT DOES:
#   1. Validates clean main branch
#   2. Updates CloudXRenderer.podspec version
#   3. Generates stable version: 1.1.59
#   4. Updates CLXRendererVersion.m constant
#   5. Validates podspec
#   6. Pushes to CocoaPods Trunk (public release)
#
# AFTER RELEASE:
#   Developers install via:
#     pod 'CloudXRenderer', '~> 1.1.59'
#
# ============================================================================

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.59"
    exit 1
fi

VERSION=$1
BRANCH_NAME="release-renderer-v${VERSION}"
PODSPEC_FILE="renderer-cloudx/CloudXRenderer.podspec"

echo "🚀 Starting CloudXRenderer v${VERSION} release..."

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

# 5. Update Renderer version constant with build metadata
echo "📝 Generating and updating Renderer version constant..."
FULL_RENDERER_VERSION=$(./scripts/generate-version.sh "${VERSION}" stable)
./scripts/update-version-constant.sh renderer "$FULL_RENDERER_VERSION"
VERSION_FILE="renderer-cloudx/Sources/CloudXRenderer/CLXRendererVersion.m"
echo "✅ Renderer version updated to: $FULL_RENDERER_VERSION"

# 6. Commit changes
echo "💾 Committing changes..."
git add "$PODSPEC_FILE" "$VERSION_FILE"
git commit -m "Release CloudXRenderer v${VERSION}

- Updated podspec version to ${VERSION}
- Updated Renderer version constant to ${FULL_RENDERER_VERSION}"

# 7. Push branch
echo "⬆️ Pushing release branch..."
git push -u origin "$BRANCH_NAME"

# 8. Lint podspec
echo "🔍 Linting podspec..."
cd renderer-cloudx
pod spec lint CloudXRenderer.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean
cd ..

# 9. Push to CocoaPods trunk
echo "☁️ Pushing to CocoaPods trunk..."
cd renderer-cloudx
for i in {1..5}; do
    if pod trunk push CloudXRenderer.podspec --allow-warnings --skip-import-validation --skip-tests; then
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
pod trunk info CloudXRenderer

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
echo "3. Create git tag: git tag v${VERSION}-renderer && git push origin v${VERSION}-renderer"
echo "4. CloudXRenderer v${VERSION} is now available on CocoaPods!"
echo ""
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXRenderer"

