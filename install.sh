#!/bin/bash
set -e

APP_NAME="ClaudeLauncher"
APP_VERSION="1.1.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Check Xcode CLI tools
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Skip build if binary already fresh
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo ""
    echo "🔨 Building $APP_NAME..."
    echo ""
    swift build -c release 2>&1
else
    echo "✅ Binary already present, skipping build. (Delete .build/ to rebuild)"
fi

echo ""
echo "📦 Creating app bundle..."

# Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon if present
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "🎨 Icon copied"
fi

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.claudelauncher</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Launcher</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Claude Launcher uses Apple Events to open the terminal with the selected settings.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Remove quarantine
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo "✅ Bundle created: $APP_BUNDLE"
echo ""

# Choose install location
SYS_APPS="/Applications"
USER_APPS="$HOME/Applications"

echo "Where do you want to install it?"
echo "  1) $SYS_APPS  (requires admin password)"
echo "  2) $USER_APPS  (no password required)"
echo "  3) Keep it in $(pwd)/$APP_BUNDLE"
read -p "Choice [1/2/3]: " choice

case "$choice" in
    1)
        cp -r "$APP_BUNDLE" "$SYS_APPS/"
        FINAL="$SYS_APPS/$APP_NAME.app"
        ;;
    2)
        mkdir -p "$USER_APPS"
        rm -rf "$USER_APPS/$APP_NAME.app"
        cp -r "$APP_BUNDLE" "$USER_APPS/"
        FINAL="$USER_APPS/$APP_NAME.app"
        ;;
    *)
        FINAL="$(pwd)/$APP_BUNDLE"
        ;;
esac

echo ""
echo "✅ App ready: $FINAL"
echo ""
read -p "Open now? [Y/n] " open_answer
open_answer=${open_answer:-Y}
if [[ "$open_answer" =~ ^[Yy]$ ]]; then
    open "$FINAL"
fi

echo ""
echo "🎉 Done!"
