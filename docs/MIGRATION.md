# Migration: nix-darwin -> mise + Brewfile + chezmoi

## 1. Architecture

| Tool | Owns |
|------|------|
| mise (`home/dot_config/mise/config.toml`) | Language runtimes and pure-binary dev CLIs (go, node, python, uv, rust, zig, java, aws-cli, gh, jq, yq, buf, goreleaser, hugo, scc, opentofu, shellcheck, direnv, bazelisk, gradle, kotlin, maven, tinygo, glow, changie) |
| Brewfile | Native-dependency formulae (qemu, podman, redis, open-ocd, ...), tools with no mise backend (ncdu, nmap, exiftool, vhs), all casks, `gcloud-cli` |
| chezmoi (`home/`) | Dotfiles (zsh, git, mise, VS Code settings) and `.chezmoiscripts/` that run brew bundle, mise install, and macOS settings |

A tool lives in exactly one of mise or brew.

| nix-darwin feature | Replacement |
|---|---|
| Touch ID for sudo | `run_once_30-touchid-sudo.sh` (writes `/etc/pam.d/sudo_local`, with `pam-reattach`) |
| Dock on the right, dock layout | `run_onchange_40-macos-defaults-dock.sh.tmpl` (`defaults` + `dockutil`) |
| Finder prefs | same script (`FXPreferredViewStyle`, `FXDefaultSearchScope`) |
| git config | `home/dot_gitconfig.tmpl`, `home/dot_config/git/ignore` |
| zsh | `home/dot_zshrc` |
| VS Code settings/extensions | `home/Library/Application Support/Code/User/settings.json`, `home/dot_config/vscode-extensions.txt`, `run_onchange_50-vscode-extensions.sh.tmpl` |

Notes:
- The `.chezmoiscripts` templates were not rendered or run (chezmoi was not available when written).
- `brew bundle` is run with `--no-upgrade` and never `--cleanup`/`--zap`.
- The `buo/cask-upgrade` tap (`brew cu`) is dropped on purpose.

## 2. WARNING: Microsoft Outlook

**Root cause.** `brew cu -a` (and `brew upgrade --greedy`) reinstalls `microsoft-office` from its full
`.pkg`, which resets the Outlook profile and wipes all accounts and signatures.

**Rule.** Never upgrade `microsoft-office` through brew. Updates come from Microsoft AutoUpdate only.
`~/bin/update.sh` (managed here) runs `brew update && brew upgrade && brew cleanup` then `mise upgrade`.

**Where the data lives.**
- `~/Library/Group Containers/UBF8T346G9.Office` (includes `Outlook 15 Profiles`)
- `~/Library/Containers/com.microsoft.Outlook`

**Scripts.** `~/bin/backup-outlook.sh [dest_dir]` (default `~/Backups`) writes a timestamped tar.gz;
`~/bin/restore-outlook.sh <archive> [--force]`. Both refuse to run while Outlook is running; restore
refuses to overwrite existing directories without `--force`.

**Moving to the new laptop.**
1. Quit Outlook on the old machine and run `backup-outlook.sh`.
2. Copy the archive to the new machine.
3. Install Office via the Brewfile (chezmoi apply / `brew bundle`). Do NOT launch Outlook.
4. Run `restore-outlook.sh <archive>`.
5. Launch Outlook.

**The restore is UNTESTED.** Try it on a spare macOS user before relying on it. The new Outlook may
also sync some settings server-side, so results can differ from a pure file restore. Keep the original
data until verified.

## 3. Edge apps and the Parallels VM

- Edge web apps (Canvas, Spotify): `run_onchange_60-edge-pwas.sh` is best-effort and UNVERIFIED; the
  Edge flags it uses may not produce a real app bundle. The reliable path: Edge > ... > Apps >
  Install this site as an app. URLs: Canvas `https://unt.instructure.com/`, Spotify `https://open.spotify.com/`.
- Parallels VM (`~/Parallels/Windows 11.pvm`) must be copied/restored manually. Install the
  `parallels` cask first; the dock item is skipped until the VM exists.

## 4. Nix retirement checklist

1. For each former nix tool (aws, gh, jq, yq, buf, goreleaser, hugo, scc, vhs, zig, rustc, cargo,
   gcloud, nmap, exiftool), check `command -v <tool>` resolves to a mise shim/path or `/opt/homebrew`,
   not `/nix` or `/run/current-system`.
2. Uninstall nix-darwin and remove `/nix`.
3. In a follow-up PR, delete `flake.nix`, `flake.lock`, and `nix.conf`.

## 5. Replacing the live ~/bin/update.sh

The existing live `~/bin/update.sh` contains `brew cu -a`. chezmoi will prompt/refuse if the target
differs, so either delete it first or run `chezmoi apply --force`. Confirm the new file has no `brew cu`
before running `update`.
