# nix-darwin -> mise

This repo sets up a macOS machine with mise: `[tools]` for CLIs and runtimes, `[dotfiles]` for config,
and `mise bootstrap` for casks, macOS defaults and setup scripts. The old nix-darwin flake has been removed from this repo.

## New laptop

**Before anything else, back up Outlook on the old machine** (`~/bin/backup-outlook.sh`) and copy the archive
somewhere that survives (OneDrive, external disk). Outlook accounts and signatures took days to rebuild once.
Details and the restore order: [docs/MIGRATION.md](docs/MIGRATION.md#2-warning-microsoft-outlook).

On the new Apple Silicon Mac (the scripts hard-code `/opt/homebrew`; Intel is not supported), open **Terminal** (it needs a real terminal: Touch ID sudo and Wireshark ask for your password) and run:

```sh
curl -fsSL https://raw.githubusercontent.com/jh125486/nix-darwin/main/bootstrap.sh -o /tmp/bootstrap.sh
bash /tmp/bootstrap.sh
```

`bootstrap.sh` is safe to re-run. It:

1. Installs Homebrew if missing, then mise.
2. Runs `mise bootstrap --from <this repo>`, which clones the repo to `~/.dotfiles` and applies it:
   brew formulae and casks (including Microsoft Office), dotfiles (`~/.zshrc`, `~/.gitconfig`, `~/.config/mise/config.toml`, ...),
   macOS defaults (Dock on the right, Finder list view), Touch ID for sudo, VS Code extensions, Edge apps and the Dock order.
3. Runs `mise install` to make sure every tool in `~/.config/mise/config.toml` is installed.

Then, in this order:

1. **Restore Outlook before opening it for the first time:** `~/bin/restore-outlook.sh <archive> --force`.
   Expect to sign in to each account again (keychain tokens are not in the backup).
2. Sign in to `gh`, 1Password and the other apps.
3. Recreate the Parallels VM and the Edge apps manually (the Edge apps script is best-effort), then re-run `~/.dotfiles/scripts/dock.sh`.

## Existing machine

Re-run setup: `mise -C ~/.dotfiles bootstrap`. Update everything with the `update` alias (in `~/.zshrc`).

**Never** use `brew cu`, `brew upgrade --greedy` or `mise bootstrap --upgrade`: they can reinstall
Microsoft Office and wipe Outlook.

Full details, the Outlook warning, and the cutover checklist: [docs/MIGRATION.md](docs/MIGRATION.md).
