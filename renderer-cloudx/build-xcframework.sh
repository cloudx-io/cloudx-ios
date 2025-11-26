#!/bin/bash

# ============================================================================
# CloudX Renderer - Static XCFramework Release Script
# ============================================================================
#
# OVERVIEW:
#   Builds CloudXRenderer as a STATIC xcframework and prepares for binary distribution.
#   This is used by CI/CD but can also be run locally for testing.
#
# USAGE:
#   cd cloudx-ios-private/renderer-cloudx
#   ./release-renderer-xcframework.sh 1.2.0
#
# WHAT IT DOES:
#   1. Validates version format and prerequisites
#   2. Builds STATIC xcframework for iOS device + simulator
#   3. Uploads dSYMs to Sentry for symbolication
#   4. Strips debug symbols from framework binary
#   5. Creates distributable .zip file
#   6. Computes SwiftPM checksum for Package.swift
#   7. Outputs release artifacts and metadata
#
# REQUIREMENTS:
#   - Xcode 15.3+ installed
#   - SENTRY_AUTH_TOKEN environment variable (for dSYM uploads)
#   - sentry-cli installed (curl -sL https://sentry.io/get-cli/ | bash)
#
# OUTPUT ARTIFACTS:
#   - CloudXRenderer.xcframework/          (unzipped framework)
#   - CloudXRenderer.xcframework.zip       (distributable binary)
#   - release_metadata.txt                 (version, checksum, URLs)
#
# DISTRIBUTION:
#   The generated xcframework.zip should be:
#   1. Uploaded to GitHub Release on cloudx-io/cloudx-ios
#   2. Referenced in CloudXRenderer.podspec with version and download URL
#   3. Referenced in Package.swift with checksum
#
# ============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

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

# Validate arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.0"
    exit 1
fi

VERSION=$1
MODULE_NAME="CloudXRenderer"
RELEASE_NAME="CloudXRenderer@$VERSION"
ARCHIVE_DIR="./build"
OUTPUT_XCFRAMEWORK="${MODULE_NAME}.xcframework"
ZIP_OUTPUT="${MODULE_NAME}.xcframework.zip"

echo ""
echo "🚀 Building ${MODULE_NAME} v${VERSION} as STATIC XCFramework"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    print_error "xcodebuild not found. Please install Xcode."
fi

print_success "Using Xcode at: $(xcode-select -p)"
xcodebuild -version

# Validate sentry-cli for dSYM uploads
if ! command -v sentry-cli &> /dev/null; then
    print_warning "sentry-cli not found. dSYM upload will be skipped."
    print_warning "Install with: curl -sL https://sentry.io/get-cli/ | bash"
    SKIP_SENTRY=true
else
    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        print_warning "SENTRY_AUTH_TOKEN not set. dSYM upload will be skipped."
        SKIP_SENTRY=true
    else
        SKIP_SENTRY=false
    fi
fi

# Clean build directory
print_step "🧹 Cleaning build directory..."
rm -rf "$ARCHIVE_DIR" "$OUTPUT_XCFRAMEWORK" "$ZIP_OUTPUT" "release_metadata.txt"
mkdir -p "$ARCHIVE_DIR"
print_success "Build directory cleaned"

# Install CocoaPods dependencies
print_step "📦 Installing CocoaPods dependencies..."
pod install || print_error "Pod install failed"
print_success "CocoaPods dependencies installed"

# Build for iOS Device
print_step "📱 Building for iOS device (STATIC)..."
set -o pipefail
IDE_ENABLE_FILE_SYSTEM_SYNCHRONIZED_GROUPS=NO xcodebuild archive \
  -workspace CloudXRenderer.xcworkspace \
  -scheme CloudXRenderer \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_DIR/ios_devices.xcarchive" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib | tee xcodebuild-ios.log
print_success "iOS device build completed (STATIC)"

# Build for iOS Simulator
print_step "🖥️  Building for iOS simulator (STATIC)..."
IDE_ENABLE_FILE_SYSTEM_SYNCHRONIZED_GROUPS=NO xcodebuild archive \
  -workspace CloudXRenderer.xcworkspace \
  -scheme CloudXRenderer \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVE_DIR/ios_simulator.xcarchive" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib | tee xcodebuild-sim.log
print_success "iOS simulator build completed (STATIC)"

