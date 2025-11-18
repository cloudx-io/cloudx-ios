#!/bin/bash

################################################################################
# CloudX iOS SDK - Complete 1.2.0-rc.1 Release Process
################################################################################
#
# This script documents the complete release candidate process executed on
# November 16, 2024 for CloudX iOS SDK v1.2.0-rc.1
#
# COMPONENTS RELEASED:
#   - CloudXCore v1.2.0-rc.1
#   - CloudXMetaAdapter v1.2.0-rc.1
#   - CloudXRenderer v1.2.0-rc.1
#   - CloudXVungleAdapter v1.2.0-rc.1
#
# PROCESS SUMMARY:
#   Phase 1: Prepare private repo (cloudx-ios-private)
#   Phase 2: Release to public repo (cloudx-ios)
#   Phase 3: Create PR and test
#
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}################################################################################"
echo "# CloudX iOS SDK - 1.2.0-rc.1 Release Process"
echo -e "################################################################################${NC}"
echo ""

################################################################################
# PHASE 1: PREPARE PRIVATE REPO (cloudx-ios-private)
################################################################################

echo -e "${GREEN}=== PHASE 1: Preparing Private Repo ===${NC}"
echo ""

cd /Users/bryanboyko/Coding/cloudx-io/cloudx-ios-private

# Step 0: Standardize build script names
echo "📝 Step 0: Standardizing build script names..."
mv core/release-core-xcframework.sh core/build-xcframework.sh 2>/dev/null || true
mv adapter-meta/build_frameworks.sh adapter-meta/build-xcframework.sh 2>/dev/null || true
mv renderer-cloudx/release-renderer-xcframework.sh renderer-cloudx/build-xcframework.sh 2>/dev/null || true
mv adapter-vungle/build_frameworks.sh adapter-vungle/build-xcframework.sh 2>/dev/null || true
chmod +x core/build-xcframework.sh adapter-meta/build-xcframework.sh renderer-cloudx/build-xcframework.sh adapter-vungle/build-xcframework.sh
echo "✅ All build scripts renamed to build-xcframework.sh"
echo ""

# Step 1: Update version constants
echo "📝 Step 1: Updating all version constants to 1.2.0-rc.1..."
./scripts/update-version-constant.sh core "1.2.0-rc.1"
./scripts/update-version-constant.sh meta "1.2.0-rc.1"
./scripts/update-version-constant.sh renderer "1.2.0-rc.1"
./scripts/update-version-constant.sh vungle "1.2.0-rc.1"
echo "✅ All 4 version constants updated"
echo ""

# Step 2: Update podspec versions
echo "📝 Step 2: Updating all podspec versions to 1.2.0-rc.1..."
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" renderer-cloudx/CloudXRenderer.podspec
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" adapter-vungle/CloudXVungleAdapter.podspec
echo "✅ All 4 podspecs updated"
echo ""

# Step 3: Build XCFrameworks
echo "📝 Step 3: Building XCFrameworks for all 4 components..."
echo ""

echo "Building Core..."
cd core
./build-xcframework.sh 1.2.0-rc.1
mv CloudXCore.xcframework.zip CloudXCore-v1.2.0-rc.1.xcframework.zip
cd ..
echo "✅ Core built: CloudXCore-v1.2.0-rc.1.xcframework.zip"
echo ""

echo "Building Meta..."
cd adapter-meta
./build-xcframework.sh
mv CloudXMetaAdapter.xcframework.zip CloudXMetaAdapter-v1.2.0-rc.1.xcframework.zip
cd ..
echo "✅ Meta built: CloudXMetaAdapter-v1.2.0-rc.1.xcframework.zip"
echo ""

echo "Building Renderer..."
cd renderer-cloudx
./build-xcframework.sh 1.2.0-rc.1
mv CloudXRenderer.xcframework.zip CloudXRenderer-v1.2.0-rc.1.xcframework.zip
cd ..
echo "✅ Renderer built: CloudXRenderer-v1.2.0-rc.1.xcframework.zip"
echo ""

echo "Building Vungle..."
cd adapter-vungle
./build-xcframework.sh
mv CloudXVungleAdapter.xcframework.zip CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip
cd ..
echo "✅ Vungle built: CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip"
echo ""

# Step 4: Create release branch and commit
echo "📝 Step 4: Creating release branch and committing changes..."
git checkout -b release/1.2.0
git add -A
git commit -m "Release 1.2.0-rc.1: Update all version constants and podspecs

Components updated:
- CloudXCore v1.2.0-rc.1
- CloudXMetaAdapter v1.2.0-rc.1  
- CloudXRenderer v1.2.0-rc.1
- CloudXVungleAdapter v1.2.0-rc.1

Changes:
- Updated all 4 version constants (.m files)
- Updated all 4 podspec versions
- Added CLXVungleAdapterVersion for version tracking
- Renamed all build scripts to build-xcframework.sh for consistency
- Updated scripts/update-version-constant.sh to support Vungle
- Built XCFrameworks for all 4 components (binaries not committed)"

