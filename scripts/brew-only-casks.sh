#!/bin/bash
# Casks that mise cannot install, installed (and later upgraded) by Homebrew instead:
#  - steam: the download has no Steam.app, so mise fails with "app artifact 'Steam.app' was not found"
#  - logitech-presentation: `installer manual:` only ("only script installers are supported")
#  - adobe-creative-cloud, displaylink, google-drive, logi-options+: pkg/installer casks, installed with brew
#    (known to work); not verified with mise. One failing cask aborts the whole `mise bootstrap packages apply`.
# Idempotent. Needs a real terminal for the sudo prompts of the pkg installers.
set -uo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"
casks=(steam logitech-presentation adobe-creative-cloud displaylink google-drive logi-options+)

status=0
for c in "${casks[@]}"; do
  if brew list --cask "$c" >/dev/null 2>&1; then
    echo "brew-only-casks: $c already installed"
  else
    brew install --cask "$c" || { echo "brew-only-casks: FAILED $c" >&2; status=1; }
  fi
done

if [ ! -e "/Applications/Logitech Presentation" ]; then
  echo "brew-only-casks: Logitech Presentation needs its installer run once by hand:" >&2
  echo "  open /opt/homebrew/Caskroom/logitech-presentation/*/" >&2
fi
exit $status
