<!--
================================================================================
PUBLIC RELEASE PROCESS
================================================================================
Purpose: Release CloudX iOS SDK to the PUBLIC cloudx-ios repository
Target:  cloudx-io/cloudx-ios (binary distribution via CocoaPods Trunk)
Audience: External developers integrating CloudX SDK

This document is used by Claude to execute public releases. Follow these steps
to build xcframeworks, publish to the public repo, and push to CocoaPods Trunk.

For INTERNAL testing releases, see: INTERNAL_RELEASE.md
================================================================================
-->

# CloudX iOS SDK Release Process

This document describes the complete release process for the CloudX iOS SDK.

## Overview

The CloudX iOS SDK uses a **trunk-based** branching strategy with two repositories:

- **`main`** is the default branch for both repositories
- All feature branches are created from `main` and merged back into `main`
- No release branches are needed - releases are tagged directly on `main`

| Repository | Purpose | Contains |
|------------|---------|----------|
| `cloudx-ios-private` | Source code + dSYMs | All source files, build scripts, tests, **dSYM releases** |
| `cloudx-ios` | Binary distribution | XCFrameworks (stripped), podspecs, demo apps |

## Components

| Component | Type | CocoaPods Trunk | Description |
|-----------|------|-----------------|-------------|
| **CloudXCore** | **DYNAMIC** | ✅ Published | Core SDK with programmatic advertising engine |
| **CloudXMetaAdapter** | Static | ✅ Published | Meta Audience Network integration |
| **CloudXVungleAdapter** | Static | ✅ Published | Vungle/Liftoff integration |
| **CloudXInMobiAdapter** | Static | ✅ Published | InMobi integration |
| **CloudXMintegralAdapter** | Static | ✅ Published | Mintegral integration |
| **CloudXUnityAdapter** | Static | ✅ Published | Unity Ads integration |
| **CloudXMolocoAdapter** | Static | ⚠️ **BETA** | Moloco integration (not on trunk yet) |
| **CloudXRenderer** | Static | ✅ Published | Creative rendering engine |

## dSYM Strategy (CloudXCore Only)

CloudXCore is distributed as a **dynamic framework** to enable crash symbolication:

| Artifact | Repository | Purpose |
|----------|------------|---------|
| `CloudXCore.xcframework.zip` | `cloudx-ios` (PUBLIC) | Stripped binary for distribution |
| `CloudXCore-dSYMs.zip` | `cloudx-ios-private` (PRIVATE) | Debug symbols for crash analysis |

**⚠️ dSYMs are strictly internal and must NEVER be shared publicly.**

### Crash Symbolication Workflow

When a host app crashes in CloudXCore code:

1. Host app owner sends unsymbolicated crash report to CloudX team
2. CloudX downloads corresponding dSYMs from private repo release
3. CloudX symbolicates crash internally using `atos` or `symbolicatecrash`
4. CloudX provides fix or symbolicated stack trace to host app owner

```bash
# Example: Symbolicate a crash address
atos -o CloudXCore-ios.dSYM/Contents/Resources/DWARF/CloudXCore \
     -arch arm64 -l <load_address> <symbol_address>
```

---

## Release Process

### Phase 1: Prepare Release (Private Repo)

**Note:** Changes are committed directly to `main` in the private repo (no release branch needed).
The public repo uses a release branch for testing before merge (see Phase 2).

```bash
# 1. Checkout and update main
cd cloudx-ios-private
git checkout main
git pull origin main

# 2. Update version constants (only components being released)
./scripts/update-version-constant.sh core "X.Y.Z"
./scripts/update-version-constant.sh meta "X.Y.Z"
./scripts/update-version-constant.sh vungle "X.Y.Z"
./scripts/update-version-constant.sh inmobi "X.Y.Z"
./scripts/update-version-constant.sh renderer "X.Y.Z"
./scripts/update-version-constant.sh mintegral "X.Y.Z"
./scripts/update-version-constant.sh unity "X.Y.Z"
# Also update moloco if releasing:
# ./scripts/update-version-constant.sh moloco "X.Y.Z"

# 3. Update podspec versions (only components being released)
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-mintegral/CloudXMintegralAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-unity/CloudXUnityAdapter.podspec
# Also update moloco if releasing:
# sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-moloco/CloudXMolocoAdapter.podspec

# 4. Update CHANGELOGs (see "CHANGELOGs" section for public vs private guidance):
#    - cloudx-ios-private/CHANGELOG.md (internal — full technical detail, PR numbers)
#    - cloudx-ios/CHANGELOG.md (public — user-facing changes only)
#    - docs: updated separately in Phase 2b

# 5. Build xcframeworks
cd core && ./build-xcframework.sh X.Y.Z && cd ..
cd renderer-cloudx && ./build-xcframework.sh X.Y.Z && cd ..
cd adapter-meta && ./build-xcframework.sh && cd ..
cd adapter-vungle && ./build-xcframework.sh && cd ..
cd adapter-inmobi && ./build-xcframework.sh && cd ..
cd adapter-mintegral && ./build-xcframework.sh && cd ..
cd adapter-unity && ./build-xcframework.sh && cd ..
# Also build moloco if releasing:
# cd adapter-moloco && ./build-xcframework.sh && cd ..

# 6. Commit and push directly to main
git add -A
git commit -m "Prepare release X.Y.Z"
git push origin main
```

