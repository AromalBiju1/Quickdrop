#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
ICON_SRC="$PROJECT_DIR/assets/images/quickdrop_icon.png"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
DESKTOP_FILE="$HOME/.local/share/applications/quickdrop.desktop"

mkdir -p "$(dirname "$DESKTOP_FILE")" "$ICON_DIR"

if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$ICON_DIR/quickdrop.png"
fi

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=QuickDrop
Comment=Local file transfer for phone and laptop
Exec=$APP_DIR/quickdrop
Terminal=false
Type=Application
Categories=Utility;Network;
Icon=quickdrop
StartupWMClass=com.elyssia.quickdrop.quickdrop
EOF

chmod +x "$DESKTOP_FILE"
echo "✓ QuickDrop launcher created at $DESKTOP_FILE"
