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
#   Renderer:        renderer-cloudx/.../CLXRendererVersion.m (CLXRendererVersion)
#
# USAGE:
#   ./update-version-constant.sh <component> <full_version>
#
# COMPONENTS:
#   core      = CloudXCore SDK
#   meta      = CloudXMetaAdapter
#   renderer  = CloudXRenderer
#   vungle    = CloudXVungleAdapter
#   inmobi    = CloudXInMobiAdapter
#   mintegral = CloudXMintegralAdapter
#   moloco    = CloudXMolocoAdapter
#   unity     = CloudXUnityAdapter
#
# EXAMPLES:
#   ./update-version-constant.sh core "X.Y.Z-dev.156+abc1234"
#   ./update-version-constant.sh meta "X.Y.Z-local+def5678"
#   ./update-version-constant.sh renderer "X.Y.Z-rc.1+abc1234"
#   ./update-version-constant.sh vungle "X.Y.Z-rc.1+abc1234"
#   ./update-version-constant.sh inmobi "X.Y.Z-rc.1+abc1234"
#   ./update-version-constant.sh mintegral "X.Y.Z-rc.1+abc1234"
#   ./update-version-constant.sh moloco "X.Y.Z-rc.1+abc1234"
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
#         "sdkReleaseVersion": "X.Y.Z-dev.156+abc1234"  ← Updated here
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
    echo "Components: core, meta, renderer, vungle, inmobi, mintegral, moloco, unity"
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
    renderer)
        VERSION_FILE="renderer-cloudx/Sources/CloudXRenderer/CLXRendererVersion.m"
        CONSTANT_NAME="CLXRendererVersion"
        ;;
    vungle)
        VERSION_FILE="adapter-vungle/Sources/CloudXVungleAdapter/CLXVungleAdapterVersion.m"
        CONSTANT_NAME="CLXVungleAdapterVersion"
        ;;
    inmobi)
        VERSION_FILE="adapter-inmobi/Sources/CloudXInMobiAdapter/CLXInMobiAdapterVersion.m"
        CONSTANT_NAME="CLXInMobiAdapterVersion"
        ;;
    mintegral)
        VERSION_FILE="adapter-mintegral/Sources/CloudXMintegralAdapter/CLXMintegralAdapterVersion.m"
        CONSTANT_NAME="CLXMintegralAdapterVersion"
        ;;
    moloco)
        VERSION_FILE="adapter-moloco/Sources/CloudXMolocoAdapter/CLXMolocoAdapterVersion.m"
        CONSTANT_NAME="CLXMolocoAdapterVersion"
        ;;
    unity)
        VERSION_FILE="adapter-unity/Sources/CloudXUnityAdapter/CLXUnityAdapterVersion.m"
        CONSTANT_NAME="CLXUnityAdapterVersion"
        ;;
    *)
        echo "Error: Unknown component '$COMPONENT'" >&2
        echo "Valid components: core, meta, renderer, vungle, inmobi, mintegral, moloco, unity" >&2
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

