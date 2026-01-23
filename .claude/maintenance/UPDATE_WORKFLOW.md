# iOS Agent Update Workflow

This document describes how to keep agent documentation synchronized with CloudX iOS SDK updates.

## Problem

When CloudX iOS SDK is updated with:
- New APIs
- Renamed classes/methods
- Changed delegate callback signatures
- Deprecated features
- New ad formats

The agent documentation becomes **outdated** and provides incorrect integration guidance.

## Solution

We maintain synchronization through:
1. **Version tracking** - `.claude/maintenance/SDK_VERSION.yaml`
2. **Automated validation** - `scripts/validate_agent_apis.sh`
3. **Update workflow** - This document
4. **CI/CD integration** - Automated checks on release

## When to Update Agents

### Trigger Events

1. **SDK Version Release**
   - New version published to CocoaPods/SPM
   - Git tag created (e.g., `v1.2.0-core`)
   - CHANGELOG updated

2. **Public API Changes**
   - Class/protocol renamed
   - Method signature changed
   - Delegate callback modified
   - New required parameters added
   - Deprecated APIs removed

3. **New Features**
   - New ad format added
   - New configuration options
   - New privacy settings

### What Changes Don't Require Updates

- Internal implementation changes (no public API impact)
- Bug fixes that don't change APIs
- Performance improvements
- Documentation-only changes in SDK

## Update Workflow

### Step 1: Detect SDK Changes

#### Automated Detection (Recommended)
```bash
# Run after pulling latest SDK code
./scripts/validate_agent_apis.sh
```

Output will show:
- ✅ APIs still valid
- ❌ APIs changed or missing
- ⚠️  Warnings about deprecated patterns

#### Manual Detection
Compare changes between versions:
```bash
# See what changed in public APIs
git diff v1.1.0 v1.2.0 -- core/Sources/CloudXCore/CloudXCoreAPI.h

# Check delegate protocols
git diff v1.1.0 v1.2.0 -- core/Sources/CloudXCore/*Delegate.h
```

### Step 2: Identify Breaking Changes

Review git diff and identify:

**Method Signature Changes:**
```objective-c
// OLD
- (void)initWithAppKey:(NSString *)appKey;

// NEW
- (void)initializeSDKWithAppKey:(NSString *)appKey
                     completion:(nullable void (^)(BOOL success, NSError *error))completion;
```

**Delegate Callback Changes:**
```objective-c
// OLD
- (void)bannerDidLoad:(CLXBannerAdView *)banner;

// NEW
- (void)bannerDidLoad:(CLXBannerAdView *)banner withAd:(CLXAd *)ad;
```

**Class/Protocol Renames:**
```objective-c
// OLD
@protocol CLXBannerViewDelegate

// NEW
@protocol CLXBannerDelegate
```

**New Required Parameters:**
```objective-c
// OLD
- (CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement;

// NEW
- (CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                viewController:(UIViewController *)viewController;
```

### Step 3: Update Agent Files

For each breaking change, update affected files:

#### 3a. Update cloudx-ios-integrator.md

Find and replace old API names/signatures.

Update Objective-C examples:
```objective-c
// Update initialization
[[CloudXCore shared] initializeSDKWithAppKey:@"YOUR_KEY" completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"CloudX SDK initialized");
    } else {
        NSLog(@"Initialization failed: %@", error.localizedDescription);
    }
}];
```

Update Swift examples:
```swift
CloudXCore.shared.initializeSDK(appKey: "YOUR_KEY") { success, error in
    if success {
        print("CloudX SDK initialized")
    } else if let error = error {
        print("Initialization failed: \(error.localizedDescription)")
    }
}
```

#### 3b. Update cloudx-ios-auditor.md

Update validation patterns:
```markdown
Check for: `- (void)bannerDidFailToLoad:(CLXBannerAdView *)banner withError:(NSError *)error`
```

Update error messages:
```markdown
❌ FAIL: Using incorrect delegate callback signature
Fix: Update to current SDK delegate protocol
```

#### 3c. Update cloudx-ios-privacy-checker.md

