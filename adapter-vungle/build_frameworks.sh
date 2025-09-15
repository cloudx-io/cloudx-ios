#!/bin/bash

# Build script for CloudXVungleAdapter
# Creates both .framework and .xcframework for distribution

set -e

# Configuration
SCHEME_NAME="CloudXVungleAdapter"
PROJECT_NAME="CloudXVungleAdapter"
FRAMEWORK_NAME="CloudXVungleAdapter"

# Build directories
BUILD_DIR="build"
FRAMEWORK_DIR="$BUILD_DIR/frameworks"
XCFRAMEWORK_DIR="$BUILD_DIR/xcframework"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$FRAMEWORK_DIR"
mkdir -p "$XCFRAMEWORK_DIR"

# Build for iOS Device (arm64)
echo "📱 Building for iOS Device (arm64)..."
xcodebuild -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    archive

# Build for iOS Simulator (arm64 + x86_64)
echo "🖥️ Building for iOS Simulator (arm64 + x86_64)..."
xcodebuild -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/iOS-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    archive

# Extract frameworks from archives
echo "📦 Extracting frameworks from archives..."
cp -R "$BUILD_DIR/iOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" "$FRAMEWORK_DIR/"
cp -R "$BUILD_DIR/iOS-Simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" "$FRAMEWORK_DIR/${FRAMEWORK_NAME}-Simulator.framework"

# Create XCFramework
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR/$FRAMEWORK_NAME.framework" \
    -framework "$FRAMEWORK_DIR/${FRAMEWORK_NAME}-Simulator.framework" \
    -output "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"

# Copy to root directory for easy access
echo "📋 Copying frameworks to root directory..."
cp -R "$FRAMEWORK_DIR/$FRAMEWORK_NAME.framework" "./"
cp -R "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework" "./"

# Create zip for distribution
echo "🗜️ Creating distribution zip..."
cd "$XCFRAMEWORK_DIR"
zip -r "../$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
cd - > /dev/null

# Move zip to root
mv "$BUILD_DIR/$FRAMEWORK_NAME.xcframework.zip" "./"

# Verify frameworks
echo "✅ Verifying frameworks..."
if [ -d "$FRAMEWORK_NAME.framework" ]; then
    echo "✓ $FRAMEWORK_NAME.framework created successfully"
    lipo -info "$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" || true
fi

if [ -d "$FRAMEWORK_NAME.xcframework" ]; then
    echo "✓ $FRAMEWORK_NAME.xcframework created successfully"
    find "$FRAMEWORK_NAME.xcframework" -name "$FRAMEWORK_NAME" -exec lipo -info {} \; || true
fi

if [ -f "$FRAMEWORK_NAME.xcframework.zip" ]; then
    echo "✓ $FRAMEWORK_NAME.xcframework.zip created successfully"
    ls -lh "$FRAMEWORK_NAME.xcframework.zip"
fi

echo "🎉 Build completed successfully!"
echo ""
echo "Generated files:"
echo "  - $FRAMEWORK_NAME.framework (iOS device only)"
echo "  - $FRAMEWORK_NAME.xcframework (Universal - iOS device + simulator)"
echo "  - $FRAMEWORK_NAME.xcframework.zip (Distribution package)"
echo ""
echo "Integration options:"
echo "  1. Drag $FRAMEWORK_NAME.framework to your Xcode project (device only)"
echo "  2. Drag $FRAMEWORK_NAME.xcframework to your Xcode project (universal)"
echo "  3. Use CocoaPods with the podspec file"
echo "  4. Use Swift Package Manager with Package.swift"
