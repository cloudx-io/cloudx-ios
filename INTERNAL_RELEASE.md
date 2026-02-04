<!--
================================================================================
INTERNAL RELEASE PROCESS
================================================================================
Purpose: Create internal binary releases for testing BEFORE public release
Targets:
  - cloudx-io/cloudx-ios-private (binaries-test/ folder)
  - cloudx-io/cloudx-unity-private (Assets/CloudX/Plugins/iOS/)
  - cloudx-io/JimsGame (binaries-test/ folder)
  - Other internal repos with iOS dependencies

Audience: Internal QA, Unity team, JimsGame testing, cross-platform testing

This document is used by Claude to execute internal releases. Follow these steps
to build xcframeworks and distribute to internal testing environments.

For PUBLIC releases to cloudx-ios and CocoaPods Trunk, see: RELEASE.md
================================================================================
-->

# CloudX iOS SDK - Internal Release Process

This document describes the internal release process for testing release candidate builds across iOS native and Unity projects.

## Overview

Internal releases create local binary distributions for testing before public release:

| Target | Location | Purpose |
|--------|----------|---------|
| `binaries-test/` | cloudx-ios-private | Local binary testing for native iOS |
| `Assets/CloudX/Plugins/iOS/` | cloudx-unity-private | Unity iOS plugin binaries |
| `binaries-test/` | JimsGame | JimsGame iOS app binary testing |

## Prerequisites

- Xcode 15+ with command line tools
- CocoaPods installed (`gem install cocoapods`)
- GitHub CLI (`gh`) authenticated
- Access to `cloudx-ios-private`, `cloudx-unity-private`, and `JimsGame` repos

---

## Phase 1: Build XCFrameworks

Build all components from source:

```bash
cd cloudx-ios-private

# Get current version from podspec
VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")
echo "Building version: $VERSION"

# Build CloudXCore (dynamic framework with dSYMs)
cd core && ./build-xcframework.sh $VERSION && cd ..

# Build adapters (static frameworks)
cd adapter-meta && ./build-xcframework.sh && cd ..
cd adapter-vungle && ./build-xcframework.sh && cd ..
cd adapter-inmobi && ./build-xcframework.sh && cd ..
cd adapter-mintegral && ./build-xcframework.sh && cd ..

# Build renderer
cd renderer-cloudx && ./build-xcframework.sh $VERSION && cd ..

echo "✅ All xcframeworks built"
```

---

## Phase 2: Create Local Binaries (binaries-test)

Set up the local binary testing folder:

```bash
cd cloudx-ios-private

# Clean and recreate binaries-test
rm -rf binaries-test
mkdir -p binaries-test/core
mkdir -p binaries-test/adapter-meta
mkdir -p binaries-test/adapter-vungle
mkdir -p binaries-test/adapter-inmobi
mkdir -p binaries-test/adapter-mintegral
mkdir -p binaries-test/renderer-cloudx

# Copy xcframeworks
cp -R core/CloudXCore.xcframework binaries-test/core/
cp -R adapter-meta/CloudXMetaAdapter.xcframework binaries-test/adapter-meta/
cp -R adapter-vungle/CloudXVungleAdapter.xcframework binaries-test/adapter-vungle/
cp -R adapter-inmobi/CloudXInMobiAdapter.xcframework binaries-test/adapter-inmobi/
cp -R adapter-mintegral/CloudXMintegralAdapter.xcframework binaries-test/adapter-mintegral/
cp -R renderer-cloudx/CloudXRenderer.xcframework binaries-test/renderer-cloudx/

echo "✅ XCFrameworks copied to binaries-test/"
```

---

## Phase 3: Create Local Podspecs

Create podspecs that point to local binaries:

