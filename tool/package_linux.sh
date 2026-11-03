#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-$(awk '/^version:/ { print $2 }' "$ROOT/pubspec.yaml" | cut -d+ -f1)}"
BUNDLE="$ROOT/build/linux/x64/release/bundle"

if [[ -z "$VERSION" ]]; then
  echo "Could not determine the version from pubspec.yaml." >&2
  exit 1
fi
if [[ ! -x "$BUNDLE/quickdrop" ]]; then
  echo "Linux release bundle not found. Run: flutter build linux --release" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
PACKAGE_NAME="QuickDrop-${VERSION}-linux-x64"
PACKAGE_DIR="$STAGE/$PACKAGE_NAME"

mkdir -p "$PACKAGE_DIR"
cp -a "$BUNDLE/." "$PACKAGE_DIR/"
cp "$ROOT/packaging/linux/install.sh" "$PACKAGE_DIR/install.sh"
cp "$ROOT/packaging/linux/README.txt" "$PACKAGE_DIR/README.txt"
chmod +x "$PACKAGE_DIR/quickdrop" "$PACKAGE_DIR/install.sh"

mkdir -p "$ROOT/release"
ARTIFACT="$ROOT/release/${PACKAGE_NAME}.tar.gz"
rm -f "$ARTIFACT" "$ARTIFACT.sha256"
tar -czf "$ARTIFACT" -C "$STAGE" "$PACKAGE_NAME"
(
  cd "$ROOT/release"
  sha256sum "$(basename "$ARTIFACT")" > "$(basename "$ARTIFACT").sha256"
)

echo "Created $ARTIFACT"
cat "$ARTIFACT.sha256"
