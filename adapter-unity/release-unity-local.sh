#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_step() { echo -e "${BLUE}🔄 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.2.1-beta"
    exit 1
fi

VERSION=$1
FULL_VERSION="v${VERSION}-unity"

echo "🚀 Starting CloudXUnityAdapter v${VERSION} local release..."

if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_error "COCOAPODS_TRUNK_TOKEN not set"
fi

print_step "Checking clean state"
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory not clean"
fi

print_step "Switch to Xcode 16.1"
sudo xcode-select -s /Applications/Xcode_16.1.app

print_step "Clean build artifacts"
rm -rf build ~/Library/Developer/Xcode/DerivedData

print_step "Build static xcframework"
bash build_frameworks.sh

print_step "Rename framework with version"
mv CloudXUnityAdapter.xcframework.zip CloudXUnityAdapter-v$VERSION.xcframework.zip

print_step "Compute SwiftPM checksum"
CHECKSUM=$(swift package compute-checksum CloudXUnityAdapter-v$VERSION.xcframework.zip)
echo "checksum=$CHECKSUM"

print_step "Update podspec and Package.swift"
cd ..
cd cloudx-ios/adapter-unity
sed -i '' "s/s\.version.*=.*/s.version = '$VERSION'/" CloudXUnityAdapter.podspec
sed -i '' "s|releases/download/v[^/]*/|releases/download/${FULL_VERSION}/|" CloudXUnityAdapter.podspec

cd ../..
sed -i '' "s|url: \".*CloudXUnityAdapter.*\",|url: \"https://github.com/cloudx-io/cloudx-ios/releases/download/$FULL_VERSION/CloudXUnityAdapter-v$VERSION.xcframework.zip\",|" Package.swift
sed -i '' "s|checksum: \".*\"|checksum: \"$CHECKSUM\"|" Package.swift

cd cloudx-ios-private/adapter-unity

print_step "Create GitHub release"
cd ..

cat > release_notes.md << EOF
CloudXUnityAdapter v$VERSION SDK release (static xcframework)

## Installation

### CocoaPods
\`\`\`ruby
pod 'CloudXUnityAdapter', '~> $VERSION'
\`\`\`

### Swift Package Manager
Add repository: https://github.com/cloudx-io/cloudx-ios

### Manual Installation
Download CloudXUnityAdapter-v$VERSION.xcframework.zip from this release.

## SwiftPM Checksum
$CHECKSUM
EOF

gh release create "$FULL_VERSION" \
  --title "CloudXUnityAdapter v$VERSION" \
  --notes-file release_notes.md \
  --latest

print_step "Upload xcframework to release"
gh release upload "$FULL_VERSION" \
  adapter-unity/CloudXUnityAdapter-v$VERSION.xcframework.zip

cd adapter-unity

print_step "Validate podspec"
cd ../../cloudx-ios/adapter-unity
pod spec lint CloudXUnityAdapter.podspec --allow-warnings --skip-import-validation --verbose
cd ../../cloudx-ios-private/adapter-unity

print_step "Push podspec to CocoaPods trunk"
mkdir -p ~/.cocoapods/trunk
echo '{"trunk":{"token":"'$COCOAPODS_TRUNK_TOKEN'"}}' > ~/.cocoapods/trunk/me.json

cd ../../cloudx-ios/adapter-unity
for i in {1..5}; do
    if pod trunk push CloudXUnityAdapter.podspec --allow-warnings --skip-import-validation --verbose; then
        echo "✅ Pod trunk push succeeded"
        break
    else
        if [ $i -lt 5 ]; then
            echo "Retrying in 30 seconds..."
            sleep 30
        else
            print_error "Pod trunk push failed after all retries"
        fi
    fi
done

cd ../..
print_success "CloudXUnityAdapter v$VERSION release completed!"
echo "🔗 GitHub Release: https://github.com/cloudx-io/cloudx-ios/releases/tag/$FULL_VERSION"
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudXUnityAdapter"

rm -f release_notes.md
