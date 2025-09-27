#!/bin/bash

# Local Core Release Script - Mirrors GitHub Actions workflow exactly
# Usage: ./release-core-local.sh 1.1.55

set -e

# Colors for pretty output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.55"
    exit 1
fi

VERSION=$1
FULL_VERSION="v${VERSION}-core"

echo "🚀 Starting CloudXCore v${VERSION} local release (mirroring GitHub Actions)..."

# Check authentication
if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_error "COCOAPODS_TRUNK_TOKEN environment variable not set. Please set it with your CocoaPods token."
fi

print_step "🗖 Checkout repo (ensuring clean state)"
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash changes."
fi

print_step "🛠 Install CocoaPods"
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods not installed. Run: sudo gem install cocoapods --no-document"
fi

print_step "📋 Debug Print CocoaPods version and env"
pod --version
pod env

print_step "📋 Debug Show trunk config file"
if [ -f ~/.cocoapods/trunk/me.json ]; then
    cat ~/.cocoapods/trunk/me.json
else
    echo "No trunk config file found."
fi

print_step "📋 Debug pod trunk me"
pod trunk me || true

print_step "🔢 Extract version from tag"
VERSION_NO_SUFFIX=${VERSION%-core}
echo "version=$VERSION_NO_SUFFIX"
echo "full_version=$FULL_VERSION"

print_step "📝 Update podspec version"
cd core
sed -i '' "s/s\.version.*=.*/s.version          = '$VERSION_NO_SUFFIX'/" CloudXCore.podspec

print_step "🧪 Validate podspec"
pod spec lint CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean

print_step "📤 Push podspec to CocoaPods trunk"
# Use exact same pattern as GitHub Actions
mkdir -p ~/.cocoapods/trunk
echo '{"trunk":{"token":"'$COCOAPODS_TRUNK_TOKEN'"}}' > ~/.cocoapods/trunk/me.json

for i in {1..5}; do
    if pod trunk push CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests; then
        print_success "Pod trunk push succeeded on attempt $i"
        break
    else
        echo "Pod trunk push failed. Retrying in 30 seconds... ($i/5)"
        sleep 30
    fi
done

print_step "🧾 Check pod trunk push succeeded"
pod trunk info CloudXCore

print_step "📊 Create GitHub release"
cd ..

# Create release notes file
cat > release_notes.md << EOF
CloudXCore v$VERSION_NO_SUFFIX SDK release (source distribution)

## Installation

### CocoaPods
Add to your Podfile: pod 'CloudXCore', '~> $VERSION_NO_SUFFIX'

### Swift Package Manager
Add repository: https://github.com/cloudx-io/cloudx-ios

This release provides source-based distribution for easier integration and debugging.
EOF

gh release create "$FULL_VERSION" \
  --title "CloudXCore v$VERSION_NO_SUFFIX" \
  --notes-file release_notes.md \
  --latest

print_success "CloudXCore v$VERSION_NO_SUFFIX release completed successfully!"
echo "🔗 GitHub Release: https://github.com/cloudx-io/cloudx-ios/releases/tag/$FULL_VERSION"
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXCore"

# Clean up
rm -f release_notes.md
