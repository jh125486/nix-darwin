#!/bin/bash
# Enable Touch ID for sudo (also inside tmux via pam-reattach). Idempotent.
# Existing rules in /etc/pam.d/sudo_local are preserved; only our two lines are
# ensured, at the top (pam_reattach optional, ABOVE pam_tid sufficient).
# On a nix-darwin machine the file is a symlink into /etc/static; it is replaced
# by a real file seeded from the symlink target's content.
set -euo pipefail

f=/etc/pam.d/sudo_local
prefix="/opt/homebrew"
if command -v brew >/dev/null 2>&1; then
  prefix="$(brew --prefix)"
fi
reattach="$prefix/lib/pam/pam_reattach.so"

tid_re='^[[:space:]]*auth[[:space:]].*pam_tid\.so'
reattach_re='^[[:space:]]*auth[[:space:]].*pam_reattach\.so'
tid_line="auth       sufficient     pam_tid.so"
reattach_line="auth       optional       $reattach"

tmp="$(mktemp)"
rest="$(mktemp)"
trap 'rm -f "$tmp" "$rest"' EXIT

# Existing content (cat follows symlinks); empty if the file is absent.
existing=""
if [ -e "$f" ]; then
  existing="$(cat "$f")"
fi

# Everything that is not one of our lines.
printf '%s\n' "$existing" | grep -vE "$tid_re|$reattach_re" >"$rest" || true

# Report other auth rules we are keeping.
kept="$(grep -E '^[[:space:]]*auth[[:space:]]' "$rest" || true)"
if [ -n "$kept" ]; then
  echo "Keeping existing auth rules in $f:"
  printf '%s\n' "$kept"
fi

{
  if [ -e "$reattach" ]; then
    echo "$reattach_line"
  fi
  echo "$tid_line"
  # Drop leading blank lines from the preserved remainder.
  sed '/./,$!d' "$rest"
} >"$tmp"

# No write when already correct (regular file with identical content).
if [ -f "$f" ] && [ ! -L "$f" ] && cmp -s "$tmp" "$f"; then
  echo "$f already configured"
  exit 0
fi

# Back up an existing regular file before changing it.
if [ -f "$f" ] && [ ! -L "$f" ]; then
  sudo cp -p "$f" "$f.bak-$(date +%s)"
fi

if [ -L "$f" ]; then
  sudo rm -f "$f"
fi
sudo install -m 444 -o root -g wheel "$tmp" "$f"
echo "Wrote $f"
