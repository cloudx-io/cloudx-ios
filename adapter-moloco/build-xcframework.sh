#!/bin/bash
set -e

FRAMEWORK_NAME="CloudXMolocoAdapter"
BUILD_DIR="build"
XCFRAMEWORK_PATH="${FRAMEWORK_NAME}.xcframework"

echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${XCFRAMEWORK_PATH}"
rm -f "${XCFRAMEWORK_PATH}.zip"

echo "📦 Installing CocoaPods dependencies..."
pod install

echo "🏗️  Building for iOS device (arm64)..."
xcodebuild archive \
  -workspace "${FRAMEWORK_NAME}.xcworkspace" \
  -scheme "${FRAMEWORK_NAME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${BUILD_DIR}/ios.xcarchive" \
  -sdk iphoneos \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | tee xcodebuild-ios.log | xcpretty || cat xcodebuild-ios.log

echo "🏗️  Building for iOS Simulator (arm64 + x86_64)..."
xcodebuild archive \
  -workspace "${FRAMEWORK_NAME}.xcworkspace" \
  -scheme "${FRAMEWORK_NAME}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${BUILD_DIR}/ios-sim.xcarchive" \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | tee xcodebuild-sim.log | xcpretty || cat xcodebuild-sim.log

echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "${BUILD_DIR}/ios-sim.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "${XCFRAMEWORK_PATH}"

echo "🔧 Converting Info.plist to XML for CocoaPods compatibility..."
plutil -convert xml1 "${XCFRAMEWORK_PATH}/Info.plist"

echo "📝 Setting up module map in XCFramework..."
for arch_dir in "${XCFRAMEWORK_PATH}"/*/; do
    HEADERS_DIR="${arch_dir}Headers"
    if [ -d "${HEADERS_DIR}" ]; then
        cp "Sources/${FRAMEWORK_NAME}/module.modulemap" "${HEADERS_DIR}/"
        echo "✅ Copied module.modulemap to ${HEADERS_DIR}"
    fi
done

echo "🗜️  Compressing XCFramework..."
zip -r "${XCFRAMEWORK_PATH}.zip" "${XCFRAMEWORK_PATH}"

echo "✅ Build complete!"
echo "📦 XCFramework: ${XCFRAMEWORK_PATH}"
echo "📦 Zip: ${XCFRAMEWORK_PATH}.zip"

CHECKSUM=$(swift package compute-checksum "${XCFRAMEWORK_PATH}.zip")
echo "🔐 SwiftPM Checksum: ${CHECKSUM}"

