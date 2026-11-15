#!/bin/bash
# Back up Outlook data to a timestamped tar.gz. Usage: backup-outlook.sh [dest_dir]
# The terminal needs Full Disk Access (System Settings > Privacy & Security) to read
# these containers; otherwise tar fails with "Operation not permitted".
set -euo pipefail

dest="${1:-$HOME/Backups}"

running="$(pgrep -fl '/Applications/Microsoft ' || true)"
if [ -n "$running" ]; then
  echo "Microsoft apps are running; quit them first:" >&2
  echo "$running" >&2
  exit 1
fi

mkdir -p "$dest"
archive="$dest/outlook-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tmp="$archive.partial"
trap 'rm -f "$tmp"' EXIT

# Paths are relative to $HOME. The preferences plist is optional.
members=(
  "Library/Group Containers/UBF8T346G9.Office"
  "Library/Containers/com.microsoft.Outlook"
)
if [ -e "$HOME/Library/Preferences/com.microsoft.Outlook.plist" ]; then
  members+=("Library/Preferences/com.microsoft.Outlook.plist")
fi

# --mac-metadata keeps xattrs/ACLs (default when creating; explicit here, and used on restore).
/usr/bin/tar -czpf "$tmp" --mac-metadata -C "$HOME" "${members[@]}"
/usr/bin/tar -tzf "$tmp" >/dev/null
mv "$tmp" "$archive"
trap - EXIT

echo "Wrote $archive"
echo "Note: keychain tokens/passwords are NOT included; expect to re-authenticate accounts."
