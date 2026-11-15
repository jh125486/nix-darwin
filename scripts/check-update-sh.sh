#!/bin/bash
# Safety net: the old ~/bin/update.sh ran `brew cu -a`, which reinstalls microsoft-office
# and wipes Outlook profiles. Fail loudly if any deployed update.sh still mentions it.
set -euo pipefail

f="$HOME/bin/update.sh"
if [ -e "$f" ] && grep -vE '^[[:space:]]*#' "$f" | grep -Eq 'brew[[:space:]]+cu|cask-upgrade|--greedy'; then
  echo "error: $f still contains 'brew cu' / '--greedy'. Delete it and re-run 'mise bootstrap'." >&2
  exit 1
fi