### Phase 2: Release to Public Repo (For Testing)

```bash
cd cloudx-ios

# 1. Checkout and update main
git checkout main
git pull origin main

# 2. Create a feature branch for the release
git checkout -b release-X.Y.Z

# 3. Copy xcframeworks from private repo
cp ../cloudx-ios-private/core/CloudXCore.xcframework.zip core/
cp ../cloudx-ios-private/adapter-meta/CloudXMetaAdapter.xcframework.zip adapter-meta/
cp ../cloudx-ios-private/adapter-vungle/CloudXVungleAdapter.xcframework.zip adapter-vungle/
cp ../cloudx-ios-private/adapter-inmobi/CloudXInMobiAdapter.xcframework.zip adapter-inmobi/
cp ../cloudx-ios-private/renderer-cloudx/CloudXRenderer.xcframework.zip renderer-cloudx/
cp ../cloudx-ios-private/adapter-mintegral/CloudXMintegralAdapter.xcframework.zip adapter-mintegral/
cp ../cloudx-ios-private/adapter-unity/CloudXUnityAdapter.xcframework.zip adapter-unity/

# 4. Unzip xcframeworks
cd core && rm -rf CloudXCore.xcframework && unzip -o CloudXCore.xcframework.zip && cd ..
cd adapter-meta && rm -rf CloudXMetaAdapter.xcframework && unzip -o CloudXMetaAdapter.xcframework.zip && cd ..
cd adapter-vungle && rm -rf CloudXVungleAdapter.xcframework && unzip -o CloudXVungleAdapter.xcframework.zip && cd ..
cd adapter-inmobi && rm -rf CloudXInMobiAdapter.xcframework && unzip -o CloudXInMobiAdapter.xcframework.zip && cd ..
cd renderer-cloudx && rm -rf CloudXRenderer.xcframework && unzip -o CloudXRenderer.xcframework.zip && cd ..
cd adapter-mintegral && rm -rf CloudXMintegralAdapter.xcframework && unzip -o CloudXMintegralAdapter.xcframework.zip && cd ..
cd adapter-unity && rm -rf CloudXUnityAdapter.xcframework && unzip -o CloudXUnityAdapter.xcframework.zip && cd ..

# 5. Update podspecs (located alongside xcframeworks in subdirectories)
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" core/CloudXCore.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-mintegral/CloudXMintegralAdapter.podspec
sed -i '' "s/s\.version.*=.*/s.version = 'X.Y.Z'/" adapter-unity/CloudXUnityAdapter.podspec

# 6. Update dependency versions in adapter podspecs
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-meta/CloudXMetaAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-vungle/CloudXVungleAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-inmobi/CloudXInMobiAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" renderer-cloudx/CloudXRenderer.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-mintegral/CloudXMintegralAdapter.podspec
sed -i '' "s/s\.dependency 'CloudXCore', '[^']*'/s.dependency 'CloudXCore', 'X.Y.Z'/" adapter-unity/CloudXUnityAdapter.podspec

# 7. Update podspec source tags to unified format: "v#{s.version}" (not "v#{s.version}-component")
#    ⚠️ ONE-TIME MIGRATION (2.2.3+): Previous releases used per-component tags (e.g., v2.2.2-core).
#    Starting with the next release, all podspecs must use "v#{s.version}" so a single git tag works.
#    Verify with: grep 's\.source' --include='*.podspec' -r . | grep -v Pods
#    Every podspec should show :tag => "v#{s.version}" — no -core, -meta, etc. suffixes.
for spec in core/CloudXCore.podspec adapter-meta/CloudXMetaAdapter.podspec adapter-vungle/CloudXVungleAdapter.podspec adapter-inmobi/CloudXInMobiAdapter.podspec renderer-cloudx/CloudXRenderer.podspec adapter-mintegral/CloudXMintegralAdapter.podspec adapter-unity/CloudXUnityAdapter.podspec; do
  sed -i '' 's/:tag => "v#{s.version}-[^"]*"/:tag => "v#{s.version}"/' "$spec"
done

# 7. Commit and push
git add -A
git commit -m "Release X.Y.Z"
git push origin release-X.Y.Z

# 8. Create PR to main
gh pr create --base main --head release-X.Y.Z --title "Release X.Y.Z"
```

