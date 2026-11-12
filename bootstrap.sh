#!/bin/bash
# Bootstrap a new Mac: Homebrew -> chezmoi + mise -> apply dotfiles from this repo.
# NOTE: the repo must be public (or you must be authenticated, e.g. via ssh/gh) for
# `chezmoi init` to clone it. Idempotent: safe to re-run.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

brew install chezmoi mise

if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  chezmoi apply
else
  chezmoi init --apply jh125486/nix-darwin
fi
