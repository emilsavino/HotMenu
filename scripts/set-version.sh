#!/bin/bash
set -euo pipefail

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo "Error: version must be a semantic version (for example, 1.2.3 or 1.2.3-beta.1)"
    exit 1
fi

echo "Setting version to $VERSION"

# Update MARKETING_VERSION in project.pbxproj
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/g" HotMenu.xcodeproj/project.pbxproj

# Update CURRENT_PROJECT_VERSION (build number) - use version without dots
BASE_VERSION="${VERSION%%-*}"
BUILD_NUMBER=$(echo "$BASE_VERSION" | tr -d '.')
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" HotMenu.xcodeproj/project.pbxproj

echo "Version set to $VERSION (build $BUILD_NUMBER)"
