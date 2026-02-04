#!/bin/bash

# ============================================================================
# CloudX Core SDK - XCFramework Release Script
# ============================================================================
#
# ⚠️  THIS SCRIPT IS FOR CloudXCore ONLY ⚠️
#
#   This dynamic framework build applies ONLY to the core SDK (CloudXCore).
#   Adapters (Meta, Vungle, InMobi, etc.) remain STATIC frameworks.
#   DO NOT apply these build settings to adapter projects.
#
# ============================================================================
#
# OVERVIEW:
#   Builds CloudXCore as a DYNAMIC xcframework with dSYMs for crash symbolication.
#   The dynamic framework allows host apps to capture crash reports that can be
#   symbolicated by CloudX using the privately-stored dSYMs.
#
#   ⚠️  dSYMs are generated for INTERNAL USE ONLY - they are never distributed
#   publicly. dSYMs stay in our private repo so we can symbolicate crash reports
#   that customers send us, without exposing our source code structure.
#
#   This is used by CI/CD but can also be run locally for testing.
#
# USAGE:
#   cd cloudx-ios-private/core
#   ./build-xcframework.sh 1.2.0
#
# WHAT IT DOES:
#   1. Validates version format and prerequisites
#   2. Builds DYNAMIC xcframework for iOS device + simulator
#   3. Generates dSYMs for crash symbolication
#   4. Creates distributable .zip file (stripped framework, no debug symbols)
#   5. Creates private dSYMs archive (for internal crash analysis)
#   6. Computes SwiftPM checksum for Package.swift
#   7. Outputs release artifacts and metadata
#
# REQUIREMENTS:
#   - Xcode 15.3+ installed
#
# OUTPUT ARTIFACTS:
#   - CloudXCore.xcframework/          (dynamic framework, stripped)
#   - CloudXCore.xcframework.zip       (distributable binary for public repo)
#   - CloudXCore-dSYMs.zip             (dSYMs for private repo)
#   - release_metadata.txt             (version, checksum, URLs)
#
# ============================================================================
# ⚠️  dSYM CONFIDENTIALITY - READ CAREFULLY ⚠️
# ============================================================================
#
#   The dSYMs contain debug symbols that allow crash reports to be symbolicated.
#   These dSYMs are STRICTLY INTERNAL and must NEVER be distributed publicly.
#
#   WHY: dSYMs can be used to reverse-engineer our code. Keeping them private
#        protects our intellectual property while still allowing us to debug
#        crashes reported by host app developers.
#
#   DISTRIBUTION RULES:
#     ✅ CloudXCore.xcframework.zip → PUBLIC (cloudx-io/cloudx-ios releases)
#     🔒 CloudXCore-dSYMs.zip       → PRIVATE (cloudx-io/cloudx-ios-private releases ONLY)
#
#   🚫 NEVER upload dSYMs to:
#      - The public cloudx-ios repo
#      - CocoaPods trunk
#      - GitHub releases on public repos
#      - Sentry, Crashlytics, or any third-party crash reporting service
#      - Any external location accessible outside our GitHub org
#
#   The dSYMs exist SOLELY for our internal crash analysis workflow.
#
# ============================================================================
#
# CRASH SYMBOLICATION WORKFLOW:
#   When a host app crashes in CloudXCore code:
#   1. Host app owner sends unsymbolicated crash report to CloudX team
#   2. CloudX downloads corresponding dSYMs from PRIVATE repo release
#   3. CloudX uses dSYMs to symbolicate crash internally (atos, symbolicatecrash)
#   4. CloudX provides symbolicated stack trace or fix to host app owner
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
DSYM_OUTPUT="${MODULE_NAME}-dSYMs.zip"

echo ""
echo "🚀 Building ${MODULE_NAME} v${VERSION} as DYNAMIC XCFramework"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    print_error "xcodebuild not found. Please install Xcode."
fi

