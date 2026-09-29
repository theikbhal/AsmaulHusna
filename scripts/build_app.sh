#!/bin/bash
# Build AsmaulHusna.app, install to /Applications, add a Desktop shortcut.
#
# Usage:
#   scripts/build_app.sh              # build + install + desktop shortcut
#   scripts/build_app.sh --build-only # build into build/ only
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="1.0.0"
APP_NAME="AsmaulHusna"
BUNDLE_ID="com.ikbhal.asmaulhusna"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
BUILD_ONLY=0
[ "${1:-}" = "--build-only" ] && BUILD_ONLY=1

echo "==> swift build -c release"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

if [ ! -f "Resources/AppIcon.png" ]; then
  echo "==> Generating app icon"
  swift scripts/make_icon.swift Resources/AppIcon.png
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"
printf 'APPL????' > "$APP/Contents/PkgInfo"

ICONSET="$BUILD_DIR/icon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "Resources/AppIcon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  s2=$((s * 2))
  sips -z $s2 $s2 "Resources/AppIcon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>Asmaul Husna</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>LSUIElement</key><false/>
    <key>NSHumanReadableCopyright</key><string>© 2026 Ikbhal · MIT License</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" 2>/dev/null || echo "    (codesign skipped)"

if [ "$BUILD_ONLY" = "1" ]; then
  echo "Done (build only): $APP"
  echo "Run it:  open $APP"
  exit 0
fi

echo "==> Install to /Applications"
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP" "/Applications/"

echo "==> Desktop shortcut"
ln -sfn "/Applications/$APP_NAME.app" "$HOME/Desktop/$APP_NAME"

echo "Done: /Applications/$APP_NAME.app  +  ~/Desktop/$APP_NAME"
echo "Launch: open /Applications/$APP_NAME.app"
