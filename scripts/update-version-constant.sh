#!/bin/bash

# ============================================================================
# CloudX iOS SDK Version Constant Updater
# ============================================================================
#
# OVERVIEW:
#   Updates version constants in .m files with generated version strings.
#   Used by release scripts and GitHub Actions to keep versions synchronized.
#
# VERSION CONSTANTS:
#   Core SDK:        core/Sources/CloudXCore/CLXVersion.m (CLXSDKVersion)
#   Meta Adapter:    adapter-meta/.../CLXMetaAdapterVersion.m (CLXMetaAdapterVersion)
#   Prebid Adapter:  adapter-cloudx/.../CLXPrebidAdapterVersion.m (CLXPrebidAdapterVersion)
#
# USAGE:
#   ./update-version-constant.sh <component> <full_version>
#
# COMPONENTS:
#   core    = CloudXCore SDK
#   meta    = CloudXMetaAdapter
#   prebid  = CloudXPrebidAdapter
#
# EXAMPLES:
#   ./update-version-constant.sh core "1.1.58-dev.156+abc1234"
#   ./update-version-constant.sh meta "1.1.66-local+def5678"
#   ./update-version-constant.sh prebid "1.1.58-rc.2+abc1234"
#
# AUTOMATED USAGE:
#   - Called by GitHub Actions workflows on every push (develop/release)
#   - Called by manual release scripts (./release-core.sh, etc.)
#   - Can be used manually for testing
#
# VERSION IN BID REQUESTS:
#   After updating, the version appears in all bid requests:
#   {
#     "ext": {
#       "cloudx": {
#         "sdkReleaseVersion": "1.1.58-dev.156+abc1234"  ← Updated here
#       }
#     }
#   }
#
# ============================================================================

set -e

COMPONENT=$1
FULL_VERSION=$2

if [ -z "$COMPONENT" ] || [ -z "$FULL_VERSION" ]; then
    echo "Usage: $0 <component> <full_version>"
    echo "Components: core, meta, prebid"
    exit 1
fi

# Determine version file path based on component
case $COMPONENT in
    core)
        VERSION_FILE="core/Sources/CloudXCore/CLXVersion.m"
        CONSTANT_NAME="CLXSDKVersion"
        ;;
    meta)
        VERSION_FILE="adapter-meta/Sources/CloudXMetaAdapter/CLXMetaAdapterVersion.m"
        CONSTANT_NAME="CLXMetaAdapterVersion"
        ;;
    prebid)
        VERSION_FILE="adapter-cloudx/Sources/CloudXPrebidAdapter/CLXPrebidAdapterVersion.m"
        CONSTANT_NAME="CLXPrebidAdapterVersion"
        ;;
    *)
        echo "Error: Unknown component '$COMPONENT'" >&2
        echo "Valid components: core, meta, prebid" >&2
        exit 1
        ;;
esac

# Check if file exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: Version file not found: $VERSION_FILE" >&2
    exit 1
fi

# Update the version constant
sed -i '' "s/${CONSTANT_NAME} = @\".*\";/${CONSTANT_NAME} = @\"${FULL_VERSION}\";/" "$VERSION_FILE"

echo "✅ Updated $COMPONENT version to: $FULL_VERSION"
echo "   File: $VERSION_FILE"

