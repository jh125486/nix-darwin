# Migration: nix-darwin -> mise + Brewfile + chezmoi

## 1. Architecture

| Tool | Owns |
|------|------|
| mise (`home/dot_config/mise/config.toml`) | Language runtimes and pure-binary dev CLIs (go, node, python, uv, rust, zig, java, aws-cli, jq, yq, buf, goreleaser, scc, opentofu, shellcheck, direnv, bazelisk, gradle, kotlin, maven, tinygo, glow, changie, protoc, golangci-lint) |
| Brewfile | Native-dependency formulae (qemu, podman, redis, open-ocd, ...), tools with no mise backend (ncdu, nmap, exiftool, vhs), `gh` and `hugo` (brew hugo is the extended build), all casks, `gcloud-cli` |
| chezmoi (`home/`) | Dotfiles (zsh, git, mise, VS Code settings) and `.chezmoiscripts/` that run brew bundle, mise install, and macOS settings |

A tool lives in exactly one of mise or brew.

| nix-darwin feature | Replacement |
|---|---|
| Touch ID for sudo | `run_once_after_30-touchid-sudo.sh` (writes `/etc/pam.d/sudo_local`, with `pam-reattach`) |
| Dock on the right, dock layout | `run_onchange_after_40-macos-defaults-dock.sh.tmpl` (`defaults` + `dockutil`) |
| Finder prefs | same script (`FXPreferredViewStyle`, `FXDefaultSearchScope`) |
| git config | `home/dot_gitconfig.tmpl`, `home/dot_config/git/ignore` |
| zsh | `home/dot_zshrc`, `home/dot_zprofile` |
| VS Code settings/extensions | `home/Library/Application Support/Code/User/create_settings.json` (created only if absent), `home/dot_config/vscode-extensions.txt`, `run_onchange_after_50-vscode-extensions.sh.tmpl` |

Notes:
- The `.chezmoiscripts` templates were not rendered or run (chezmoi was not available when written).
- `brew bundle` is run with `--no-upgrade` and never `--cleanup`/`--zap`.
- If `brew bundle` has failures (e.g. a cask), `chezmoi apply` continues; rerun `brew bundle install --no-upgrade --file=<repo>/Brewfile`.
- On this machine `/etc/pam.d/sudo_local` is a nix symlink into `/etc/static`; the touchid script replaces it with a regular file. The `pam_reattach.so` path is taken from `$(brew --prefix)/lib/pam/`; the line is skipped if the file is absent.
- `~/.config/git/config`, `~/.config/git/ignore` and `~/.zshenv` are currently home-manager symlinks into `/nix/store`; remove the dangling links as part of cutover (below).
- Dock: the script skips missing items. Re-run it after the Parallels VM and Edge apps exist (`chezmoi state delete-bucket --bucket=scriptState`, then `chezmoi apply`, or edit the script). Teams is installed outside brew and is NOT in the Brewfile (a cask would conflict); install it manually.
- The `buo/cask-upgrade` tap (`brew cu`) is dropped on purpose.

## 2. WARNING: Microsoft Outlook

**Root cause.** `brew cu -a` (and `brew upgrade --greedy`) reinstalls `microsoft-office` from its full
`.pkg`, which resets the Outlook profile and wipes all accounts and signatures.

**Second root cause: nix-darwin zap.** `flake.nix` used `homebrew.onActivation.cleanup = "zap"`. The
`microsoft-office`/Outlook cask zap stanza trashes `~/Library/Group Containers/UBF8T346G9.Office`,
`~/Library/Containers/com.microsoft.Outlook` and `com.microsoft.Outlook.plist`. `flake.nix` is now
neutered (`cleanup = "none"`, no upgrade/autoUpdate), but **never run `darwin-rebuild` again**.
Also, home-manager's `backupFileExtension = "backup"` can rename or clobber chezmoi-managed files.
nix-darwin must be retired/neutered before the first `chezmoi apply`.

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
4. Run `restore-outlook.sh <archive> --force` (moves any fresh install data aside).
5. Launch Outlook.

Notes:
- Both scripts refuse to run if any `/Applications/Microsoft ` process is running and print which.
- Backup writes `*.partial` then renames on success, and verifies with `tar -tzf`, so a truncated archive never looks valid. Archives use `--mac-metadata` (xattrs/ACLs) on create and extract.
- Your terminal needs Full Disk Access (System Settings > Privacy & Security) to read/write these containers.
- Keychain tokens/passwords are NOT in the backup; expect to re-authenticate every account.
- A fresh Office install will likely already have created the Group Container, so restore needs `--force`. That moves existing dirs to `*.bak-<epoch>` rather than deleting them.
- The optional `~/Library/Preferences/com.microsoft.Outlook.plist` is included when present.

**The restore is UNTESTED.** Try it on a spare macOS user before relying on it. The new Outlook may
also sync some settings server-side, so results can differ from a pure file restore. Keep the original
data until verified.

## 3. Edge apps and the Parallels VM

- Edge web apps (Canvas, Spotify): `run_onchange_after_60-edge-pwas.sh` is best-effort and UNVERIFIED (create-pwa.sh now launches Edge via `open -na` so it does not block); the
  Edge flags it uses may not produce a real app bundle. The reliable path: Edge > ... > Apps >
  Install this site as an app. URLs: Canvas `https://unt.instructure.com/`, Spotify `https://open.spotify.com/`.
- Parallels VM (`~/Parallels/Windows 11.pvm`) must be copied/restored manually. Install the
  `parallels` cask first; the dock item is skipped until the VM exists.

## 4. Nix retirement checklist

1. For each former nix tool (aws, gh, jq, yq, buf, goreleaser, hugo, protoc, golangci-lint, scc, vhs, zig, rustc, cargo,
   gcloud, nmap, exiftool), check `command -v <tool>` resolves to a mise shim/path or `/opt/homebrew`,
   not `/nix` or `/run/current-system`.
2. Uninstall nix-darwin and remove `/nix`.
3. After mise is verified, `brew uninstall` the duplicates now owned by mise: bazelisk, changie, direnv, gradle, kotlin, maven, opentofu, shellcheck, uv, tinygo, glow, buf, goreleaser, plus brew's go/node/python@* if you want mise to own them (check dependents with `brew uses --installed <formula>` first).
4. Remove dangling home-manager links (`~/.zshenv`, `~/.config/git/config`, `~/.config/git/ignore`) if they are symlinks into `/nix/store`.
5. In a follow-up PR, delete `flake.nix`, `flake.lock`, and `nix.conf`.

## 5. Replacing the live ~/bin/update.sh

The existing live `~/bin/update.sh` contains `brew cu -a`. The new one also unsets `HOMEBREW_UPGRADE_GREEDY*`. chezmoi will prompt/refuse if the target
differs, so either delete it first or run `chezmoi apply --force`. Confirm the new file has no `brew cu`
before running `update`.
