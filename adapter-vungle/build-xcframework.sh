#!/bin/bash

# Build script for CloudXVungleAdapter
# Creates .xcframework for distribution

# Fix UTF-8 encoding issues for CocoaPods
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colors for pretty output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1 ${NC}"
}

print_error() {
    echo -e "${RED}❌ $1 ${NC}"
    exit 1
}

# Configuration
SCHEME_NAME="CloudXVungleAdapter"
FRAMEWORK_NAME="CloudXVungleAdapter"

# --- Step 1: Setup ---
print_status "1. Setting up the environment..."
pod install || print_error "Pod install failed."

# --- Step 2: Build Static Framework for Device ---
print_status "2. Building Static Framework for Device..."
xcodebuild archive \
  -workspace CloudXVungleAdapter.xcworkspace \
  -scheme CloudXVungleAdapter \
  -destination "generic/platform=iOS" \
  -archivePath ./build/static/ios_devices.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=14.0 \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES \
  HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources $(SRCROOT)/Sources/CloudXVungleAdapter $(SRCROOT)/Sources/CloudXVungleAdapter/Base $(SRCROOT)/Sources/CloudXVungleAdapter/Banner $(SRCROOT)/Sources/CloudXVungleAdapter/Initializers $(SRCROOT)/Sources/CloudXVungleAdapter/Interstitial $(SRCROOT)/Sources/CloudXVungleAdapter/Native $(SRCROOT)/Sources/CloudXVungleAdapter/Rewarded $(SRCROOT)/Sources/CloudXVungleAdapter/AppOpen $(SRCROOT)/Sources/CloudXVungleAdapter/BidTokenSource $(SRCROOT)/Sources/CloudXVungleAdapter/Utils' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources $(SRCROOT)/Sources/CloudXVungleAdapter $(SRCROOT)/Sources/CloudXVungleAdapter/Base $(SRCROOT)/Sources/CloudXVungleAdapter/Banner $(SRCROOT)/Sources/CloudXVungleAdapter/Initializers $(SRCROOT)/Sources/CloudXVungleAdapter/Interstitial $(SRCROOT)/Sources/CloudXVungleAdapter/Native $(SRCROOT)/Sources/CloudXVungleAdapter/Rewarded $(SRCROOT)/Sources/CloudXVungleAdapter/AppOpen $(SRCROOT)/Sources/CloudXVungleAdapter/BidTokenSource $(SRCROOT)/Sources/CloudXVungleAdapter/Utils' 2>&1 | tee xcodebuild-ios.log || print_error "Failed to build static framework for device."

# --- Step 3: Build Static Framework for Simulator ---
print_status "3. Building Static Framework for Simulator..."
xcodebuild archive \
  -workspace CloudXVungleAdapter.xcworkspace \
  -scheme CloudXVungleAdapter \
  -destination "generic/platform=iOS Simulator" \
  -archivePath ./build/static/ios_simulator.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=14.0 \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES \
  HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources $(SRCROOT)/Sources/CloudXVungleAdapter $(SRCROOT)/Sources/CloudXVungleAdapter/Base $(SRCROOT)/Sources/CloudXVungleAdapter/Banner $(SRCROOT)/Sources/CloudXVungleAdapter/Initializers $(SRCROOT)/Sources/CloudXVungleAdapter/Interstitial $(SRCROOT)/Sources/CloudXVungleAdapter/Native $(SRCROOT)/Sources/CloudXVungleAdapter/Rewarded $(SRCROOT)/Sources/CloudXVungleAdapter/AppOpen $(SRCROOT)/Sources/CloudXVungleAdapter/BidTokenSource $(SRCROOT)/Sources/CloudXVungleAdapter/Utils' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources $(SRCROOT)/Sources/CloudXVungleAdapter $(SRCROOT)/Sources/CloudXVungleAdapter/Base $(SRCROOT)/Sources/CloudXVungleAdapter/Banner $(SRCROOT)/Sources/CloudXVungleAdapter/Initializers $(SRCROOT)/Sources/CloudXVungleAdapter/Interstitial $(SRCROOT)/Sources/CloudXVungleAdapter/Native $(SRCROOT)/Sources/CloudXVungleAdapter/Rewarded $(SRCROOT)/Sources/CloudXVungleAdapter/AppOpen $(SRCROOT)/Sources/CloudXVungleAdapter/BidTokenSource $(SRCROOT)/Sources/CloudXVungleAdapter/Utils' 2>&1 | tee xcodebuild-sim.log || print_error "Failed to build static framework for simulator."

# --- Step 4: Create .xcframework ---
print_status "4. Creating .xcframework..."
rm -rf ./CloudXVungleAdapter.xcframework
xcodebuild -create-xcframework \
  -framework ./build/static/ios_devices.xcarchive/Products/Library/Frameworks/CloudXVungleAdapter.framework \
  -framework ./build/static/ios_simulator.xcarchive/Products/Library/Frameworks/CloudXVungleAdapter.framework \
  -output ./CloudXVungleAdapter.xcframework || print_error "Failed to create .xcframework."

# --- Step 5: Setup Module Map and Headers ---
print_status "5. Setting up module map and headers..."
for platform in ios-arm64 ios-arm64_x86_64-simulator; do
    FRAMEWORK_PATH="./CloudXVungleAdapter.xcframework/${platform}/CloudXVungleAdapter.framework"
    
    # Create Modules directory if it doesn't exist
    mkdir -p "${FRAMEWORK_PATH}/Modules"
    
    # Ensure headers are in the right place
    mkdir -p "${FRAMEWORK_PATH}/Headers"
    
    # Copy all public headers
    find "Sources/CloudXVungleAdapter" -name "*.h" -exec cp {} "${FRAMEWORK_PATH}/Headers/" \; || print_error "Failed to copy public headers"
done

# --- Step 6: Zip the xcframework ---
print_status "6. Zipping the .xcframework..."
zip -r CloudXVungleAdapter.xcframework.zip CloudXVungleAdapter.xcframework LICENSE || print_error "Failed to zip .xcframework."

# --- Step 7: Cleanup ---
print_status "7. Cleaning up build artifacts..."
rm -rf ./build

# --- Step 8: Verify ---
print_status "Build completed successfully!"
echo ""
echo "Generated files:"
echo "  - CloudXVungleAdapter.xcframework (Universal - iOS device + simulator)"
echo "  - CloudXVungleAdapter.xcframework.zip (Distribution package)"
echo ""
echo "Integration options:"
echo "  1. Drag CloudXVungleAdapter.xcframework to your Xcode project (universal)"
echo "  2. Use CocoaPods with the podspec file"
echo "  3. Use Swift Package Manager with Package.swift"
