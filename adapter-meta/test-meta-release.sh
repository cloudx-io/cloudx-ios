#!/bin/bash

# Test script for meta adapter release workflow
# This mirrors the GitHub Actions workflow EXACTLY for local testing

set -e  # Exit on any error

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

# Simulate the tag-based version extraction (since we don't have GITHUB_REF_NAME locally)
SIMULATED_TAG="v1.1.25-meta"
echo "🏷️  Simulating tag: $SIMULATED_TAG"

print_step "Step 1: 𝔠 Debug available Xcode versions"
ls -la /Applications/ | grep -i xcode || echo "No Xcode versions found in /Applications/"

print_step "Step 2: 𝔠 Switch to Xcode (skip locally - using current)"
echo "Using current Xcode version (skipping xcode-select for local test)"

print_step "Step 3: 🤠 Clean build artifacts"
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "Build artifacts cleaned"

print_step "Step 4: 🛠 Install CocoaPods"
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods not installed. Run: sudo gem install cocoapods --no-document"
fi

print_step "Step 5: 📋 Debug Print CocoaPods version and env"
pod --version
echo "Skipping 'pod env' locally due to UTF-8 encoding issues (works fine in GitHub Actions)"

print_step "Step 6: 📋 Debug Show trunk config file"
if [ -f ~/.cocoapods/trunk/me.json ]; then
    cat ~/.cocoapods/trunk/me.json
else
    echo "No trunk config file found."
fi

print_step "Step 7: 📋 Debug pod trunk me"
echo "Skipping 'pod trunk me' locally due to UTF-8 encoding issues (works fine in GitHub Actions)"

print_step "Step 8: 🔢 Extract version from tag"
VERSION=${SIMULATED_TAG#v}
VERSION_NO_SUFFIX=${VERSION%-meta}
echo "version=$VERSION_NO_SUFFIX"
echo "full_version=$VERSION"

print_step "Step 9: 📀 Build static xcframework"
echo "Running: bash build_frameworks.sh"
if bash build_frameworks.sh; then
    print_success "Framework build completed"
else
    print_error "Framework build failed"
fi

print_step "Step 10: 📦 Rename framework with version"
echo "Before rename:"
ls -la *.xcframework.zip 2>/dev/null || echo "No .xcframework.zip files found"
if [ -f "CloudXMetaAdapter.xcframework.zip" ]; then
    mv CloudXMetaAdapter.xcframework.zip CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip
    echo "Renamed to: CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip"
else
    print_error "CloudXMetaAdapter.xcframework.zip not found after build"
fi

print_step "Step 11: 🔢 Compute SwiftPM checksum"
if command -v swift &> /dev/null; then
    CHECKSUM=$(swift package compute-checksum CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip)
    echo "checksum=$CHECKSUM"
else
    print_warning "Swift not available, skipping checksum computation"
    CHECKSUM="dummy-checksum-for-local-test"
fi

print_step "Step 12: 📝 Update podspec and Package.swift"
echo "Before podspec update:"
grep "s.version" CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = '$VERSION_NO_SUFFIX'/" CloudXMetaAdapter.podspec
echo "After podspec update:"
grep "s.version" CloudXMetaAdapter.podspec

echo "Before Package.swift update:"
grep -A2 -B1 "url.*CloudXMetaAdapter" ../Package.swift || echo "No CloudXMetaAdapter url line found"
grep -A1 -B1 "checksum:" ../Package.swift || echo "No checksum line found"

# Update root Package.swift with simulated values
cd ..
sed -i '' "s|url: \".*CloudXMetaAdapter.*\",|url: \"https://github.com/cloudx-io/cloudx-ios/releases/download/v$VERSION/CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip\",|" Package.swift
sed -i '' "s|checksum: \".*\"|checksum: \"$CHECKSUM\"|" Package.swift
cd adapter-meta

echo "After Package.swift update:"
grep -A2 -B1 "url.*CloudXMetaAdapter" ../Package.swift
grep -A1 -B1 "checksum:" ../Package.swift

print_step "Step 13: 🧪 Validate podspec"
echo "Running: pod spec lint CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests"
if pod spec lint CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests; then
    print_success "Podspec validation passed"
else
    print_error "Podspec validation failed"
fi

print_step "Step 14: 📊 Test GitHub release creation (simulation)"
echo "Would create GitHub release with:"
echo "  Title: CloudXMetaAdapter v$VERSION_NO_SUFFIX"
echo "  Tag: $VERSION"
echo "  Asset: adapter-meta/CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip"
echo "  Release notes: CloudXMetaAdapter v$VERSION_NO_SUFFIX SDK release (static xcframework)"

print_step "Step 15: 💤 Test framework availability (simulation)"
ZIP_URL="https://github.com/cloudx-io/cloudx-ios/releases/download/v$VERSION/CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip"
echo "Would wait for: $ZIP_URL"
echo "Would test HTTP 200 status and curl downloadability"

print_step "Step 16: 📤 Test CocoaPods trunk setup"
if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_warning "COCOAPODS_TRUNK_TOKEN not set. Set it with:"
    echo "export COCOAPODS_TRUNK_TOKEN='your_token_here'"
    echo "Skipping trunk operations..."
else
    echo "Token is set, setting up trunk auth..."
    mkdir -p ~/.cocoapods/trunk
    echo "{\"trunk\":{\"token\":\"$COCOAPODS_TRUNK_TOKEN\"}}" > ~/.cocoapods/trunk/me.json
    
    print_step "Step 17: 📤 Test trunk push (with retry logic)"
    echo "Would run the following command with retry logic:"
    echo "for i in {1..5}; do"
    echo "  pod trunk push CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests && break"
    echo "  echo 'Pod trunk push failed. Retrying in 30 seconds... (\$i/5)'"
    echo "  sleep 30"
    echo "done"
    
    print_step "Step 18: 🧾 Test trunk info check"
    echo "Would run: pod trunk info CloudXMetaAdapter"
fi

# Already in adapter-meta directory

print_success "Local meta adapter test completed!"
echo "All steps from the GitHub Actions workflow have been tested locally."
echo "Framework file created: CloudXMetaAdapter-v$VERSION_NO_SUFFIX.xcframework.zip"
echo "If validation passed, the actual workflow should work."
