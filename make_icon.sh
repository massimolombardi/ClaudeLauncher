#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/icon.png"
ICONSET="/tmp/AppIcon.iconset"
DEST="$SCRIPT_DIR/Resources/AppIcon.icns"

# Check source exists
if [ ! -f "$SRC" ]; then
    echo "❌ File non trovato: $SRC"
    echo "   Assicurati che icon.png sia nella stessa cartella di questo script."
    exit 1
fi

# Check it's big enough
W=$(sips -g pixelWidth "$SRC" | awk '/pixelWidth/{print $2}')
if [ "$W" -lt 512 ]; then
    echo "⚠️  Attenzione: l'immagine è ${W}px. Consigliato almeno 1024×1024."
fi

echo "🎨 Generazione iconset da icon.png (${W}px)..."

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

sips -z 16   16   "$SRC" --out "$ICONSET/icon_16x16.png"       > /dev/null
sips -z 32   32   "$SRC" --out "$ICONSET/icon_16x16@2x.png"    > /dev/null
sips -z 32   32   "$SRC" --out "$ICONSET/icon_32x32.png"       > /dev/null
sips -z 64   64   "$SRC" --out "$ICONSET/icon_32x32@2x.png"    > /dev/null
sips -z 128  128  "$SRC" --out "$ICONSET/icon_128x128.png"     > /dev/null
sips -z 256  256  "$SRC" --out "$ICONSET/icon_128x128@2x.png"  > /dev/null
sips -z 256  256  "$SRC" --out "$ICONSET/icon_256x256.png"     > /dev/null
sips -z 512  512  "$SRC" --out "$ICONSET/icon_256x256@2x.png"  > /dev/null
sips -z 512  512  "$SRC" --out "$ICONSET/icon_512x512.png"     > /dev/null
sips -z 1024 1024 "$SRC" --out "$ICONSET/icon_512x512@2x.png"  > /dev/null

mkdir -p "$SCRIPT_DIR/Resources"
iconutil -c icns "$ICONSET" -o "$DEST"
rm -rf "$ICONSET"

echo "✅ Icona salvata in: Resources/AppIcon.icns"
echo ""
echo "Ora rilancia ./install.sh per ricreare il bundle con l'icona."
