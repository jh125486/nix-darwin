#!/bin/bash
# Back up Outlook data to a timestamped zip. Usage: backup-outlook.sh [dest_dir]
#
# Format: outlook-backup-YYYYMMDD-HHMMSS.zip, made with `ditto -c -k --sequesterRsrc`.
# Members are rooted at `Library/...` (relative to $HOME), so restore-outlook.sh can
# also read the older .tar.gz archives. Extended attributes (about 58k files carry
# them) and ACLs are preserved via AppleDouble `__MACOSX/` entries.
#
# Why not tar.gz: `tar --mac-metadata` wrote an archive that bsdtar 3.5.3 (libarchive
# 3.7.4) cannot read back ("Special header too large"), so verification failed and no
# backup was ever produced. tar with --no-xattrs --no-acls does work but drops them.
#
# Not included: keychain tokens/passwords (re-authenticate accounts after restoring).
# The terminal needs Full Disk Access (System Settings > Privacy & Security) to read
# these containers; otherwise it fails with "Operation not permitted".
set -euo pipefail
# Byte-wise text tools: Office file names are not always valid UTF-8.
export LC_ALL=C

dest="${1:-$HOME/Backups}"

# Main app binaries only. Deliberately not Edge (a browser that does not write the
# Office containers) and not the macOS-managed *.appex widget extensions, which live
# under .app/Contents/PlugIns/ and so never match `.app/Contents/MacOS/`.
office_pattern='/Microsoft (Outlook|Word|Excel|PowerPoint|OneNote|Teams|Teams classic)\.app/Contents/MacOS/|/Microsoft (AutoUpdate|Update Assistant)\.app/Contents/MacOS/'

running="$(pgrep -fl -- "$office_pattern" || true)"
if [ -n "$running" ]; then
  echo "Office apps are running; quit them first:" >&2
  echo "$running" | cut -c1-160 >&2
  exit 1
fi

# Paths relative to $HOME. The preferences plist is optional.
members=(
  "Library/Group Containers/UBF8T346G9.Office"
  "Library/Containers/com.microsoft.Outlook"
)
if [ -e "$HOME/Library/Preferences/com.microsoft.Outlook.plist" ]; then
  members+=("Library/Preferences/com.microsoft.Outlook.plist")
fi
for m in "${members[@]:0:2}"; do
  if [ ! -d "$HOME/$m" ]; then
    echo "Missing source directory: $HOME/$m" >&2
    exit 1
  fi
done

mkdir -p "$dest"
archive="$dest/outlook-backup-$(date +%Y%m%d-%H%M%S).zip"
tmp="$archive.partial"
# ditto takes a single source, so APFS-clone the members into a staging tree rooted at
# Library/ (same volume as $HOME, so clones cost no extra space where supported).
stage="$(mktemp -d "$HOME/.outlook-backup-stage.XXXXXX")"
errlog="$(mktemp)"
cleanup() {
  rm -f "$tmp" "$errlog"
  chmod -R u+w "$stage" 2>/dev/null || true
  rm -rf "$stage"
}
trap cleanup EXIT

fail() {
  echo "Backup FAILED: $*" >&2
  [ -s "$errlog" ] && head -n 20 "$errlog" >&2
  exit 1
}

# Fail on a non-zero exit or any "error" in captured stderr (libarchive-style delayed errors).
run() {
  : >"$errlog"
  "$@" 2>"$errlog" || fail "$1 exited non-zero"
  if grep -qi 'error' "$errlog"; then fail "$1 reported errors"; fi
}

for m in "${members[@]}"; do
  mkdir -p "$stage/$(dirname "$m")"
  run /bin/cp -Rc "$HOME/$m" "$stage/$m"
done

run /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$stage/Library" "$tmp"

# Verify readability and contents before the final rename.
run /usr/bin/unzip -tq "$tmp" >/dev/null
listfile="$(mktemp)"
trap 'cleanup; rm -f "$listfile"' EXIT
/usr/bin/zipinfo -1 "$tmp" >"$listfile" || fail "cannot list $tmp"
for m in "${members[@]}"; do
  grep -qxF -e "$m" -e "$m/" "$listfile" || fail "archive is missing $m"
done
expected="$(find "$stage/Library" | wc -l | tr -d ' ')"
actual="$(grep -vc '^__MACOSX/' "$listfile" || true)"
total="$(wc -l <"$listfile" | tr -d ' ')"
[ "$expected" = "$actual" ] || fail "entry count mismatch (staged $expected, archive $actual)"

mv "$tmp" "$archive"
trap - EXIT
cleanup
rm -f "$listfile"

echo "Wrote $archive"
echo "  entries: $total ($actual real, rest are __MACOSX metadata)"
echo "  sha256:  $(shasum -a 256 "$archive" | cut -d' ' -f1)"
echo "Note: keychain tokens/passwords are NOT included; expect to re-authenticate accounts."
