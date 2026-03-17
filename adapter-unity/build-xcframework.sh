#!/bin/bash

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

# --- Step 1: Setup ---
print_status "1. Setting up the environment..."
pod install || print_error "Pod install failed."

# --- Step 1a: Validate Compile Sources ---
print_status "1a. Validating all .m files are in the Xcode project..."
bash ../scripts/validate-compile-sources.sh Sources/CloudXUnityAdapter CloudXUnityAdapter.xcodeproj/project.pbxproj || print_error "Compile sources validation failed. See above."

# --- Step 1.5: Setup Module Structure ---
print_status "1.5. Setting up module structure..."
FRAMEWORK_PATH="./CloudXUnityAdapter.framework"
mkdir -p "${FRAMEWORK_PATH}/Headers"
mkdir -p "${FRAMEWORK_PATH}/Modules"

# Copy umbrella header and module map to the framework
cp "Sources/CloudXUnityAdapter/CloudXUnityAdapter.h" "${FRAMEWORK_PATH}/Headers/" || print_error "Failed to copy umbrella header"
cp "Sources/CloudXUnityAdapter/module.modulemap" "${FRAMEWORK_PATH}/Modules/" || print_error "Failed to copy module map"

# --- Step 2: Build Static Framework for Device ---
print_status "2. Building Static Framework for Device..."
xcodebuild archive \
  -workspace CloudXUnityAdapter.xcworkspace \
  -scheme CloudXUnityAdapter \
  -destination "generic/platform=iOS" \
  -archivePath ./build/static/ios_devices.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=13.0 \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES \
  HEADER_SEARCH_PATHS='$(SRCROOT)/Sources/CloudXUnityAdapter $(SRCROOT)/Sources/CloudXUnityAdapter/Banner $(SRCROOT)/Sources/CloudXUnityAdapter/Initializers $(SRCROOT)/Sources/CloudXUnityAdapter/Interstitial $(SRCROOT)/Sources/CloudXUnityAdapter/Rewarded $(SRCROOT)/Sources/CloudXUnityAdapter/Utils' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/Sources/CloudXUnityAdapter $(SRCROOT)/Sources/CloudXUnityAdapter/Banner $(SRCROOT)/Sources/CloudXUnityAdapter/Initializers $(SRCROOT)/Sources/CloudXUnityAdapter/Interstitial $(SRCROOT)/Sources/CloudXUnityAdapter/Rewarded $(SRCROOT)/Sources/CloudXUnityAdapter/Utils' \
  CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES 2>&1 | tee xcodebuild-ios.log || print_error "Failed to build static framework for device."

# --- Step 3: Build Static Framework for Simulator ---
print_status "3. Building Static Framework for Simulator..."
xcodebuild archive \
  -workspace CloudXUnityAdapter.xcworkspace \
  -scheme CloudXUnityAdapter \
  -destination "generic/platform=iOS Simulator" \
  -archivePath ./build/static/ios_simulator.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  MACH_O_TYPE=staticlib \
  IPHONEOS_DEPLOYMENT_TARGET=13.0 \
  DEBUG_INFORMATION_FORMAT=dwarf \
  DEPLOYMENT_POSTPROCESSING=YES \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_STYLE=non-global \
  COPY_PHASE_STRIP=YES \
  HEADER_SEARCH_PATHS='$(SRCROOT)/Sources/CloudXUnityAdapter $(SRCROOT)/Sources/CloudXUnityAdapter/Banner $(SRCROOT)/Sources/CloudXUnityAdapter/Initializers $(SRCROOT)/Sources/CloudXUnityAdapter/Interstitial $(SRCROOT)/Sources/CloudXUnityAdapter/Rewarded $(SRCROOT)/Sources/CloudXUnityAdapter/Utils' \
  USER_HEADER_SEARCH_PATHS='$(SRCROOT)/Sources/CloudXUnityAdapter $(SRCROOT)/Sources/CloudXUnityAdapter/Banner $(SRCROOT)/Sources/CloudXUnityAdapter/Initializers $(SRCROOT)/Sources/CloudXUnityAdapter/Interstitial $(SRCROOT)/Sources/CloudXUnityAdapter/Rewarded $(SRCROOT)/Sources/CloudXUnityAdapter/Utils' \
  CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES 2>&1 | tee xcodebuild-sim.log || print_error "Failed to build static framework for simulator."

# --- Step 4: Create .xcframework ---
print_status "4. Creating .xcframework..."
rm -rf ./CloudXUnityAdapter.xcframework
xcodebuild -create-xcframework \
  -framework ./build/static/ios_devices.xcarchive/Products/Library/Frameworks/CloudXUnityAdapter.framework \
  -framework ./build/static/ios_simulator.xcarchive/Products/Library/Frameworks/CloudXUnityAdapter.framework \
  -output ./CloudXUnityAdapter.xcframework || print_error "Failed to create .xcframework."

# --- Step 4.5: Convert Info.plist to XML for CocoaPods compatibility ---
print_status "4.5. Converting Info.plist to XML format..."
plutil -convert xml1 ./CloudXUnityAdapter.xcframework/Info.plist || print_error "Failed to convert Info.plist"

# --- Step 5: Setup Module Map and Headers ---
print_status "5. Setting up module map and headers..."
for platform in ios-arm64 ios-arm64_x86_64-simulator; do
    FRAMEWORK_PATH="./CloudXUnityAdapter.xcframework/${platform}/CloudXUnityAdapter.framework"
    
    # Create Modules directory if it doesn't exist
    mkdir -p "${FRAMEWORK_PATH}/Modules"
    
    # Copy module map
    cp "Sources/CloudXUnityAdapter/module.modulemap" "${FRAMEWORK_PATH}/Modules/module.modulemap" || print_error "Failed to copy module map"
    
    # Ensure headers are in the right place
    mkdir -p "${FRAMEWORK_PATH}/Headers"
    cp "Sources/CloudXUnityAdapter/CloudXUnityAdapter.h" "${FRAMEWORK_PATH}/Headers/" || print_error "Failed to copy umbrella header"
    
    # Copy all public headers
    find "Sources/CloudXUnityAdapter" -name "*.h" -exec cp {} "${FRAMEWORK_PATH}/Headers/" \; || print_error "Failed to copy public headers"
done

# --- Step 6: Zip the xcframework ---
print_status "6. Zipping the .xcframework..."
zip -r CloudXUnityAdapter.xcframework.zip CloudXUnityAdapter.xcframework LICENSE || print_error "Failed to zip .xcframework."

# --- Step 7: Cleanup ---
print_status "7. Cleaning up build artifacts..."
rm -rf ./build || print_error "Failed to clean up build artifacts."

# --- Step 8: Complete ---
print_status "🎉 Build completed successfully!"
print_status "📦 Output:"
echo " - CloudXUnityAdapter.xcframework.zip"
