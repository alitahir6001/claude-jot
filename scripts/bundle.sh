#!/bin/bash
# Build release, wrap the binary in Jot.app, ad-hoc sign, install app + CLI.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=dist/Jot.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Jot "$APP/Contents/MacOS/Jot"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Jot</string>
  <key>CFBundleIdentifier</key><string>local.jot.app</string>
  <key>CFBundleName</key><string>Jot</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"

mkdir -p "$HOME/Applications" "$HOME/.local/bin"
rm -rf "$HOME/Applications/Jot.app"
cp -R "$APP" "$HOME/Applications/"
install -m 755 .build/release/jot-cli "$HOME/.local/bin/jot-cli"
echo "Installed ~/Applications/Jot.app and ~/.local/bin/jot-cli"

# Übersicht ignores symlinked widgets, so copy.
WIDGETS="$HOME/Library/Application Support/Übersicht/widgets"
if [ -d "$WIDGETS" ]; then
  rm -rf "$WIDGETS/jot.widget"
  cp -R widget/jot.widget "$WIDGETS/"
  echo "Installed Übersicht widget"
fi
