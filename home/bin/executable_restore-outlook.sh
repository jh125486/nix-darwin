#!/bin/bash
# Restore an Outlook backup made by backup-outlook.sh.
# Usage: restore-outlook.sh <archive.tar.gz> [--force]
# UNTESTED: try on a spare macOS user first.
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

if pgrep -x "Microsoft Outlook" >/dev/null; then
  echo "Microsoft Outlook is running. Quit it first." >&2
  exit 1
fi

targets=(
  "$HOME/Library/Group Containers/UBF8T346G9.Office"
  "$HOME/Library/Containers/com.microsoft.Outlook"
)

for t in "${targets[@]}"; do
  if [ -e "$t" ] && [ "$force" -ne 1 ]; then
    echo "Refusing to overwrite existing: $t (use --force)" >&2
    exit 1
  fi
done

if [ "$force" -eq 1 ]; then
  for t in "${targets[@]}"; do
    rm -rf "$t"
  done
fi

tar -xzf "$archive" -C "$HOME"
echo "Restored from $archive"
