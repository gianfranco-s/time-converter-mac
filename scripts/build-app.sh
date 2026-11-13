#!/bin/sh
# Builds a double-clickable ZoneGrid.app (menu bar only) into ./build/
set -e
cd "$(dirname "$0")/.."
# Version comes from the latest git tag (e.g. v1.1.0 -> 1.1.0). Tag a release with: git tag -a vX.Y.Z
VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
VERSION="${VERSION:-0.0.0}"
APP="build/ZoneGrid.app"

swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ZoneGrid "$APP/Contents/MacOS/ZoneGrid"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>ZoneGrid</string>
    <key>CFBundleDisplayName</key><string>ZoneGrid</string>
    <key>CFBundleIdentifier</key><string>com.codesmiths.zonegrid</string>
    <key>CFBundleExecutable</key><string>ZoneGrid</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will launch it locally.
codesign --force --sign - "$APP"
echo "Built $APP"