### Phase 2b: Update Docs Repo

```bash
cd docs
git checkout main
git pull origin main
git checkout -b release-ios-X.Y.Z
```

**1. Changelog (en + zh):** Add a version entry to `en/ios/changelog.mdx` and `zh/ios/changelog.mdx`. Include **only user-facing changes** — see the "CHANGELOGs" section for guidance.

**2. Adapter pages (if a new adapter is being released):** Create `en/ios/adapters/<adapter>.mdx` and `zh/ios/adapters/<adapter>.mdx`. Mirror the structure of existing adapter pages (e.g., `meta.mdx`): title/description frontmatter, Requirements, Installation (CocoaPods + Manual), Info.plist (SKAdNetwork IDs, ATT), Project Configuration, Support. Add the new page to both language sections in `docs.json` under the Adapters group.

**3. Integration page (if the Podfile example needs updating):** Add the new adapter pod to the CocoaPods example in `en/ios/integration.mdx` and `zh/ios/integration.mdx`, matching the existing comment style (`# Network SDK X.Y.Z`). Only touch the integration page when the Podfile example or API surface changes — keep edits minimal and match the existing format exactly.

```bash
git add -A
git commit -m "Add docs for iOS X.Y.Z release"
git push origin release-ios-X.Y.Z
gh pr create --base main --head release-ios-X.Y.Z --title "iOS X.Y.Z docs"
```

---

### Phase 3: Test Demo Apps (CRITICAL - DO BEFORE MERGING)

**⚠️ DO NOT MERGE ANY PRs UNTIL TESTING IS COMPLETE**

#### Step 1: Test BOTH Demo Apps from Feature Branch

Test **both** the Objective-C and Swift demo apps with temporary branch URLs:

**Objective-C Demo App:**
```bash
cd cloudx-ios/demo-app-objc

# Temporarily update Podfile to test from feature branch
cat > Podfile << 'EOF'
platform :ios, '13.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXInMobiAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXMintegralAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXUnityAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'

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
platform :ios, '13.0'

target 'CloudXSwiftRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXInMobiAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXMintegralAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'
  pod 'CloudXUnityAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'release-X.Y.Z'

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
platform :ios, '13.0'

target 'CloudXObjCRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', '~> X.Y.Z'
  pod 'CloudXMetaAdapter', '~> X.Y.Z'
  pod 'CloudXRenderer', '~> X.Y.Z'
  pod 'CloudXVungleAdapter', '~> X.Y.Z'
  pod 'CloudXInMobiAdapter', '~> X.Y.Z'
  pod 'CloudXMintegralAdapter', '~> X.Y.Z'
  pod 'CloudXUnityAdapter', '~> X.Y.Z'

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
platform :ios, '13.0'

target 'CloudXSwiftRemotePods' do
  use_frameworks! :linkage => :static

  pod 'CloudXCore', '~> X.Y.Z'
  pod 'CloudXMetaAdapter', '~> X.Y.Z'
  pod 'CloudXRenderer', '~> X.Y.Z'
  pod 'CloudXVungleAdapter', '~> X.Y.Z'
  pod 'CloudXInMobiAdapter', '~> X.Y.Z'
  pod 'CloudXMintegralAdapter', '~> X.Y.Z'
  pod 'CloudXUnityAdapter', '~> X.Y.Z'

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
git push origin release-X.Y.Z
```

**Note:** The version specifier Podfiles won't work until after CocoaPods Trunk push (Phase 5). This is intentional - the demo apps should show the production installation method.

### Phase 4: Merge PRs and Tag (After Testing Passes)

**Only proceed after Phase 3 testing is successful!**

#### Step 1: Merge PUBLIC Repo PR

