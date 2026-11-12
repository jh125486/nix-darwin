# Brewfile -- casks (GUI apps), bootstrap tools, and the few formulae mise cannot provide.
#
# Casks live here because mise has no .app/.dmg/.pkg backend.
# Everything else (CLIs, runtimes, native tools) is in home/dot_config/mise/config.toml.
# A tool lives in exactly ONE of mise or brew. Formulae below each state why mise can't.
#
# Applied by `brew bundle install --no-upgrade` (never --cleanup / --zap).

# ---- Taps ----
# (none needed)

# ---- Bootstrap formulae ----
brew "chezmoi"           # installs dotfiles; must exist before mise config does
brew "mise"              # the tool manager itself

# ---- Formulae mise cannot provide ----
# mise only fetches prebuilt binaries and cannot compile from source. Homebrew compiles these
# and publishes arm64 bottles, which is why they stay in brew.
brew "dockutil"          # upstream release is a .pkg only; Homebrew supplies a prebuilt arm64 bottle
brew "mkvtoolnix"        # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "nmap"              # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "john-jumbo"        # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "pam-reattach"      # must live under $(brew --prefix)/lib/pam; Homebrew has an arm64 bottle
brew "qemu"              # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "sl"                # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "wireguard-tools"   # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle
brew "yubico-piv-tool"   # no prebuilt arm64 binary for mise (not in registry/aqua/conda-forge/github); Homebrew has an arm64 bottle

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
cask "gcloud-cli"        # mise gcloud is a third-party vfox plugin; the cask is the official install
cask "google-drive"
cask "grandperspective"
cask "hoppscotch"
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
