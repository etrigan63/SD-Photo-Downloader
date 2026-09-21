#!/usr/bin/env bash
# build-desktop.sh [DEST_DIR]
#
# Builds a double-clickable "SD Photo Downloader" desktop launcher, the Linux
# analogue of the original macOS build-app.sh. It runs the import script in a
# terminal so you can watch the progress; notifications still appear via
# notify-send (see NOTIFY in the config).
#
# The import script must be installed first:
#   ./install.sh
#
# DEST_DIR defaults to ~/.local/share/applications (user applications).

set -euo pipefail

SRC_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SCRIPT="$HOME/.local/bin/sd-photo-download"
DEST_DIR="${1:-$HOME/.local/share/applications}"

[ -x "$SCRIPT" ] || {
  echo "error: $SCRIPT not found. Run ./install.sh first." >&2
  exit 1
}

mkdir -p "$DEST_DIR"

cat > "$DEST_DIR/sd-photo-download.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=SD Photo Downloader
Comment=Import photos and videos from a mounted SD card
Exec=bash -lc '${SCRIPT}; exec bash'
Icon=camera-photo
Terminal=true
Categories=Graphics;AudioVideo;
StartupNotify=true
EOF

chmod +x "$DEST_DIR/sd-photo-download.desktop"

echo "Built $DEST_DIR/sd-photo-download.desktop"
echo "Look for 'SD Photo Downloader' in your application launcher,"
echo "or use it as the target of a Stream Deck / custom launcher action."