```bash
cd cloudx-ios-private

VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")

# CloudXCore podspec
cat > binaries-test/core/CloudXCore.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '$VERSION'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXCore.xcframework'
  
  s.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'CoreLocation', 'WebKit', 'CoreData']
  
  # CloudXCore is DYNAMIC - requires -ObjC for category loading
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '\$(inherited) -ObjC'
  }
end
EOF

# CloudXMetaAdapter podspec
cat > binaries-test/adapter-meta/CloudXMetaAdapter.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXMetaAdapter'
  s.version          = '$VERSION'
  s.summary          = 'CloudX Meta Adapter'
  s.description      = 'Meta Audience Network adapter - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXMetaAdapter.xcframework'
  
  s.dependency 'CloudXCore', '$VERSION'
  s.dependency 'FBAudienceNetwork', '~> 6.15'
  
  s.static_framework = true
end
EOF

# CloudXVungleAdapter podspec
cat > binaries-test/adapter-vungle/CloudXVungleAdapter.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXVungleAdapter'
  s.version          = '$VERSION'
  s.summary          = 'CloudX Vungle Adapter'
  s.description      = 'Vungle/Liftoff adapter - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXVungleAdapter.xcframework'
  
  s.dependency 'CloudXCore', '$VERSION'
  s.dependency 'VungleAds', '~> 7.4'
  
  s.static_framework = true
end
EOF

# CloudXInMobiAdapter podspec
cat > binaries-test/adapter-inmobi/CloudXInMobiAdapter.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXInMobiAdapter'
  s.version          = '$VERSION'
  s.summary          = 'CloudX InMobi Adapter'
  s.description      = 'InMobi adapter - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXInMobiAdapter.xcframework'
  
  s.dependency 'CloudXCore', '$VERSION'
  s.dependency 'InMobiSDK', '~> 11.1'
  
  s.static_framework = true
end
EOF

# CloudXMintegralAdapter podspec
cat > binaries-test/adapter-mintegral/CloudXMintegralAdapter.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXMintegralAdapter'
  s.version          = '$VERSION'
  s.summary          = 'CloudX Mintegral Adapter'
  s.description      = 'Mintegral adapter - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXMintegralAdapter.xcframework'
  
  s.dependency 'CloudXCore', '$VERSION'
  s.dependency 'MintegralAdSDK', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidBannerAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidNewInterstitialAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '~> 8.0'
  
  s.static_framework = true
end
EOF

# CloudXRenderer podspec
cat > binaries-test/renderer-cloudx/CloudXRenderer.podspec << EOF
Pod::Spec.new do |s|
  s.name             = 'CloudXRenderer'
  s.version          = '$VERSION'
  s.summary          = 'CloudX Renderer'
  s.description      = 'Creative rendering engine - BINARY testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXRenderer.xcframework'
  
  s.dependency 'CloudXCore', '$VERSION'
  
  s.static_framework = true
end
EOF

# Add LICENSE files
cp LICENCE binaries-test/adapter-meta/LICENSE
cp LICENCE binaries-test/adapter-vungle/LICENSE
cp LICENCE binaries-test/adapter-inmobi/LICENSE
cp LICENCE binaries-test/adapter-mintegral/LICENSE
cp LICENCE binaries-test/renderer-cloudx/LICENSE

echo "✅ Local podspecs created"
```

---

## Phase 4: Test with ObjC Demo App

Update the demo app to use local binaries:

```bash
cd cloudx-ios-private/demo-app-objc

# Update Podfile to use local binaries
cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  # CloudX SDK - Local binary testing
  pod 'CloudXCore', :path => '../binaries-test/core'
  pod 'CloudXMetaAdapter', :path => '../binaries-test/adapter-meta'
  pod 'CloudXVungleAdapter', :path => '../binaries-test/adapter-vungle'
  pod 'CloudXInMobiAdapter', :path => '../binaries-test/adapter-inmobi'
  pod 'CloudXMintegralAdapter', :path => '../binaries-test/adapter-mintegral'
  pod 'CloudXRenderer', :path => '../binaries-test/renderer-cloudx'

  target 'CloudXObjCRemotePodsTests' do
    inherit! :search_paths
  end

  target 'CloudXObjCRemotePodsUITests' do
  end

end
EOF

# Install pods
pod install

echo "✅ Demo app configured with local binaries"
echo "Open CloudXObjCRemotePods.xcworkspace to test"
```

---

## Phase 5: Setup Unity Project

Check for and setup cloudx-unity-private:

```bash
cd cloudx-ios-private

# Check if unity repo exists
UNITY_REPO="../cloudx-unity-private"
if [ ! -d "$UNITY_REPO" ]; then
    echo "Cloning cloudx-unity-private..."
    cd ..
    gh repo clone cloudx-io/cloudx-unity-private
    cd cloudx-ios-private
fi

# Get version and create branch name
VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")
BRANCH_NAME="release/$VERSION"

# Create release branch in unity repo
cd $UNITY_REPO
git fetch origin
git checkout develop
git pull origin develop
git checkout -b $BRANCH_NAME 2>/dev/null || git checkout $BRANCH_NAME

echo "✅ Unity repo ready on branch: $BRANCH_NAME"
```

---

## Phase 6: Copy Binaries to Unity

Copy xcframeworks and podspecs to Unity project:

