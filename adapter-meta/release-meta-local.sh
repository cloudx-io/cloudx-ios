#!/bin/bash

# Local Meta Adapter Release Script - Mirrors GitHub Actions workflow exactly
# Usage: ./release-meta-local.sh 1.1.58

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
    echo "Example: $0 1.1.58"
    exit 1
fi

VERSION=$1
FULL_VERSION="v${VERSION}-meta"

echo "🚀 Starting CloudXMetaAdapter v${VERSION} local release (mirroring GitHub Actions)..."

# Check authentication
if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_error "COCOAPODS_TRUNK_TOKEN environment variable not set. Please set it with your CocoaPods token."
fi

print_step "🗖 Checkout repo (ensuring clean state)"
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash changes."
fi

print_step "𝔠 Debug available Xcode versions"
ls -la /Applications/ | grep -i xcode

print_step "𝔠 Switch to Xcode 16.1"
sudo xcode-select -s /Applications/Xcode_16.1.app

print_step "🤠 Clean build artifacts"
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData

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
VERSION_NO_SUFFIX=${VERSION%-meta}
echo "version=$VERSION_NO_SUFFIX"
echo "full_version=$FULL_VERSION"

print_step "📀 Build static xcframework"
bash build_frameworks.sh

print_step "📦 Rename framework with version"
mv CloudXMetaAdapter.xcframework.zip CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip

print_step "🔢 Compute SwiftPM checksum"
CHECKSUM=$(swift package compute-checksum CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip)
echo "checksum=$CHECKSUM"

print_step "📝 Update podspec and Package.swift"
# Update podspec version
sed -i '' "s/s\.version.*=.*/s.version = '$VERSION_NO_SUFFIX'/" CloudXMetaAdapter.podspec

# Fix podspec source URL to point to correct version
sed -i '' "s|https://github.com/cloudx-io/cloudx-ios/releases/download/.*CloudXMetaAdapter-v.*\.xcframework\.zip|https://github.com/cloudx-io/cloudx-ios/releases/download/${FULL_VERSION}/CloudXMetaAdapter-v${VERSION_NO_SUFFIX}.xcframework.zip|" CloudXMetaAdapter.podspec

# Fix license path relative to podspec directory  
sed -i '' "s|'adapter-meta/LICENSE'|'LICENSE'|" CloudXMetaAdapter.podspec

# Update root Package.swift version and checksum for CloudXMetaAdapter binary target
cd ..
sed -i '' "s|url: \".*CloudXMetaAdapter.*\",|url: \"https://github.com/cloudx-io/cloudx-ios/releases/download/$FULL_VERSION/CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip\",|" Package.swift
sed -i '' "s|checksum: \".*\"|checksum: \"$CHECKSUM\"|" Package.swift
cd adapter-meta

print_step "📊 Create GitHub release (step 1 - empty release)"
cd ..

# Create release notes file
cat > release_notes.md << EOF
CloudXMetaAdapter v$VERSION_NO_SUFFIX SDK release (static xcframework)

## Installation

### CocoaPods
Add to your Podfile: pod 'CloudXMetaAdapter', '~> $VERSION_NO_SUFFIX'

### Swift Package Manager
Add repository: https://github.com/cloudx-io/cloudx-ios

### Manual Installation
Download CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip from this release.

## SwiftPM Checksum
$CHECKSUM
EOF

# Create empty release first (two-step process for better CDN propagation)
gh release create "$FULL_VERSION" \
  --title "CloudXMetaAdapter v$VERSION_NO_SUFFIX" \
  --notes-file release_notes.md \
  --latest

print_step "📦 Upload xcframework to release (step 2 - file upload)"
# Upload the xcframework file to the existing release
gh release upload "$FULL_VERSION" \
  adapter-meta/CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip

cd adapter-meta

print_step "🔍 Debug file structure"
echo "=== Repository structure ==="
ls -la ..
echo "=== Adapter-meta directory ==="
ls -la
echo "=== License file check ==="
if [ -f "LICENSE" ]; then
    echo "✅ LICENSE file found at adapter-meta/LICENSE"
    wc -l LICENSE
else
    echo "❌ LICENSE file NOT found at adapter-meta/LICENSE"
fi

print_step "🧪 Validate podspec with detailed output"
echo "=== Validating CloudXMetaAdapter.podspec ==="
echo "Current directory: $(pwd)"
echo "Podspec content:"
cat CloudXMetaAdapter.podspec
echo "=== Running podspec validation ==="
pod spec lint CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests --verbose || {
    echo "❌ Podspec validation failed"
    exit 1
}

print_step "📋 Verify CocoaPods authentication"
if [ -z "${COCOAPODS_TRUNK_TOKEN:-}" ]; then
    echo "❌ COCOAPODS_TRUNK_TOKEN is empty/unset"
    exit 1
else
    echo "✅ COCOAPODS_TRUNK_TOKEN is set (length: ${#COCOAPODS_TRUNK_TOKEN})"
fi
echo "=== Checking authentication ==="
pod trunk me || true
echo "=== Checking pod ownership ==="
pod trunk info CloudXMetaAdapter || true

print_step "📤 Push podspec to CocoaPods trunk"
# Use EXACT same pattern as working Core workflow
mkdir -p ~/.cocoapods/trunk
echo '{"trunk":{"token":"'$COCOAPODS_TRUNK_TOKEN'"}}' > ~/.cocoapods/trunk/me.json

for i in {1..5}; do
    echo "=== Attempt $i/5 ==="
    if pod trunk push CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests --verbose; then
        echo "✅ Pod trunk push succeeded on attempt $i"
        break
    else
        echo "❌ Pod trunk push failed on attempt $i"
        if [ $i -lt 5 ]; then
            echo "Retrying in 30 seconds..."
            sleep 30
        else
            echo "❌ Pod trunk push failed after all retries"
            exit 1
        fi
    fi
done

print_step "🧾 Verify successful pod trunk push"
echo "=== Verifying pod trunk push success ==="

# Wait a moment for CocoaPods to process
sleep 10

# Verify the pod is available
if pod trunk info CloudXMetaAdapter; then
    echo "✅ Pod trunk push verification successful"
    
    # Extract and display the latest version
    LATEST_VERSION=$(pod trunk info CloudXMetaAdapter | grep -E "^\s*-\s*[0-9]" | head -1 | sed 's/^\s*-\s*//')
    echo "Latest published version: $LATEST_VERSION"
    
    # Verify it matches our expected version
    if [[ "$LATEST_VERSION" == "$VERSION_NO_SUFFIX" ]]; then
        echo "✅ Version verification successful: $LATEST_VERSION matches expected $VERSION_NO_SUFFIX"
    else
        echo "⚠️ Version mismatch: Latest=$LATEST_VERSION, Expected=$VERSION_NO_SUFFIX"
        echo "This might be expected if the version was already published"
    fi
else
    echo "❌ Pod trunk info failed - pod may not be properly published"
    exit 1
fi

cd ..
print_success "CloudXMetaAdapter v$VERSION_NO_SUFFIX release completed successfully!"
echo "🔗 GitHub Release: https://github.com/cloudx-io/cloudx-ios/releases/tag/$FULL_VERSION"
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXMetaAdapter"

# Clean up
rm -f release_notes.md
