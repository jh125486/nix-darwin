#!/bin/bash
# Bootstrap a new Mac: Homebrew -> mise -> `mise bootstrap` from this repo.
# `mise bootstrap` installs packages/casks, deploys dotfiles, sets macOS defaults and tools.
# NOTE: the repo must be public (or git-authenticated, e.g. ssh/gh) so it can be cloned.
# Idempotent: re-running is safe. Requires mise >= 2026.9.2.
set -euo pipefail

repo="${REPO_URL:-https://github.com/jh125486/nix-darwin.git}"
dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

if ! command -v mise >/dev/null 2>&1; then
  brew install mise
fi

# --from clones the repo to $dir and trusts its mise.toml for this run.
# The old ~/bin/update.sh (`brew cu`) is removed by an `absent` dotfiles entry; the `update` alias lives in ~/.zshrc.
# mise asks before replacing other differing dotfiles; pass --yes for non-interactive runs.
# Never pass --upgrade (it could reinstall microsoft-office and wipe Outlook).
if [ -d "$dir/.git" ]; then
  mise bootstrap --from "$repo" --from-dir "$dir" --update
else
  mise bootstrap --from "$repo" --from-dir "$dir"
fi

# Make sure every tool in ~/.config/mise/config.toml (deployed above) is installed.
# Safe to repeat: already-installed tools are skipped.
mise install

# Re-run later with:  mise -C "$dir" bootstrap   (needs the checkout to be trusted)
mise trust "$dir"
