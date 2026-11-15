#!/bin/bash
# Dock app order via dockutil. Orientation/Finder prefs are set natively by
# [bootstrap.settings.macos] in mise.toml. Idempotent: skips when the desired
# list (existing paths only) is unchanged since the last successful run.
# Missing items are skipped; re-run `mise bootstrap` after the Parallels VM and Edge
# apps exist. Teams is installed outside brew and is only added if already present.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"
if ! command -v dockutil >/dev/null 2>&1; then
  echo "error: dockutil not found (did package install fail?); dock layout not applied" >&2
  exit 1
fi

items=(
  "/Applications/Proton Mail.app"
  "/Applications/Microsoft Outlook.app"
  "/Applications/Microsoft Teams.app"
  "/Applications/Microsoft Edge.app"
  "/Applications/ChatGPT.app"
  "/Applications/Claude.app"
  "$HOME/Applications/Edge Apps.localized/Canvas.app"
  "/System/Applications/Reminders.app"
  "/System/Applications/Notes.app"
  "/System/Applications/Messages.app"
  "/Applications/Signal.app"
  "/Applications/Discord.app"
  "/Applications/WhatsApp.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Ghostty.app"
  "/Applications/Docker.app/Contents/MacOS/Docker Desktop.app"
  "/Applications/DBeaver.app"
  "$HOME/Parallels/Windows 11.pvm/VM.app"
)

present=()
for item in "${items[@]}"; do
  if [ -e "$item" ]; then
    present+=("$item")
  else
    echo "dock: skip (missing): $item"
  fi
done

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix-darwin-migration"
state_file="$state_dir/dock.sha256"
want="$(printf '%s\n' "${present[@]}" | shasum -a 256 | cut -d' ' -f1)"

if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$want" ]; then
  echo "dock: layout unchanged"
  exit 0
fi

dockutil --remove all --no-restart
for item in "${present[@]}"; do
  dockutil --add "$item" --no-restart
done
killall Dock || true

mkdir -p "$state_dir"
printf '%s\n' "$want" >"$state_file"
