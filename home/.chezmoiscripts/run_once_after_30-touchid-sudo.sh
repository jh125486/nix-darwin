#!/bin/bash
# Enable Touch ID for sudo (also inside tmux via pam-reattach). Idempotent.
# NOTE: on a nix-darwin machine /etc/pam.d/sudo_local is a symlink into /etc/static;
# it is replaced by a regular file here.
set -euo pipefail

f=/etc/pam.d/sudo_local
prefix="/opt/homebrew"
if command -v brew >/dev/null 2>&1; then
  prefix="$(brew --prefix)"
fi
reattach="$prefix/lib/pam/pam_reattach.so"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Desired content: pam_reattach (if installed) ABOVE pam_tid.
{
  if [ -e "$reattach" ]; then
    echo "auth       optional       $reattach"
  fi
  echo "auth       sufficient     pam_tid.so"
} >"$tmp"

# Compare full content (also checks ordering); rewrite only when different.
if [ -f "$f" ] && [ ! -L "$f" ] && cmp -s "$tmp" "$f"; then
  echo "$f already configured"
  exit 0
fi

sudo rm -f "$f"
sudo install -m 444 -o root -g wheel "$tmp" "$f"
echo "Wrote $f"
