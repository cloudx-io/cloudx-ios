#!/bin/bash

# ============================================================================
# CloudX Prebid Adapter - Stable Release Script
# ============================================================================
#
# OVERVIEW:
#   Publishes stable CloudXPrebidAdapter releases to CocoaPods Trunk.
#   Uses SOURCE distribution for easier debugging and integration.
#
# USAGE:
#   cd cloudx-ios/adapter-cloudx
#   ./release-prebid.sh 1.1.59
#
# WHAT IT DOES:
#   1. Validates clean main branch
#   2. Updates CloudXPrebidAdapter.podspec version
#   3. Generates stable version: 1.1.59
#   4. Updates CLXPrebidAdapterVersion.m constant
#   5. Validates podspec
#   6. Pushes to CocoaPods Trunk (public release)
#
# AFTER RELEASE:
#   Developers install via:
#     pod 'CloudXPrebidAdapter', '~> 1.1.59'
#
# ============================================================================

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.59"
    exit 1
fi

VERSION=$1
BRANCH_NAME="release-prebid-v${VERSION}"
PODSPEC_FILE="adapter-cloudx/CloudXPrebidAdapter.podspec"

echo "🚀 Starting CloudXPrebidAdapter v${VERSION} release..."

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

# 5. Update Prebid Adapter version constant with build metadata
echo "📝 Generating and updating Prebid Adapter version constant..."
FULL_PREBID_VERSION=$(./scripts/generate-version.sh "${VERSION}" stable)
./scripts/update-version-constant.sh prebid "$FULL_PREBID_VERSION"
VERSION_FILE="adapter-cloudx/Sources/CloudXPrebidAdapter/CLXPrebidAdapterVersion.m"
echo "✅ Prebid Adapter version updated to: $FULL_PREBID_VERSION"

# 6. Commit changes
echo "💾 Committing changes..."
git add "$PODSPEC_FILE" "$VERSION_FILE"
git commit -m "Release CloudXPrebidAdapter v${VERSION}

- Updated podspec version to ${VERSION}
- Updated Prebid Adapter version constant to ${FULL_PREBID_VERSION}"

# 7. Push branch
echo "⬆️ Pushing release branch..."
git push -u origin "$BRANCH_NAME"

# 8. Lint podspec
echo "🔍 Linting podspec..."
cd adapter-cloudx
pod spec lint CloudXPrebidAdapter.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean
cd ..

# 9. Push to CocoaPods trunk
echo "☁️ Pushing to CocoaPods trunk..."
cd adapter-cloudx
for i in {1..5}; do
    if pod trunk push CloudXPrebidAdapter.podspec --allow-warnings --skip-import-validation --skip-tests; then
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
pod trunk info CloudXPrebidAdapter

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
echo "3. Create git tag: git tag v${VERSION}-prebid && git push origin v${VERSION}-prebid"
echo "4. CloudXPrebidAdapter v${VERSION} is now available on CocoaPods!"
echo ""
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXPrebidAdapter"

