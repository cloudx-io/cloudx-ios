# CloudX iOS SDK Release Process

This document describes the complete release process for the CloudX iOS SDK.

## Overview

The CloudX iOS SDK uses a **Gitflow** branching strategy with two repositories:

| Repository | Purpose | Contains |
|------------|---------|----------|
| `cloudx-ios-private` | Source code | All source files, build scripts, tests |
| `cloudx-ios` | Binary distribution | XCFrameworks, podspecs, demo apps |

## Components

| Component | Description |
|-----------|-------------|
| **CloudXCore** | Core SDK with programmatic advertising engine |
| **CloudXMetaAdapter** | Meta Audience Network integration |
| **CloudXVungleAdapter** | Vungle/Liftoff integration |
| **CloudXInMobiAdapter** | InMobi integration |
| **CloudXRenderer** | Creative rendering engine |

---

## Release Process

### Phase 1: Prepare Release Branch (Private Repo)

```bash
# 1. Checkout and update develop
cd cloudx-ios-private
git checkout develop
git pull origin develop

# 2. Create release branch
git checkout -b release/X.Y.Z

# 3. Update version constants
./scripts/update-version-constant.sh core "X.Y.Z"
./scripts/update-version-constant.sh meta "X.Y.Z"
./scripts/update-version-constant.sh vungle "X.Y.Z"
./scripts/update-version-constant.sh inmobi "X.Y.Z"
./scripts/update-version-constant.sh renderer "X.Y.Z"

# 4. Update podspec versions
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec

# 5. Update CHANGELOG.md with release date

# 6. Build xcframeworks
cd core && ./build-xcframework.sh X.Y.Z && cd ..
cd adapter-meta && ./build-xcframework.sh && cd ..
cd adapter-vungle && ./build-xcframework.sh && cd ..
cd adapter-inmobi && ./build-xcframework.sh && cd ..
cd renderer-cloudx && ./build-xcframework.sh X.Y.Z && cd ..

# 7. Commit and push release branch
git add -A
git commit -m "Prepare release X.Y.Z"
git push origin release/X.Y.Z
```

### Phase 2: Create Private Repo PRs (DO NOT MERGE YET)

Create two PRs on GitHub but **DO NOT MERGE** until testing is complete:

```bash
gh pr create --base develop --head release/X.Y.Z --title "Release X.Y.Z → develop"
gh pr create --base main --head release/X.Y.Z --title "Release X.Y.Z"
```

### Phase 3: Release to Public Repo (For Testing)

```bash
cd cloudx-ios

# 1. Create release branch from main
git checkout main
git pull origin main
git checkout -b release/vX.Y.Z

# 2. Copy xcframeworks from private repo
cp ../cloudx-ios-private/core/CloudXCore.xcframework.zip core/
cp ../cloudx-ios-private/adapter-meta/CloudXMetaAdapter.xcframework.zip adapter-meta/
cp ../cloudx-ios-private/adapter-vungle/CloudXVungleAdapter.xcframework.zip adapter-vungle/
cp ../cloudx-ios-private/adapter-inmobi/CloudXInMobiAdapter.xcframework.zip adapter-inmobi/
cp ../cloudx-ios-private/renderer-cloudx/CloudXRenderer.xcframework.zip renderer-cloudx/

# 3. Unzip xcframeworks
cd core && rm -rf CloudXCore.xcframework && unzip -o CloudXCore.xcframework.zip && cd ..
cd adapter-meta && rm -rf CloudXMetaAdapter.xcframework && unzip -o CloudXMetaAdapter.xcframework.zip && cd ..
cd adapter-vungle && rm -rf CloudXVungleAdapter.xcframework && unzip -o CloudXVungleAdapter.xcframework.zip && cd ..
cd adapter-inmobi && rm -rf CloudXInMobiAdapter.xcframework && unzip -o CloudXInMobiAdapter.xcframework.zip && cd ..
cd renderer-cloudx && rm -rf CloudXRenderer.xcframework && unzip -o CloudXRenderer.xcframework.zip && cd ..

# 4. Update podspecs (located alongside xcframeworks in subdirectories)
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec

# 5. Update dependency versions in adapter podspecs
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec

# 6. Commit and push release branch
git add -A
git commit -m "Release X.Y.Z"
git push origin release/vX.Y.Z

# 7. Create PR (DO NOT MERGE YET)
gh pr create --base main --head release/vX.Y.Z --title "Release X.Y.Z"
```

