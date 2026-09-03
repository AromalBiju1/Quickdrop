#!/usr/bin/env bash
set -e

APP_DIR="/home/elyssia/Desktop/QuickDrop/build/linux/x64/release/bundle"
DESKTOP_FILE="$HOME/.local/share/applications/quickdrop.desktop"

mkdir -p "$HOME/.local/share/applications"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=QuickDrop
Comment=Zero-friction phone to laptop screenshot receiver
Exec=$APP_DIR/quickdrop
Terminal=false
Type=Application
Categories=Utility;Network;
Icon=camera-photo
StartupWMClass=quickdrop
EOF

chmod +x "$DESKTOP_FILE"
echo "✓ QuickDrop launcher created at $DESKTOP_FILE"