```bash
# Go to GitHub and merge cloudx-ios PR to main
# Then tag and create a single release:

cd cloudx-ios
git checkout main
git pull origin main

git tag vX.Y.Z
git push origin vX.Y.Z

# Create a single GitHub release with ALL xcframework zips attached
# Omit any adapter not being released (e.g., remove the unity line if not releasing unity)
gh release create vX.Y.Z \
  --title "CloudX iOS SDK X.Y.Z" \
  core/CloudXCore.xcframework.zip \
  adapter-meta/CloudXMetaAdapter.xcframework.zip \
  adapter-vungle/CloudXVungleAdapter.xcframework.zip \
  adapter-inmobi/CloudXInMobiAdapter.xcframework.zip \
  renderer-cloudx/CloudXRenderer.xcframework.zip \
  adapter-mintegral/CloudXMintegralAdapter.xcframework.zip \
  adapter-unity/CloudXUnityAdapter.xcframework.zip
```

#### Step 2: Tag PRIVATE Repo Main and Create dSYM Release

**Note:** No PR to merge for the private repo -- changes were committed directly to main in Phase 1.
All components share the same version, so the private repo uses a **single tag and single release** per version.

**⚠️ CRITICAL: dSYMs must stay in the PRIVATE repo - never upload to public repo!**

```bash
cd cloudx-ios-private
git checkout main
git pull origin main

git tag vX.Y.Z
git push origin vX.Y.Z

# Create a single private release with dSYMs for crash symbolication
gh release create vX.Y.Z \
  --title "CloudX iOS SDK X.Y.Z (INTERNAL — dSYMs)" \
  --notes "## CloudX iOS SDK vX.Y.Z — dSYMs

⚠️ **CONFIDENTIAL**: These dSYMs are for internal crash symbolication only.
Never share these files outside the CloudX organization.

### Usage
When a host app owner reports a crash in CloudXCore:
1. Download \`CloudXCore-dSYMs.zip\` from this release
2. Use atos or symbolicatecrash to symbolicate the crash

### Corresponding Public Release
https://github.com/cloudx-io/cloudx-ios/releases/tag/vX.Y.Z-core" \
  core/CloudXCore-dSYMs.zip
```

**Verification:** Confirm dSYMs are only in the private repo:
- ✅ `cloudx-ios-private` release has `CloudXCore-dSYMs.zip`
- ✅ `cloudx-ios` releases have ONLY xcframework zips (no dSYMs!)

---

### Phase 5: Push to CocoaPods Trunk (Required for `pod install` to work)

**⚠️ CRITICAL: This step is required for third-party developers to install via `pod 'CloudXCore'`**

```bash
cd cloudx-ios

# Verify you're logged into CocoaPods Trunk
pod trunk me

# If not logged in:
pod trunk register YOUR_EMAIL 'Your Name' --description='Release machine'
# Check email and click verification link

# ⚠️ PRE-FLIGHT: Verify every podspec source tag matches an actual git tag.
# Each podspec has s.source = { :tag => "v#{s.version}-<component>" }.
# Confirm the corresponding tags exist BEFORE pushing:
grep -r "s\.source" --include="*.podspec" . | grep -v Pods
git tag -l "vX.Y.Z-*"
# Every podspec tag must have a matching git tag. If not, fix before proceeding.

# Push each podspec to trunk (ORDER MATTERS - Core first!)
pod trunk push core/CloudXCore.podspec --allow-warnings

# Wait for CloudXCore CDN propagation before pushing adapters.
# The CDN can take 5-30+ minutes. Check with:
#   curl -s "https://cdn.cocoapods.org/all_pods_versions_7_4_3.txt" | grep CloudXCore
# Must show X.Y.Z in the version list. Retry every 2-3 min until it appears.
# Do NOT try workarounds — just wait for the CDN.

# Once Core is on CDN, push adapters (can run in parallel with --skip-import-validation):
pod trunk push renderer-cloudx/CloudXRenderer.podspec --allow-warnings --skip-import-validation --skip-tests
pod trunk push adapter-meta/CloudXMetaAdapter.podspec --allow-warnings --skip-import-validation --skip-tests
pod trunk push adapter-vungle/CloudXVungleAdapter.podspec --allow-warnings --skip-import-validation --skip-tests
pod trunk push adapter-inmobi/CloudXInMobiAdapter.podspec --allow-warnings --skip-import-validation --skip-tests
pod trunk push adapter-mintegral/CloudXMintegralAdapter.podspec --allow-warnings --skip-import-validation --skip-tests
pod trunk push adapter-unity/CloudXUnityAdapter.podspec --allow-warnings --skip-import-validation --skip-tests

# Verify pods are published
pod trunk info CloudXCore
pod trunk info CloudXMetaAdapter
pod trunk info CloudXVungleAdapter
pod trunk info CloudXInMobiAdapter
pod trunk info CloudXRenderer
pod trunk info CloudXMintegralAdapter
pod trunk info CloudXUnityAdapter
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

---

### Beta Adapter Releases (Moloco)

**⚠️ The following adapters are in BETA and are NOT pushed to CocoaPods trunk:**

| Adapter | Status | When to Release to Trunk |
|---------|--------|--------------------------|
| CloudXMolocoAdapter | BETA | When production-ready and fully tested |

#### How Beta Adapters Are Released

Beta adapters use a **soft release** process:

1. **GitHub Release Only** - Creates a pre-release on GitHub with xcframework
2. **No CocoaPods Trunk Push** - NOT available via `pod 'CloudXMolocoAdapter'`
3. **Pre-release Flag** - Marked as pre-release in GitHub (not "latest")

#### How to Release a Beta Adapter

```bash
# Tag format: v{version}-{adapter}
# Example for Moloco:
git tag v1.3.0-moloco
git push origin v1.3.0-moloco

