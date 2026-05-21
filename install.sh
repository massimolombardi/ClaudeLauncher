#!/bin/bash
set -e

APP_NAME="ClaudeLauncher"
APP_VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Check Xcode CLI tools
if ! command -v swift &> /dev/null; then
    echo "❌ Swift non trovato. Installa Xcode Command Line Tools:"
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
    echo "✅ Binario già presente, skip build. (Cancella .build/ per ricompilare)"
fi

echo ""
echo "📦 Creazione app bundle..."

# Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon if present
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "🎨 Icona copiata"
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
    <string>Claude Launcher usa Apple Events per aprire il terminale con le impostazioni scelte.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Remove quarantine
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo "✅ Bundle creato: $APP_BUNDLE"
echo ""

# Choose install location
SYS_APPS="/Applications"
USER_APPS="$HOME/Applications"

echo "Dove vuoi installare?"
echo "  1) $SYS_APPS  (richiede password admin)"
echo "  2) $USER_APPS  (nessuna password)"
echo "  3) Lascia in $(pwd)/$APP_BUNDLE"
read -p "Scelta [1/2/3]: " choice

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
echo "✅ App pronta: $FINAL"
echo ""
read -p "Aprire ora? [S/n] " open_answer
open_answer=${open_answer:-S}
if [[ "$open_answer" =~ ^[Ss]$ ]]; then
    open "$FINAL"
fi

echo ""
echo "🎉 Fatto!"
