#!/bin/bash
# Install VS Code extensions from vscode-extensions.txt that are not yet installed.
# Idempotent and cheap: lists installed extensions once.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

eval "$(/opt/homebrew/bin/brew shellenv)"
if ! command -v code >/dev/null 2>&1; then
  echo "error: 'code' not on PATH (is the visual-studio-code cask installed?)" >&2
  exit 1
fi

installed="$(code --list-extensions | tr '[:upper:]' '[:lower:]')"
while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  if printf '%s\n' "$installed" | grep -qxF "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"; then
    continue
  fi
  code --install-extension "$ext" || echo "warning: failed to install $ext" >&2
done <"$here/vscode-extensions.txt"
