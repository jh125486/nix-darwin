#!/bin/bash
# Restore an Outlook backup made by backup-outlook.sh.
# Usage: restore-outlook.sh <archive.zip|archive.tar.gz|archive.tgz> [--force]
#
# Accepts the current .zip format (ditto, keeps xattrs/ACLs) and the older
# outlook-backup-YYYYMMDD-HHMMSS.tar.gz archives (made without xattrs/ACLs).
# --force moves existing data aside to *.bak-<epoch> (never deletes it).
# Only the three known members are restored into $HOME; archive entries that are
# absolute, contain "..", or sit outside Library/ cause a refusal. Only restore
# archives you made yourself.
# The terminal needs Full Disk Access. Tested only against a scratch $HOME.
set -euo pipefail
# Byte-wise text tools: Office file names are not always valid UTF-8.
export LC_ALL=C

archive=""
force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    *) archive="$arg" ;;
  esac
done

if [ -z "$archive" ] || [ ! -f "$archive" ]; then
  echo "Usage: $0 <archive.zip|archive.tar.gz> [--force]" >&2
  exit 1
fi

case "$archive" in
  *.zip) kind=zip ;;
  *.tar.gz | *.tgz) kind=tar ;;
  *)
    echo "Unsupported archive type (want .zip, .tar.gz or .tgz): $archive" >&2
    exit 1
    ;;
esac

# Same check as backup-outlook.sh: main app binaries only, not Edge or *.appex widgets.
office_pattern='/Microsoft (Outlook|Word|Excel|PowerPoint|OneNote|Teams|Teams classic)\.app/Contents/MacOS/|/Microsoft (AutoUpdate|Update Assistant)\.app/Contents/MacOS/'
running="$(pgrep -fl -- "$office_pattern" || true)"
if [ -n "$running" ]; then
  echo "Office apps are running; quit them first:" >&2
  echo "$running" | cut -c1-160 >&2
  exit 1
fi

die() {
  echo "Restore FAILED: $*" >&2
  exit 1
}

listfile="$(mktemp)"
stage=""
cleanup() {
  rm -f "$listfile"
  if [ -n "$stage" ]; then
    chmod -R u+w "$stage" 2>/dev/null || true
    rm -rf "$stage"
  fi
}
trap cleanup EXIT

# 1. Validate the archive and read its listing before touching anything.
if [ "$kind" = zip ]; then
  /usr/bin/unzip -tq "$archive" >/dev/null || die "zip failed integrity test: $archive"
  /usr/bin/zipinfo -1 "$archive" >"$listfile" || die "cannot list $archive"
else
  /usr/bin/tar -tzf "$archive" >"$listfile" || die "cannot list $archive"
fi

# Strip a leading "./" so ./Library/... archives are handled.
sed -i '' 's|^\./||' "$listfile"

if awk '/^\// || /(^|\/)\.\.(\/|$)/ { bad=1 } END { exit !bad }' "$listfile"; then
  die "archive has absolute or '..' entries; refusing"
fi
if grep -qvE '^(Library(/|$)|__MACOSX/|$)' "$listfile"; then
  die "archive has entries outside Library/; refusing"
fi

members=(
  "Library/Group Containers/UBF8T346G9.Office"
  "Library/Containers/com.microsoft.Outlook"
)
# The preferences plist is optional; only restore it if the archive has it.
if grep -qxF "Library/Preferences/com.microsoft.Outlook.plist" "$listfile"; then
  members+=("Library/Preferences/com.microsoft.Outlook.plist")
fi

# Entries (excluding __MACOSX metadata) at or under a member.
count_listing() {
  awk -v p="$1" '!/^__MACOSX\// && (index($0, p) == 1) &&
    (length($0) == length(p) || substr($0, length(p) + 1, 1) == "/") { n++ } END { print n + 0 }' "$listfile"
}

for m in "${members[@]}"; do
  [ "$(count_listing "$m")" -gt 0 ] || die "archive is missing expected member: $m"
done

# 2. Refuse before changing anything if targets exist and --force was not given.
for m in "${members[@]}"; do
  if [ -e "$HOME/$m" ] && [ "$force" -ne 1 ]; then
    die "refusing to overwrite existing $HOME/$m (use --force to move it aside)"
  fi
done

# 3. Extract only the named members into a staging dir on the same volume as $HOME.
stage="$(mktemp -d "$HOME/.outlook-restore-stage.XXXXXX")"
if [ "$kind" = zip ]; then
  # ditto -x -k has no member filter, so extract everything (names validated above)
  # into the staging dir and move only the named members out of it.
  /usr/bin/ditto -x -k "$archive" "$stage" || die "ditto extraction failed"
else
  /usr/bin/tar -xzpf "$archive" -C "$stage" "${members[@]}" || die "tar extraction failed"
fi

# 4. Verify the staged copy before moving anything aside.
for m in "${members[@]}"; do
  [ -e "$stage/$m" ] || die "extraction did not produce $m"
  want="$(count_listing "$m")"
  have="$(find "$stage/$m" | wc -l | tr -d ' ')"
  [ "$want" = "$have" ] || die "entry count mismatch for $m (archive $want, extracted $have)"
done

# 5. Move existing data aside (with --force), then move the staged members into place.
epoch="$(date +%s)"
for m in "${members[@]}"; do
  t="$HOME/$m"
  if [ -e "$t" ]; then
    mv "$t" "$t.bak-$epoch"
    echo "Moved aside: $t.bak-$epoch"
  fi
  mkdir -p "$(dirname "$t")"
  mv "$stage/$m" "$t"
done

# 6. Final check on the installed targets.
for m in "${members[@]}"; do
  want="$(count_listing "$m")"
  have="$(find "$HOME/$m" | wc -l | tr -d ' ')"
  [ "$want" = "$have" ] || die "post-restore count mismatch for $m (archive $want, found $have)"
  echo "Restored $m ($have entries)"
done
echo "Restored from $archive"
echo "Keychain tokens are not part of the backup; expect to re-authenticate accounts."
