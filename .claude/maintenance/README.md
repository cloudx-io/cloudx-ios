# iOS Agent Documentation Maintenance System

Complete system for keeping CloudX iOS integration agent documentation synchronized with SDK updates.

## Files in This System

```
cloudx-sdk-agents/                  # Publisher-facing agent repository
├── .claude/agents/ios/
│   ├── cloudx-ios-integrator.md        # Implementation agent
│   ├── cloudx-ios-auditor.md           # Validation agent
│   ├── cloudx-ios-build-verifier.md    # Build testing agent
│   └── cloudx-ios-privacy-checker.md   # Privacy compliance agent
├── docs/ios/
│   ├── SETUP.md                    # Publisher setup guide
│   ├── INTEGRATION_GUIDE.md        # Comprehensive integration guide
│   └── ORCHESTRATION.md            # Orchestration guide
├── scripts/ios/
│   └── validate_agent_apis.sh     # Automated validation script
└── SDK_VERSION.yaml               # Version tracking (iOS platform section)

cloudx-ios-private/                 # SDK repository (this repo)
└── .claude/maintenance/
    ├── README.md                   # This file
    ├── UPDATE_WORKFLOW.md          # Step-by-step update process
    └── SDK_VERSION.yaml            # Version tracking and API signatures (source of truth)

.github/workflows/
└── validate-maintainer-agent.yml  # CI/CD automation
```

## Purpose

**Problem**: CloudX iOS SDK evolves with new APIs, renamed classes, and changed signatures. Agent documentation must stay synchronized or it provides incorrect integration guidance.

**Solution**: Automated validation + structured update workflow + CI/CD integration

## Quick Start

### For SDK Developers

**Before releasing new SDK version:**
```bash
# 1. Run validation
./scripts/validate_agent_apis.sh

# 2. If failures, update agents
# See .claude/maintenance/UPDATE_WORKFLOW.md

# 3. Verify fixes
./scripts/validate_agent_apis.sh  # Should pass

# 4. Update version
# Edit .claude/maintenance/SDK_VERSION.yaml

# 5. Commit
git commit -m "Update agents for iOS SDK vX.X.X"
```

### For Agent Maintainers

**When SDK update is released:**
```bash
# 1. Check what changed
git diff v1.1.0 v1.2.0 -- core/Sources/CloudXCore/

# 2. Run validation to see failures
./scripts/validate_agent_apis.sh

# 3. Follow update workflow
cat .claude/maintenance/UPDATE_WORKFLOW.md

# 4. Update files systematically
# See checklist in UPDATE_WORKFLOW.md
```

## iOS-Specific Considerations

### Language Support
- **Primary**: Objective-C
- **Secondary**: Swift (via NS_SWIFT_NAME)
- **Requirement**: Always provide examples in BOTH languages

### Key Differences from Android
1. **Auto-loading**: iOS ads auto-load (no explicit `.load()` call)
2. **View Controllers**: Banner/native require `UIViewController` parameter
3. **Delegates**: Use delegate protocols, not listener interfaces
4. **Privacy**: Class methods (`+` prefix), not instance methods
5. **Show Method**: Fullscreen ads require `showFromViewController:`
6. **Nullability**: Uses `_Nullable` return types

### Package Managers
- **CocoaPods**: `pod 'CloudXCore', '~> 1.2.0'`
- **Swift Package Manager**: GitHub URL + version

## Validation Scripts

### validate_agent_apis.sh
**Purpose:** Verify agent docs reference valid class/method names
**Run:** `./scripts/validate_agent_apis.sh`
**Checks:**
- Class and protocol names exist
- Factory method names correct
- Privacy API methods present
- Delegate callback signatures
- SDK version consistency

### check_api_coverage.sh
**Purpose:** Detect which public APIs are documented vs missing
**Run:** `./scripts/check_api_coverage.sh`
**Output:** Coverage percentage, list of undocumented APIs

## Common Maintenance Workflows

### Scenario 1: Minor SDK Update (No Breaking Changes)
**Example:** SDK 1.2.0 → 1.2.1 (bug fixes only)

```bash
# 1. Verify no public API changes
git diff v1.2.0 v1.2.1 -- core/Sources/CloudXCore/CloudXCoreAPI.h

# 2. Run validation (should pass)
./scripts/validate_agent_apis.sh

# 3. Update version only
sed -i '' 's/sdk_version: "1.2.0"/sdk_version: "1.2.1"/' .claude/maintenance/SDK_VERSION.yaml

# 4. Commit
git commit -m "Bump iOS agent docs version to SDK 1.2.1 (no changes needed)"
```

**Time:** 5 minutes

### Scenario 2: Major SDK Update (Breaking Changes)
**Example:** SDK 1.1.0 → 1.2.0 (API renames)

1. Detect changes with git diff
2. Run validation (may fail if APIs changed)
3. Update each affected file systematically
4. Update code examples (both Objective-C and Swift)
5. Update SDK_VERSION.yaml
6. Re-validate (should pass)
7. Test with real integration
8. Commit

**Time:** 30-60 minutes

### Scenario 3: New Feature Added
**Example:** SDK 1.2.0 adds MREC ads

1. Detect new APIs
2. Add new examples to integration guide
3. Update integrator agent with MREC examples
4. Update auditor checks for MREC
5. Update SDK_VERSION.yaml with MREC section
6. Commit

**Time:** 45 minutes

## Validation Coverage

**What We Validate:**
- Class and protocol names exist in SDK
- Factory method names exist
- Privacy API class method names correct
- Delegate callback signatures match
- SDK version consistency

**What We DON'T Validate:**
- Method signatures (parameter types/order) - smoke test only
- Return types
- All delegate callbacks (only critical ones)
- Code examples compile
- NS_SWIFT_NAME correctness
- Complete API coverage (~20% currently checked)

**Known Risks:**
- SDK could add new ad formats - agents won't know
- Method parameters could change - agents show wrong signature
- Swift API changes via NS_SWIFT_NAME not validated

## Success Criteria

Agents are **well-maintained** when:
- ✅ Validation script passes on every main branch commit
- ✅ SDK version matches agent docs version
- ✅ Updates completed within 24 hours of SDK release
- ✅ CI/CD catches regressions before merge
- ✅ Zero support tickets about incorrect APIs
- ✅ All code examples include both Objective-C and Swift
- ✅ Documentation is always current

## Support

**Questions about:**
- **Validation script**: Check script comments or create issue
- **Update workflow**: See UPDATE_WORKFLOW.md
- **CI/CD**: Check GitHub Actions logs
- **SDK changes**: Contact SDK team

**Getting Help:**
- Create GitHub issue with `ios-agent-docs` label
- Check existing issues for similar problems
- Review UPDATE_WORKFLOW.md

## Best Practices

1. **Update Agents BEFORE SDK Release** - Don't wait until after release
2. **Always Provide Both Languages** - Objective-C AND Swift examples
3. **Test with Real Integration** - Don't just validate syntax
4. **Automate Everything Possible** - Let CI/CD catch issues early
5. **Document iOS Differences** - Call out differences from Android SDK

---

**Remember**: Well-maintained agent documentation is critical for publisher success!
