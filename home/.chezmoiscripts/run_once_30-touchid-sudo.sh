#!/bin/bash
# Enable Touch ID for sudo (also inside tmux via pam-reattach). Idempotent.
set -euo pipefail

f=/etc/pam.d/sudo_local
reattach=/opt/homebrew/lib/pam/pam_reattach.so
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  if [ -e "$reattach" ]; then
    echo "auth       optional       $reattach"
  fi
  echo "auth       sufficient     pam_tid.so"
} >"$tmp"

if [ -f "$f" ] && cmp -s "$tmp" "$f"; then
  echo "$f already configured"
  exit 0
fi

# Idempotent: only write when the required lines are missing/different.
if [ -f "$f" ] && grep -q 'pam_tid.so' "$f" && { [ ! -e "$reattach" ] || grep -q 'pam_reattach.so' "$f"; }; then
  echo "$f already contains required entries"
  exit 0
fi

sudo install -m 444 -o root -g wheel "$tmp" "$f"
echo "Wrote $f"
