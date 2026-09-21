# SD Photo Downloader

Downloads photos and videos from a mounted SD card into your photo library,
organized by EXIF date and renamed by camera model.

This is a Linux port of [mac-photo-downloader](https://github.com/etrigan63/mac-photo-downloader).
All features are preserved; the macOS-specific parts (Automator workflow,
`osascript`, `diskutil`, `/Volumes`) were replaced with Linux equivalents
(`notify-send`, `udisksctl`/`umount`, `/media | /run/media | /mnt`).

* **Photo folder** — photos copied to `TARGET_DIR/{YYYY}/{YYYY-MM-DD}` and
  renamed to `{Camera Model}-{YYYYMMDD}-{image number}.ext`
  (e.g. `Canon-EOS-R5-20260829-0001.JPG`).
* **Video folder** — videos copied to `VIDEO_DIR/{YYYY}/{YYYY-MM-DD}` with
  the same rename scheme.
* **Backup folders** — `BACKUP_DIR` / `VIDEO_BACKUP_DIR` receive a second
  copy of each photo / video under the same date subfolder structure, using
  the same renamed filenames as the primary folders.
* The image number is taken from the camera file name (the digits just before
  the extension, e.g. `_DSF5099.RAF` → `5099`), so a RAW + HEIF pair keeps the
  same number across both cards. Files without trailing digits in their name
  fall back to a sequential counter tracked per camera model.
* Runs from a file-manager right-click script (Files → Scripts → **SD Photo
  Downloader**). Re-running is safe: files still in the library are skipped,
  while files you deleted from the library are re-imported on the next run.
  The card is unmounted automatically when a run finishes successfully
  (`--no-eject` to keep it mounted).

## Requirements

* Linux with **exiftool** installed, e.g. on Arch:
  `sudo pacman -S perl-image-exiftool`. `notify-send`, `udisksctl`, `md5sum`,
  and `stat` (GNU coreutils) are typically already present.

## Install

```sh
./install.sh
```

This copies the script to `~/.sd-photo-downloader/`, creates a config from
`config.example` (edit it first!), and symlinks `sd-photo-download` into
`~/.local/bin/` if present. It then detects your installed file managers and
wires up a right-click **SD Photo Downloader** action for each one:

| File manager | Integration |
|---|---|
| GNOME Files (nautilus) | `~/.local/share/nautilus/scripts/` (Scripts menu) |
| Nemo | `~/.local/share/nemo/scripts/` (Scripts menu) |
| Caja (MATE) | `~/.config/caja/scripts/` (Scripts menu) |
| Dolphin (KDE) | kio service menu (`~/.local/share/kio/servicemenus/`) |
| Thunar (XFCE) | custom action in `~/.config/Thunar/uca.xml` |

For GNOME Files, enable the Scripts menu if it is hidden:

```sh
gsettings set org.gnome.nautilus.preferences show-scripts-menu true
```

Then right-click your mounted SD card folder in **Files** → *Scripts* → *SD
Photo Downloader*.

## Configuration

Edit `~/.sd-photo-downloader/config` (the format is `KEY=VALUE`, see
`config.example` for every option):

| Key | Purpose |
|-----|---------|
| `TARGET_DIR` | Where **photos** go (subfolders auto-created) |
| `VIDEO_DIR` | Where **videos** go (defaults to `TARGET_DIR` if blank) |
| `BACKUP_DIR` | Optional second copy of **photos** (leave blank to disable) |
| `VIDEO_BACKUP_DIR` | Optional second copy of **videos** (leave blank to disable) |
| `EXIFTOOL` | Path to exiftool (auto-detected if blank) |
| `FOLDER_PATTERN` | Subfolder layout, e.g. `%Y/%Y-%m-%d` or `{YYYY}/{YYYY-MM-DD}` |
| `COUNTER_DIGITS` | Zero-padding for the image number (default 4) |
| `NUMBER_SOURCE` | `exif` (digits before extension in the filename, default) or `counter` (sequential) |
| `COUNTER_PER_MODEL` | Separate number sequence per camera model (yes/no) |
| `PHOTO_EXTS` / `VIDEO_EXTS` | File extensions to import |
| `SD_CARD` | `auto`, or a fixed mount point like `/run/media/guru/CANON` |
| `EJECT_CARD` | Unmount the card when done (`yes`/`no`, override with `--no-eject`) |
| `NOTIFY` | Desktop notifications via notify-send: started, result, errors (`yes`/`no`) |

Files with no usable EXIF date use the file's modification date; files with no
camera model get `UNKNOWN`.

## Usage

```sh
sd-photo-download.sh                                   # auto-detect the card
sd-photo-download.sh --card /run/media/guru/CANON      # explicit mount point
sd-photo-download.sh --dry-run                         # preview, write nothing, don't eject
sd-photo-download.sh --config /path/to/config
sd-photo-download.sh --no-eject                        # import but keep the card mounted
```

Progress is logged to `~/.sd-photo-downloader/run.log`.

## Desktop launcher (alternative to the command line)

To get a double-clickable launcher entry (the Linux analogue of the original
macOS `build-app.sh`):

```sh
./build-desktop.sh
```

This writes `~/.local/share/applications/sd-photo-download.desktop`. You can
launch it from your app launcher, or point a Stream Deck / custom launcher
button at the terminal command. Status banners appear via notify-send (see
`NOTIFY` above), so you get feedback without watching a terminal.

## Stream Deck

The most reliable way to trigger the import from a Stream Deck button is a
terminal command, e.g. a button running:

```sh
bash /home/guru/.sd-photo-downloader/sd-photo-download.sh
```

The script reports its own status via notify-send, so you get feedback
without a visible terminal (as long as a notification daemon is running).

Notes:

* Allow notifications for your compositor's desktop entries so the status
  banners are visible.
* If you use a third-party "Run Shell Script" Stream Deck plugin, use the
  absolute path with an explicit `bash` as above so `$HOME` and environment
  variables are expanded correctly.