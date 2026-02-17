#!/bin/bash
set -euo pipefail

# Create a DMG for distribution
# Requires: build-app.sh to have been run first

APP_NAME="Quill"
VERSION=$(grep CFBundleShortVersionString Quill/Info.plist -A1 | grep string | sed 's/.*<string>//;s/<\/string>//')
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_DIR="dist/dmg-staging"

echo "Creating DMG: ${DMG_NAME}"

# Ensure .app exists
if [ ! -d "dist/${APP_NAME}.app" ]; then
    echo "Error: dist/${APP_NAME}.app not found. Run build-app.sh first."
    exit 1
fi

# Clean staging
rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"

# Copy app
cp -R "dist/${APP_NAME}.app" "${DMG_DIR}/"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "dist/${DMG_NAME}"

# Cleanup
rm -rf "${DMG_DIR}"

echo ""
echo "DMG created: dist/${DMG_NAME}"
