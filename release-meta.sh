#!/bin/bash

# CloudX Meta Adapter Local Release Script
# Usage: ./release-meta.sh 1.1.49

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.49"
    exit 1
fi

VERSION=$1
BRANCH_NAME="release-meta-v${VERSION}"
PODSPEC_FILE="adapter-meta/CloudXMetaAdapter.podspec"
XCFRAMEWORK_ZIP="adapter-meta/CloudXMetaAdapter-v${VERSION}.xcframework.zip"

echo "🚀 Starting CloudXMetaAdapter v${VERSION} release..."

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

# 5. Build the xcframework
echo "🔨 Building CloudXMetaAdapter.xcframework..."
cd adapter-meta
./build_frameworks.sh
cd ..

# 6. Rename and move the xcframework zip
echo "📦 Preparing xcframework zip..."
mv "adapter-meta/CloudXMetaAdapter.xcframework.zip" "$XCFRAMEWORK_ZIP"

# 7. Update podspec URL to point to the new release
echo "🔗 Updating podspec download URL..."
sed -i '' "s|:http => \".*\"|:http => \"https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-meta/CloudXMetaAdapter-v${VERSION}.xcframework.zip\"|" "$PODSPEC_FILE"

# 8. Commit changes
echo "💾 Committing changes..."
git add "$PODSPEC_FILE" "$XCFRAMEWORK_ZIP"
git commit -m "Release CloudXMetaAdapter v${VERSION}

- Updated podspec version to ${VERSION}
- Built xcframework with latest changes
- Updated download URL for GitHub release"

# 9. Push branch
echo "⬆️ Pushing release branch..."
git push -u origin "$BRANCH_NAME"

# 10. Create GitHub release
echo "🏷️ Creating GitHub release..."
gh release create "v${VERSION}-meta" \
    --title "CloudXMetaAdapter v${VERSION}" \
    --notes "CloudXMetaAdapter v${VERSION} release with latest fixes and improvements." \
    --latest

# 11. Upload xcframework to release
echo "📤 Uploading xcframework to GitHub release..."
gh release upload "v${VERSION}-meta" "$XCFRAMEWORK_ZIP"

# 12. Wait a moment for GitHub CDN
echo "⏳ Waiting for GitHub CDN propagation..."
sleep 10

# 13. Push to CocoaPods trunk
echo "☁️ Pushing to CocoaPods trunk..."
cd adapter-meta
for i in {1..5}; do
    if pod trunk push CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests; then
        echo "✅ Successfully pushed to CocoaPods trunk!"
        break
    else
        echo "⚠️ Pod trunk push failed. Retrying in 30 seconds... ($i/5)"
        sleep 30
    fi
done
cd ..

# 14. Verify pod push
echo "🔍 Verifying pod trunk push..."
pod trunk info CloudXMetaAdapter

# 15. Switch back to main
echo "🔄 Switching back to main..."
git checkout main

# 16. Create PR URL
PR_URL="https://github.com/cloudx-io/cloudx-ios/pull/new/${BRANCH_NAME}"

echo "🎉 Release process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Create PR: $PR_URL"
echo "2. Merge the PR to main"
echo "3. CloudXMetaAdapter v${VERSION} is now available on CocoaPods!"
echo ""
echo "🔗 GitHub Release: https://github.com/cloudx-io/cloudx-ios/releases/tag/v${VERSION}-meta"
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXMetaAdapter"
