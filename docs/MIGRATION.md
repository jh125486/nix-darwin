# Migration: nix-darwin -> mise (tools, dotfiles, bootstrap)

Everything is driven by mise (>= 2026.9.2): `[tools]`, `[dotfiles]`, and `mise bootstrap`.
There is no chezmoi and no Brewfile. Homebrew is only the backend that `[bootstrap.packages]` uses
for casks and nine formulae, plus the one thing needed to get mise itself.

## 1. Architecture and layout

```
mise.toml               project config: [dotfiles], [bootstrap.*], hooks, [tasks.bootstrap], packages
dotfiles/               sources deployed by [dotfiles] (zshrc, zprofile, gitconfig.tera, git/ignore,
                        mise/config.toml = the global tools list, vscode/shared.json, bin/*.sh)
scripts/                idempotent helper scripts called from hooks / the bootstrap task
bootstrap.sh            new-Mac entry point (Homebrew -> mise -> `mise bootstrap --from`)
docs/MIGRATION.md      this file
```

**Why `--from` and not `--adopt`.** Per the mise docs, `--adopt <repo>` either clones a repo into
`~/.config/mise` as the global config, or restores a setup repo that has `.mise-history/` (made by
`mise dot track` + `mise dot origin set`). This repo is neither: it is a *bootstrap project* with a root
`mise.toml`, which is exactly what `mise bootstrap --from <url> --from-dir ~/.dotfiles` handles (it clones
to `~/.dotfiles` and trusts that `mise.toml` for the run). The global tools list is deployed as a
dotfile (`~/.config/mise/config.toml`); mise re-reads its own config after writing it and then installs
`[tools]`.

| What | Owner |
|------|------|
| Runtimes and ~55 CLIs (go, node, python, uv, rust, zig, java, aws-cli, gh, jq, ... ) | `[tools]` in `dotfiles/mise/config.toml` (registry/aqua, `github:`, `go:`, `npm:`, `conda:` backends; list with backends in the PR description) |
| Casks (46 GUI apps) and 9 formulae (dockutil, mkvtoolnix, nmap, john-jumbo, pam-reattach, qemu, sl, wireguard-tools, yubico-piv-tool) | `[bootstrap.packages]` in `mise.toml` (`brew-cask:` / `brew:`; mise installs only what is missing) |
| Dotfiles | `[dotfiles]` in `mise.toml` |
| macOS Dock orientation, Finder view style and search scope | `[bootstrap.settings.macos]` (native) |
| Dock app order, VS Code extensions, Edge apps, Touch ID sudo | hooks / `[tasks.bootstrap]` calling `scripts/*.sh` (not expressible natively; see below) |

A tool lives in exactly one of mise tools or bootstrap packages. Homebrew formulae remain only for tools
mise cannot install: mise only fetches prebuilt binaries and cannot compile from source; Homebrew compiles
these and publishes arm64 bottles. Casks stay because mise `[tools]` has no .app/.dmg/.pkg backend (the
`brew-cask:` package manager handles them).

| nix-darwin feature | Replacement |
|---|---|
| Touch ID for sudo | `post-packages` hook -> `scripts/touchid-sudo.sh` (backs up and preserves existing rules, reattach above tid, replaces the nix symlink; hook, because `[bootstrap.files]` has no backup/merge and the file is a symlink here) |
| Dock on the right | `[bootstrap.settings.macos.dock] orientation = "right"` |
| Finder prefs | `[bootstrap.settings.macos.finder] preferred_view_style = "list"` (Nlsv) and `defaults."com.apple.finder".FXDefaultSearchScope = "SCcf"` |
| Dock app order | `scripts/dock.sh` (dockutil; the native `dock.apps` requires every app to exist, but the VM/PWAs may not yet) |
| git config | `dotfiles/gitconfig.tera` (Tera template; credential helper = mise shim path), `dotfiles/git/ignore` |
| zsh | `dotfiles/zshrc`, `dotfiles/zprofile` |
| VS Code | `merge = true` JSONC entry for settings.json (mise owns only the keys we ship; the app and your edits keep the rest), `scripts/vscode-extensions.sh` |