git push origin release/1.2.0
echo "✅ Release branch created and pushed to origin"
echo ""

# Step 5: Reset develop branch (fix mistake)
echo "📝 Step 5: Cleaning up develop branch..."
git checkout develop
git reset --hard d65f5a1  # Reset to commit before RC changes
git push --force origin develop
echo "✅ Develop branch cleaned up"
echo ""

################################################################################
# PHASE 2: RELEASE TO PUBLIC REPO (cloudx-ios)
################################################################################

echo -e "${GREEN}=== PHASE 2: Releasing to Public Repo ===${NC}"
echo ""

cd /Users/bryanboyko/Coding/cloudx-io/cloudx-ios

# Step 6: Clean public repo
echo "📝 Step 6: Cleaning public repo..."
git restore .gitignore adapter-meta/CloudXMetaAdapter.podspec adapter-meta/README.md core/Package.swift 2>/dev/null || true
rm -rf adapter-mintegral/ 2>/dev/null || true
echo "✅ Public repo cleaned"
echo ""

# Step 7: Create GitHub pre-releases
echo "📝 Step 7: Creating GitHub pre-releases for all 4 components..."
echo ""

gh release create "v1.2.0-rc.1-core" \
  --title "CloudXCore v1.2.0-rc.1" \
  --notes "Release candidate for testing - XCFramework binary distribution" \
  --prerelease \
  ../cloudx-ios-private/core/CloudXCore-v1.2.0-rc.1.xcframework.zip
echo "✅ Core pre-release created"

gh release create "v1.2.0-rc.1-meta" \
  --title "CloudXMetaAdapter v1.2.0-rc.1" \
  --notes "Release candidate for testing - XCFramework binary distribution" \
  --prerelease \
  ../cloudx-ios-private/adapter-meta/CloudXMetaAdapter-v1.2.0-rc.1.xcframework.zip
echo "✅ Meta pre-release created"

gh release create "v1.2.0-rc.1-renderer" \
  --title "CloudXRenderer v1.2.0-rc.1" \
  --notes "Release candidate for testing - XCFramework binary distribution" \
  --prerelease \
  ../cloudx-ios-private/renderer-cloudx/CloudXRenderer-v1.2.0-rc.1.xcframework.zip
echo "✅ Renderer pre-release created"

gh release create "v1.2.0-rc.1-vungle" \
  --title "CloudXVungleAdapter v1.2.0-rc.1" \
  --notes "Release candidate for testing - XCFramework binary distribution" \
  --prerelease \
  ../cloudx-ios-private/adapter-vungle/CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip
echo "✅ Vungle pre-release created"
echo ""

# Step 8: Compute checksums
echo "📝 Step 8: Computing checksums for Package.swift..."
cd /Users/bryanboyko/Coding/cloudx-io/cloudx-ios-private
CORE_CHECKSUM=$(swift package compute-checksum core/CloudXCore-v1.2.0-rc.1.xcframework.zip)
META_CHECKSUM=$(swift package compute-checksum adapter-meta/CloudXMetaAdapter-v1.2.0-rc.1.xcframework.zip)
RENDERER_CHECKSUM=$(swift package compute-checksum renderer-cloudx/CloudXRenderer-v1.2.0-rc.1.xcframework.zip)
VUNGLE_CHECKSUM=$(swift package compute-checksum adapter-vungle/CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip)
echo "Core:     $CORE_CHECKSUM"
echo "Meta:     $META_CHECKSUM"
echo "Renderer: $RENDERER_CHECKSUM"
echo "Vungle:   $VUNGLE_CHECKSUM"
echo ""

# Step 9: Create release branch in public repo
echo "📝 Step 9: Creating release branch in public repo..."
cd /Users/bryanboyko/Coding/cloudx-io/cloudx-ios
git checkout -b release/v1.2.0-rc.1
echo "✅ Release branch created"
echo ""

# Step 10: Update podspecs
echo "📝 Step 10: Updating all podspecs with RC version and GitHub URLs..."
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" renderer-cloudx/CloudXRenderer.podspec