print_success "Using Xcode at: $(xcode-select -p)"
xcodebuild -version

# Clean build directory
print_step "🧹 Cleaning build directory..."
rm -rf "$ARCHIVE_DIR" "$OUTPUT_XCFRAMEWORK" "$ZIP_OUTPUT" "$DSYM_OUTPUT" "release_metadata.txt"
mkdir -p "$ARCHIVE_DIR"
print_success "Build directory cleaned"

# Build for iOS Device
print_step "📱 Building for iOS device (DYNAMIC)..."
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
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym | tee xcodebuild-ios.log
print_success "iOS device build completed (DYNAMIC with dSYM)"

# Build for iOS Simulator
print_step "🖥️  Building for iOS simulator (DYNAMIC)..."
IDE_ENABLE_FILE_SYSTEM_SYNCHRONIZED_GROUPS=NO xcodebuild archive \
  -project CloudXCore.xcodeproj \
  -scheme CloudXCore \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVE_DIR/ios_simulator.xcarchive" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym | tee xcodebuild-sim.log
print_success "iOS simulator build completed (DYNAMIC with dSYM)"

# Create XCFramework WITHOUT -debug-symbols flag
# Note: We intentionally omit -debug-symbols to avoid adding DebugSymbolsPath entries
# to Info.plist. dSYMs are archived separately for private distribution and should
# not be referenced in the public xcframework.
print_step "🧱 Creating DYNAMIC .xcframework (dSYMs archived separately)..."
xcodebuild -create-xcframework \
  -framework "$ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -framework "$ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${MODULE_NAME}.framework" \
  -output "$OUTPUT_XCFRAMEWORK"
print_success "DYNAMIC XCFramework created: $OUTPUT_XCFRAMEWORK"

# Remove DebugSymbolsPath entries from Info.plist
# xcodebuild -create-xcframework adds these entries even without -debug-symbols flag
# when it detects dSYMs in the archive. We strip them since dSYMs are distributed privately.
print_step "🔧 Removing DebugSymbolsPath from Info.plist..."
PLIST_PATH="$OUTPUT_XCFRAMEWORK/Info.plist"
if [ -f "$PLIST_PATH" ]; then
    # Use plutil to convert to XML, remove DebugSymbolsPath entries, then convert back
    plutil -convert xml1 "$PLIST_PATH"
    
    # Remove all DebugSymbolsPath entries using sed
    # This handles the pattern: <key>DebugSymbolsPath</key>\n\t\t\t<string>dSYMs</string>
    sed -i '' '/<key>DebugSymbolsPath<\/key>/,/<string>.*<\/string>/d' "$PLIST_PATH"
    
    # Keep as XML format for CocoaPods compatibility (CocoaPods can't parse binary plists)
    print_success "DebugSymbolsPath entries removed from Info.plist (kept as XML for CocoaPods)"
else
    print_warning "Info.plist not found at $PLIST_PATH"
fi

# Archive dSYMs for private distribution (crash symbolication)
print_step "📦 Archiving dSYMs for private distribution..."
DSYM_DIR="./build/dSYMs"
mkdir -p "$DSYM_DIR"
cp -R "$ARCHIVE_DIR/ios_devices.xcarchive/dSYMs/${MODULE_NAME}.framework.dSYM" "$DSYM_DIR/${MODULE_NAME}-ios.dSYM"
cp -R "$ARCHIVE_DIR/ios_simulator.xcarchive/dSYMs/${MODULE_NAME}.framework.dSYM" "$DSYM_DIR/${MODULE_NAME}-simulator.dSYM"

# Create dSYM metadata file
cat > "$DSYM_DIR/dSYM_metadata.txt" << EOF
CloudXCore dSYM Archive
=======================
Version: $VERSION
Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

Contents:
- ${MODULE_NAME}-ios.dSYM        (iOS device architecture)
- ${MODULE_NAME}-simulator.dSYM  (iOS simulator architecture)

