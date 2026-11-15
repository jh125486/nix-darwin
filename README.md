# nix-darwin -> mise

This repo sets up a macOS machine with mise: `[tools]` for CLIs and runtimes, `[dotfiles]` for config,
and `mise bootstrap` for casks, macOS defaults and setup scripts. The old nix-darwin `flake.nix` is retired.

New machine: `./bootstrap.sh`. Re-run on an existing machine: `mise -C ~/.dotfiles bootstrap`.
Full details, the Outlook warning, and the cutover checklist: [docs/MIGRATION.md](docs/MIGRATION.md).
