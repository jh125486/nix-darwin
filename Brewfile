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
brew "avrdude"           # only release binary is x86_64 (github:avrdudes/avrdude, Rosetta); not on conda-forge/aqua
brew "dockutil"          # release is a .pkg only; no conda/aqua/github binary
brew "mkvtoolnix"        # no GitHub release binaries, not on conda-forge osx-arm64, not in registry
brew "nmap"              # not in registry/aqua, no conda-forge osx-arm64 build
brew "john-jumbo"        # source-only upstream releases, not on conda-forge osx-arm64
brew "pam-reattach"      # must live at $(brew --prefix)/lib/pam; not on conda-forge
brew "qemu"              # not in registry/aqua, not on conda-forge osx-arm64
brew "sl"                # source-only upstream, not on conda-forge
brew "wireguard-tools"   # not in registry, not on conda-forge osx-arm64
brew "yubico-piv-tool"   # upstream release has no arm64 binary, not on conda-forge

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
