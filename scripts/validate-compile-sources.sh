#!/bin/bash
#
# Validates that every .m file in the source directory is included
# in the Xcode project's compile sources. Catches files that were
# added to the filesystem but not to the Xcode project — these
# will be silently omitted from the xcframework binary.
#
# Usage: validate-compile-sources.sh <source_dir> <pbxproj_path>
# Example: validate-compile-sources.sh Sources/CloudXInMobiAdapter CloudXInMobiAdapter.xcodeproj/project.pbxproj

set -euo pipefail

SOURCE_DIR="${1:?Usage: validate-compile-sources.sh <source_dir> <pbxproj_path>}"
PBXPROJ="${2:?Usage: validate-compile-sources.sh <source_dir> <pbxproj_path>}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source directory not found: $SOURCE_DIR"
    exit 1
fi
if [ ! -f "$PBXPROJ" ]; then
    echo "❌ project.pbxproj not found: $PBXPROJ"
    exit 1
fi

MISSING=()
while IFS= read -r mfile; do
    filename=$(basename "$mfile")
    if ! grep -q "$filename" "$PBXPROJ"; then
        MISSING+=("$mfile")
    fi
done < <(find "$SOURCE_DIR" -name "*.m" -type f)

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "❌ COMPILE SOURCES MISMATCH"
    echo "The following .m files exist on disk but are NOT in the Xcode project:"
    echo ""
    for f in "${MISSING[@]}"; do
        echo "  - $f"
    done
    echo ""
    echo "These files will NOT be compiled into the xcframework binary."
    echo "Add them to the Xcode project's compile sources before building."
    exit 1
fi

echo "✅ All .m files in $SOURCE_DIR are in the Xcode project."