### Phase 4: Test Demo Apps (CRITICAL - DO BEFORE MERGING)

**⚠️ DO NOT MERGE ANY PRs UNTIL TESTING IS COMPLETE**

#### Step 1: Test BOTH Demo Apps from Release Branch

Test **both** the Objective-C and Swift demo apps with temporary branch URLs:

**Objective-C Demo App:**
```bash
cd cloudx-ios/demo-app-objc

# Temporarily update Podfile to test from release branch
cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXInMobiAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'

  target 'CloudXObjCRemotePodsTests' do
    inherit! :search_paths
  end
  target 'CloudXObjCRemotePodsUITests' do
  end
end
EOF

pod install --repo-update
open CloudXObjCRemotePods.xcworkspace
# Build and run tests
```

**Swift Demo App:**
```bash
cd cloudx-ios/demo-app-swift

cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXSwiftRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'
  pod 'CloudXInMobiAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release/vX.Y.Z'

  target 'CloudXSwiftRemotePodsTests' do
    inherit! :search_paths
  end
  target 'CloudXSwiftRemotePodsUITests' do
  end
end
EOF

pod install --repo-update
open CloudXSwiftRemotePods.xcworkspace
# Build and run tests
```

**Test Checklist (run for BOTH apps):**
- [ ] App builds successfully
- [ ] SDK initializes without errors
- [ ] Banner ads load and display
- [ ] MREC ads load and display
- [ ] Interstitial ads load and display
- [ ] SDK version shows X.Y.Z in logs/requests
- [ ] No crashes

#### Step 2: Update Podfiles for Production (Before Merge)

After testing passes, update **both** demo app Podfiles to use version specifiers:

**Objective-C Demo App:**
```bash
cd cloudx-ios/demo-app-objc

cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', '~> X.Y.Z'
  pod 'CloudXMetaAdapter', '~> X.Y.Z'
  pod 'CloudXRenderer', '~> X.Y.Z'
  pod 'CloudXVungleAdapter', '~> X.Y.Z'
  pod 'CloudXInMobiAdapter', '~> X.Y.Z'

  target 'CloudXObjCRemotePodsTests' do
    inherit! :search_paths
  end
  target 'CloudXObjCRemotePodsUITests' do
  end
end
EOF
```

**Swift Demo App:**
```bash
cd cloudx-ios/demo-app-swift

cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'CloudXSwiftRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', '~> X.Y.Z'
  pod 'CloudXMetaAdapter', '~> X.Y.Z'
  pod 'CloudXRenderer', '~> X.Y.Z'
  pod 'CloudXVungleAdapter', '~> X.Y.Z'
  pod 'CloudXInMobiAdapter', '~> X.Y.Z'

  target 'CloudXSwiftRemotePodsTests' do
    inherit! :search_paths
  end
  target 'CloudXSwiftRemotePodsUITests' do
  end
end
EOF
```

**Commit the updated Podfiles:**
```bash
cd cloudx-ios
git add demo-app-objc/Podfile demo-app-swift/Podfile
git commit -m "chore: Update demo apps for X.Y.Z release"
git push origin release/vX.Y.Z
```

**Note:** The version specifier Podfiles won't work until after CocoaPods Trunk push (Phase 6). This is intentional - the demo apps should show the production installation method.

### Phase 5: Merge PRs and Tag (After Testing Passes)

**Only proceed after Phase 4 testing is successful!**