# Create XCFramework
print_step "🧱 Creating STATIC .xcframework..."
xcodebuild -create-xcframework \
  -framework "$ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -framework "$ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -output "$OUTPUT_XCFRAMEWORK"
print_success "STATIC XCFramework created: $OUTPUT_XCFRAMEWORK"

# Upload dSYMs to Sentry
if [ "$SKIP_SENTRY" = false ]; then
    print_step "🕵️  Uploading dSYMs to Sentry..."
    sentry-cli releases new "$RELEASE_NAME" || true
    sentry-cli debug-files upload "$ARCHIVE_DIR/ios_devices.xcarchive/dSYMs" || print_warning "Device dSYM upload failed"
    sentry-cli debug-files upload "$ARCHIVE_DIR/ios_simulator.xcarchive/dSYMs" || print_warning "Simulator dSYM upload failed"
    sentry-cli releases finalize "$RELEASE_NAME" || true
    print_success "dSYMs uploaded to Sentry"
else
    print_warning "Skipping Sentry dSYM upload"
fi

# Strip debug symbols from xcframework
print_step "🔪 Stripping debug symbols from .xcframework..."
find "$OUTPUT_XCFRAMEWORK" -name "*.framework" | while read FRAMEWORK; do
    BINARY_NAME=$(basename "$FRAMEWORK" .framework)
    BINARY_PATH="$FRAMEWORK/$BINARY_NAME"
    if [ -f "$BINARY_PATH" ]; then
        echo "  Stripping: $BINARY_PATH"
        strip -x "$BINARY_PATH"
    fi
done
print_success "Debug symbols stripped"

# Zip the xcframework
print_step "📦 Zipping .xcframework..."
zip -r "$ZIP_OUTPUT" "$OUTPUT_XCFRAMEWORK" > /dev/null
ZIP_SIZE=$(du -h "$ZIP_OUTPUT" | awk '{print $1}')
print_success "Created: $ZIP_OUTPUT ($ZIP_SIZE)"

# Compute SwiftPM checksum
print_step "🧮 Computing SwiftPM checksum..."
CHECKSUM=$(swift package compute-checksum "$ZIP_OUTPUT")
print_success "Checksum: $CHECKSUM"

# Generate release metadata
print_step "📝 Generating release metadata..."
cat > release_metadata.txt << EOF
CloudXRenderer v$VERSION - STATIC XCFramework Release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VERSION:    $VERSION
TAG:        v${VERSION}-renderer
TYPE:       STATIC FRAMEWORK
SIZE:       $ZIP_SIZE
CHECKSUM:   $CHECKSUM

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Upload to GitHub Release:
   - Repository: cloudx-io/cloudx-ios
   - Tag: v${VERSION}-renderer
   - Attach: $ZIP_OUTPUT

2. Update cloudx-ios/renderer-cloudx/CloudXRenderer.podspec:
   s.version = '$VERSION'
   s.source = {
     :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-renderer/CloudXRenderer.xcframework.zip'
   }
   s.vendored_frameworks = 'renderer-cloudx/CloudXRenderer.xcframework'

3. Update cloudx-ios/Package.swift:
   url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-renderer/CloudXRenderer.xcframework.zip",
   checksum: "$CHECKSUM"

4. Copy framework to public repo:
   cp -r CloudXRenderer.xcframework ../cloudx-ios/renderer-cloudx/

5. Push to CocoaPods:
   cd cloudx-ios/renderer-cloudx
   pod trunk push CloudXRenderer.podspec --allow-warnings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

print_success "Release metadata saved to: release_metadata.txt"

# Display summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ XCFramework build completed successfully!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Artifacts:"
echo "   • $OUTPUT_XCFRAMEWORK"
echo "   • $ZIP_OUTPUT ($ZIP_SIZE)"
echo "   • release_metadata.txt"
echo ""
echo "🏗️  Framework Type: STATIC"
echo "   ✅ No dSYM warnings"
echo "   ✅ Faster app launch times"
echo "   ✅ Industry standard (matches AdMob, Meta, IronSource)"
echo ""
echo "📄 View release metadata:"
echo "   cat release_metadata.txt"
echo ""
echo "🔗 GitHub Release URL:"
echo "   https://github.com/cloudx-io/cloudx-ios/releases/tag/v${VERSION}-renderer"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