Update privacy API checks:
```objective-c
// If privacy methods change
[CloudXCore setCCPAPrivacyString:@"1YNN"];
[CloudXCore setIsUserConsent:YES];
[CloudXCore setIsAgeRestrictedUser:NO];
```

#### 3d. Update cloudx-ios-build-verifier.md

Add common errors for deprecated APIs:
```markdown
### Issue: "No visible @interface for 'CloudXCore' declares the selector 'oldMethodName:'"
**Fix:** Use current API method name from SDK documentation
```

#### 3e. Update docs/ios/INTEGRATION_GUIDE.md

This is the MOST IMPORTANT file - it has all code examples.

Update all:
- Initialization examples (both ObjC and Swift)
- Ad loading examples (both ObjC and Swift)
- Delegate implementations (both ObjC and Swift)
- Import statements
- CocoaPods/SPM installation instructions

### Step 4: Update Version Tracking

Edit `.claude/maintenance/SDK_VERSION.yaml`:

```yaml
sdk_version: "1.2.0"  # Update to new version
agents_last_updated: "2025-11-14"  # Update to current date
verified_against_commit: "24ad68a"  # Latest commit hash

# Update api_signatures section with current signatures from SDK
api_signatures:
  initialization:
    method: "initializeSDKWithAppKey:completion:"
    swift_name: "initializeSDK(appKey:completion:)"
    # ... rest
```

### Step 5: Validate Changes

Run validation script:
```bash
./scripts/validate_agent_apis.sh
```

Expected output:
```
✅ ALL CHECKS PASSED
Agent documentation is in sync with iOS SDK 1.2.0
```

If failures:
```
❌ FAIL: Agent uses deprecated method name
   → Should be updated to current API name
```

Fix and re-run until all checks pass.

### Step 6: Test with Real Integration

Create a test scenario:
```bash
# Use updated agents to integrate SDK
Use cloudx-ios-integrator to integrate CloudX SDK v1.2.0 in a test app
```

Verify:
- Code compiles (both Objective-C and Swift projects)
- APIs are correct
- No deprecation warnings
- Fallback works

### Step 7: Commit and Tag

```bash
git add .claude/ scripts/
git commit -m "Update iOS agents for CloudX SDK v1.2.0

- Updated initialization method signature
- Added MREC ad format support
- Updated privacy API examples
- Validated with validate_agent_apis.sh

Refs: #issue_number"

git tag ios-agent-docs-v1.2.0
git push origin main --tags
```

## Update Checklist

Use this for each SDK update:

### Pre-Update
- [ ] Pull latest SDK code
- [ ] Check CHANGELOG for breaking changes
- [ ] Run `./scripts/validate_agent_apis.sh` (baseline)
- [ ] Note current SDK version from `.claude/maintenance/SDK_VERSION.yaml`

### Detect Changes
- [ ] Run `git diff <old-tag> <new-tag> -- core/Sources/CloudXCore/`
- [ ] List all renamed classes/protocols
- [ ] List all changed method signatures
- [ ] List all new APIs
- [ ] List all deprecated/removed APIs
- [ ] Check NS_SWIFT_NAME changes

### Update Files
- [ ] Update `.claude/agents/ios/cloudx-ios-integrator.md` (both ObjC and Swift)
- [ ] Update `.claude/agents/ios/cloudx-ios-auditor.md`
- [ ] Update `.claude/agents/ios/cloudx-ios-build-verifier.md`
- [ ] Update `.claude/agents/ios/cloudx-ios-privacy-checker.md`
- [ ] Update `docs/ios/INTEGRATION_GUIDE.md` (all examples, both languages)
- [ ] Update `docs/ios/ORCHESTRATION.md` (if needed)
- [ ] Update `.claude/maintenance/SDK_VERSION.yaml`

### Validate
- [ ] Run `./scripts/validate_agent_apis.sh` (all checks pass)
- [ ] Run `./scripts/check_api_coverage.sh` (check coverage)
- [ ] Test agent with real Objective-C project
- [ ] Test agent with real Swift project
- [ ] Verify code compiles
- [ ] Check no deprecation warnings

### Finalize
- [ ] Commit changes with detailed message
- [ ] Tag commit: `ios-agent-docs-vX.X.X`
- [ ] Push to remote
- [ ] Update team documentation
- [ ] Notify integration partners

