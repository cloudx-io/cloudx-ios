#!/bin/bash

# ============================================================================
# CloudX InMobi Adapter - Static XCFramework Release Script
# ============================================================================
#
# OVERVIEW:
#   Builds CloudXMediationInMobiAdapter as a STATIC xcframework and prepares for binary distribution.
#   This is used by CI/CD but can also be run locally for testing.
#
# USAGE:
#   cd cloudx-ios-private/adapter-inmobi
#   ./release-inmobi-xcframework.sh 1.2.0
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
#   - CloudXMediationInMobiAdapter.xcframework/          (unzipped framework)
#   - CloudXMediationInMobiAdapter.xcframework.zip       (distributable binary)
#   - release_metadata.txt                               (version, checksum, URLs)
#
# DISTRIBUTION:
#   The generated xcframework.zip should be:
#   1. Uploaded to GitHub Release on cloudx-io/cloudx-ios
#   2. Referenced in CloudXMediationInMobiAdapter.podspec with version and download URL
#   3. Referenced in Package.swift with checksum
#
# ============================================================================

set -e

# Fix UTF-8 encoding issues for CocoaPods
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Configuration
# ============================================================================

FRAMEWORK_NAME="CloudXMediationInMobiAdapter"
SCHEME_NAME="CloudXMediationInMobiAdapter"
WORKSPACE_FILE="CloudXMediationInMobiAdapter.xcworkspace"

ARCHIVE_DIR="${SCRIPT_DIR}/build/archives"
OUTPUT_DIR="${SCRIPT_DIR}/build/output"
OUTPUT_XCFRAMEWORK="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
OUTPUT_ZIP="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
DSYM_DIR="${SCRIPT_DIR}/build/dsyms"

# Sentry configuration
SENTRY_ORG="cloudx"
SENTRY_PROJECT="cloudx-ios"

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        print_error "Invalid version format: $version"
        print_info "Expected format: X.Y.Z or X.Y.Z-suffix (e.g., 1.2.0 or 1.2.0-beta)"
        exit 1
    fi
}

check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -n 1)
    print_info "Using $xcode_version"
}

check_sentry_cli() {
    if ! command -v sentry-cli &> /dev/null; then
        print_warning "sentry-cli not found. dSYM upload will be skipped."
        print_info "Install with: curl -sL https://sentry.io/get-cli/ | bash"
        return 1
    fi
    
    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        print_warning "SENTRY_AUTH_TOKEN not set. dSYM upload will be skipped."
        return 1
    fi
    
    return 0
}

clean_build() {
    print_header "Cleaning Previous Build"
    
    rm -rf "${ARCHIVE_DIR}"
    rm -rf "${OUTPUT_DIR}"
    rm -rf "${DSYM_DIR}"
    
    mkdir -p "${ARCHIVE_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    mkdir -p "${DSYM_DIR}"
    
    print_success "Cleaned build directories"
}

setup_pods() {
    print_header "Setting up CocoaPods"
    
    print_info "Running pod install..."
    pod install || {
        print_error "Pod install failed"
        exit 1
    }
    
    print_success "CocoaPods setup complete"
}

archive_framework() {
    local sdk=$1
    local destination=$2
    local archive_name=$3
    
    print_info "Archiving for $sdk..."
    
    xcodebuild archive \
        -workspace "${WORKSPACE_FILE}" \
        -scheme "${SCHEME_NAME}" \
        -destination "$destination" \
        -archivePath "${ARCHIVE_DIR}/${archive_name}" \
        -sdk "$sdk" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        MACH_O_TYPE=staticlib \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGNING_ALLOWED=NO \
        IPHONEOS_DEPLOYMENT_TARGET=14.0 \
        | xcbeautify || xcodebuild archive \
        -workspace "${WORKSPACE_FILE}" \
        -scheme "${SCHEME_NAME}" \
        -destination "$destination" \
        -archivePath "${ARCHIVE_DIR}/${archive_name}" \
        -sdk "$sdk" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        MACH_O_TYPE=staticlib \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGNING_ALLOWED=NO \
        IPHONEOS_DEPLOYMENT_TARGET=14.0
    
    print_success "Archived for $sdk"
}