# Update source URLs to point to GitHub releases
sed -i '' "s|s\.source.*=.*|s.source           = { :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v1.2.0-rc.1-core/CloudXCore-v1.2.0-rc.1.xcframework.zip' }|" core/CloudXCore.podspec
sed -i '' "s|s\.source.*=.*|s.source           = { :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v1.2.0-rc.1-meta/CloudXMetaAdapter-v1.2.0-rc.1.xcframework.zip' }|" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s|s\.source.*=.*|s.source           = { :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v1.2.0-rc.1-renderer/CloudXRenderer-v1.2.0-rc.1.xcframework.zip' }|" renderer-cloudx/CloudXRenderer.podspec

# Add Vungle adapter
mkdir -p adapter-vungle
cp ../cloudx-ios-private/adapter-vungle/CloudXVungleAdapter.podspec adapter-vungle/
cp ../cloudx-ios-private/adapter-vungle/LICENSE adapter-vungle/
sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s|s\.source.*=.*|s.source = { :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v1.2.0-rc.1-vungle/CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip' }|" adapter-vungle/CloudXVungleAdapter.podspec

# Update root-level podspecs
for podspec in CloudXCore.podspec CloudXMetaAdapter.podspec CloudXRenderer.podspec; do
  if [ -f "$podspec" ]; then
    sed -i '' "s/s\.version.*=.*/s.version = '1.2.0-rc.1'/" "$podspec"
  fi
done
echo "✅ All podspecs updated"
echo ""

# Step 11: Update demo app Podfiles
echo "📝 Step 11: Updating demo app Podfiles..."
cat > demo-app-objc/Podfile << 'EOF'
platform :ios, '14.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  # Release Candidate v1.2.0-rc.1 - Install from GitHub releases
  pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-core'
  pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-meta'
  pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-renderer'
  pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-vungle'

  target 'CloudXObjCRemotePodsTests' do
    inherit! :search_paths
  end

  target 'CloudXObjCRemotePodsUITests' do
  end
end
EOF

cp demo-app-objc/Podfile demo-app-swift/Podfile
sed -i '' "s/CloudXObjCRemotePods/CloudXSwiftRemotePods/g" demo-app-swift/Podfile
echo "✅ Demo app Podfiles updated"
echo ""

# Step 12: Create CHANGELOG.md
echo "📝 Step 12: Creating CHANGELOG.md..."
cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0-rc.1] - 2024-11-16

### Release Candidate

First release candidate for v1.2.0 with all active adapters.

### Components

- **CloudXCore** v1.2.0-rc.1 - Core SDK with programmatic advertising capabilities
- **CloudXMetaAdapter** v1.2.0-rc.1 - Meta (Facebook Audience Network) adapter
- **CloudXRenderer** v1.2.0-rc.1 - CloudX rendering engine for header bidding
- **CloudXVungleAdapter** v1.2.0-rc.1 - Vungle/Liftoff adapter with header bidding support

### Distribution

- All components distributed as XCFrameworks for optimal performance
- Binary distribution for faster integration and smaller build times
- Available via CocoaPods and Swift Package Manager
EOF
echo "✅ CHANGELOG.md created"
echo ""

# Step 13: Commit and push
echo "📝 Step 13: Committing and pushing release branch..."
git add -A
git commit -m "Release v1.2.0-rc.1: Public release candidate with all active adapters

Components included:
- CloudXCore v1.2.0-rc.1 (XCFramework)
- CloudXMetaAdapter v1.2.0-rc.1 (XCFramework)
- CloudXRenderer v1.2.0-rc.1 (XCFramework)
- CloudXVungleAdapter v1.2.0-rc.1 (XCFramework - NEW)

Changes:
- Updated all podspecs to version 1.2.0-rc.1
- Configured podspecs for binary XCFramework distribution
- Updated GitHub release URLs for all 4 components
- Added CloudXVungleAdapter to public repo
- Updated demo app Podfiles to install from RC tags
- Created CHANGELOG.md following Android pattern
- All XCFrameworks uploaded to GitHub pre-releases"

git push origin release/v1.2.0-rc.1
echo "✅ Release branch pushed"
echo ""

################################################################################
# PHASE 3: FINAL STEPS
################################################################################

echo -e "${GREEN}=== PHASE 3: Final Steps ===${NC}"
echo ""

echo "📝 Next Manual Steps:"
echo "1. Create PR: https://github.com/cloudx-io/cloudx-ios/pull/new/release/v1.2.0-rc.1"
echo "2. Review and merge PR to main"
echo "3. Test RC installation in demo apps:"
echo "   cd demo-app-objc && pod install"
echo "   cd demo-app-swift && pod install"
echo "4. Verify SDK version shows 1.2.0-rc.1 in server requests"
echo ""

echo -e "${GREEN}✅ Release Candidate 1.2.0-rc.1 Process Complete!${NC}"
echo ""

echo "GitHub Releases:"
echo "- https://github.com/cloudx-io/cloudx-ios/releases/tag/v1.2.0-rc.1-core"
echo "- https://github.com/cloudx-io/cloudx-ios/releases/tag/v1.2.0-rc.1-meta"
echo "- https://github.com/cloudx-io/cloudx-ios/releases/tag/v1.2.0-rc.1-renderer"
echo "- https://github.com/cloudx-io/cloudx-ios/releases/tag/v1.2.0-rc.1-vungle"
echo ""

################################################################################
# KEY LEARNINGS
################################################################################

echo -e "${YELLOW}=== Key Learnings ===${NC}"
echo "1. NEVER push directly to develop - always use feature/release branches and PRs"
echo "2. Private repo podspecs use :path => '.' for local development"
echo "3. Public repo podspecs use :http => 'https://...' for binary distribution"
echo "4. Release candidates go on release/* branches, not develop"
echo "5. All build scripts standardized to 'build-xcframework.sh'"
echo "6. Version constants automatically propagate to server requests"
echo ""

