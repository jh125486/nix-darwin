# Migration: nix-darwin -> mise (tools, dotfiles, bootstrap)

Everything is driven by mise (>= 2026.9.2): `[tools]`, `[dotfiles]`, and `mise bootstrap`.
There is no chezmoi and no Brewfile. Homebrew is only the backend that `[bootstrap.packages]` uses
for casks and nine formulae, plus the one thing needed to get mise itself.

## 1. Architecture and layout

```
mise.toml               project config: [dotfiles], [bootstrap.*], hooks, [tasks.bootstrap], packages
dotfiles/               sources deployed by [dotfiles] (zshrc, zprofile, gitconfig.tera, git/ignore,
                        mise/config.toml = the global tools list, vscode/shared.json, bin/*.sh,
                        claude/ codex/ copilot/ = AI tool config, see section 6)
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
| 39 GUI casks and 9 formulae (dockutil, mkvtoolnix, nmap, john-jumbo, pam-reattach, qemu, sl, wireguard-tools, yubico-piv-tool) | `[bootstrap.packages]` in `mise.toml` (`brew-cask:` / `brew:`; mise installs only what is missing) |
| 6 more GUI casks mise cannot install (steam, logitech-presentation, adobe-creative-cloud, displaylink, google-drive, logi-options+) | `scripts/brew-only-casks.sh`, the first step of the `bootstrap` task (`brew install --cask`; see "Casks mise cannot install" below) |
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
- **Casks mise cannot install** (`steam`, `logitech-presentation`, `adobe-creative-cloud`, `displaylink`, `google-drive`, `logi-options+`) are NOT in `[bootstrap.packages]`: `scripts/brew-only-casks.sh` (first step of the `bootstrap` task) installs them with `brew install --cask`, and `brew upgrade` keeps them current. Reasons: steam's download has no `Steam.app` (mise: "app artifact 'Steam.app' was not found"); logitech-presentation has only a `manual` installer app (mise: "only script installers are supported"; run `LogiPresentation Installer.app` from its Caskroom folder once); the other four are pkg/installer casks that brew installs fine but were never verified with mise. A failing cask aborts the whole `mise bootstrap packages apply`, so unverified ones stay out of it.
- **Packages never upgrade on apply.** Docs: `apply` "installs missing packages but does not upgrade". Upgrades are separate. `mise bootstrap packages upgrade` only upgrades casks that mise itself installed; casks installed by Homebrew print "installed and managed by Homebrew; leaving unchanged". Called with no names it upgrades EVERY declared package, including microsoft-office when mise owns it (e.g. after a fresh-laptop bootstrap), which wipes Outlook, so never run it bare or use `mise bootstrap --upgrade`. The `update` function (in `~/.zshrc`) runs `brew upgrade --formula`, then upgrades outdated casks only by an explicit name list without any `microsoft-*` cask and with `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1` (current Homebrew otherwise upgrades `auto_updates` casks such as microsoft-office on a plain `brew upgrade`, which wipes Outlook), then `mise bootstrap packages upgrade --yes <explicit list of the declared casks minus every microsoft-* cask>`, then `mise upgrade`. It refuses to run the mise step if the list comes out empty.
- `gh` is in mise. The git credential helper points at the mise shim (`$HOME/.local/share/mise/shims/gh`), which works for non-interactive git (IDEs) once tools are installed; `zprofile` also activates shims for login shells.
- hugo is the plain `hugo` mise tool: since 0.170 there is a single binary (the extended edition was removed). SCSS/Sass themes need Dart Sass installed separately (not managed here).
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
The `update` function in `~/.zshrc` (from `dotfiles/zshrc`) runs `brew update && brew upgrade --formula && brew cleanup` (with `HOMEBREW_UPGRADE_GREEDY*` unset and `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1`), then an explicit-name `brew upgrade --cask` without `microsoft-*` casks, then `mise bootstrap packages upgrade --yes` with an explicit cask list that excludes every `microsoft-*` cask, then `mise upgrade`.

**Where the data lives.**
- `~/Library/Group Containers/UBF8T346G9.Office` (includes `Outlook 15 Profiles`)
- `~/Library/Containers/com.microsoft.Outlook`

**Scripts.** `~/bin/backup-outlook.sh [dest_dir]` (default `~/Backups`) writes `outlook-backup-YYYYMMDD-HHMMSS.zip`;
`~/bin/restore-outlook.sh <archive> [--force]` restores it. Restore accepts the current `.zip` and the older
`.tar.gz`/`.tgz` archives (members rooted at `Library/...`, made without xattrs/ACLs).

**Moving to the new laptop.**
1. Quit all Office apps (Outlook, Word, Excel, PowerPoint, OneNote, Teams, AutoUpdate) on the old machine and run `backup-outlook.sh`.
2. Copy the archive to the new machine.
3. Install Office via `mise bootstrap` (the `brew-cask:microsoft-office` package). Do NOT launch Outlook.
4. Run `restore-outlook.sh <archive> --force` (moves any fresh install data aside).
5. Launch Outlook.

Notes:
- **Running-app check.** Both scripts refuse to run while a real Office app is running (main binaries of Outlook, Word, Excel, PowerPoint, OneNote, Teams, Microsoft AutoUpdate / Update Assistant) and print which. Microsoft Edge and the macOS-managed widget extensions (`*.appex` such as `TeamsWidgetExtension`, `WordWidget_mac`) are deliberately ignored: Edge does not write the Office containers and the widgets are kept alive by macOS. The first version matched every `/Applications/Microsoft ` process, so it could never pass while Edge was open.
- **Format and what is preserved.** The zip is made with `ditto -c -k --sequesterRsrc`; extended attributes (about 58k files carry them) and ACLs ride along as AppleDouble `__MACOSX/` entries and come back on restore. Symlinks are kept. Not included: keychain tokens/passwords (re-authenticate every account) and anything outside the three paths below.
- **Why not tar.gz.** The first version used `tar --mac-metadata -czpf`. On this data bsdtar 3.5.3 (libarchive 3.7.4) wrote an archive it could not read back (`tar: Special header too large`), so its own `tar -tzf` verification failed and no backup was produced. `tar --no-mac-metadata --no-xattrs --no-acls` does round-trip but drops xattrs/ACLs (accounts, signatures and the mail cache are plain file contents, so Outlook does not need them, but a zip that keeps them is closer to the original). The old `.tar.gz` format is still accepted on restore.
- **Backup safety.** It writes `*.partial`, then checks `unzip -t`, that all expected members are listed, and that the entry count matches the staged tree, before renaming. It prints the sha256 and entry count, and prints "Wrote ..." only after all of that passed. Because `ditto` takes one source, it first APFS-clones the members into a staging dir in `$HOME` (removed on exit; a plain copy, needing about 2 GB free, if cloning is unavailable).
- **Restore safety.** It validates the archive first, rejects absolute, `..` or non-`Library/` entries, refuses to overwrite existing targets without `--force`, extracts into a staging dir and verifies entry counts, only then moves existing targets aside to `*.bak-<epoch>` (never deleted) and moves the restored members into `$HOME`. Only restore archives you made yourself.
- Your terminal needs Full Disk Access (System Settings > Privacy & Security) to read/write these containers.
- A fresh Office install will likely already have created the Group Container, so restore needs `--force`.
- The optional `~/Library/Preferences/com.microsoft.Outlook.plist` is included when present.

**Testing status.** Backup and restore were run end to end only against a scratch `$HOME` holding a copy of a real backup of the Office group container (58k files) plus the Outlook container: zip create/verify/restore, the refuse-without-`--force` path, the `--force` move-aside path, and restore of an existing-style `.tar.gz`. File counts, a 1,535-file sha256 sample and xattr counts matched. It has NOT been tested into the real `~/Library`, on a second machine, or with Outlook then launching against the restored data. The new Outlook may also sync some settings server-side, so results can differ from a pure file restore. Keep the original data until verified.

## 3. Edge apps and the Parallels VM

- Edge web apps (Canvas, Spotify): `scripts/edge-pwas.sh` (run by the bootstrap task) is best-effort and UNVERIFIED (create-pwa.sh now launches Edge via `open -na` so it does not block); the
  Edge flags it uses may not produce a real app bundle. The reliable path: Edge > ... > Apps >
  Install this site as an app. URLs: Canvas `https://unt.instructure.com/`, Spotify `https://open.spotify.com/`.