create_xcframework() {
    print_header "Creating XCFramework"
    
    # Extract static libraries from frameworks and rename to .a
    local device_framework="${ARCHIVE_DIR}/ios_devices.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    local simulator_framework="${ARCHIVE_DIR}/ios_simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    
    local device_lib="${ARCHIVE_DIR}/lib${FRAMEWORK_NAME}_device.a"
    local simulator_lib="${ARCHIVE_DIR}/lib${FRAMEWORK_NAME}_simulator.a"
    
    # Copy static libraries with .a extension
    cp "${device_framework}/${FRAMEWORK_NAME}" "$device_lib"
    cp "${simulator_framework}/${FRAMEWORK_NAME}" "$simulator_lib"
    
    # Create xcframework with raw static libraries
    xcodebuild -create-xcframework \
        -library "$device_lib" \
        -library "$simulator_lib" \
        -output "${OUTPUT_XCFRAMEWORK}"
    
    print_success "Created XCFramework at: ${OUTPUT_XCFRAMEWORK}"
}

collect_dsyms() {
    print_header "Collecting dSYMs"
    
    # Device dSYMs
    if [ -d "${ARCHIVE_DIR}/ios_devices.xcarchive/dSYMs" ]; then
        cp -R "${ARCHIVE_DIR}/ios_devices.xcarchive/dSYMs/"* "${DSYM_DIR}/" 2>/dev/null || true
    fi
    
    # Simulator dSYMs
    if [ -d "${ARCHIVE_DIR}/ios_simulator.xcarchive/dSYMs" ]; then
        cp -R "${ARCHIVE_DIR}/ios_simulator.xcarchive/dSYMs/"* "${DSYM_DIR}/" 2>/dev/null || true
    fi
    
    local dsym_count=$(find "${DSYM_DIR}" -name "*.dSYM" | wc -l | tr -d ' ')
    
    if [ "$dsym_count" -gt 0 ]; then
        print_success "Collected $dsym_count dSYM file(s)"
    else
        print_warning "No dSYM files found"
    fi
}

upload_dsyms_to_sentry() {
    if ! check_sentry_cli; then
        return
    fi
    
    print_header "Uploading dSYMs to Sentry"
    
    local dsym_count=$(find "${DSYM_DIR}" -name "*.dSYM" | wc -l | tr -d ' ')
    
    if [ "$dsym_count" -eq 0 ]; then
        print_warning "No dSYM files to upload"
        return
    fi
    
    print_info "Uploading $dsym_count dSYM file(s) to Sentry..."
    
    sentry-cli upload-dif \
        --org "${SENTRY_ORG}" \
        --project "${SENTRY_PROJECT}" \
        "${DSYM_DIR}"
    
    print_success "Uploaded dSYMs to Sentry"
}

strip_debug_symbols() {
    print_header "Stripping Debug Symbols"
    
    # Find all static libraries (.a files) in the xcframework
    find "${OUTPUT_XCFRAMEWORK}" -type f \( -name "*.a" -o -name "${FRAMEWORK_NAME}" \) | while read binary; do
        print_info "Checking: $(basename $binary)"
        
        # Check if it's a static library (ar archive) or Mach-O
        if file "$binary" | grep -q "ar archive"; then
            print_info "Static library detected - stripping object files within archive"
            # For static libraries, use strip -S on the archive
            strip -S "$binary" 2>/dev/null || print_warning "Could not strip static library (this is usually fine)"
            print_success "Processed static library: $(basename $binary)"
        elif file "$binary" | grep -q "Mach-O"; then
            print_info "Dynamic library detected - stripping debug symbols"
            strip -x "$binary"
            print_success "Stripped dynamic library: $(basename $binary)"
        else
            print_warning "Unknown binary type: $binary"
        fi
    done
    
    print_success "Debug symbol stripping complete"
}

create_zip() {
    print_header "Creating Distribution ZIP"
    
    cd "${OUTPUT_DIR}"
    zip -r -q "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
    cd "${SCRIPT_DIR}"
    
    local zip_size=$(du -h "${OUTPUT_ZIP}" | cut -f1)
    print_success "Created ZIP: ${OUTPUT_ZIP} ($zip_size)"
}