Usage:
  To symbolicate a crash report:
  1. Extract this archive
  2. Use atos or symbolicatecrash with the appropriate dSYM
  
  Example with atos:
    atos -o ${MODULE_NAME}-ios.dSYM/Contents/Resources/DWARF/${MODULE_NAME} -arch arm64 -l <load_address> <symbol_address>

  Example with symbolicatecrash:
    symbolicatecrash crash.ips ${MODULE_NAME}-ios.dSYM > symbolicated.crash
EOF

zip -r "$DSYM_OUTPUT" "$DSYM_DIR" > /dev/null
DSYM_SIZE=$(du -h "$DSYM_OUTPUT" | awk '{print $1}')
print_success "dSYMs archived: $DSYM_OUTPUT ($DSYM_SIZE)"
print_warning "⚠️  KEEP dSYMs PRIVATE - Upload to cloudx-ios-private releases only!"

# Strip debug symbols from XCFramework for public distribution
print_step "🔪 Stripping debug symbols from XCFramework..."
find "$OUTPUT_XCFRAMEWORK" -name "*.framework" | while read FRAMEWORK; do
    BINARY_NAME=$(basename "$FRAMEWORK" .framework)
    BINARY_PATH="$FRAMEWORK/$BINARY_NAME"
    if [ -f "$BINARY_PATH" ]; then
        echo "  Stripping: $BINARY_PATH"
        strip -x "$BINARY_PATH"
    fi
done
print_success "Debug symbols stripped from distributable framework"

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
CloudXCore v$VERSION - DYNAMIC XCFramework Release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VERSION:    $VERSION
TAG:        v${VERSION}-core
TYPE:       DYNAMIC FRAMEWORK
SIZE:       $ZIP_SIZE (framework) / $DSYM_SIZE (dSYMs)
CHECKSUM:   $CHECKSUM

⚠️  dSYM CONFIDENTIALITY NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The dSYMs in $DSYM_OUTPUT are STRICTLY INTERNAL.
NEVER upload dSYMs to the public repo or any external service.
dSYMs can be used to reverse-engineer our code - keep them private!

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Upload FRAMEWORK to PUBLIC GitHub Release:
   - Repository: cloudx-io/cloudx-ios
   - Tag: v${VERSION}-core
   - Attach: $ZIP_OUTPUT

2. Upload dSYMs to PRIVATE GitHub Release:
   - Repository: cloudx-io/cloudx-ios-private
   - Tag: v${VERSION}-core
   - Attach: $DSYM_OUTPUT
   ⚠️  This must stay in the PRIVATE repo!

3. Update cloudx-ios/core/CloudXCore.podspec:
   s.version = '$VERSION'
   s.source = {
     :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-core/CloudXCore.xcframework.zip'
   }

4. Update cloudx-ios/core/Package.swift:
   url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v${VERSION}-core/CloudXCore.xcframework.zip",
   checksum: "$CHECKSUM"

5. Push to CocoaPods:
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
echo "📦 PUBLIC Artifacts (for cloudx-ios):"
echo "   • $OUTPUT_XCFRAMEWORK"
echo "   • $ZIP_OUTPUT ($ZIP_SIZE)"
echo ""
echo "🔒 PRIVATE Artifacts (for cloudx-ios-private ONLY):"
echo "   • $DSYM_OUTPUT ($DSYM_SIZE)"
echo -e "   ${YELLOW}⚠️  NEVER upload dSYMs to public repo!${NC}"
echo ""
echo "📄 View release metadata:"
echo "   cat release_metadata.txt"
echo ""
echo "🔗 GitHub Release URLs:"
echo "   PUBLIC:  https://github.com/cloudx-io/cloudx-ios/releases/tag/v${VERSION}-core"
echo "   PRIVATE: https://github.com/cloudx-io/cloudx-ios-private/releases/tag/v${VERSION}-core"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""