# This triggers .github/workflows/moloco-release.yml
# which creates a GitHub pre-release but does NOT push to trunk
```

#### How Users Install Beta Adapters

Users must reference the GitHub tag directly in their Podfile:

```ruby
# Podfile for Moloco beta
pod 'CloudXMolocoAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.3.0-moloco'
```

#### Promoting Beta to Production

When a beta adapter is ready for production:

1. Update the adapter's release workflow to include `pod trunk push`
2. Remove the `--prerelease` flag from `gh release create`
3. Remove BETA warnings from README and podspec
4. Add the adapter to the Phase 5 trunk push commands above
5. Update the Components table to show ✅ Published

---

### Phase 6: Update Cross-Platform SDKs

After the iOS SDK is released and verified, update the wrapper SDKs. Each SDK follows the same pattern:
1. Create a release branch from main
2. Update dependencies and version
3. Test the demo app
4. Create PR to main
5. After PR is merged, tag and publish

#### Flutter SDK (`cloudx-flutter`)

```bash
cd cloudx-flutter

# 1. Create release branch
git checkout main
git pull origin main
git checkout -b release-X.Y.Z

# 2. Update iOS dependency version in podspec
# Edit ios/cloudx_flutter.podspec:
#   s.dependency 'CloudXCore', '~> X.Y.Z'
#   s.dependency 'CloudXMetaAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXRenderer', '~> X.Y.Z'
#   s.dependency 'CloudXVungleAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXInMobiAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXMintegralAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXUnityAdapter', '~> X.Y.Z'

# 3. Update pubspec.yaml version
# Edit pubspec.yaml:
#   version: X.Y.Z

# 4. Update CHANGELOG.md

# 5. Test the Flutter demo app
cd example
flutter pub get
cd ios && pod install && cd ..
flutter run
cd ..

# 6. Commit and push release branch
git add -A
git commit -m "Release X.Y.Z - Update iOS SDK dependency"
git push origin release-X.Y.Z

# 7. Create PR to main
gh pr create --base main --head release-X.Y.Z --title "Release X.Y.Z"

# 8. After PR is merged, tag and publish
git checkout main
git pull origin main
git tag vX.Y.Z
git push origin vX.Y.Z

# 9. Publish to pub.dev (if applicable)
flutter pub publish
```

#### React Native SDK (`cloudx-react-native`)

```bash
cd cloudx-react-native

# 1. Create release branch
git checkout main
git pull origin main
git checkout -b release-X.Y.Z

# 2. Update iOS dependency version in podspec
# Edit cloudx-react-native.podspec:
#   s.dependency 'CloudXCore', '~> X.Y.Z'
#   s.dependency 'CloudXMetaAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXRenderer', '~> X.Y.Z'
#   s.dependency 'CloudXVungleAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXInMobiAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXMintegralAdapter', '~> X.Y.Z'
#   s.dependency 'CloudXUnityAdapter', '~> X.Y.Z'

# 3. Update package.json version
# Edit package.json:
#   "version": "X.Y.Z"

# 4. Update CHANGELOG.md

# 5. Test the React Native demo app
cd example
npm install
cd ios && pod install && cd ..
npx react-native run-ios
cd ..

# 6. Commit and push release branch
git add -A
git commit -m "Release X.Y.Z - Update iOS SDK dependency"
git push origin release-X.Y.Z