compute_checksum() {
    print_header "Computing Checksum"
    
    local checksum=$(swift package compute-checksum "${OUTPUT_ZIP}")
    
    print_success "SwiftPM Checksum: $checksum"
    echo "$checksum"
}

generate_metadata() {
    local version=$1
    local checksum=$2
    
    print_header "Generating Release Metadata"
    
    local metadata_file="${OUTPUT_DIR}/release_metadata.txt"
    
    cat > "$metadata_file" << EOF
CloudX InMobi Adapter Release Metadata
======================================

Version: $version
Framework: ${FRAMEWORK_NAME}.xcframework
Type: STATIC
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Xcode: $(xcodebuild -version | head -n 1)

Files
-----
XCFramework: ${OUTPUT_XCFRAMEWORK}
ZIP: ${OUTPUT_ZIP}
ZIP Size: $(du -h "${OUTPUT_ZIP}" | cut -f1)
SwiftPM Checksum: $checksum

GitHub Release
--------------
Tag: v${version}-inmobi
Release Title: CloudX InMobi Adapter v${version}

Download URL (replace with actual after upload):
https://github.com/cloudx-io/cloudx-ios/releases/download/v${version}-inmobi/${FRAMEWORK_NAME}.xcframework.zip

CocoaPods Podspec
-----------------
Update CloudXMediationInMobiAdapter.podspec:

  s.version = '${version}'
  s.source = {
    :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v${version}-inmobi/${FRAMEWORK_NAME}.xcframework.zip',
    :sha256 => '<compute with: shasum -a 256 ${FRAMEWORK_NAME}.xcframework.zip>'
  }
  s.vendored_frameworks = 'adapter-inmobi/${FRAMEWORK_NAME}.xcframework'

Swift Package Manager
---------------------
Update Package.swift:

  .binaryTarget(
    name: "${FRAMEWORK_NAME}",
    url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v${version}-inmobi/${FRAMEWORK_NAME}.xcframework.zip",
    checksum: "${checksum}"
  )

Next Steps
----------
1. Upload ${FRAMEWORK_NAME}.xcframework.zip to GitHub Release v${version}-inmobi
2. Update podspec in cloudx-ios/adapter-inmobi/CloudXMediationInMobiAdapter.podspec
3. Update Package.swift in cloudx-ios/adapter-inmobi/
4. Push podspec to CocoaPods trunk: pod trunk push CloudXMediationInMobiAdapter.podspec
5. Test integration in demo apps

EOF
    
    cat "$metadata_file"
    print_success "Metadata saved to: $metadata_file"
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    print_header "CloudX InMobi Adapter - Static XCFramework Build"
    
    # Validate version argument
    if [ $# -eq 0 ]; then
        print_error "Version argument required"
        echo "Usage: $0 <version>"
        echo "Example: $0 1.2.0"
        exit 1
    fi
    
    local VERSION=$1
    validate_version "$VERSION"
    
    print_info "Building version: $VERSION"
    print_info "Framework: $FRAMEWORK_NAME (STATIC)"
    echo ""
    
    # Pre-flight checks
    check_xcode
    
    # Setup pods (InMobi workspace is generated from pod install)
    setup_pods
    
    # Build process
    clean_build
    
    print_header "Building Archives"
    
    # Archive for iOS devices (arm64)
    archive_framework \
        "iphoneos" \
        "generic/platform=iOS" \
        "ios_devices"
    
    # Archive for iOS simulator (arm64 + x86_64)
    archive_framework \
        "iphonesimulator" \
        "generic/platform=iOS Simulator" \
        "ios_simulator"
    
    # Create xcframework
    create_xcframework
    
    # Collect and upload dSYMs
    collect_dsyms
    upload_dsyms_to_sentry
    
    # Strip debug symbols from framework
    strip_debug_symbols
    
    # Create distribution zip
    create_zip
    
    # Compute checksum for SPM
    local CHECKSUM=$(compute_checksum)
    
    # Generate metadata
    generate_metadata "$VERSION" "$CHECKSUM"
    
    # Final summary
    print_header "Build Complete!"
    print_success "Version: $VERSION"
    print_success "Output: ${OUTPUT_DIR}"
    print_info "Next: Copy ${FRAMEWORK_NAME}.xcframework to cloudx-ios/adapter-inmobi/"
}

# Run main function
main "$@"


