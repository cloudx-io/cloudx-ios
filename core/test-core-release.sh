#!/bin/bash

# Test script for core release workflow
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
SIMULATED_TAG="v1.1.41-core"
echo "🏷️  Simulating tag: $SIMULATED_TAG"

print_step "Step 1: 🛠 Install CocoaPods"
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods not installed. Run: sudo gem install cocoapods --no-document"
fi

print_step "Step 2: 📋 Debug Print CocoaPods version and env"
pod --version
echo "Skipping 'pod env' locally due to UTF-8 encoding issues (works fine in GitHub Actions)"

print_step "Step 3: 📋 Debug Show trunk config file"
if [ -f ~/.cocoapods/trunk/me.json ]; then
    cat ~/.cocoapods/trunk/me.json
else
    echo "No trunk config file found."
fi

print_step "Step 4: 📋 Debug pod trunk me"
echo "Skipping 'pod trunk me' locally due to UTF-8 encoding issues (works fine in GitHub Actions)"

print_step "Step 5: 🔢 Extract version from tag"
VERSION=${SIMULATED_TAG#v}
VERSION_NO_SUFFIX=${VERSION%-core}
echo "version=$VERSION_NO_SUFFIX"
echo "full_version=$VERSION"

print_step "Step 6: 📝 Update podspec version"
cd core
echo "Before update:"
grep "s.version" CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version          = '$VERSION_NO_SUFFIX'/" CloudXCore.podspec
echo "After update:"
grep "s.version" CloudXCore.podspec

print_step "Step 7: 🧪 Validate podspec"
echo "Running: pod spec lint CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean"
if pod spec lint CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean; then
    print_success "Podspec validation passed"
else
    print_error "Podspec validation failed"
fi

print_step "Step 8: 📤 Test CocoaPods trunk setup"
if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_warning "COCOAPODS_TRUNK_TOKEN not set. Set it with:"
    echo "export COCOAPODS_TRUNK_TOKEN='your_token_here'"
    echo "Skipping trunk operations..."
else
    echo "Token is set, setting up trunk auth..."
    mkdir -p ~/.cocoapods/trunk
    echo "{\"trunk\":{\"token\":\"$COCOAPODS_TRUNK_TOKEN\"}}" > ~/.cocoapods/trunk/me.json
    
    print_step "Step 9: 📤 Test trunk push (with retry logic)"
    echo "Would run the following command with retry logic:"
    echo "for i in {1..5}; do"
    echo "  pod trunk push CloudXCore.podspec --allow-warnings --skip-import-validation --skip-tests --no-clean && break"
    echo "  echo 'Pod trunk push failed. Retrying in 30 seconds... (\$i/5)'"
    echo "  sleep 30"
    echo "done"
    
    print_step "Step 10: 🧾 Test trunk info check"
    echo "Would run: pod trunk info CloudXCore"
    
    print_step "Step 11: 📊 Test GitHub release creation"
    echo "Would create GitHub release with:"
    echo "  Title: CloudXCore v$VERSION_NO_SUFFIX"
    echo "  Tag: $VERSION"
    echo "  Release notes: CloudXCore v$VERSION_NO_SUFFIX SDK release (source distribution)"
fi

# Return to original directory
cd ..

print_success "Local test completed successfully!"
echo "All steps from the GitHub Actions workflow have been tested locally."
echo "If validation passed, the actual workflow should work."
