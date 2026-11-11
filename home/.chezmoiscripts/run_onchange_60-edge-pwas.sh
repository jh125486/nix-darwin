#!/bin/bash
# BEST-EFFORT recreation of Edge web apps. UNVERIFIED: create-pwa.sh uses Edge
# --app/--create-shell-shortcuts flags that may NOT produce a real macOS app bundle.
# Always exits 0. Reliable path: Edge > ... > Apps > Install this site as an app.
set -uo pipefail

# URLs read from the live apps' Info.plist (CrAppModeShortcutURL).
CANVAS_URL="https://unt.instructure.com/"
SPOTIFY_URL="https://open.spotify.com/"

script="$HOME/bin/create-pwa.sh"
failed=0

create() {
  local url="$1" name="$2"
  if [ -d "$HOME/Applications/Edge Apps.localized/$name.app" ]; then
    echo "$name already exists; skipping"
    return 0
  fi
  if [ ! -x "$script" ] || ! "$script" "$url" --name "$name" --browser edge; then
    failed=1
  fi
}

create "$CANVAS_URL" "Canvas"
create "$SPOTIFY_URL" "Spotify"

if [ "$failed" -eq 1 ] || [ ! -d "$HOME/Applications/Edge Apps.localized/Canvas.app" ] || [ ! -d "$HOME/Applications/Edge Apps.localized/Spotify.app" ]; then
  cat <<MSG
Edge apps may not have been created automatically. Do it manually:
  1. Open Microsoft Edge and visit the site
       Canvas:  $CANVAS_URL
       Spotify: $SPOTIFY_URL
  2. Menu (...) > Apps > Install this site as an app
MSG
fi
exit 0