## iOS-Specific Update Guidelines

### Always Provide Both Languages

**Objective-C:**
```objective-c
[[CloudXCore shared] initializeSDKWithAppKey:@"YOUR_KEY" completion:^(BOOL success, NSError *error) {
    // ...
}];
```

**Swift:**
```swift
CloudXCore.shared.initializeSDK(appKey: "YOUR_KEY") { success, error in
    // ...
}
```

### Handle NS_SWIFT_NAME Changes

If `NS_SWIFT_NAME` macro changes:
```objective-c
// Objective-C signature stays the same
- (void)createBannerWithPlacement:(NSString *)placement
    NS_SWIFT_NAME(createBanner(placement:));

// But Swift examples must update
// OLD: CloudXCore.shared.createBannerWithPlacement("banner")
// NEW: CloudXCore.shared.createBanner(placement: "banner")
```

### Update CocoaPods and SPM Examples

**CocoaPods:**
```ruby
pod 'CloudXCore', '~> 1.2.0'  # Update version
```

**Swift Package Manager:**
```swift
.package(url: "https://github.com/cloudx-io/cloudx-ios", from: "1.2.0")
```

### Delegate Protocol Updates

Always show full protocol conformance:
```objective-c
@interface MyViewController : UIViewController <CLXBannerDelegate>
@end

@implementation MyViewController

- (void)bannerDidLoad:(CLXBannerAdView *)banner {
    NSLog(@"Banner loaded");
}

- (void)bannerDidFailToLoad:(CLXBannerAdView *)banner withError:(NSError *)error {
    NSLog(@"Banner failed: %@", error.localizedDescription);
    // Fallback logic here
}

@end
```

## Common Pitfalls

### iOS-Specific Issues
1. **Forgetting Swift examples** - Always provide both languages
2. **Wrong NS_SWIFT_NAME** - Check SDK header for correct Swift API
3. **Missing UIViewController** - Banner/native creation requires it
4. **Wrong delegate conformance** - Must implement protocol correctly
5. **Class vs instance methods** - Privacy methods are class methods

### General Issues
1. **Missing state flags** - Track which SDK successfully loaded
2. **Not clearing fallback** - Clear when CloudX succeeds
3. **Wrong lifecycle handling** - Respect delegate callbacks

## Best Practices

### 1. Update Agents BEFORE SDK Release
- Agents should be ready when SDK ships
- Include agent updates in release checklist
- Test agents during SDK beta period

### 2. Test Both Languages
```bash
# Test with Objective-C project
cd /path/to/objc/test/project
Use cloudx-ios-integrator to integrate CloudX SDK

# Test with Swift project
cd /path/to/swift/test/project
Use cloudx-ios-integrator to integrate CloudX SDK
```

### 3. Maintain Language-Specific Notes

In agents, call out language differences:
```markdown
**Objective-C:**
```objective-c
[interstitial showFromViewController:self];
```

**Swift:**
```swift
interstitial.show(from: self)
```
```

### 4. Keep CocoaPods and SPM in Sync

Both package managers should have same version:
- Update Package.swift
- Update CloudXCore.podspec
- Update agent installation examples

## Emergency Fix Process

If agents are deployed with incorrect APIs:

### 1. Immediate Mitigation
```bash
# Revert to last known good version
git revert <bad-commit>
git push origin main
```

### 2. Fast Update
```bash
# Fix priority files only
1. Update cloudx-ios-integrator.md (most used)
2. Run validation script
3. Push immediately
4. Update other files later
```

### 3. Notify Users
```markdown
⚠️  IMPORTANT: CloudX iOS Agent Documentation Update

Version X.X.X of the agents had incorrect API signatures.
Please update:

```bash
# If using local agents
cd /path/to/cloudx-sdk-agents
git pull

# Or re-invoke agents
Use cloudx-ios-integrator to...
```

## Contacts

- **SDK Team**: For API change notifications - mobile@cloudx.io
- **Agent Maintainer**: For agent update questions
- **DevOps**: For CI/CD integration

---

**Remember**: Keeping agents in sync is critical for publisher success. Outdated agents cause compilation errors and support burden.

Make agent updates part of your SDK release process!