```bash
cd cloudx-ios-private

UNITY_REPO="../cloudx-unity-private"
UNITY_IOS_PLUGINS="$UNITY_REPO/Assets/CloudX/Plugins/iOS"

# Create directory structure if needed
mkdir -p "$UNITY_IOS_PLUGINS"

# Copy xcframeworks
cp -R binaries-test/core/CloudXCore.xcframework "$UNITY_IOS_PLUGINS/"
cp -R binaries-test/adapter-meta/CloudXMetaAdapter.xcframework "$UNITY_IOS_PLUGINS/"
cp -R binaries-test/adapter-vungle/CloudXVungleAdapter.xcframework "$UNITY_IOS_PLUGINS/"
cp -R binaries-test/adapter-inmobi/CloudXInMobiAdapter.xcframework "$UNITY_IOS_PLUGINS/"
cp -R binaries-test/adapter-mintegral/CloudXMintegralAdapter.xcframework "$UNITY_IOS_PLUGINS/"
cp -R binaries-test/renderer-cloudx/CloudXRenderer.xcframework "$UNITY_IOS_PLUGINS/"

# Copy podspecs
cp binaries-test/core/CloudXCore.podspec "$UNITY_IOS_PLUGINS/"
cp binaries-test/adapter-meta/CloudXMetaAdapter.podspec "$UNITY_IOS_PLUGINS/"
cp binaries-test/adapter-vungle/CloudXVungleAdapter.podspec "$UNITY_IOS_PLUGINS/"
cp binaries-test/adapter-inmobi/CloudXInMobiAdapter.podspec "$UNITY_IOS_PLUGINS/"
cp binaries-test/adapter-mintegral/CloudXMintegralAdapter.podspec "$UNITY_IOS_PLUGINS/"
cp binaries-test/renderer-cloudx/CloudXRenderer.podspec "$UNITY_IOS_PLUGINS/"

echo "✅ Binaries copied to Unity project"
```

---

## Phase 7: Configure Unity iOS Build

Update Unity's iOS Podfile to use local binaries:

```bash
cd cloudx-ios-private

UNITY_REPO="../cloudx-unity-private"
VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")

# Create/update Unity iOS post-build Podfile template
# This will be used when Unity builds for iOS
cat > "$UNITY_REPO/Assets/CloudX/Editor/CloudXPodfile.txt" << EOF
# CloudX SDK - Internal Release Binaries
# Version: $VERSION
# Generated: $(date)

platform :ios, '15.0'

target 'UnityFramework' do
  use_frameworks! :linkage => :static
  
  # Local binaries from Assets/CloudX/Plugins/iOS
  pod 'CloudXCore', :path => 'Assets/CloudX/Plugins/iOS'
  pod 'CloudXMetaAdapter', :path => 'Assets/CloudX/Plugins/iOS'
  pod 'CloudXVungleAdapter', :path => 'Assets/CloudX/Plugins/iOS'
  pod 'CloudXInMobiAdapter', :path => 'Assets/CloudX/Plugins/iOS'
  pod 'CloudXMintegralAdapter', :path => 'Assets/CloudX/Plugins/iOS'
  pod 'CloudXRenderer', :path => 'Assets/CloudX/Plugins/iOS'
end

target 'Unity-iPhone' do
end
EOF

echo "✅ Unity Podfile template created"
```

---

## Phase 8: Setup JimsGame Project

Check for and setup JimsGame repository:

```bash
cd cloudx-ios-private

# Check if JimsGame repo exists
JIMSGAME_REPO="../JimsGame"
if [ ! -d "$JIMSGAME_REPO" ]; then
    echo "Cloning JimsGame..."
    cd ..
    gh repo clone cloudx-io/JimsGame
    cd cloudx-ios-private
fi

# Get version and create branch name
VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")
BRANCH_NAME="release/$VERSION"

# Create release branch in JimsGame repo
cd $JIMSGAME_REPO
git fetch origin
git checkout develop 2>/dev/null || git checkout main
git pull --rebase origin $(git branch --show-current)
git checkout -b $BRANCH_NAME 2>/dev/null || git checkout $BRANCH_NAME

echo "✅ JimsGame repo ready on branch: $BRANCH_NAME"
```

---

## Phase 9: Copy Binaries to JimsGame

Copy xcframeworks and podspecs to JimsGame project:

```bash
cd cloudx-ios-private

JIMSGAME_REPO="../JimsGame"
JIMSGAME_BINARIES="$JIMSGAME_REPO/binaries-test"

# Clean and recreate binaries-test in JimsGame
rm -rf "$JIMSGAME_BINARIES"
mkdir -p "$JIMSGAME_BINARIES/core"
mkdir -p "$JIMSGAME_BINARIES/adapter-meta"
mkdir -p "$JIMSGAME_BINARIES/adapter-vungle"
mkdir -p "$JIMSGAME_BINARIES/adapter-inmobi"
mkdir -p "$JIMSGAME_BINARIES/adapter-mintegral"
mkdir -p "$JIMSGAME_BINARIES/renderer-cloudx"

# Copy xcframeworks
cp -R binaries-test/core/CloudXCore.xcframework "$JIMSGAME_BINARIES/core/"
cp -R binaries-test/adapter-meta/CloudXMetaAdapter.xcframework "$JIMSGAME_BINARIES/adapter-meta/"
cp -R binaries-test/adapter-vungle/CloudXVungleAdapter.xcframework "$JIMSGAME_BINARIES/adapter-vungle/"
cp -R binaries-test/adapter-inmobi/CloudXInMobiAdapter.xcframework "$JIMSGAME_BINARIES/adapter-inmobi/"
cp -R binaries-test/adapter-mintegral/CloudXMintegralAdapter.xcframework "$JIMSGAME_BINARIES/adapter-mintegral/"
cp -R binaries-test/renderer-cloudx/CloudXRenderer.xcframework "$JIMSGAME_BINARIES/renderer-cloudx/"

# Copy podspecs
cp binaries-test/core/CloudXCore.podspec "$JIMSGAME_BINARIES/core/"
cp binaries-test/adapter-meta/CloudXMetaAdapter.podspec "$JIMSGAME_BINARIES/adapter-meta/"
cp binaries-test/adapter-vungle/CloudXVungleAdapter.podspec "$JIMSGAME_BINARIES/adapter-vungle/"
cp binaries-test/adapter-inmobi/CloudXInMobiAdapter.podspec "$JIMSGAME_BINARIES/adapter-inmobi/"
cp binaries-test/adapter-mintegral/CloudXMintegralAdapter.podspec "$JIMSGAME_BINARIES/adapter-mintegral/"
cp binaries-test/renderer-cloudx/CloudXRenderer.podspec "$JIMSGAME_BINARIES/renderer-cloudx/"

# Run pod install in JimsGame
cd $JIMSGAME_REPO
pod install

echo "✅ Binaries copied to JimsGame and pods installed"
echo "Open JimsGame.xcworkspace to test"
```

---

## Phase 10: Commit and Push

Commit changes to all repos:

```bash
cd cloudx-ios-private

VERSION=$(grep "s.version" core/CloudXCore.podspec | head -1 | sed "s/.*'\(.*\)'/\1/")

# Commit binaries-test changes to iOS private
git add binaries-test/
git commit -m "Update internal release binaries for $VERSION" || echo "No changes to commit"

# Commit Unity changes
cd ../cloudx-unity-private
git add Assets/CloudX/
git commit -m "Update CloudX iOS binaries to $VERSION" || echo "No changes to commit"
git push origin HEAD

# Commit JimsGame changes
cd ../JimsGame
git add binaries-test/
git add Podfile.lock
git commit -m "Update CloudX iOS binaries to $VERSION" || echo "No changes to commit"
git push origin HEAD

echo "✅ Changes committed and pushed to all repos"
```

---

## Verification Checklist

### iOS Native App (demo-app-objc)
- [ ] `pod install` succeeds in demo-app-objc
- [ ] App builds successfully
- [ ] SDK initializes without errors
- [ ] Ads load and display correctly

### JimsGame iOS App
- [ ] `pod install` succeeds in JimsGame
- [ ] App builds successfully
- [ ] SDK initializes without errors
- [ ] Ads load and display correctly

### Unity iOS Build
- [ ] Unity project opens without errors
- [ ] iOS build exports successfully
- [ ] Xcode project builds
- [ ] SDK initializes in Unity app
- [ ] Ads load and display correctly

---

## Rollback

To revert to source-based development:

```bash
cd cloudx-ios-private/demo-app-objc

cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  # CloudX SDK - Source development
  pod 'CloudXCore', :path => '../core'
  pod 'CloudXMetaAdapter', :path => '../adapter-meta'
  pod 'CloudXVungleAdapter', :path => '../adapter-vungle'
  pod 'CloudXInMobiAdapter', :path => '../adapter-inmobi'
  pod 'CloudXMintegralAdapter', :path => '../adapter-mintegral'
  pod 'CloudXRenderer', :path => '../renderer-cloudx'

  target 'CloudXObjCRemotePodsTests' do
    inherit! :search_paths
  end

  target 'CloudXObjCRemotePodsUITests' do
  end

end
EOF

pod install
```