- Parallels VM (`~/Parallels/Windows 11.pvm`) must be copied/restored manually. Install the
  `parallels` cask first; the dock item is skipped until the VM exists.

## 4. Nix retirement (done on the original machine, 2026-11-18)

Kept as a record and as a checklist if another machine still has nix.

1. For each former nix tool (aws, gh, jq, yq, buf, goreleaser, hugo, protoc, golangci-lint, scc, vhs, zig, rustc, cargo,
   exiftool), check that `mise which <tool>` resolves (use `MISE_EXEC_AUTO_INSTALL=false` so the check does not install anything). `gcloud` (cask `gcloud-cli`) and `nmap` (formula) come from `[bootstrap.packages]`, not `[tools]`: check them with `command -v` and make sure it points at `/opt/homebrew`, not `/nix`.
2. Move the old `~/.config/nix` checkout out of the way (it was moved to `~/Backups/nix-config-old-<date>`, which also keeps any uncommitted edits). Its flake has `cleanup = "zap"`, so never run `darwin-rebuild` from it.
3. Remove symlinks that point into `/nix/store` from the home folder, and only those (this includes `~/.config/git/config` and `~/.config/git/ignore`, which home-manager may have linked; `~/.config/git/ignore` is then recreated by `[dotfiles]`): `find ~/.zshenv ~/.config/git ~/.vscode/extensions ~/Applications ~/.cache ~/.local/state -maxdepth 2 -type l -lname '/nix/store/*' -delete`. Real extension folders are not touched. Then remove `~/.nix-profile`, `~/.nix-channels`, `~/.nix-defexpr`, `~/.local/state/nix`.
4. `brew uninstall` the formulae mise `[tools]` now owns, after confirming each binary with `mise which`. `brew uninstall` refuses if something depends on a formula. Keep `mise` and the `[bootstrap.packages]` formulae. Then `brew untap` the taps no longer needed (including `buo/cask-upgrade`, which provides `brew cu`), and review `brew autoremove -n` before running it, because it also removes orphaned dependencies you may use (pandoc, deno).
5. Uninstall nix-darwin, then nix. Both need sudo and a real terminal:
   - `sudo darwin-uninstaller` removes the nix-darwin `/etc` links and restores the `/etc/*.before-nix-darwin` files. It does not run brew, so it does not touch Outlook. `/etc/pam.d/sudo_local` survived because `scripts/touchid-sudo.sh` had already replaced the symlink with a regular file.
   - `sudo /nix/nix-installer uninstall --no-confirm` (Determinate installer). Without `--no-confirm` it asks "Proceed?" and fails with "unable to read from stdin" when run through Claude Code's `!` prefix. It removes the daemons, the build users and the encrypted `Nix Store` APFS volume.
   - Afterwards: reboot (or open a new terminal; shells started before still carry the old nix PATH), and check that `/run/current-system` and the Determinate LaunchDaemons are gone. An empty `/nix` mount point and an empty `/Applications/Nix Apps` may remain until reboot; `sudo rmdir "/Applications/Nix Apps"` removes the latter.
