#!/bin/bash

# ============================================================================
# CloudX iOS SDK Version Generator
# ============================================================================
#
# OVERVIEW:
#   Generates semantic versions with build metadata for complete traceability.
#   Matches Android SDK versioning format exactly.
#
# VERSION FORMATS:
#   Develop (CI):     1.1.58-dev.156+fe5b6f8   (Every push to develop)
#   RC (CI):          1.1.58-rc.2+a1b2c3d      (Every push to release/*)
#   Stable:           1.1.58                   (Manual releases only)
#   Local:            1.1.58-local+abc1234     (Developer machines)
#   Custom:           1.1.58-john-test+def5678 (Manual custom builds)
#
# VERSION PARTS:
#   1.1.58           = Base semantic version (MAJOR.MINOR.PATCH)
#   dev/rc/local     = Build type (where it was built)
#   156              = GitHub Actions run number (CI only, auto-increments)
#   fe5b6f8          = Git commit SHA (7 chars, links to exact code)
#
# USAGE:
#   ./generate-version.sh <base_version> [build_type] [build_number]
#
# EXAMPLES:
#   ./generate-version.sh 1.1.58               → 1.1.58-local+abc1234
#   ./generate-version.sh 1.1.58 dev 156       → 1.1.58-dev.156+abc1234
#   ./generate-version.sh 1.1.58 rc 2          → 1.1.58-rc.2+abc1234
#   ./generate-version.sh 1.1.58 stable        → 1.1.58
#   ./generate-version.sh 1.1.58 john-bugfix   → 1.1.58-john-bugfix+abc1234
#
# AUTOMATED USAGE:
#   - GitHub Actions (develop):  auto-generates dev.BUILD+SHA on every push
#   - GitHub Actions (release):  auto-generates rc.BUILD+SHA on every push
#   - Release scripts:           generates stable version (no metadata)
#
# WHY BUILD METADATA?
#   - Full traceability: Know exact source code for every build
#   - Debug support: Quickly identify version-specific issues
#   - Analytics: Track SDK version distribution in production
#   - Consistency: Matches Android SDK versioning format
#
# OUTPUT:
#   Prints full version string to stdout (can be captured: VERSION=$(./generate-version.sh ...))
#
# ============================================================================

set -e

BASE_VERSION=$1
BUILD_TYPE=${2:-local}
BUILD_NUMBER=$3

# Validate base version format (X.Y.Z)
if ! [[ $BASE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid base version format. Expected X.Y.Z (e.g., 1.1.58)" >&2
    exit 1
fi

# Get Git commit SHA (7 characters)
GIT_SHA=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")

# Generate full version based on build type
case $BUILD_TYPE in
    dev)
        if [ -z "$BUILD_NUMBER" ]; then
            echo "Error: BUILD_NUMBER required for dev builds" >&2
            exit 1
        fi
        FULL_VERSION="${BASE_VERSION}-dev.${BUILD_NUMBER}+${GIT_SHA}"
        ;;
    rc)
        if [ -z "$BUILD_NUMBER" ]; then
            echo "Error: BUILD_NUMBER required for rc builds" >&2
            exit 1
        fi
        FULL_VERSION="${BASE_VERSION}-rc.${BUILD_NUMBER}+${GIT_SHA}"
        ;;
    stable)
        FULL_VERSION="${BASE_VERSION}"
        ;;
    local)
        FULL_VERSION="${BASE_VERSION}-local+${GIT_SHA}"
        ;;
    *)
        # Custom build type (e.g., "john-bugfix")
        FULL_VERSION="${BASE_VERSION}-${BUILD_TYPE}+${GIT_SHA}"
        ;;
esac

echo "$FULL_VERSION"

