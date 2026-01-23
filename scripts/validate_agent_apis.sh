#!/bin/bash

# CloudX iOS SDK - Agent API Validation Script
# Validates that agent documentation references correct iOS SDK APIs
# Usage: ./scripts/validate_agent_apis.sh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SDK_DIR:-$SCRIPT_DIR/..}"
AGENT_REPO_DIR="${AGENT_REPO_DIR:-$SDK_DIR/../cloudx-sdk-agents}"
AGENT_DIR="$AGENT_REPO_DIR/.claude/agents/ios"
DOCS_DIR="$AGENT_REPO_DIR/docs/ios"

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  CloudX iOS Agent API Validation      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}✓${NC} PASS: $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} FAIL: $1"
    if [ -n "$2" ]; then
        echo -e "  ${RED}→${NC} $2"
    fi
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} WARN: $1"
    if [ -n "$2" ]; then
        echo -e "  ${YELLOW}→${NC} $2"
    fi
    ((WARNINGS++))
}

check_info() {
    echo -e "${BLUE}ℹ${NC} INFO: $1"
}

# Main validation
print_header

# Check if agent repo exists
if [ ! -d "$AGENT_REPO_DIR" ]; then
    check_fail "Agent repository not found at $AGENT_REPO_DIR" \
        "Clone cloudx-sdk-agents to $(dirname $AGENT_REPO_DIR)/"
    exit 1
fi

check_info "SDK Directory: $SDK_DIR"
check_info "Agent Repository: $AGENT_REPO_DIR"
echo ""

# Validate iOS SDK sources exist
if [ ! -d "$SDK_DIR/core/Sources/CloudXCore" ]; then
    check_fail "iOS SDK source not found at $SDK_DIR/core/Sources/CloudXCore"
    exit 1
fi
check_pass "iOS SDK source directory found"

# Validate agent files exist
echo ""
echo "Checking agent files..."
if [ ! -f "$AGENT_DIR/cloudx-ios-integrator.md" ]; then
    check_fail "Integrator agent not found"
else
    check_pass "Integrator agent exists"
fi

if [ ! -f "$AGENT_DIR/cloudx-ios-auditor.md" ]; then
    check_fail "Auditor agent not found"
else
    check_pass "Auditor agent exists"
fi

if [ ! -f "$AGENT_DIR/cloudx-ios-build-verifier.md" ]; then
    check_fail "Build verifier agent not found"
else
    check_pass "Build verifier agent exists"
fi

if [ ! -f "$AGENT_DIR/cloudx-ios-privacy-checker.md" ]; then
    check_fail "Privacy checker agent not found"
else
    check_pass "Privacy checker agent exists"
fi

# Validate critical API references
echo ""
echo "Checking critical API classes..."

# Check CloudXCore class
if grep -q "interface CloudXCore" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "CloudXCore class exists in SDK"
else
    check_fail "CloudXCore class not found in SDK"
fi

# Check delegate protocols
if grep -q "protocol CLXBannerDelegate" "$SDK_DIR/core/Sources/CloudXCore/CLXBannerDelegate.h" 2>/dev/null; then
    check_pass "CLXBannerDelegate protocol exists"
else
    check_fail "CLXBannerDelegate protocol not found"
fi

if grep -q "protocol CLXInterstitialDelegate" "$SDK_DIR/core/Sources/CloudXCore/CLXInterstitialDelegate.h" 2>/dev/null; then
    check_pass "CLXInterstitialDelegate protocol exists"
else
    check_fail "CLXInterstitialDelegate protocol not found"
fi

if grep -q "protocol CLXRewardedDelegate" "$SDK_DIR/core/Sources/CloudXCore/CLXRewardedDelegate.h" 2>/dev/null; then
    check_pass "CLXRewardedDelegate protocol exists"
else
    check_fail "CLXRewardedDelegate protocol not found"
fi

# Check factory methods
echo ""
echo "Checking factory methods..."

if grep -q "createBannerWithPlacement:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "createBannerWithPlacement: method exists"
else
    check_fail "createBannerWithPlacement: method not found"
fi

if grep -q "createMRECWithPlacement:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "createMRECWithPlacement: method exists"
else
    check_fail "createMRECWithPlacement: method not found"
fi

if grep -q "createInterstitialWithPlacement:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "createInterstitialWithPlacement: method exists"
else
    check_fail "createInterstitialWithPlacement: method not found"
