#!/bin/bash
# Restore an Outlook backup made by backup-outlook.sh.
# Usage: restore-outlook.sh <archive.tar.gz> [--force]
# --force moves existing data aside to *.bak-<epoch> (never deletes it).
# UNTESTED: try on a spare macOS user first. Terminal needs Full Disk Access.
set -euo pipefail

archive=""
force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    *) archive="$arg" ;;
  esac
done

if [ -z "$archive" ] || [ ! -f "$archive" ]; then
  echo "Usage: $0 <archive.tar.gz> [--force]" >&2
  exit 1
fi

running="$(pgrep -fl '/Applications/Microsoft ' || true)"
if [ -n "$running" ]; then
  echo "Microsoft apps are running; quit them first:" >&2
  echo "$running" >&2
  exit 1
fi

# Validate the archive before touching anything.
listing="$(/usr/bin/tar -tzf "$archive")"

members=(
  "Library/Group Containers/UBF8T346G9.Office"
  "Library/Containers/com.microsoft.Outlook"
)
# The preferences plist is optional; only restore it if the archive has it.
if printf '%s\n' "$listing" | grep -qx "Library/Preferences/com.microsoft.Outlook.plist"; then
  members+=("Library/Preferences/com.microsoft.Outlook.plist")
fi

for m in "${members[@]}"; do
  if ! printf '%s\n' "$listing" | grep -q "^$m"; then
    echo "Archive is missing expected member: $m" >&2
    exit 1
  fi
done

for m in "${members[@]}"; do
  t="$HOME/$m"
  if [ -e "$t" ]; then
    if [ "$force" -ne 1 ]; then
      echo "Refusing to overwrite existing: $t (use --force to move it aside)" >&2
      exit 1
    fi
  fi
done

stamp="$(date +%s)"
if [ "$force" -eq 1 ]; then
  for m in "${members[@]}"; do
    t="$HOME/$m"
    if [ -e "$t" ]; then
      mv "$t" "$t.bak-$stamp"
      echo "Moved aside: $t.bak-$stamp"
    fi
  done
fi

/usr/bin/tar -xpzf "$archive" --mac-metadata -C "$HOME" "${members[@]}"
echo "Restored from $archive"