Notes:
- **Hooks and the task run on every `mise bootstrap`**, so each script is idempotent and cheap (dock.sh hashes the desired list; the extension script installs only missing ones; touchid compares before using sudo).
- **Re-running:** `mise -C ~/.dotfiles bootstrap` (after a one-time `mise trust ~/.dotfiles`, which bootstrap.sh does). Re-run it after the Parallels VM and Edge apps exist so the Dock picks them up. To pull repo updates: `mise bootstrap --from <url> --from-dir ~/.dotfiles --update`.
- **Packages never upgrade.** Docs: `apply` "installs missing packages but does not upgrade". Upgrades only happen with `mise bootstrap --upgrade` / `mise bootstrap packages upgrade`; do not use them (see the Outlook section). The `update` alias (in `~/.zshrc`) upgrades with plain `brew upgrade` (no `--greedy`, so self-updating casks like microsoft-office are skipped) and `mise upgrade`.
- `gh` is in mise. The git credential helper points at the mise shim (`$HOME/.local/share/mise/shims/gh`), which works for non-interactive git (IDEs) once tools are installed; `zprofile` also activates shims for login shells.
- hugo uses `aqua:gohugoio/hugo/hugo-extended` (extended build).
- Services: nothing runs under `brew services` on the old machine (jupyterlab, podman, redis all `none`). mise-installed redis/podman are plain binaries; launchd services are not available for them.
- conda-forge packages need mise `experimental = true` (set in the config). `mise install` uses the GitHub API; set `GITHUB_TOKEN` (e.g. `export GITHUB_TOKEN=$(gh auth token)`) on first run to avoid rate limits. If `go:`/`npm:` tools fail on the first pass, re-run `mise bootstrap`.
- `yubico-yubikey-manager` was removed from homebrew-cask (its API entry 404s; mise needs the API), so it is not declared. The installed copy is untouched.
- On this machine `/etc/pam.d/sudo_local`, `~/.zshenv`, `~/.config/git/{config,ignore}` may be nix/home-manager symlinks. `[dotfiles]` copy mode replaces a symlink with a regular file; remove dangling links at cutover (below).
- Existing differing dotfiles (e.g. a live `~/.zshrc`, `~/.config/mise/config.toml`, `~/.gitconfig`) are overwritten after confirmation (or `--yes`). Back them up first. mise also keeps dotfile history (`mise dot undo`) once a checkpoint exists.
- Dotfiles history/auto-sync is NOT enabled. This repo is public and the author of the feature warns against public repos with auto-sync (secrets can leak into history). To keep local-only history, run `mise dot track <file>` (no `mise dot origin set`).
- Teams is installed outside brew; it is not declared (a cask would conflict). It is added to the Dock only if present.

## 2. WARNING: Microsoft Outlook

**Root cause.** `brew cu -a` (and `brew upgrade --greedy`, and `mise bootstrap --upgrade` / `mise bootstrap packages upgrade`) can reinstall `microsoft-office` from its full
`.pkg`, which resets the Outlook profile and wipes all accounts and signatures.

**Second root cause: nix-darwin zap.** The old nix-darwin flake used `homebrew.onActivation.cleanup = "zap"`. The
`microsoft-office`/Outlook cask zap stanza trashes `~/Library/Group Containers/UBF8T346G9.Office`,
`~/Library/Containers/com.microsoft.Outlook` and `com.microsoft.Outlook.plist`. The flake is deleted from this repo,
but on an EXISTING machine the old live `~/.config/nix` checkout may still contain it: **never run `darwin-rebuild` again.**
Run `git pull` there (or remove that checkout) so the old flake is gone, and retire nix-darwin before the first `mise bootstrap`.
Also, home-manager's `backupFileExtension = "backup"` could have renamed or clobbered dotfiles on that machine; check for `*.backup` files next to the mise-managed dotfiles.

**Rule.** Never upgrade `microsoft-office` through brew. Updates come from Microsoft AutoUpdate only.
The `update` alias in `~/.zshrc` (from `dotfiles/zshrc`) runs `brew update && brew upgrade && brew cleanup` (with `HOMEBREW_UPGRADE_GREEDY*` unset) then `mise upgrade`.

