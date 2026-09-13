#!/bin/bash
# install.sh
#
# Installs SD Photo Downloader for the current user:
#   * copies sd-photo-download.sh to ~/.sd-photo-downloader/
#   * creates ~/.sd-photo-downloader/config from config.example on first run
#   * symlinks sd-photo-download into ~/.local/bin/ (if it exists)
#   * detects the installed file managers and wires up a right-click
#     "SD Photo Downloader" action for each one found.
#
# Supported file managers:
#   - GNOME Files (nautilus)   -> ~/.local/share/nautilus/scripts/
#   - Nemo                     -> ~/.local/share/nemo/scripts/
#   - Caja (MATE)              -> ~/.config/caja/scripts/
#   - Dolphin (KDE)            -> ~/.local/share/kio/servicemenus/*.desktop
#   - Thunar (XFCE)            -> ~/.config/Thunar/uca.xml custom action
#
# To build a double-clickable desktop launcher instead, run:
#   ./build-desktop.sh

set -euo pipefail

SRC_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DEST="$HOME/.sd-photo-downloader"
BIN_DIR="$HOME/.local/bin"

SCRIPT_SOURCE="$SRC_DIR/sd-photo-download.sh"
SCRIPT_DEST="$DEST/sd-photo-download.sh"

# ---------------------------------------------------------------------------
# 1. Copy the main script
# ---------------------------------------------------------------------------
mkdir -p "$DEST"
cp -f "$SCRIPT_SOURCE" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"

# ---------------------------------------------------------------------------
# 2. Create the config from the example on first run
# ---------------------------------------------------------------------------
if [ ! -f "$DEST/config" ]; then
  cp "$SRC_DIR/config.example" "$DEST/config"
  echo "Created $DEST/config - edit TARGET_DIR/BACKUP_DIR before your first run."
else
  echo "Keeping existing config: $DEST/config"
fi

# ---------------------------------------------------------------------------
# 3. Convenience symlink on your PATH
# ---------------------------------------------------------------------------
if [ -d "$BIN_DIR" ]; then
  ln -sf "$SCRIPT_DEST" "$BIN_DIR/sd-photo-download"
  echo "Linked $BIN_DIR/sd-photo-download -> $SCRIPT_DEST"
fi

# ---------------------------------------------------------------------------
# File-manager integration
# ---------------------------------------------------------------------------
INSTALLED=0

# Most GNOME-derived file managers run any executable script placed in their
# scripts directory; the selected folders are passed as arguments.
install_script_based() {  # <label> <scripts-dir>
  local label="$1" dir="$2" file
  mkdir -p "$dir"
  file="$dir/SD Photo Downloader"
  cat > "$file" <<EOF
#!/bin/bash
# Right-click a mounted SD card folder -> Scripts -> SD Photo Downloader.
# Any selected folder(s) are treated as the card path(s).
exec "$SCRIPT_DEST" --card "\$@"
EOF
  chmod +x "$file"
  echo "Installed $label script to: $file"
  INSTALLED=1
}

# Dolphin (KDE) uses a .desktop entry in the kio servicemenus directory.
install_dolphin() {
  local dir="$HOME/.local/share/kio/servicemenus" file
  mkdir -p "$dir"
  file="$dir/sd-photo-download.desktop"
  cat > "$file" <<'EOF'
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=SDPhotoDownloader;

[Desktop Action SDPhotoDownloader]
Name=SD Photo Downloader
Icon=media-optical
Exec=bash -c 'exec "$HOME/.sd-photo-downloader/sd-photo-download.sh" --card "$1"' _ %f
EOF
  chmod +x "$file"
  echo "Installed Dolphin service menu to: $file"
  echo "  (menu appears when you right-click a folder, incl. a mounted card)"
  INSTALLED=1
}

# Thunar (XFCE) stores custom actions in uca.xml. Adds the action to the
# existing file if present, otherwise creates a fresh one.
install_thunar() {
  local dir="$HOME/.config/Thunar" file tmp action
  local xml
  mkdir -p "$dir"
  file="$dir/uca.xml"
  if grep -q "SD Photo Downloader" "$file" 2>/dev/null; then
    echo "Thunar uca.xml already contains SD Photo Downloader: $file"
    INSTALLED=1
    return 0
  fi
  action="$(mktemp "${TMPDIR:-/tmp}/sd-thunar-action.XXXXXX")"
  cat > "$action" <<'EOF'
	<action>
		<icon>media-optical</icon>
		<name>SD Photo Downloader</name>
		<command>bash -lc 'exec "$HOME/.sd-photo-downloader/sd-photo-download.sh" --card "$1"' dummy %f</command>
		<description>Import photos and videos from the mounted SD card</description>
		<patterns>*</patterns>
		<directories/>
	</action>
EOF
  if [ -f "$file" ] && grep -q '</actions>' "$file"; then
    tmp="$(mktemp "${TMPDIR:-/tmp}/sd-thunar.XXXXXX")"
    awk -v ins="$action" '
      { if ($0 ~ /<\/actions>/) { while ((getline l < ins) > 0) print l; close(ins) } print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
  else
    cat > "$file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<actions>
$(cat "$action")
</actions>
EOF
  fi
  rm -f "$action"
  echo "Installed Thunar custom action to: $file"
  echo "  (open Thunar -> Edit -> Configure custom actions to double-check)"
  INSTALLED=1
}

detect_and_install() {
  if command -v nautilus >/dev/null 2>&1; then
    install_script_based "Nautilus" "$HOME/.local/share/nautilus/scripts"
    NAUTILUS_FOUND=1
  fi
  if command -v nemo >/dev/null 2>&1; then
    install_script_based "Nemo" "$HOME/.local/share/nemo/scripts"
  fi
  if command -v caja >/dev/null 2>&1; then
    install_script_based "Caja" "$HOME/.config/caja/scripts"
  fi
  if command -v dolphin >/dev/null 2>&1; then
    install_dolphin
  fi
  if command -v thunar >/dev/null 2>&1; then
    install_thunar
  fi
}

NAUTILUS_FOUND=0
detect_and_install

if [ "$INSTALLED" -eq 0 ]; then
  echo
  echo "No supported file manager detected. You can still run the import from a"
  echo "terminal: $SCRIPT_DEST [--card /path/to/card] [--dry-run]"
fi

echo
echo "Next steps:"
if [ "$NAUTILUS_FOUND" -eq 1 ]; then
  echo "  0. If the Files 'Scripts' menu is hidden, enable it with:"
  echo "     gsettings set org.gnome.nautilus.preferences show-scripts-menu true"
fi
echo "  1. Edit $DEST/config (set TARGET_DIR / BACKUP_DIR)"
echo "  2. Right-click the mounted card folder in your file manager ->"
echo "     'SD Photo Downloader'"
echo "  3. Test without writing anything:"
echo "     $SCRIPT_DEST --dry-run"