6. Verify: `/etc/pam.d/sudo_local` still has `pam_reattach` above `pam_tid`, Outlook's containers are intact, `mise bootstrap plan` shows nothing to create.

Casks that `mise bootstrap` installs through `brew-cask:` may show up in `brew doctor` as "Caskroom directories without valid metadata" (seen for `zed` and `hoppscotch`). The apps run; `brew upgrade` just cannot update them, so update those two from inside the app.

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

## 6. AI tool config (Claude Code, Codex, Copilot CLI)

`[dotfiles]` in `mise.toml` captures the hand-written part of the AI tools' config, so a new laptop gets it
from `mise bootstrap`. Sources are under `dotfiles/claude/`, `dotfiles/codex/` and `dotfiles/copilot/`.

| Captured | Mode |
|---|---|
| `~/.claude/CLAUDE.md`, `~/.claude/skills/{bash-tool-habits,git-worktree-workflow,go-present,go-test-conventions}/` (one entry per skill directory; mise copies directories) | copy |
| `~/.claude/settings.json`: only `permissions`, `model`, `skillOverrides`, `statusLine`, `enabledPlugins`, `extraKnownMarketplaces`, `effortLevel`, `tui`, `skipDangerousModePermissionPrompt`, `theme`, `switchModelsOnFlag`, `agentPushNotifEnabled` | merge (json) |
| `~/.codex/AGENTS.md`, `~/.codex/RTK.md` (AGENTS.md includes `@RTK.md`; `rtk` is in the tools list) | copy |
| `~/.codex/config.toml`: only `model`, `model_reasoning_effort`, `approvals_reviewer`, `service_tier`, `web_search`, `[features]`, `[tui]`, `[memories]` | merge (toml) |
| `~/.copilot/mcp-config.json` | copy |
| `~/.copilot/settings.json`: only `allowedUrls` and `model` | merge (json) |

**Deliberately NOT captured:**
- Auth and secrets (`~/.codex/auth.json`), Codex memories, history, sessions, sqlite, logs, caches, `*.local.json`, trusted-project lists and hook trust hashes.
- Anything a plugin or tool installs itself: `~/.claude/skills/synced`, `~/.agents/skills`, the herdr skill, and every `hooks/` directory (installed by herdr and caveman). Those re-install themselves.
- Files with machine-specific absolute paths: the `hooks` key of Claude's and Copilot's `settings.json`, `~/.codex/hooks.json`, Claude's `autoMode` (names specific repos), `~/.copilot/config.json` and `permissions-config.json`, Codex `[projects.*]`, `[hooks.*]`, `[marketplaces.*]`, `[plugins.*]`, `[mcp_servers.*]`, `notify`.

**Merge behaviour** (checked in a scratch `$HOME`): a missing target is created from the source; keys only the target has
(`hooks`, extra `deny` rules, other plugins, Codex `[projects.*]`) are kept; nested objects merge recursively, but
**arrays are replaced, not unioned**, so `permissions.allow` and `allowedUrls` in the repo win on every apply (an extra
allow rule added in the app is dropped; add it to the source instead). Scalars such as `model` are reset to the repo value
on apply; use `merge = "missing"` on an entry if the app should win. TOML comments and key order are preserved.

**Editing:** copy mode means the live file and the repo diverge when you edit the live one. Copy edits back with
`mise dot add --changed` (updates every changed copy-mode file; it does not pick up files inside the skill directories) or
`mise dot add '~/.claude/skills/<name>'` for a skill, then commit. Merge entries are not copied back: edit the
`*.shared.*` source. `mise dot diff` shows what an apply would change.

Known inconsistency: `~/.codex/AGENTS.md` still says to enable squash auto-merge, while `~/.claude/CLAUDE.md` says not to.
Both are copied as they are.
