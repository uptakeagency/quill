#!/bin/bash
set -euo pipefail

# Build Quill.app bundle from Swift Package Manager output
# Usage: ./scripts/build-app.sh [release|debug]

CONFIG="${1:-release}"
APP_NAME="Quill"
BUNDLE_ID="com.c3nx.quill"
BUILD_DIR=".build/${CONFIG}"
APP_DIR="dist/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"

echo "Building Quill (${CONFIG})..."

# Build
if [ "$CONFIG" = "release" ]; then
    swift build -c release
    BINARY="${BUILD_DIR}/${APP_NAME}"
else
    swift build
    BINARY=".build/debug/${APP_NAME}"
fi

# Clean previous bundle
rm -rf "${APP_DIR}"

# Create .app bundle structure
mkdir -p "${CONTENTS}/MacOS"
mkdir -p "${CONTENTS}/Resources"

# Copy binary
cp "${BINARY}" "${CONTENTS}/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Quill/Info.plist" "${CONTENTS}/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "${CONTENTS}/PkgInfo"

# Sign with stable identity (preserves TCC permissions across rebuilds)
SIGN_IDENTITY="Quill Development"
if security find-identity -v -p codesigning | grep -q "${SIGN_IDENTITY}"; then
    codesign --force --deep --sign "${SIGN_IDENTITY}" "${APP_DIR}"
else
    echo "Warning: '${SIGN_IDENTITY}' certificate not found, falling back to ad-hoc signing"
    echo "  TCC permissions (Accessibility, Screen Recording) will reset on each rebuild."
    echo "  Run: scripts/setup-cert.sh to create a development certificate."
    codesign --force --deep --sign - "${APP_DIR}"
fi

echo ""
echo "Build complete: ${APP_DIR}"
echo "To run: open ${APP_DIR}"
