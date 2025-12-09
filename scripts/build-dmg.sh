#!/bin/bash
set -e

# Configuration
APP_NAME="QuickTodo"
BUILD_DIR="build"
DMG_DIR="$BUILD_DIR/dmg"

echo "Building $APP_NAME DMG..."

# Clean previous build
rm -rf "$BUILD_DIR"

# Build Release
echo "→ Building Release..."
xcodebuild -scheme "$APP_NAME" -configuration Release build CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" 2>&1 | tail -5

# Check if app was built
if [ ! -d "$BUILD_DIR/Release/$APP_NAME.app" ]; then
    echo "✗ Build failed - $APP_NAME.app not found"
    exit 1
fi

# Create DMG contents
echo "→ Creating DMG contents..."
mkdir -p "$DMG_DIR"
cp -R "$BUILD_DIR/Release/$APP_NAME.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "→ Creating DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$BUILD_DIR/$APP_NAME.dmg"

# Cleanup intermediate files
rm -rf "$DMG_DIR"

echo ""
echo "✓ Created $BUILD_DIR/$APP_NAME.dmg"
echo "  Size: $(du -h "$BUILD_DIR/$APP_NAME.dmg" | cut -f1)"