**Where the data lives.**
- `~/Library/Group Containers/UBF8T346G9.Office` (includes `Outlook 15 Profiles`)
- `~/Library/Containers/com.microsoft.Outlook`

**Scripts.** `~/bin/backup-outlook.sh [dest_dir]` (default `~/Backups`) writes a timestamped tar.gz;
`~/bin/restore-outlook.sh <archive> [--force]`. Both refuse to run while Outlook is running; restore
refuses to overwrite existing directories without `--force`.

**Moving to the new laptop.**
1. Quit Outlook on the old machine and run `backup-outlook.sh`.
2. Copy the archive to the new machine.
3. Install Office via `mise bootstrap` (the `brew-cask:microsoft-office` package). Do NOT launch Outlook.
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

- Edge web apps (Canvas, Spotify): `scripts/edge-pwas.sh` (run by the bootstrap task) is best-effort and UNVERIFIED (create-pwa.sh now launches Edge via `open -na` so it does not block); the
  Edge flags it uses may not produce a real app bundle. The reliable path: Edge > ... > Apps >
  Install this site as an app. URLs: Canvas `https://unt.instructure.com/`, Spotify `https://open.spotify.com/`.
- Parallels VM (`~/Parallels/Windows 11.pvm`) must be copied/restored manually. Install the
  `parallels` cask first; the dock item is skipped until the VM exists.

## 4. Nix retirement checklist

1. For each former nix tool (aws, gh, jq, yq, buf, goreleaser, hugo, protoc, golangci-lint, scc, vhs, zig, rustc, cargo,
   gcloud, nmap, exiftool), check `command -v <tool>` resolves to a mise shim/path or `/opt/homebrew`,
   not `/nix` or `/run/current-system`.
2. Make sure the old `~/.config/nix` checkout no longer has the flake (`git pull` or remove it), then uninstall nix-darwin and remove `/nix`. Never run `darwin-rebuild` again.
3. ONLY after `command -v` verification, `brew uninstall` the formulae mise `[tools]` now owns (check dependents first with `brew uses --installed <formula>`; `brew uninstall` will refuse if something depends on it): agg arm-none-eabi-gcc automake bazelisk changie direnv furkankly/tap/zoetrope glow gradle herdr httpie jupyterlab kotlin maven ncdu ninja open-ocd openapi-generator opentofu podman poppler redis rtk sevenzip shellcheck tinygo tmux tree uv worktrunk xgo youtube-dl yt-dlp go node python@3.13 python@3.15 and, if installed, gh jq yq htop wget watch coreutils vhs exiftool hugo protobuf. Then `brew untap furkankly/tap goreleaser/tap tinygo-org/tools buo/cask-upgrade`.
4. Remove dangling home-manager links (`~/.zshenv`, `~/.config/git/config`, `~/.config/git/ignore`) if they are symlinks into `/nix/store`.

## 5. Removing the live ~/bin/update.sh (safety-critical)

There is no `update.sh` any more: updating is the `update` alias in `~/.zshrc`. The existing live `~/bin/update.sh`
contains `brew cu -a` (wipes Outlook), so it must not survive. How it is removed:
1. `[dotfiles]` has `"~/bin/update.sh" = { mode = "absent" }`. Verified with a real mise v2026.11.9 arm64 binary in an
   isolated HOME: `mise dot apply --dry-run` prints `rm ~/bin/update.sh`; a real apply with no TTY and no `--yes`
   deletes the file (no prompt, no content comparison, permanent delete, not Trash); a second apply is a no-op.
   `mise dot undo` can restore it, so do not run that.
2. A `post-dotfiles` hook (`scripts/check-update-sh.sh`) fails the whole bootstrap if `~/bin/update.sh` still exists and
   any non-comment line contains `brew cu`, `cask-upgrade` or `--greedy`. Verified exit 1 against an old-style file, 0 after removal.
3. Belt and braces: `rm ~/bin/update.sh` before the first run is also fine.