# 7. Create PR to main
gh pr create --base main --head release-X.Y.Z --title "Release X.Y.Z"

# 8. After PR is merged, tag and publish
git checkout main
git pull origin main
git tag vX.Y.Z
git push origin vX.Y.Z

# 9. Publish to npm
npm publish
```

#### Unity SDK (`cloudx-unity-private`)

```bash
cd cloudx-unity-private

# 1. Create release branch
git checkout main
git pull origin main
git checkout -b release-X.Y.Z

# 2. Update iOS dependency version
# Edit the iOS plugin podspec or dependency file to reference:
#   CloudXCore ~> X.Y.Z
#   CloudXMetaAdapter ~> X.Y.Z
#   CloudXRenderer ~> X.Y.Z
#   CloudXVungleAdapter ~> X.Y.Z
#   CloudXInMobiAdapter ~> X.Y.Z
#   CloudXMintegralAdapter ~> X.Y.Z
#   CloudXUnityAdapter ~> X.Y.Z

# 3. Update package version (package.json or equivalent)

# 4. Update CHANGELOG.md

# 5. Test the Unity demo project
# - Open Unity project
# - Build for iOS
# - Run on device/simulator
# - Verify SDK initializes and ads load

# 6. Commit and push release branch
git add -A
git commit -m "Release X.Y.Z - Update iOS SDK dependency"
git push origin release-X.Y.Z

# 7. Create PR to main
gh pr create --base main --head release-X.Y.Z --title "Release X.Y.Z"

# 8. After PR is merged, tag
git checkout main
git pull origin main
git tag vX.Y.Z
git push origin vX.Y.Z

