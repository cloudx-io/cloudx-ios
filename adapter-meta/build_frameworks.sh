#!/bin/bash

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

# --- Step 1: Setup ---
print_status "1. Setting up the environment..."
pod install || print_error "Pod install failed."

# --- Step 1.5: Setup Module Structure ---
print_status "1.5. Setting up module structure..."
FRAMEWORK_PATH="./CloudXMetaAdapter.framework"
mkdir -p "${FRAMEWORK_PATH}/Headers"
mkdir -p "${FRAMEWORK_PATH}/Modules"

# Copy umbrella header and module map to the framework
cp "Sources/CloudXMetaAdapter/CloudXMetaAdapter.h" "${FRAMEWORK_PATH}/Headers/" || print_error "Failed to copy umbrella header"
cp "Sources/CloudXMetaAdapter/module.modulemap" "${FRAMEWORK_PATH}/Modules/" || print_error "Failed to copy module map"

# --- Step 2: Build Static Framework for Device ---
print_status "2. Building Static Framework for Device..."
xcodebuild archive \
  -workspace CloudXMetaAdapter.xcworkspace \
  -scheme CloudXMetaAdapter \
  -destination "generic/platform=iOS" \
  -archivePath ./build/static/ios_devices.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=13.0 \
  HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources' 2>&1 | tee xcodebuild-ios.log || print_error "Failed to build static framework for device."

# --- Step 3: Build Static Framework for Simulator ---
print_status "3. Building Static Framework for Simulator..."
xcodebuild archive \
  -workspace CloudXMetaAdapter.xcworkspace \
  -scheme CloudXMetaAdapter \
  -destination "generic/platform=iOS Simulator" \
  -archivePath ./build/static/ios_simulator.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=13.0 \
  HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/../core/Sources' 2>&1 | tee xcodebuild-sim.log || print_error "Failed to build static framework for simulator."

# --- Step 4: Create .xcframework ---
print_status "4. Creating .xcframework..."
xcodebuild -create-xcframework \
  -framework ./build/static/ios_devices.xcarchive/Products/Library/Frameworks/CloudXMetaAdapter.framework \
  -framework ./build/static/ios_simulator.xcarchive/Products/Library/Frameworks/CloudXMetaAdapter.framework \
  -output ./CloudXMetaAdapter.xcframework || print_error "Failed to create .xcframework."

# --- Step 5: Setup Module Map and Headers ---
print_status "5. Setting up module map and headers..."
for platform in ios-arm64 ios-arm64_x86_64-simulator; do
    FRAMEWORK_PATH="./CloudXMetaAdapter.xcframework/${platform}/CloudXMetaAdapter.framework"
    
    # Create Modules directory if it doesn't exist
    mkdir -p "${FRAMEWORK_PATH}/Modules"
    
    # Copy module map
    cp "Sources/CloudXMetaAdapter/module.modulemap" "${FRAMEWORK_PATH}/Modules/module.modulemap" || print_error "Failed to copy module map"
    
    # Ensure headers are in the right place
    mkdir -p "${FRAMEWORK_PATH}/Headers"
    cp "Sources/CloudXMetaAdapter/CloudXMetaAdapter.h" "${FRAMEWORK_PATH}/Headers/" || print_error "Failed to copy umbrella header"
    
    # Copy all public headers
    find "Sources/CloudXMetaAdapter" -name "*.h" -exec cp {} "${FRAMEWORK_PATH}/Headers/" \; || print_error "Failed to copy public headers"
done

# --- Step 6: Zip the xcframework ---
print_status "6. Zipping the .xcframework..."
zip -r CloudXMetaAdapter.xcframework.zip CloudXMetaAdapter.xcframework || print_error "Failed to zip .xcframework."

# --- Step 7: Cleanup ---
print_status "7. Cleaning up build artifacts..."
rm -rf ./build || print_error "Failed to clean up build artifacts."

# --- Step 8: Complete ---
print_status "🎉 Build completed successfully!"
print_status "📦 Output:"
echo " - CloudXMetaAdapter.xcframework.zip"

