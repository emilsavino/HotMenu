#!/bin/bash
set -euo pipefail

VERSION="${1:-}"
SIGNING_IDENTITY="${HOTMENU_SIGNING_IDENTITY:--}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Building HotMenu v$VERSION"

# Build first, then sign the complete bundle after Sparkle has been embedded.
# The default ad-hoc identity is enough for Sparkle validation. Set
# HOTMENU_SIGNING_IDENTITY to a Developer ID Application identity for releases
# that also need to pass Gatekeeper and notarization.
xcodebuild -project HotMenu.xcodeproj \
    -scheme HotMenu \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

# Create release directory
mkdir -p release

APP_PATH="build/Build/Products/Release/HotMenu.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Signing app bundle with identity: $SIGNING_IDENTITY"
if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --deep --force --sign - "$APP_PATH"
else
    codesign --deep --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_PATH"
fi
codesign --verify --deep --strict "$APP_PATH"

# Create ZIP
echo "Creating ZIP archive..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "release/HotMenu-${VERSION}.zip"

# Create DMG using create-dmg
echo "Creating DMG..."
create-dmg \
    --volname "HotMenu" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "HotMenu.app" 150 190 \
    --hide-extension "HotMenu.app" \
    --app-drop-link 450 185 \
    "release/HotMenu-${VERSION}.dmg" \
    "$APP_PATH"

echo "Release artifacts created:"
ls -la release/

echo "Done!"
