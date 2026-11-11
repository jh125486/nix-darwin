# Brewfile -- native-dependency CLIs, GUI apps (casks), and things mise cannot provide.
#
# Split of responsibilities:
#   mise      (home/dot_config/mise/config.toml): language runtimes and pure-binary dev CLIs.
#   Brewfile  (this file): formulae with native deps / services, casks, macOS glue.
#   chezmoi   : dotfiles and the scripts that run `brew bundle` and `mise install`.
# A tool lives in exactly ONE of mise or brew. Do not duplicate.
#
# Applied by `brew bundle install --no-upgrade` (never --cleanup / --zap).

# ---- Taps ----
tap "furkankly/tap"

# ---- Formulae ----
brew "agg"
brew "arm-none-eabi-gcc"
brew "automake"
brew "avrdude"
brew "dockutil"
brew "exiftool"          # mise only has a conda backend; brew is simpler
brew "furkankly/tap/zoetrope"
brew "herdr"
brew "httpie"
brew "john-jumbo"
brew "jupyterlab"
brew "mkvtoolnix"
brew "ncdu"              # no mise registry short name
brew "ninja"
brew "nmap"
brew "open-ocd"
brew "pam-reattach"      # Touch ID for sudo inside tmux (see run_once_30-touchid-sudo.sh)
brew "podman"
brew "poppler"
brew "qemu"
brew "redis"
brew "rtk"
brew "sevenzip"
brew "sl"
brew "tmux"
brew "tree"
brew "vhs"               # needs ttyd/ffmpeg deps; brew resolves them
brew "worktrunk"
brew "xgo"
brew "youtube-dl"
brew "yt-dlp"
brew "yubico-piv-tool"

# ---- Casks ----
cask "1password"
cask "1password-cli"
cask "adobe-creative-cloud"
cask "bartender"
cask "chatgpt"
cask "claude"
cask "claude-code"
cask "copilot-cli"
cask "dbeaver-community"
cask "discord"
cask "displaylink"
cask "docker-desktop"
cask "drawio"
cask "ghostty"
cask "github"
cask "gcloud-cli"        # mise's gcloud plugin is a third-party vfox plugin; use the cask
cask "google-drive"
cask "grandperspective"
cask "inkscape"
cask "iterm2"
cask "jetbrains-toolbox"
cask "keepingyouawake"
cask "libreoffice"
cask "logi-options+"
cask "logitech-presentation"
cask "macshot"
cask "microsoft-auto-update"
cask "microsoft-edge"

# !!! MICROSOFT OFFICE -- READ THIS !!!
# NEVER upgrade this with `brew cu`, `brew upgrade --greedy`, or `brew upgrade --cask microsoft-office`.
# Reinstalling the full .pkg resets Outlook and WIPES accounts/signatures.
# Updates come from Microsoft AutoUpdate ONLY. See docs/MIGRATION.md.
cask "microsoft-office"

cask "openinterminal-lite"
cask "parallels"
cask "proton-mail"
cask "protonvpn"
cask "qflipper"
cask "rstudio"
cask "shottr"
cask "signal"
cask "stats"
cask "steam"
cask "visual-studio-code"
cask "whatsapp"
cask "wireshark-app"
cask "yubico-authenticator"
cask "yubico-yubikey-manager"
cask "zed"
