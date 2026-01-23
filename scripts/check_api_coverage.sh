#!/bin/bash

# CloudX iOS SDK - API Coverage Check Script
# Analyzes which public APIs are documented in agent files vs missing
# Usage: ./scripts/check_api_coverage.sh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SDK_DIR:-$SCRIPT_DIR/..}"
AGENT_REPO_DIR="${AGENT_REPO_DIR:-$SDK_DIR/../cloudx-sdk-agents}"
AGENT_DIR="$AGENT_REPO_DIR/.claude/agents/ios"
DOCS_DIR="$AGENT_REPO_DIR/docs/ios"

# Counters
TOTAL_APIS=0
DOCUMENTED_APIS=0
MISSING_APIS=0

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  CloudX iOS API Coverage Analysis     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

check_documented() {
    local api_name=$1
    local search_pattern=$2

    if grep -rq "$search_pattern" "$AGENT_DIR" "$DOCS_DIR" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $api_name"
        ((DOCUMENTED_APIS++))
        return 0
    else
        echo -e "  ${RED}✗${NC} $api_name"
        ((MISSING_APIS++))
        return 1
    fi
}

# Main analysis
print_header

echo -e "${BLUE}Checking agent repository...${NC}"
if [ ! -d "$AGENT_REPO_DIR" ]; then
    echo -e "${RED}Error: Agent repository not found at $AGENT_REPO_DIR${NC}"
    echo "Clone cloudx-sdk-agents to $(dirname $AGENT_REPO_DIR)/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Agent repository found"
echo ""

# Check initialization APIs
echo -e "${BLUE}Initialization APIs:${NC}"
((TOTAL_APIS++))
check_documented "initializeSDKWithAppKey:completion:" "initializeSDK"

# Check banner APIs
echo ""
echo -e "${BLUE}Banner APIs:${NC}"
((TOTAL_APIS++))
check_documented "createBannerWithPlacement:" "createBanner"
((TOTAL_APIS++))
check_documented "CLXBannerDelegate" "CLXBannerDelegate"
((TOTAL_APIS++))
check_documented "bannerDidLoad:" "bannerDidLoad"
((TOTAL_APIS++))
check_documented "bannerDidFailToLoad:withError:" "bannerDidFailToLoad"

# Check MREC APIs
echo ""
echo -e "${BLUE}MREC APIs:${NC}"
((TOTAL_APIS++))
check_documented "createMRECWithPlacement:" "createMREC"

# Check interstitial APIs
echo ""
echo -e "${BLUE}Interstitial APIs:${NC}"
((TOTAL_APIS++))
check_documented "createInterstitialWithPlacement:" "createInterstitial"
((TOTAL_APIS++))
check_documented "CLXInterstitialDelegate" "CLXInterstitialDelegate"
((TOTAL_APIS++))
check_documented "interstitialDidLoad:" "interstitialDidLoad"
((TOTAL_APIS++))
check_documented "interstitialDidFailToLoad:withError:" "interstitialDidFailToLoad"
((TOTAL_APIS++))
check_documented "showFromViewController:" "showFromViewController"

# Check rewarded APIs
echo ""
echo -e "${BLUE}Rewarded APIs:${NC}"
((TOTAL_APIS++))
check_documented "createRewardedWithPlacement:" "createRewarded"
((TOTAL_APIS++))
check_documented "CLXRewardedDelegate" "CLXRewardedDelegate"
((TOTAL_APIS++))
check_documented "rewardedDidLoad:" "rewardedDidLoad"
((TOTAL_APIS++))
check_documented "rewardedDidFailToLoad:withError:" "rewardedDidFailToLoad"
((TOTAL_APIS++))
check_documented "rewardedUserDidEarnReward:" "rewardedUserDidEarnReward"

# Check native APIs
echo ""
echo -e "${BLUE}Native APIs:${NC}"
((TOTAL_APIS++))
check_documented "createNativeAdWithPlacement:" "createNativeAd"
((TOTAL_APIS++))
check_documented "CLXNativeDelegate" "CLXNativeDelegate"
((TOTAL_APIS++))
check_documented "nativeAdDidLoad:" "nativeAdDidLoad"

# Check privacy APIs
echo ""
echo -e "${BLUE}Privacy APIs:${NC}"
((TOTAL_APIS++))
check_documented "setCCPAPrivacyString:" "setCCPAPrivacyString"
((TOTAL_APIS++))
check_documented "setIsUserConsent:" "setIsUserConsent"
((TOTAL_APIS++))
check_documented "setIsAgeRestrictedUser:" "setIsAgeRestrictedUser"
((TOTAL_APIS++))
check_documented "setIsDoNotSell:" "setIsDoNotSell"

# Check logging APIs
echo ""
echo -e "${BLUE}Logging APIs:${NC}"
((TOTAL_APIS++))
check_documented "setLoggingEnabled:" "setLoggingEnabled"
((TOTAL_APIS++))
check_documented "setMinLogLevel:" "setMinLogLevel"

# Calculate coverage
COVERAGE_PERCENT=$((DOCUMENTED_APIS * 100 / TOTAL_APIS))

# Summary
echo ""
echo "========================================="
echo ""
echo -e "${BLUE}API Coverage Summary:${NC}"
echo ""
echo -e "  Total APIs checked:    $TOTAL_APIS"
echo -e "  ${GREEN}Documented:${NC}            $DOCUMENTED_APIS"
echo -e "  ${RED}Missing:${NC}               $MISSING_APIS"
echo ""
echo -e "  ${BLUE}Coverage:${NC}              $COVERAGE_PERCENT%"
echo ""

if [ $COVERAGE_PERCENT -ge 80 ]; then
    echo -e "${GREEN}✅ Excellent API coverage${NC}"
elif [ $COVERAGE_PERCENT -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Good API coverage, room for improvement${NC}"
elif [ $COVERAGE_PERCENT -ge 40 ]; then
    echo -e "${YELLOW}⚠️  Moderate API coverage, consider documenting more${NC}"
else
    echo -e "${RED}❌ Low API coverage, many APIs undocumented${NC}"
fi

echo ""
echo "Target: 80% coverage of critical APIs"
echo ""

if [ $MISSING_APIS -gt 0 ]; then
    echo "Missing APIs should be documented in:"
    echo "  - .claude/agents/ios/cloudx-ios-integrator.md"
    echo "  - docs/ios/INTEGRATION_GUIDE.md"
    echo ""
fi

# Exit with coverage-based status
if [ $COVERAGE_PERCENT -ge 60 ]; then
    exit 0
else
    exit 1
fi
