#!/bin/bash
# Safety net: the old ~/bin/update.sh ran `brew cu -a`, which reinstalls microsoft-office
# and wipes Outlook profiles. The `absent` dotfiles entry removes it; fail loudly if it survives.
set -euo pipefail

f="$HOME/bin/update.sh"
if [ -e "$f" ] && grep -vE '^[[:space:]]*#' "$f" | grep -Eq 'brew[[:space:]]+cu|cask-upgrade|--greedy'; then
  echo "error: $f still contains 'brew cu' / '--greedy'. Delete it (rm) and re-run 'mise bootstrap'." >&2
  exit 1
fi
