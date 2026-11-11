#!/bin/bash
# Back up Outlook data to a timestamped tar.gz. Usage: backup-outlook.sh [dest_dir]
set -euo pipefail

dest="${1:-$HOME/Backups}"

if pgrep -x "Microsoft Outlook" >/dev/null; then
  echo "Microsoft Outlook is running. Quit it first." >&2
  exit 1
fi

mkdir -p "$dest"
archive="$dest/outlook-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Paths are relative to $HOME so the archive restores cleanly.
tar -czf "$archive" -C "$HOME" \
  "Library/Group Containers/UBF8T346G9.Office" \
  "Library/Containers/com.microsoft.Outlook"

echo "Wrote $archive"