#### Step 1: Merge PUBLIC Repo PR

```bash
# Go to GitHub and merge cloudx-ios PR to main
# Then tag and create releases:

cd cloudx-ios
git checkout main
git pull origin main

git tag vX.Y.Z-core
git tag vX.Y.Z-meta
git tag vX.Y.Z-vungle
git tag vX.Y.Z-inmobi
git tag vX.Y.Z-renderer
git push origin vX.Y.Z-core vX.Y.Z-meta vX.Y.Z-vungle vX.Y.Z-inmobi vX.Y.Z-renderer

# Create GitHub releases with xcframework attachments
gh release create vX.Y.Z-core --title "CloudXCore X.Y.Z" core/CloudXCore.xcframework.zip
gh release create vX.Y.Z-meta --title "CloudXMetaAdapter X.Y.Z" adapter-meta/CloudXMetaAdapter.xcframework.zip
gh release create vX.Y.Z-vungle --title "CloudXVungleAdapter X.Y.Z" adapter-vungle/CloudXVungleAdapter.xcframework.zip
gh release create vX.Y.Z-inmobi --title "CloudXInMobiAdapter X.Y.Z" adapter-inmobi/CloudXInMobiAdapter.xcframework.zip
gh release create vX.Y.Z-renderer --title "CloudXRenderer X.Y.Z" renderer-cloudx/CloudXRenderer.xcframework.zip
```

#### Step 2: Merge PRIVATE Repo PRs

```bash
# Go to GitHub:
# 1. Merge release/X.Y.Z → develop (regular merge)
# 2. Merge release/X.Y.Z → main (SQUASH merge)
```

#### Step 3: Sync Main Back to Develop (CRITICAL)

**⚠️ This step prevents merge conflicts in future releases!**

After squash merging to main, sync the squashed commit back to develop:

```bash
cd cloudx-ios-private
git checkout develop
git pull origin develop
git merge main -m "Sync release X.Y.Z from main"
git push origin develop
```

**Why is this necessary?**
- Squash merge creates a NEW commit that Git doesn't recognize as related to the original commits
- Without this sync, the next release branch (created from develop) won't have main's history
- This causes merge conflicts when trying to merge future releases to main

#### Step 4: Tag PRIVATE Repo Main

```bash
cd cloudx-ios-private
git checkout main
git pull origin main

git tag vX.Y.Z-core
git tag vX.Y.Z-meta
git tag vX.Y.Z-vungle
git tag vX.Y.Z-inmobi
git tag vX.Y.Z-renderer
git push origin vX.Y.Z-core vX.Y.Z-meta vX.Y.Z-vungle vX.Y.Z-inmobi vX.Y.Z-renderer
```

---

### First Release Bootstrap (One-Time Only)

If this is your **first release** and main has diverged significantly from develop, you may encounter merge conflicts. To bootstrap:

**Option A: Temporarily disable branch protection**
1. Go to GitHub → Settings → Branches → main → Edit
2. Disable "Require pull request before merging"
3. Force push:
   ```bash
   git checkout main
   git reset --hard release/X.Y.Z
   git push origin main --force
   ```
4. Re-enable branch protection

**Option B: Use GitHub's web UI to resolve conflicts**
1. In the PR, click "Resolve conflicts"
2. For each file, accept the incoming (release branch) version
3. Mark as resolved and merge

After bootstrapping, future releases will merge cleanly as long as you perform Step 3 (sync main → develop) after each release.

---

### Phase 6: Push to CocoaPods Trunk (Required for `pod install` to work)

**⚠️ CRITICAL: This step is required for third-party developers to install via `pod 'CloudXCore'`**

