#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$HOME/.local/opt/quickdrop"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
DESKTOP_DIR="$HOME/.local/share/applications"

mkdir -p "$APP_DIR" "$ICON_DIR" "$DESKTOP_DIR"

if [ "$SRC_DIR" != "$APP_DIR" ]; then
  cp -a "$SRC_DIR/." "$APP_DIR/"
fi
chmod +x "$APP_DIR/quickdrop" "$APP_DIR/install.sh"

cp "$SRC_DIR/data/flutter_assets/assets/images/quickdrop_icon.png" \
  "$ICON_DIR/quickdrop.png"

cat > "$DESKTOP_DIR/quickdrop.desktop" <<DESKTOP
[Desktop Entry]
Name=QuickDrop
Comment=Local file transfer for phone and computer
Exec=$APP_DIR/quickdrop
Terminal=false
Type=Application
Categories=Utility;Network;
Icon=quickdrop
StartupWMClass=com.elyssia.quickdrop.quickdrop
DESKTOP
chmod +x "$DESKTOP_DIR/quickdrop.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

echo "QuickDrop installed to $APP_DIR"
echo "Launch it from your application menu or run: $APP_DIR/quickdrop"