fi

if grep -q "createRewardedWithPlacement:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "createRewardedWithPlacement: method exists"
else
    check_fail "createRewardedWithPlacement: method not found"
fi

# Check privacy methods
echo ""
echo "Checking privacy API methods..."

if grep -q "setCCPAPrivacyString:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "setCCPAPrivacyString: method exists"
else
    check_fail "setCCPAPrivacyString: method not found"
fi

if grep -q "setIsUserConsent:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "setIsUserConsent: method exists"
else
    check_fail "setIsUserConsent: method not found"
fi

if grep -q "setIsAgeRestrictedUser:" "$SDK_DIR/core/Sources/CloudXCore/CloudXCoreAPI.h" 2>/dev/null; then
    check_pass "setIsAgeRestrictedUser: method exists"
else
    check_fail "setIsAgeRestrictedUser: method not found"
fi

# Check agent documentation for deprecated patterns
echo ""
echo "Checking for deprecated API patterns in agents..."

# Skip files that don't exist
if [ -f "$AGENT_DIR/cloudx-ios-integrator.md" ]; then
    # Check for old initialization patterns (example - adjust as needed)
    if grep -q "initWithAppKey:" "$AGENT_DIR/cloudx-ios-integrator.md" 2>/dev/null; then
        check_warn "Agent uses old initialization pattern 'initWithAppKey:'" \
            "Should use 'initializeSDKWithAppKey:completion:'"
    fi
fi

# Check delegate callback signatures
echo ""
echo "Checking delegate callback patterns..."

if [ -f "$AGENT_DIR/cloudx-ios-integrator.md" ]; then
    # Check for correct callback signature (banner)
    if grep -q "bannerDidLoad:" "$AGENT_DIR/cloudx-ios-integrator.md" 2>/dev/null; then
        check_pass "Agent uses correct bannerDidLoad: callback"
    else
        check_warn "Agent missing bannerDidLoad: callback example"
    fi

    # Check for correct failure callback
    if grep -q "bannerDidFailToLoad:withError:" "$AGENT_DIR/cloudx-ios-integrator.md" 2>/dev/null; then
        check_pass "Agent uses correct bannerDidFailToLoad:withError: callback"
    else
        check_warn "Agent missing bannerDidFailToLoad:withError: callback example"
    fi
fi

# Check for Swift examples
echo ""
echo "Checking for Swift examples..."

if [ -f "$AGENT_DIR/cloudx-ios-integrator.md" ]; then
    if grep -q "CloudXCore.shared" "$AGENT_DIR/cloudx-ios-integrator.md" 2>/dev/null; then
        check_pass "Agent includes Swift examples"
    else
        check_warn "Agent may be missing Swift examples"
    fi
fi

# Check SDK version consistency
echo ""
echo "Checking SDK version consistency..."

SDK_VERSION_FILE="$SDK_DIR/core/Sources/CloudXCore/CLXVersion.m"
AGENT_VERSION_FILE="$SDK_DIR/.claude/maintenance/SDK_VERSION.yaml"

if [ -f "$SDK_VERSION_FILE" ] && [ -f "$AGENT_VERSION_FILE" ]; then
    SDK_VERSION=$(grep "CLXSDKVersion = @" "$SDK_VERSION_FILE" | sed 's/.*@"\(.*\)".*/\1/')
    AGENT_VERSION=$(grep "^sdk_version:" "$AGENT_VERSION_FILE" | sed 's/sdk_version: "\(.*\)"/\1/')

    if [ "$SDK_VERSION" = "$AGENT_VERSION" ]; then
        check_pass "SDK version matches agent version ($SDK_VERSION)"
    else
        check_fail "SDK version ($SDK_VERSION) != agent version ($AGENT_VERSION)" \
            "Update .claude/maintenance/SDK_VERSION.yaml"
    fi
else
    check_warn "Could not verify SDK version consistency"
fi

# Summary
echo ""
echo "========================================="
echo ""
echo -e "${BLUE}Validation Summary:${NC}"
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Validation FAILED${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review failed checks above"
    echo "2. Update agent documentation"
    echo "3. Run validation again"
    echo ""
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Validation PASSED with warnings${NC}"
    echo ""
    echo "Consider addressing warnings before release"
    echo ""
    exit 0
else
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Agent documentation is in sync with iOS SDK"
    echo ""
    exit 0
fi