# 9. Publish Unity package (if applicable)
# Follow Unity package publishing process
```

**Cross-Platform Test Checklist:**
- [ ] Flutter demo app builds and runs
- [ ] Flutter SDK initializes and loads ads
- [ ] React Native demo app builds and runs
- [ ] React Native SDK initializes and loads ads
- [ ] Unity demo project builds for iOS
- [ ] Unity SDK initializes and loads ads

### Phase 7: Cleanup

```bash
# Delete release branch from public repo (optional - can be done via GitHub PR merge settings)
cd cloudx-ios
git branch -d release-X.Y.Z
git push origin --delete release-X.Y.Z
```

---

## CHANGELOGs (All Must Be Updated)

**⚠️ THREE CHANGELOGs must be updated for each release:**

| File | Repository | When to Update |
|------|------------|----------------|
| `CHANGELOG.md` | cloudx-ios-private | Phase 1 (prepare release) |
| `CHANGELOG.md` | cloudx-ios | Phase 2 (write public version) |
| `ios/changelog.mdx` | docs | Phase 2 (write public version) |

**Format:** Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with sections for Added, Changed, Fixed, Removed.

### Private CHANGELOG (cloudx-ios-private)

The internal changelog includes **all** changes with full technical detail and PR numbers. This is for internal reference only.

**Include:** Internal infrastructure (ILRD, session events, click notifications, adapter metadata, metrics gating), refactors (geo service, architecture alignment), test improvements, CI/CD changes, internal tooling, adapter hardening details, and all bug fixes with root-cause detail.

### Public CHANGELOG (cloudx-ios, docs)

The public changelog is for **publishers integrating the SDK**. Only include changes that affect the public API, observable behavior, or integration requirements.

**Include:**
- New public APIs (e.g., `setHasUserConsent:`, `setDoNotSell:`)
- New adapter availability (e.g., "Mintegral adapter now available")
- Bug fixes that publishers may have encountered (describe the symptom, not the internal cause)
- Third-party SDK version upgrades that affect publisher builds
- Deprecations and migration guides

**Exclude:**
- Internal tracking systems (ILRD, session events, click notifications, adapter metadata)
- Internal infrastructure (metrics gating, config request changes)
- Internal refactors (geo service architecture, code cleanup)
- Test infrastructure changes
- CI/CD and build system changes
- Detailed root-cause analysis of bugs (describe the fix from the publisher's perspective)

**Tone:** Describe changes from the publisher's perspective. Instead of "Parse seatNonBid and nbr for actionable no-bid diagnostics," write "Improved error visibility for no-bid scenarios." Instead of "Preserve server diagnostic messages in banner error callbacks," write "Fixed an issue where some error details were lost in banner ad callbacks."

---

## Version Files

### Version Constants (Private Repo)

⚠️ **ALL components must have their version constants updated during each release!**

| Component | File | Constant |
|-----------|------|----------|
| Core | `core/Sources/CloudXCore/CLXVersion.m` | `CLXSDKVersion` |
| Meta | `adapter-meta/Sources/CloudXMetaAdapter/CLXMetaAdapterVersion.m` | `CLXMetaAdapterVersion` |
| Vungle | `adapter-vungle/Sources/CloudXVungleAdapter/CLXVungleAdapterVersion.m` | `CLXVungleAdapterVersion` |
| InMobi | `adapter-inmobi/Sources/CloudXInMobiAdapter/CLXInMobiAdapterVersion.m` | `CLXInMobiAdapterVersion` |
| Mintegral | `adapter-mintegral/Sources/CloudXMintegralAdapter/CLXMintegralAdapterVersion.m` | `CLXMintegralAdapterVersion` |
| Unity | `adapter-unity/Sources/CloudXUnityAdapter/CLXUnityAdapterVersion.m` | `CLXUnityAdapterVersion` |
| Moloco | `adapter-moloco/Sources/CloudXMolocoAdapter/CLXMolocoAdapterVersion.m` | `CLXMolocoAdapterVersion` |
| Renderer | `renderer-cloudx/Sources/CloudXRenderer/CLXRendererVersion.m` | `CLXRendererVersion` |

### Podspecs (Private Repo - Local Development)

| Component | File |
|-----------|------|
| Core | `core/CloudXCore.podspec` |
| Meta | `adapter-meta/CloudXMetaAdapter.podspec` |
| Vungle | `adapter-vungle/CloudXVungleAdapter.podspec` |
| InMobi | `adapter-inmobi/CloudXInMobiAdapter.podspec` |
| Mintegral | `adapter-mintegral/CloudXMintegralAdapter.podspec` |
| Unity | `adapter-unity/CloudXUnityAdapter.podspec` |
| Moloco | `adapter-moloco/CloudXMolocoAdapter.podspec` |
| Renderer | `renderer-cloudx/CloudXRenderer.podspec` |

### Podspecs (Public Repo - Binary Distribution)

| Component | File |
|-----------|------|
| Core | `core/CloudXCore.podspec` |
| Meta | `adapter-meta/CloudXMetaAdapter.podspec` |
| Vungle | `adapter-vungle/CloudXVungleAdapter.podspec` |
| InMobi | `adapter-inmobi/CloudXInMobiAdapter.podspec` |
| Mintegral | `adapter-mintegral/CloudXMintegralAdapter.podspec` |
| Unity | `adapter-unity/CloudXUnityAdapter.podspec` |
| Moloco | `adapter-moloco/CloudXMolocoAdapter.podspec` |
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

### General Release Rules

1. **Never push source code to public repo** - Binary distribution only
2. **One tag per version** - Single `vX.Y.Z` tag on both repos (all components share the same version)
3. **One GitHub release per version** - Single release with all xcframework zips (public) or dSYMs (private) attached
4. **Update ALL CHANGELOGs** - Internal (cloudx-ios-private), public (cloudx-ios), AND docs (docs/ios/changelog.mdx)
5. **Test demo apps BEFORE merging PRs** - Verify xcframeworks work
6. **Push to CocoaPods Trunk** - Required for public `pod install`

### Framework Type Rules (CRITICAL)

| Component | Framework Type | Has dSYMs? | Notes |
|-----------|---------------|------------|-------|
| **CloudXCore** | **DYNAMIC** | ✅ Yes (private) | Only component built as dynamic framework |
| CloudXMetaAdapter | Static | ❌ No | Remains static - DO NOT CHANGE |
| CloudXVungleAdapter | Static | ❌ No | Remains static - DO NOT CHANGE |
| CloudXInMobiAdapter | Static | ❌ No | Remains static - DO NOT CHANGE |
| CloudXMintegralAdapter | Static | ❌ No | Remains static - DO NOT CHANGE |
| CloudXUnityAdapter | Static | ❌ No | Remains static - DO NOT CHANGE |
| CloudXRenderer | Static | ❌ No | Remains static - DO NOT CHANGE |

**Why only CloudXCore is dynamic:**
- CloudXCore contains our proprietary code that we want to debug via crash reports
- Adapters are open source and will be moved to public repos - no need for private dSYMs
- Dynamic frameworks enable host apps to capture crash reports we can symbolicate

### `-ObjC` Linker Flag (CRITICAL for Dynamic Framework)

⚠️ **The PUBLIC repo's `CloudXCore.podspec` MUST include the `-ObjC` linker flag!**

Dynamic frameworks don't automatically load Objective-C categories at runtime. Without this flag, apps will crash with errors like:
```
-[CLXRendererBanner clx_isFlexibleSize]: unrecognized selector sent to instance
```

The public repo podspec must include:
```ruby
s.user_target_xcconfig = {
  'OTHER_LDFLAGS' => '$(inherited) -ObjC'
}
```

| Distribution Type | `-ObjC` Required? | Why |
|------------------|-------------------|-----|
| Source files | ❌ No | Categories compiled directly into binary |
| Static framework | ❌ No | Symbols linked into app binary |
| **Dynamic framework** | ✅ **YES** | Categories loaded at runtime - linker skips "unused" symbols |

**This flag was NOT needed when CloudXCore was static, but IS required now that it's dynamic.**

### dSYM Confidentiality Rules (CRITICAL)

🔒 **dSYMs are STRICTLY INTERNAL and must NEVER be exposed publicly.**

| Action | Allowed? |
|--------|----------|
| Upload dSYMs to `cloudx-ios-private` releases | ✅ Yes |
| Upload dSYMs to `cloudx-ios` releases | 🚫 **NEVER** |
| Push dSYMs to CocoaPods trunk | 🚫 **NEVER** |
| Upload dSYMs to Sentry/Crashlytics | 🚫 **NEVER** |
| Share dSYMs with customers | 🚫 **NEVER** |
| Include dSYMs in public xcframework zip | 🚫 **NEVER** |

**Why:** dSYMs can be used to reverse-engineer our code structure, function names, and logic.

---

## Troubleshooting

### Build Artifacts (MUST CLEAN UP AFTER RELEASE)

⚠️ **The build scripts generate temporary files that should NOT be committed to the repo!**

These files are generated during the build process and should be deleted after uploading to GitHub releases:

| File | Purpose | Action |
|------|---------|--------|
| `**/release_metadata.txt` | Build info for humans | Delete after release |
| `core/CloudXCore-dSYMs.zip` | Debug symbols for crash analysis | Upload to private GitHub release, then delete |
| `**/*.xcframework.zip` | Framework archives | Upload to GitHub release, then delete |
| `**/build/` | Build directories | Delete |

```bash
# Clean up after release (run from repo root)
rm -f core/release_metadata.txt renderer-cloudx/release_metadata.txt
rm -f core/CloudXCore-dSYMs.zip
rm -f core/CloudXCore.xcframework.zip
rm -f adapter-*/CloudX*Adapter.xcframework.zip
rm -f renderer-cloudx/CloudXRenderer.xcframework.zip
rm -rf */build
```

**Why these files appear as "untracked":**
- The build scripts create these files locally
- They should be uploaded to GitHub releases, NOT committed to the repo
- After the release is complete, delete them to keep your working directory clean

**Recommended .gitignore additions** (if not already present):
```
**/release_metadata.txt
*-dSYMs.zip
```

**⚠️ Never commit dSYM files to any repository** - they should only exist in private GitHub releases.

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

### dSYM Issues

**dSYMs not generated:**
```bash
# Ensure DEBUG_INFORMATION_FORMAT is set correctly
cd core
grep -r "DEBUG_INFORMATION_FORMAT" CloudXCore.xcodeproj/project.pbxproj
# Should show: DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym" for Release

# Rebuild with explicit dSYM generation
./build-xcframework.sh X.Y.Z
ls -la build/dSYMs/  # Should contain .dSYM folders
```

**Symbolicating a crash report:**
```bash
# Download dSYMs from private release
gh release download vX.Y.Z --repo cloudx-io/cloudx-ios-private --pattern "*dSYMs*"
unzip CloudXCore-dSYMs.zip

# Symbolicate using atos
atos -o build/dSYMs/CloudXCore-ios.dSYM/Contents/Resources/DWARF/CloudXCore \
     -arch arm64 -l 0x100000000 0x100001234

# Or use symbolicatecrash
export DEVELOPER_DIR=$(xcode-select -p)
symbolicatecrash crash.ips build/dSYMs/CloudXCore-ios.dSYM > symbolicated.crash
```

**Verify dSYMs match framework:**
```bash
# Get UUID from framework
dwarfdump --uuid CloudXCore.xcframework/ios-arm64/CloudXCore.framework/CloudXCore

# Get UUID from dSYM
dwarfdump --uuid CloudXCore-ios.dSYM

# UUIDs must match for symbolication to work
```