```bash
cd cloudx-ios

# Verify you're logged into CocoaPods Trunk
pod trunk me

# If not logged in:
pod trunk register YOUR_EMAIL 'Your Name' --description='Release machine'
# Check email and click verification link

# Push each podspec to trunk (ORDER MATTERS - Core first!)
pod trunk push core/CloudXCore.podspec --allow-warnings

# Wait for CloudXCore to be available, then push adapters
pod trunk push renderer-cloudx/CloudXRenderer.podspec --allow-warnings
pod trunk push adapter-meta/CloudXMetaAdapter.podspec --allow-warnings
pod trunk push adapter-vungle/CloudXVungleAdapter.podspec --allow-warnings
pod trunk push adapter-inmobi/CloudXInMobiAdapter.podspec --allow-warnings

# Verify pods are published
pod trunk info CloudXCore
pod trunk info CloudXMetaAdapter
pod trunk info CloudXVungleAdapter
pod trunk info CloudXInMobiAdapter
pod trunk info CloudXRenderer
```

**Note:** CocoaPods Trunk can take 5-15 minutes to propagate. Run `pod repo update` to get the latest specs.

#### Verify BOTH Demo Apps Work from Trunk (CRITICAL)

**⚠️ This step confirms that third-party developers can install the SDK via `pod install`**

After trunk push succeeds and CDN propagates (~5-15 minutes), test **both** demo apps:

```bash
# Update CocoaPods repo cache
pod repo update

# Test Objective-C Demo App
cd cloudx-ios/demo-app-objc
pod install
open CloudXObjCRemotePods.xcworkspace
# Build and run - verify SDK initializes and ads load

# Test Swift Demo App
cd ../demo-app-swift
pod install
open CloudXSwiftRemotePods.xcworkspace
# Build and run - verify SDK initializes and ads load
```

**Verification Checklist:**
- [ ] `pod install` succeeds for both apps (no "unable to find specification" errors)
- [ ] Podfile.lock shows correct version X.Y.Z for all CloudX pods
- [ ] Both apps build successfully
- [ ] SDK initializes without errors
- [ ] At least one ad format loads correctly

If `pod install` fails with version not found, wait a few more minutes for CDN propagation and run `pod repo update` again.

### Phase 7: Update Cross-Platform SDKs

After the iOS SDK is released and verified, update the wrapper SDKs:

#### Flutter SDK (`cloudx-flutter`)

```bash
cd cloudx-flutter

# 1. Update iOS dependency version in podspec
# Edit ios/cloudx_flutter.podspec:
#   s.dependency 'CloudXCore', '~> X.Y.Z'
#   s.dependency 'CloudXMetaAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXRenderer', '~> X.Y.Z'
#   s.dependency 'CloudXVungleAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXInMobiAdapter', '~> X.Y.Z'

# 2. Update pubspec.yaml version
# Edit pubspec.yaml:
#   version: X.Y.Z

# 3. Update CHANGELOG.md

# 4. Test the Flutter demo app
cd example
flutter pub get
cd ios && pod install && cd ..
flutter run

# 5. Commit and create release
git add -A
git commit -m "Release X.Y.Z - Update iOS SDK dependency"
git tag vX.Y.Z
git push origin main --tags

# 6. Publish to pub.dev (if applicable)
flutter pub publish
```

#### React Native SDK (`cloudx-react-native`)

```bash
cd cloudx-react-native

# 1. Update iOS dependency version in podspec
# Edit cloudx-react-native.podspec:
#   s.dependency 'CloudXCore', '~> X.Y.Z'
#   s.dependency 'CloudXMetaAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXRenderer', '~> X.Y.Z'
#   s.dependency 'CloudXVungleAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXInMobiAdapter', '~> X.Y.Z'

# 2. Update package.json version
# Edit package.json:
#   "version": "X.Y.Z"

# 3. Update CHANGELOG.md

# 4. Test the React Native demo app
cd example
npm install
cd ios && pod install && cd ..
npx react-native run-ios

# 5. Commit and create release
git add -A
git commit -m "Release X.Y.Z - Update iOS SDK dependency"
git tag vX.Y.Z
git push origin main --tags

# 6. Publish to npm
npm publish
```

