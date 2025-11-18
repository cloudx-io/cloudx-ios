#!/bin/bash

# ============================================================================
# CloudX Core SDK - XCFramework Release Script
# ============================================================================
#
# OVERVIEW:
#   Builds CloudXCore as a dynamic xcframework and prepares for binary distribution.
#   This is used by CI/CD but can also be run locally for testing.
#
# USAGE:
#   cd cloudx-ios-private/core
#   ./release-core-xcframework.sh 1.2.0
#
# WHAT IT DOES:
#   1. Validates version format and prerequisites
#   2. Builds xcframework for iOS device + simulator
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
#   - CloudXCore.xcframework/          (unzipped framework)
#   - CloudXCore.xcframework.zip       (distributable binary)
#   - release_metadata.txt             (version, checksum, URLs)
#
# DISTRIBUTION:
#   The generated xcframework.zip should be:
#   1. Uploaded to GitHub Release on cloudx-io/cloudx-ios
#   2. Referenced in CloudXCore.podspec with version and download URL
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
MODULE_NAME="CloudXCore"
RELEASE_NAME="CloudXCore@$VERSION"
ARCHIVE_DIR="./build"
OUTPUT_XCFRAMEWORK="${MODULE_NAME}.xcframework"
ZIP_OUTPUT="${MODULE_NAME}.xcframework.zip"

echo ""
echo "🚀 Building ${MODULE_NAME} v${VERSION} as XCFramework"
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

# Build for iOS Device
print_step "📱 Building for iOS device..."
set -o pipefail
IDE_ENABLE_FILE_SYSTEM_SYNCHRONIZED_GROUPS=NO xcodebuild archive \
  -project CloudXCore.xcodeproj \
  -scheme CloudXCore \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_DIR/ios_devices.xcarchive" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES | tee xcodebuild-ios.log
print_success "iOS device build completed"

# Build for iOS Simulator
print_step "🖥️  Building for iOS simulator..."
IDE_ENABLE_FILE_SYSTEM_SYNCHRONIZED_GROUPS=NO xcodebuild archive \
  -project CloudXCore.xcodeproj \
  -scheme CloudXCore \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVE_DIR/ios_simulator.xcarchive" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES | tee xcodebuild-sim.log
print_success "iOS simulator build completed"

# Create XCFramework
print_step "🧱 Creating .xcframework..."
xcodebuild -create-xcframework \
  -framework "$ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -framework "$ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -output "$OUTPUT_XCFRAMEWORK"
print_success "XCFramework created: $OUTPUT_XCFRAMEWORK"

# Note: dSYM generation disabled - no debug symbols to upload or strip
print_step "ℹ️  Debug symbols disabled (no dSYMs generated)"
print_success "Framework built without debug symbols"

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
CloudXCore v$VERSION - XCFramework Release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VERSION:    $VERSION
TAG:        v${VERSION}-core
SIZE:       $ZIP_SIZE
CHECKSUM:   $CHECKSUM

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Upload to GitHub Release:
   - Repository: cloudx-io/cloudx-ios
   - Tag: v${VERSION}-core
   - Attach: $ZIP_OUTPUT

2. Update cloudx-ios/core/CloudXCore.podspec:
   s.version = '$VERSION'
   s.source = {
     :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-core/CloudXCore.xcframework.zip'
   }

3. Update cloudx-ios/core/Package.swift:
   url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-core/CloudXCore.xcframework.zip",
   checksum: "$CHECKSUM"

4. Push to CocoaPods:
   cd cloudx-ios/core
   pod trunk push CloudXCore.podspec --allow-warnings

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
echo "📄 View release metadata:"
echo "   cat release_metadata.txt"
echo ""
echo "🔗 GitHub Release URL:"
echo "   https://github.com/cloudx-io/cloudx-ios/releases/tag/v${VERSION}-core"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""



