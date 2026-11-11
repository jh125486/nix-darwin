# nix-darwin -> mise + Brewfile + chezmoi

This repo manages a macOS machine with chezmoi (source root: `home/`), a `Brewfile`, and mise.
The old nix-darwin `flake.nix`/`flake.lock` are retained only until retirement.

New machine: `./bootstrap.sh`. Full details, the Outlook warning, and the cutover checklist
are in [docs/MIGRATION.md](docs/MIGRATION.md).