**Cross-Platform Test Checklist:**
- [ ] Flutter demo app builds and runs
- [ ] Flutter SDK initializes and loads ads
- [ ] React Native demo app builds and runs
- [ ] React Native SDK initializes and loads ads

### Phase 8: Cleanup

```bash
# Delete release branches
cd cloudx-ios-private
git branch -d release/X.Y.Z
git push origin --delete release/X.Y.Z

cd ../cloudx-ios
git branch -d release/vX.Y.Z
git push origin --delete release/vX.Y.Z
```

---

## Version Files

### Version Constants (Private Repo)

| Component | File |
|-----------|------|
| Core | `core/Sources/CloudXCore/CLXVersion.m` |
| Meta | `adapter-meta/Sources/CloudXMetaAdapter/CLXMetaAdapterVersion.m` |
| Vungle | `adapter-vungle/Sources/CloudXVungleAdapter/CLXVungleAdapterVersion.m` |
| InMobi | `adapter-inmobi/Sources/CloudXInMobiAdapter/CLXInMobiAdapterVersion.m` |
| Renderer | `renderer-cloudx/Sources/CloudXRenderer/CLXRendererVersion.m` |

### Podspecs (Private Repo - Local Development)

| Component | File |
|-----------|------|
| Core | `core/CloudXCore.podspec` |
| Meta | `adapter-meta/CloudXMetaAdapter.podspec` |
| Vungle | `adapter-vungle/CloudXVungleAdapter.podspec` |
| InMobi | `adapter-inmobi/CloudXInMobiAdapter.podspec` |
| Renderer | `renderer-cloudx/CloudXRenderer.podspec` |

### Podspecs (Public Repo - Binary Distribution)

| Component | File |
|-----------|------|
| Core | `core/CloudXCore.podspec` |
| Meta | `adapter-meta/CloudXMetaAdapter.podspec` |
| Vungle | `adapter-vungle/CloudXVungleAdapter.podspec` |
| InMobi | `adapter-inmobi/CloudXInMobiAdapter.podspec` |
| Renderer | `renderer-cloudx/CloudXRenderer.podspec` |

---

## CocoaPods Trunk Setup (One-Time)

If you haven't set up CocoaPods Trunk:

```bash
# Register (only needed once per machine)
pod trunk register your@email.com 'Your Name' --description='CloudX Release'

# Check your email and click the verification link

# Verify registration
pod trunk me
```

---

## Important Rules

1. **Never push directly to main or develop** - Always use PRs
2. **Never push source code to public repo** - Binary distribution only
3. **Always squash merge to main** - Clean release history
4. **Tag main after squash merge** - Component-specific tags
5. **Update CHANGELOG.md** - Document what's in each release
6. **Test demo apps BEFORE merging PRs** - Verify xcframeworks work
7. **Push to CocoaPods Trunk** - Required for public `pod install`

---

## Troubleshooting

### Build Artifacts

The build scripts may generate `release_metadata.txt` files in component directories. These are informational only and should **not be committed**. Delete them before committing:

```bash
rm -f core/release_metadata.txt renderer-cloudx/release_metadata.txt
```

### Build Failures

If xcframework builds fail:

```bash
# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean local build directories
rm -rf core/build adapter-meta/build adapter-vungle/build adapter-inmobi/build renderer-cloudx/build

# Re-run pod install if needed
cd adapter-meta && pod install && cd ..
cd adapter-vungle && pod install && cd ..
cd adapter-inmobi && pod install && cd ..
cd renderer-cloudx && pod install && cd ..
```

### Version Mismatch

To verify all versions match:

```bash
# Check version constants
grep -r "Version = @" --include="*.m" . | grep -v Pods

# Check podspec versions
grep -r "s\.version" --include="*.podspec" . | grep -v Pods
```

### CocoaPods Trunk Issues

```bash
# Clear CocoaPods cache
pod cache clean --all
pod repo update

# Check if pod is available
pod search CloudXCore
```
